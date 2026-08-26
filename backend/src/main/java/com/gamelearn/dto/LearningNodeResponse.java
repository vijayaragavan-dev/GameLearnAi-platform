package com.gamelearn.dto;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Ordered node inside a learning path (PATH-001).
 */
public record LearningNodeResponse(
        UUID id,
        UUID topicId,
        String topicName,
        int sequenceNumber,
        BigDecimal requiredMastery,
        String status) {
}
