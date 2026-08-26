package com.gamelearn.service;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.gamelearn.ai.gemini.GenerationRateLimiter;
import com.gamelearn.ai.gemini.GeminiClient;
import com.gamelearn.ai.gemini.GeminiPermanentException;
import com.gamelearn.ai.gemini.GeminiPrompt;
import com.gamelearn.ai.gemini.GeminiTransientException;
import com.gamelearn.ai.parser.GeneratedPathCandidate;
import com.gamelearn.ai.parser.LearningPathOutputParser;
import com.gamelearn.ai.prompts.LearningPathPromptBuilder;
import com.gamelearn.ai.validation.AiBusinessValidator;
import com.gamelearn.ai.validation.AiContentSafetyValidator;
import com.gamelearn.ai.validation.AiOutputRejectionException;
import com.gamelearn.ai.validation.AiSchemaValidator;
import com.gamelearn.ai.validation.ValidatedPathPlan;
import com.gamelearn.config.AiProperties;
import com.gamelearn.entity.LearningPath;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.User;
import com.gamelearn.service.context.LearnerPathContext;
import com.gamelearn.entity.enums.GeneratedBy;

/**
 * PATH-002 orchestration (Learning Path AI Specification sections 5, 26-31;
 * central API Contract section 5).
 *
 * <p>Guarantees implemented here:</p>
 * <ul>
 * <li>Idempotent normal generation: an existing ACTIVE path is returned
 *     unchanged with ZERO Gemini calls and zero rate-limit consumption.</li>
 * <li>Rate limiting applies only when Gemini generation actually happens.</li>
 * <li>The approved retry policy: one automatic retry for transient failures,
 *     exponential backoff with jitter, overall deadline; deterministic output
 *     rejections are never retried.</li>
 * <li>Fallback: any AI failure/rejection delivers the deterministic SYSTEM
 *     path through identical validation.</li>
 * <li>Regeneration safety: the replacement is generated and FULLY validated
 *     BEFORE a single transaction archives the old path and persists the new
 *     one; any failure leaves the old path ACTIVE.</li>
 * </ul>
 */
@Service
public class LearningPathGenerationService {

    private static final Logger log = LoggerFactory.getLogger(LearningPathGenerationService.class);
    private static final SecureRandom RANDOM = new SecureRandom();

    private final LearningPathPersistenceService persistenceService;
    private final com.gamelearn.repository.UserRepository userRepository;
    private final LearnerContextBuilder contextBuilder;
    private final SubjectService subjectService;
    private final LearningPathPromptBuilder promptBuilder;
    private final GeminiClient geminiClient;
    private final AiProperties properties;
    private final GenerationRateLimiter rateLimiter;
    private final LearningPathOutputParser outputParser;
    private final AiSchemaValidator schemaValidator;
    private final AiContentSafetyValidator safetyValidator;
    private final AiBusinessValidator businessValidator;
    private final FallbackPathPlanner fallbackPlanner;
    private final AiInteractionAuditService auditService;
    private final Object generationLock = new Object();

    public LearningPathGenerationService(LearningPathPersistenceService persistenceService,
                                         com.gamelearn.repository.UserRepository userRepository,
                                         LearnerContextBuilder contextBuilder,
                                         SubjectService subjectService,
                                         LearningPathPromptBuilder promptBuilder,
                                         GeminiClient geminiClient,
                                         AiProperties properties,
                                         GenerationRateLimiter rateLimiter,
                                         LearningPathOutputParser outputParser,
                                         AiSchemaValidator schemaValidator,
                                         AiContentSafetyValidator safetyValidator,
                                         AiBusinessValidator businessValidator,
                                         FallbackPathPlanner fallbackPlanner,
                                         AiInteractionAuditService auditService) {
        this.persistenceService = persistenceService;
        this.userRepository = userRepository;
        this.contextBuilder = contextBuilder;
        this.subjectService = subjectService;
        this.promptBuilder = promptBuilder;
        this.geminiClient = geminiClient;
        this.properties = properties;
        this.rateLimiter = rateLimiter;
        this.outputParser = outputParser;
        this.schemaValidator = schemaValidator;
        this.safetyValidator = safetyValidator;
        this.businessValidator = businessValidator;
        this.fallbackPlanner = fallbackPlanner;
        this.auditService = auditService;
    }

    /**
     * Executes PATH-002 for the authenticated learner.
     *
     * @return the delivered outcome; {@code created=false} marks the
     *         idempotent return of an existing ACTIVE path.
     */
    public GenerationOutcome generate(UUID userId, UUID subjectId, boolean regenerate,
                                      String sanitizedLearningGoal, String correlationId) {
        // Step 0: resolve the authenticated account server-side.
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new com.gamelearn.exception.ApiException(
                        com.gamelearn.exception.ErrorCode.UNAUTHORIZED.getHttpStatus(),
                        com.gamelearn.exception.ErrorCode.UNAUTHORIZED.name(),
                        "Authentication required"));

