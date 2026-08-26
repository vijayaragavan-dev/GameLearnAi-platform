package com.gamelearn.service;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.gamelearn.ai.gemini.GenerationOptions;
import com.gamelearn.ai.gemini.GeminiClient;
import com.gamelearn.ai.gemini.GeminiPermanentException;
import com.gamelearn.ai.gemini.GeminiPrompt;
import com.gamelearn.ai.gemini.GeminiTransientException;
import com.gamelearn.ai.gemini.TutorRateLimiter;
import com.gamelearn.ai.prompts.TutorPromptBuilder;
import com.gamelearn.ai.validation.TutorOutputValidator;
import com.gamelearn.ai.validation.TutorRefusalClassifier;
import com.gamelearn.config.AiProperties;
import com.gamelearn.dto.AiTutorRequest;
import com.gamelearn.dto.AiTutorResponse;
import com.gamelearn.entity.User;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.logging.RequestCorrelationFilter;
import com.gamelearn.repository.UserRepository;
import com.gamelearn.service.TutorContextBuilder.TutorContext;

/**
 * AI-001 orchestration (AI-TUTOR v1.0.0 APPROVED; API Contract v1.4.0
 * section 5D): retrieve the allowlisted learner context -> build the
 * versioned prompt -> Gemini (one logical request, one approved retry) ->
 * validate output strictly -> answer.
 *
 * <p>Boundaries honored: the Tutor EXPLAINS and never MUTATES - zero writes
 * outside sanitized {@code ai_interactions} (type=TUTOR) audit rows.
 * STATELESS: conversation content is never persisted. NO-FALLBACK: provider
 * failures surface as the safe 503 envelope (OT-3); unsafe outputs surface
 * as the deterministic degraded template. The full prompt is never logged,
 * stored or returned.</p>
 */
@Service
public class AiTutorService {

    private static final Logger log = LoggerFactory.getLogger(AiTutorService.class);
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final ObjectMapper MAPPER = new ObjectMapper();
    private static final String AUDIT_PREFIX = "TUTOR";

    // Internal failure/rejection categories (audit-only; never surfaced).
    static final String CAT_DISABLED = "TUTOR_DISABLED";
    static final String CAT_RATE_LIMITED = "TUTOR_RATE_LIMITED";
    static final String CAT_POLICY_REFUSAL = "TUTOR_POLICY_REFUSAL";

    private final UserRepository userRepository;
    private final TutorContextBuilder contextBuilder;
    private final TutorPromptBuilder promptBuilder;
    private final TutorRefusalClassifier refusalClassifier;
    private final TutorOutputValidator outputValidator;
    private final TutorRateLimiter rateLimiter;
    private final AiInteractionAuditService auditService;
    private final AiProperties properties;
    private final GeminiClient geminiClient;

    public AiTutorService(UserRepository userRepository,
                          TutorContextBuilder contextBuilder,
                          TutorPromptBuilder promptBuilder,
                          TutorRefusalClassifier refusalClassifier,
                          TutorOutputValidator outputValidator,
                          TutorRateLimiter rateLimiter,
                          AiInteractionAuditService auditService,
                          AiProperties properties,
                          GeminiClient geminiClient) {
        this.userRepository = userRepository;
        this.contextBuilder = contextBuilder;
        this.promptBuilder = promptBuilder;
        this.refusalClassifier = refusalClassifier;
        this.outputValidator = outputValidator;
        this.rateLimiter = rateLimiter;
        this.auditService = auditService;
        this.properties = properties;
        this.geminiClient = geminiClient;
    }

