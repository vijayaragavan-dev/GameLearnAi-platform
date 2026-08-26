package com.gamelearn.dto;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * ASMT-003 response (API Contract v1.2.0 section 5B). Derived read of the
 * persisted placement baselines; {@code assessed:false} before the first
 * successful ASMT-002.
 */
public record AssessmentResultResponse(
        UUID subjectId,
        boolean assessed,
        BigDecimal overallMastery,
        List<AssessmentTopicResult> topics) {

    /** Persisted per-topic baseline triplet. */
    public record AssessmentTopicResult(
            UUID topicId,
            String topicName,
            BigDecimal masteryScore,
            String masteryLevel,
            String currentDifficulty) {
    }
}