        // Step 1: subject must exist and be active - before anything else.
        Subject subject = subjectService.requireActiveSubject(subjectId);

        // Step 2: idempotency gate - NEVER call Gemini or consume quota here.
        LearningPath activePath = contextBuilder.findActivePath(user.getId(), subject.getId());
        if (!regenerate && activePath != null) {
            log.info("AI-LP idempotent return for subject {}", subject.getId());
            return GenerationOutcome.idempotent(activePath);
        }

        synchronized (lockFor(user.getId(), subjectId)) {
            // Re-check under the per-(user,subject) guard (concurrent double-submit).
            activePath = contextBuilder.findActivePath(user.getId(), subject.getId());
            if (!regenerate && activePath != null) {
                return GenerationOutcome.idempotent(activePath);
            }

            // Step 3: rate limit - only now can a Gemini-backed call happen.
            if (!rateLimiter.tryAcquire(user.getId())) {
                throw new com.gamelearn.exception.ApiException(
                        com.gamelearn.exception.ErrorCode.AI_RATE_LIMITED.getHttpStatus(),
                        com.gamelearn.exception.ErrorCode.AI_RATE_LIMITED.name(),
                        "Learning path generation limit reached. Try again later.");
            }

            // Step 4: context from verified state only.
            var context = contextBuilder.build(user, subject, sanitizedLearningGoal);

            // Steps 5-7: generate + validate the candidate (or fall back).
            GenerationResult result = generateWithFallback(user, subject, context, correlationId);

            // Steps 8-9: persistence - regeneration swaps atomically. A
            // failure here rolls back EVERYTHING (old path untouched) and
            // writes an independent FAILED audit row before surfacing a safe
            // error (spec section 30.2).
            if (result.plan() == null) {
                throw new com.gamelearn.exception.ApiException(
                        com.gamelearn.exception.ErrorCode.AI_GENERATION_FAILED.getHttpStatus(),
                        com.gamelearn.exception.ErrorCode.AI_GENERATION_FAILED.name(),
                        "Learning path generation failed");
            }
            try {
                LearningPathPersistenceService.Delivery delivery;
                if (regenerate && activePath != null) {
                    delivery = persistenceService.archiveAndInsert(activePath.getId(), user, subject,
                            result.plan(), result.generatedBy(), auditService, result.modelName(),
                            result.promptVersion(), result.sanitizedContext(), result.sanitizedResponse(),
                            result.latencyMs(), result.errorCode());
                } else {
                    delivery = persistenceService.insertPath(user, subject, result.plan(),
                            result.generatedBy(), auditService, result.modelName(),
                            result.promptVersion(), result.sanitizedContext(),
                            result.sanitizedResponse(), result.latencyMs(), result.errorCode());
                }
                log.info("AI-LP delivered {} path with {} nodes", result.generatedBy(),
                        delivery.nodeCount());
                return GenerationOutcome.created(delivery.pathId(), result.generatedBy(),
                        result.plan());
            } catch (RuntimeException persistFailure) {
                log.warn("AI-LP persistence failed; rolling back: {}", persistFailure.getMessage());
                auditService.recordFailureIndependently(user, subject, result.promptVersion(),
                        "LP_PERSISTENCE_FAILED");
                throw new com.gamelearn.exception.ApiException(
                        com.gamelearn.exception.ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                        com.gamelearn.exception.ErrorCode.INTERNAL_ERROR.name(),
                        "Learning path could not be saved");
            }
        }
    }

    private GenerationResult generateWithFallback(User user, Subject subject,
                                                  LearnerPathContext context, String correlationId) {
        String promptVersion = promptBuilder.promptVersion();
        // Deterministic-only mode: never render a prompt or touch the client.
        if (!properties.getLearningPath().isEnabled()) {
            return fallback(user, subject, context, "LP_GEMINI_DISABLED", 0);
        }
        String modelName = aiModelName();
        long startedAt = System.currentTimeMillis();
        try {
            String promptText = promptBuilder.build(context);
            Instant deadline = Instant.now().plus(properties.getLearningPath().getDeadline());
            int maxAttempts = properties.getLearningPath().getRetry().getMaxRetries() + 1;

            String rawResponse = null;
            GeminiTransientException lastTransient = null;
            for (int attempt = 1; attempt <= maxAttempts && rawResponse == null; attempt++) {
                try {
                    rawResponse = geminiClient.generate(new GeminiPrompt(promptText, promptVersion,
                            correlationId));
                } catch (GeminiPermanentException permanent) {
                    // Deterministic client failure - never retried; fallback follows.
                    lastTransient = null;
                    break;
                } catch (GeminiTransientException transientEx) {
                    lastTransient = transientEx;
                    boolean attemptsRemain = attempt < maxAttempts;
                    if (!attemptsRemain || !sleepBackoff(attempt, deadline)) {
                        break;
                    }
                }
            }

            int latencyMs = (int) (System.currentTimeMillis() - startedAt);
            if (rawResponse == null) {
                String category = lastTransient != null ? lastTransient.getCategory()
                        : "LP_GEMINI_REJECTED_CLIENT";
                log.info("AI-LP Gemini failed after retries: {}", category);
                return fallback(user, subject, context, category, latencyMs);
            }

            GeneratedPathCandidate candidate = outputParser.parse(rawResponse);
            schemaValidator.validate(candidate, context.catalog().size());
            // C-4 (amended, spec section 25.1): per-node relevance against
            // the server-authoritative catalog; paraphrases accepted.
            if (!safetyValidator.isSafe(candidate, context.catalog())) {
                throw new AiOutputRejectionException("LP_UNSAFE_CONTENT",
                        "Generated content was rejected");
            }
            ValidatedPathPlan plan = businessValidator.validate(candidate, context);

            String sanitizedContext = promptBuilder.learnerDataJson(context);
            String sanitizedResponse = AiInteractionAuditService.successResponseJson(
                    GeneratedBy.AI.name(), plan.nodes().size());
            return new GenerationResult(plan, GeneratedBy.AI, modelName, promptVersion,
                    sanitizedContext, sanitizedResponse, latencyMs, null);
        } catch (AiOutputRejectionException rejection) {
            int latencyMs = (int) (System.currentTimeMillis() - startedAt);
            log.info("AI-LP output rejected ({}), falling back", rejection.getAuditErrorCode());
            return fallback(user, subject, context, rejection.getAuditErrorCode(), latencyMs);
        }
    }

    /** Deterministic SYSTEM path through the same validation gates (spec section 28). */
    private GenerationResult fallback(User user, Subject subject, LearnerPathContext context,
                                      String failureCategory, int latencyMs) {
        ValidatedPathPlan plan = fallbackPlanner.plan(context); // cannot fail while catalog non-empty
        String promptVersion = promptBuilder.promptVersion();
        String sanitizedContext = promptBuilder.learnerDataJson(context);
        String sanitizedResponse = AiInteractionAuditService.fallbackResponseJson(failureCategory);
        return new GenerationResult(plan, GeneratedBy.SYSTEM, aiModelName(), promptVersion,
                sanitizedContext, sanitizedResponse, latencyMs, failureCategory);
    }

    private String aiModelName() {
        // Recorded verbatim in audit rows; NULL when disabled/unconfigured -
        // never fabricate a model name for SYSTEM-only deliveries.
        if (!properties.getLearningPath().isEnabled()) {
            return null;
        }
        String model = properties.getGemini().getModel();
        return (model == null || model.isBlank()) ? null : model;
    }

    /**
     * Approved backoff: base 2 s +/- 25% jitter, bounded by the overall
     * deadline. Returns false when sleeping would exceed the deadline.
     */
    private boolean sleepBackoff(int attempt, Instant deadline) {
        Duration base = properties.getLearningPath().getRetry().getBackoffBase();
        double jitterFactor = 1.0 + (RANDOM.nextDouble() * 2 - 1)
                * properties.getLearningPath().getRetry().getJitterFraction();
        long sleepMs = (long) (base.toMillis() * Math.pow(2, attempt - 1) * jitterFactor);
        if (Instant.now().plusMillis(sleepMs).isAfter(deadline)) {
            return false;
        }
        try {
            Thread.sleep(sleepMs);
            return true;
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
            return false;
        }
    }

    private Object lockFor(UUID userId, UUID subjectId) {
        return generationLock; // single-instance serialization of generation per JVM
    }

    /** Pipeline outcome before persistence. */
    private record GenerationResult(ValidatedPathPlan plan, GeneratedBy generatedBy,
                                    String modelName, String promptVersion,
                                    String sanitizedContext, String sanitizedResponse,
                                    Integer latencyMs, String errorCode) {
    }

    /**
     * What PATH-002 delivers to the controller. {@code plan} carries the
     * in-memory validated candidate (for optional aiMetadata display fields)
     * and is null for idempotent returns.
     */
    public record GenerationOutcome(UUID pathId, GeneratedBy generatedBy, boolean created,
                                    ValidatedPathPlan plan) {

        static GenerationOutcome idempotent(LearningPath existing) {
            return new GenerationOutcome(existing.getId(), existing.getGeneratedBy(),
                    false, null);
        }

        static GenerationOutcome created(UUID pathId, GeneratedBy generatedBy,
                                         ValidatedPathPlan plan) {
            return new GenerationOutcome(pathId, generatedBy, true, plan);
        }
    }
}
