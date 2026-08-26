package com.gamelearn.dto;

import java.time.Instant;
import java.util.UUID;

/**
 * Dashboard section 7 element (Dashboard Specification section 8.7): one
 * ACTIVE recommendation displayed without mutation. topicId/topicName are
 * defensively nullable (schema allows a null topic reference; Phase 5
 * always sets it). Priority values and their meaning are Adaptive-owned.
 */
public record RecommendationItem(
        UUID topicId,
        String topicName,
        String activityType,
        String recommendedDifficulty,
        int priority,
        String reason,
        Instant generatedAt) {
}
