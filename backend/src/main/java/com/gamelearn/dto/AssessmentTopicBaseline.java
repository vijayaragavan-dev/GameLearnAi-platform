package com.gamelearn.dto;

import java.math.BigDecimal;
import java.util.UUID;

/** ASMT-002 per-topic baseline summary (API Contract v1.2.0 section 5B). */
public record AssessmentTopicBaseline(
        UUID topicId,
        BigDecimal accuracy,
        String masteryLevel,
        String currentDifficulty) {
}
