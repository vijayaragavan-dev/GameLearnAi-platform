package com.gamelearn.dto;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Deterministic adaptive outcome attached to a quiz submission result
 * (Adaptive Engine Specification v1.0.0, section 26). Every value is
 * backend-derived; clients can never supply any of these.
 */
public record AdaptiveInsight(
        UUID topicId,
        BigDecimal masteryScore,
        BigDecimal previousMasteryScore,
        String masteryLevel,
        String trend,
        String nextDifficulty,
        String recommendedActivity,
        String reasonCode) {
}
