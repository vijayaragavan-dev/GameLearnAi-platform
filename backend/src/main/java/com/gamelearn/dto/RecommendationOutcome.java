package com.gamelearn.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Post-recommendation learner outcome (Gate 14.2, observational only).
 *
 * <p>Derived read-only from authoritative attempts; never persisted, never
 * fed back into adaptive decisions. {@code null} accuracies/delta mean
 * the evidence was insufficient — never zero-substituted. Language
 * discipline: "observed association", never "causal effect".</p>
 */
public record RecommendationOutcome(
        UUID recommendationId,
        UUID userId,
        UUID topicId,
        String status,
        Instant generatedAt,
        BigDecimal preAccuracy,
        BigDecimal postAccuracy,
        BigDecimal delta,
        Category category,
        int preAttempts,
        int postAttempts,
        String detail,
        Instant evaluatedAt) {

    public enum Category {
        IMPROVED,
        NO_MEASURABLE_IMPROVEMENT,
        DECLINED,
        INSUFFICIENT_DATA,
        AMBIGUOUS
    }
}
