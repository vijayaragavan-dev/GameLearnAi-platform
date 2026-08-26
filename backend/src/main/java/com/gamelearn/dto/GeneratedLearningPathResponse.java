package com.gamelearn.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * PATH-002 success response (central API Contract sections 5.3-5.4).
 * Persisted fields first; {@code aiMetadata} is OPTIONAL NON-PERSISTED
 * display data present only on the generation response that produced it and
 * only when validated AI content exists (never for fallback paths).
 */
public record GeneratedLearningPathResponse(
        UUID id,
        UUID subjectId,
        String title,
        String description,
        String status,
        String generatedBy,
        Instant createdAt,
        Instant updatedAt,
        List<Node> nodes,
        AiMetadata aiMetadata) {

    public record Node(
            UUID id,
            UUID topicId,
            String topicName,
            int sequenceNumber,
            BigDecimal requiredMastery,
            String status) {
    }

    public record AiMetadata(List<AiNode> nodes) {
    }

    public record AiNode(
            int sequenceNumber,
            String objective,
            String rationale) {
    }
}
