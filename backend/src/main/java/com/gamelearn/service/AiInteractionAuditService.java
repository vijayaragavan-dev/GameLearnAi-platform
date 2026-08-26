package com.gamelearn.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.entity.AiInteraction;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.AiInteractionStatus;
import com.gamelearn.entity.enums.AiInteractionType;
import com.gamelearn.repository.AiInteractionRepository;

/**
 * AI interaction auditing for PATH-002 (Learning Path AI Specification
 * sections 36-38). One sanitized row per actual Gemini attempt; failure rows
 * use an independent transaction so history survives main-transaction
 * rollbacks. Never stores keys, tokens, prompts, or raw model output.
 */
@Service
public class AiInteractionAuditService {

    private static final Logger log = LoggerFactory.getLogger(AiInteractionAuditService.class);

    private final AiInteractionRepository aiInteractionRepository;

    public AiInteractionAuditService(AiInteractionRepository aiInteractionRepository) {
        this.aiInteractionRepository = aiInteractionRepository;
    }

    /** Row persisted inside the SAME transaction as the delivered path (SUCCESS/FALLBACK). */
    public AiInteraction record(User user, String modelName, String promptVersion,
                                String sanitizedRequestContext, String sanitizedResponse,
                                AiInteractionStatus status, Integer latencyMs, String errorCode) {
        AiInteraction interaction = new AiInteraction();
        interaction.setUser(user);
        interaction.setInteractionType(AiInteractionType.LEARNING_PATH);
        interaction.setModelName(modelName);
        interaction.setPromptVersion(promptVersion);
        interaction.setRequestContextJson(sanitizedRequestContext);
        interaction.setResponseJson(sanitizedResponse);
        interaction.setStatus(status);
        interaction.setLatencyMs(latencyMs);
        interaction.setErrorCode(errorCode);
        return aiInteractionRepository.save(interaction);
    }

    /**
     * Independent audit write used when the main transaction rolled back -
     * failure history must survive even though no path was persisted.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void recordFailureIndependently(User user, Subject subject, String promptVersion,
                                           String errorCode) {
        try {
            AiInteraction interaction = new AiInteraction();
            interaction.setUser(user);
            interaction.setInteractionType(AiInteractionType.LEARNING_PATH);
            interaction.setModelName(null);
            interaction.setPromptVersion(promptVersion);
            interaction.setRequestContextJson("{\"subjectId\":\"" + subject.getId() + "\"}");
            interaction.setResponseJson("{\"errorCategory\":\"" + errorCode + "\"}");
            interaction.setStatus(AiInteractionStatus.FAILED);
            interaction.setLatencyMs(null);
            interaction.setErrorCode(errorCode);
            aiInteractionRepository.save(interaction);
        } catch (RuntimeException ex) {
            // Audit loss is logged and never blocks the learner-facing error path.
            log.warn("Failed to persist independent AI audit row: {}", ex.getMessage());
        }
    }

    // ------------------------------------------------------------------
    // AI-TUTOR v1.0.0 section 16 - type=TUTOR rows (sanitized counts only)
    // ------------------------------------------------------------------

    /**
     * One sanitized TUTOR row per accepted request (success or in-flow
     * rejection). Payloads are counts/categories ONLY - never the
     * question, history or answer text (Database Spec section 26).
     */
    public AiInteraction recordTutor(User user, String modelName, String promptVersion,
                                     String sanitizedRequestContextJson,
                                     String sanitizedResponseJson,
                                     AiInteractionStatus status, Integer latencyMs,
                                     String errorCode) {
        AiInteraction interaction = new AiInteraction();
        interaction.setUser(user);
        interaction.setInteractionType(AiInteractionType.TUTOR);
        interaction.setModelName(modelName);
        interaction.setPromptVersion(promptVersion);
        interaction.setRequestContextJson(sanitizedRequestContextJson);
        interaction.setResponseJson(sanitizedResponseJson);
        interaction.setStatus(status);
        interaction.setLatencyMs(latencyMs);
        interaction.setErrorCode(errorCode);
        return aiInteractionRepository.save(interaction);
    }

    /**
     * Independent TUTOR failure row: history survives even when nothing
     * else persists (mirrors the LP convention). Audit loss is logged and
     * never changes the learner outcome.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void recordTutorFailureIndependently(User user, String promptVersion,
                                                String sanitizedRequestContextJson,
                                                String errorCode) {
        try {
            AiInteraction interaction = new AiInteraction();
            interaction.setUser(user);
            interaction.setInteractionType(AiInteractionType.TUTOR);
            interaction.setModelName(null);
            interaction.setPromptVersion(promptVersion);
            interaction.setRequestContextJson(sanitizedRequestContextJson);
            interaction.setResponseJson("{\"errorCategory\":\"" + errorCode + "\"}");
            interaction.setStatus(AiInteractionStatus.FAILED);
            interaction.setLatencyMs(null);
            interaction.setErrorCode(errorCode);
            aiInteractionRepository.save(interaction);
        } catch (RuntimeException ex) {
            log.warn("Failed to persist independent tutor audit row: {}", ex.getMessage());
        }
    }

    private static String truncate(String value) {
        return value == null ? null : value.substring(0, Math.min(value.length(), 2000));
    }

    public static String successResponseJson(String generatedBy, int nodeCount) {
        return "{\"delivered\":\"" + generatedBy + "\",\"nodeCount\":" + nodeCount + "}";
    }

    public static String fallbackResponseJson(String reasonCategory) {
        return "{\"fallback\":true,\"reason\":\"" + reasonCategory + "\"}";
    }

    public static String rejectedResponseJson(String errorCategory) {
        return "{\"errorCategory\":\"" + errorCategory + "\"}";
    }
}