    /**
     * Executes AI-001 for the authenticated learner.
     *
     * <p>Ordering is normative (spec sections 6/12/13/14): disabled gate ->
     * focus resolution -> input sanitization/caps -> policy refusal ->
     * prompt budget -> rate limit -> Gemini retry loop -> strict validation
     * -> response. Validation rejections happen BEFORE quota consumption;
     * internal retries never consume extra slots.</p>
     */
    public AiTutorResponse ask(UUID authenticatedUserId, AiTutorRequest request) {
        User user = userRepository.findById(authenticatedUserId)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.UNAUTHORIZED.getHttpStatus(),
                        ErrorCode.UNAUTHORIZED.name(),
                        "Authentication required"));

        // OT-3/H: feature disabled -> controlled 503 before any other work.
        if (!properties.getTutor().isEnabled()) {
            writeIndependentFailure(user, withIds(null), 0, 0, CAT_DISABLED);
            throw unavailable("AI tutor is not enabled.");
        }

        // Focus resolution (server-authoritative referential checks).
        TutorContext context = contextBuilder.resolve(user.getId(),
                request.subjectId(), request.topicId());

        // Input sanitization then post-strip caps (spec section 8.1 ordering).
        String question = TutorPromptBuilder.sanitizeUntrusted(request.question());
        requireCap(question.isEmpty(), "question", "question is required");
        requireCap(question.length() > TutorPromptBuilder.QUESTION_MAX_CHARS,
                "question", "question must be at most "
                        + TutorPromptBuilder.QUESTION_MAX_CHARS + " characters");

        List<String> historyTurns = new ArrayList<>();
        List<AiTutorRequest.ConversationMessage> conversation =
                request.conversation() == null ? List.of() : request.conversation();
        int index = 0;
        for (AiTutorRequest.ConversationMessage message : conversation) {
            index++;
            String content = TutorPromptBuilder.sanitizeUntrusted(message.content());
            if (content.isEmpty()) {
                throw validationFailure("conversation",
                        "conversation[" + index + "] content is empty after normalization");
            }
            if (!TutorPromptBuilder.isAllowedRole(message.role())) {
                throw validationFailure("conversation",
                        "conversation[" + index + "] role must be LEARNER or TUTOR");
            }
            if (content.length() > TutorPromptBuilder.MESSAGE_MAX_CHARS) {
                throw validationFailure("conversation",
                        "conversation[" + index + "] content must be at most "
                                + TutorPromptBuilder.MESSAGE_MAX_CHARS + " characters");
            }
            historyTurns.add(TutorPromptBuilder.turnLine(message.role(), content));
        }

        // Policy refusal: deterministic, pre-Gemini, quota-free (section 12.3).
        if (refusalClassifier.isPolicyRefusal(question)) {
            auditRejectedRow(user, context, question.length(), historyTurns.size(),
                    CAT_POLICY_REFUSAL);
            return respond(promptBuilder.refusalTemplate(), true, false, context);
        }

        // Prompt budget (defense in depth over the per-field caps).
        String contextJson = renderContext(context);
        String promptText = promptBuilder.build(contextJson, historyTurns, question);
        if (promptText.length() > TutorPromptBuilder.RENDERED_PROMPT_BUDGET_CHARS) {
            throw new ApiException(
                    ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                    ErrorCode.VALIDATION_FAILED.name(),
                    "Request too large");
        }

        // Rate limit AFTER validation, BEFORE any Gemini contact (OT-4).
        if (!rateLimiter.tryAcquire(user.getId())) {
            writeIndependentFailure(user, context, question.length(), historyTurns.size(),
                    CAT_RATE_LIMITED);
            throw new ApiException(
                    ErrorCode.AI_RATE_LIMITED.getHttpStatus(),
                    ErrorCode.AI_RATE_LIMITED.name(),
                    "AI tutor limit reached. Try again later.");
        }

        // Gemini phase: exactly ONE automatic retry for transient failures.
        long startedAt = System.currentTimeMillis();
        GenerationOptions options = new GenerationOptions(
                properties.getTutor().getTemperature(),
                properties.getTutor().getMaxOutputTokens(),
                AUDIT_PREFIX);
        Instant deadline = Instant.now().plus(properties.getTutor().getDeadline());
        int maxAttempts = properties.getTutor().getRetry().getMaxRetries() + 1;

        String rawResponse = null;
        String lastCategory = null;
        boolean permanent = false;
        for (int attempt = 1; attempt <= maxAttempts && rawResponse == null; attempt++) {
            try {
                rawResponse = geminiClient.generate(new GeminiPrompt(promptText,
                        promptBuilder.promptVersion(),
                        RequestCorrelationFilter.currentRequestId()), options);
            } catch (GeminiPermanentException permanentEx) {
                lastCategory = permanentEx.getMessage();
                permanent = true;
                break; // deterministic provider fault - never retried
            } catch (GeminiTransientException transientEx) {
                lastCategory = transientEx.getCategory();
                if (attempt >= maxAttempts || !sleepBackoff(attempt, deadline)) {
                    break;
                }
            }
        }
        int latencyMs = (int) (System.currentTimeMillis() - startedAt);

        if (rawResponse == null) {
            String category = lastCategory != null ? lastCategory
                    : AUDIT_PREFIX + "_GEMINI_UNAVAILABLE";
            auditFailedRow(user, context, question.length(), historyTurns.size(),
                    category);
            throw unavailable("AI tutor is temporarily unavailable. Please try again shortly.");
        }

        // Strict validation chain; malformed/schema-invalid -> safe 503,
        // unsafe output -> deterministic degraded template (spec section 13).
        TutorOutputValidator.TutorAnswer validated;
        try {
            validated = outputValidator.validate(rawResponse);
        } catch (TutorOutputValidator.TutorOutputRejection rejection) {
            String category = rejection.category;
            if (TutorOutputValidator.MALFORMED.equals(category)
                    || TutorOutputValidator.SCHEMA_INVALID.equals(category)) {
                auditFailedRow(user, context, question.length(), historyTurns.size(),
                        category);
                throw unavailable("AI tutor is temporarily unavailable. Please try again shortly.");
            }
            auditRejectedRow(user, context, question.length(), historyTurns.size(), category);
            log.info("TUT_REJECTED category={} questionChars={} latencyMs={}",
                    category, question.length(), latencyMs);
            return respond(promptBuilder.degradedTemplate(), false, true, context);
        }

        auditSuccessRow(user, context, question.length(), historyTurns.size(),
                validated.answer().length(), validated.truncated(), latencyMs);
        log.info("TUT_ANSWERED questionChars={} answerChars={} truncated={} latencyMs={}",
                question.length(), validated.answer().length(), validated.truncated(),
                latencyMs);
        return respond(validated.answer(), false, false, context);
    }

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------

    /** Allowlist TC1-TC6 rendered as sanitized JSON (names/values only). */
    private String renderContext(TutorContext context) {
        ObjectNode root = MAPPER.createObjectNode();
        if (context.subjectName() != null) {
            root.put("subjectName", context.subjectName());
        }
        if (context.topicName() != null) {
            root.put("topicName", context.topicName());
            if (context.topicDifficulty() != null) {
                root.put("topicDifficulty", context.topicDifficulty());
            }
            if (context.mastery() != null) {
                ObjectNode masteryNode = root.putObject("learnerMasteryForTopic");
                masteryNode.put("masteryScore", context.mastery().score());
                masteryNode.put("masteryLevel", context.mastery().level());
                masteryNode.put("trend", context.mastery().trend());
                masteryNode.put("attemptCount", context.mastery().attemptCount());
            }
        }
        if (context.overallMastery() != null) {
            root.put("overallMastery", context.overallMastery());
        }
        if (context.currentLevel() > 1) { // TC6 note: omit until it differs from 1
            root.put("currentLevel", context.currentLevel());
        }
        return root.toString();
    }

    private AiTutorResponse respond(String answer, boolean refused, boolean degraded,
                                    TutorContext context) {
        return new AiTutorResponse(answer, refused, degraded,
                new AiTutorResponse.ContextView(
                        context.subjectIdOrNull(),
                        context.topicIdOrNull(),
                        context.subjectName(),
                        context.topicName()));
    }

    private void requireCap(boolean violated, String field, String message) {
        if (violated) {
            throw validationFailure(field, message);
        }
    }

    private ApiException validationFailure(String field, String message) {
        return new ApiException(
                ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                ErrorCode.VALIDATION_FAILED.name(),
                "Request validation failed",
                Map.of(field, message));
    }

    private ApiException unavailable(String message) {
        return new ApiException(
                ErrorCode.AI_SERVICE_UNAVAILABLE.getHttpStatus(),
                ErrorCode.AI_SERVICE_UNAVAILABLE.name(),
                message);
    }

    /** Exponential backoff with +/- jitter, capped by the remaining deadline. */
    private boolean sleepBackoff(int attempt, Instant deadline) {
        long remainingMillis = Duration.between(Instant.now(), deadline).toMillis();
        if (remainingMillis <= 0) {
            return false;
        }
        double jitter = 1.0
                + (RANDOM.nextDouble() * 2 - 1) * properties.getTutor().getRetry().getJitterFraction();
        long backoffMillis = (long) Math.min(Integer.MAX_VALUE,
                properties.getTutor().getRetry().getBackoffBase().toMillis()
                        * Math.pow(2, attempt - 1) * jitter);
        long sleepMillis = Math.min(backoffMillis, remainingMillis);
        if (sleepMillis <= 0) {
            return false;
        }
        try {
            Thread.sleep(sleepMillis);
            return true;
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
            return false;
        }
    }

    // ------------------------------------------------------------------
    // audit rows (counts/categories ONLY - never question/history/answer)
    // ------------------------------------------------------------------

    private String requestContextJson(TutorContext context, int questionChars,
                                      int historyMessages) {
        ObjectNode root = MAPPER.createObjectNode();
        if (context.subjectIdOrNull() != null) {
            root.put("subjectId", context.subjectIdOrNull().toString());
        }
        if (context.topicIdOrNull() != null) {
            root.put("topicId", context.topicIdOrNull().toString());
        }
        root.put("questionChars", questionChars);
        root.put("historyMessages", historyMessages);
        return root.toString();
    }

    private void auditSuccessRow(User user, TutorContext context, int questionChars,
                                 int historyMessages, int answerChars, boolean truncated,
                                 Integer latencyMs) {
        try {
            ObjectNode responseJson = MAPPER.createObjectNode();
            responseJson.put("answerChars", answerChars);
            responseJson.put("truncated", truncated);
            responseJson.put("refused", false);
            responseJson.put("degraded", false);
            auditService.recordTutor(user, properties.getGemini().getModel(),
                    promptBuilder.promptVersion(),
                    requestContextJson(context, questionChars, historyMessages),
                    responseJson.toString(),
                    com.gamelearn.entity.enums.AiInteractionStatus.SUCCESS,
                    latencyMs, null);
        } catch (RuntimeException auditLoss) {
            log.warn("Tutor success audit row lost: {}", auditLoss.getMessage());
        }
    }

    private void auditFailedRow(User user, TutorContext context, int questionChars,
                                int historyMessages, String category) {
        try {
            ObjectNode responseJson = MAPPER.createObjectNode();
            responseJson.put("errorCategory", category);
            auditService.recordTutor(user, null, promptBuilder.promptVersion(),
                    requestContextJson(context, questionChars, historyMessages),
                    responseJson.toString(),
                    com.gamelearn.entity.enums.AiInteractionStatus.FAILED,
                    null, category);
        } catch (RuntimeException auditLoss) {
            log.warn("Tutor failure audit row lost: {}", auditLoss.getMessage());
        }
    }

    private void auditRejectedRow(User user, TutorContext context, int questionChars,
                                  int historyMessages, String category) {
        try {
            ObjectNode responseJson = MAPPER.createObjectNode();
            responseJson.put("errorCategory", category);
            auditService.recordTutor(user, null, promptBuilder.promptVersion(),
                    requestContextJson(context, questionChars, historyMessages),
                    responseJson.toString(),
                    com.gamelearn.entity.enums.AiInteractionStatus.REJECTED,
                    null, category);
        } catch (RuntimeException auditLoss) {
            log.warn("Tutor rejection audit row lost: {}", auditLoss.getMessage());
        }
    }

    /**
     * Independent-persistence wrapper for failures that occur outside any
     * transactional guarantee (disabled flag, quota, provider faults) -
     * mirrors the LP convention that failure history always survives.
     */
    private void writeIndependentFailure(User user, TutorContext context,
                                         Integer questionChars, Integer historyMessages,
                                         String category) {
        try {
            auditService.recordTutorFailureIndependently(user,
                    promptBuilder.promptVersion(),
                    requestContextJson(withIds(context), questionChars == null ? 0 : questionChars,
                            historyMessages == null ? 0 : historyMessages),
                    category);
        } catch (RuntimeException auditLoss) {
            log.warn("Independent tutor failure audit row lost: {}", auditLoss.getMessage());
        }
    }

    /**
     * The disabled-gate check runs before focus resolution, where the
     * context would be null; ids are simply absent from those rows.
     */
    private TutorContext withIds(TutorContext context) {
        return context != null ? context
                : new TutorContext(null, null, null, null, null, null, 1, null);
    }
}
