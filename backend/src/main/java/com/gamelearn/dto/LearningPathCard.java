package com.gamelearn.dto;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Dashboard section 8 (Dashboard Specification section 8.8, decision D1):
 * the learner's active plan card. Node objects mirror LearningNodeResponse
 * so Flutter renders the card with its existing path components. No Gemini
 * internals, aiMetadata or completion percentage is ever exposed.
 */
public record LearningPathCard(
        UUID id,
        UUID subjectId,
        String subjectName,
        String title,
        String status,
        String generatedBy,
        Instant createdAt,
        List<LearningNodeResponse> nodes) {
}
