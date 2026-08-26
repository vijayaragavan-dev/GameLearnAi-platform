package com.gamelearn.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Learner progress view (PROG-001/PROG-002).
 */
public record ProgressResponse(
        UUID id,
        UUID topicId,
        UUID learningPathNodeId,
        BigDecimal completionPercentage,
        String status,
        Instant lastActivityAt,
        Instant completedAt) {
}
