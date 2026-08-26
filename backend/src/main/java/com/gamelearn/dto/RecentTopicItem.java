package com.gamelearn.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Dashboard section 3 element (Dashboard Specification section 8.3): one
 * stored mastery row. Every value is a verbatim column copy — the Adaptive
 * Engine owns all semantics (levels, trends, difficulty); the Dashboard
 * only displays and orders them.
 */
public record RecentTopicItem(
        UUID topicId,
        String topicName,
        BigDecimal masteryScore,
        String masteryLevel,
        String currentDifficulty,
        String trend,
        Instant lastAssessedAt) {
}
