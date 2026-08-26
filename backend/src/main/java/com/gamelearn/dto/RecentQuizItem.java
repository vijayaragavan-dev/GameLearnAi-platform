package com.gamelearn.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Dashboard section 10 element (Dashboard Specification section 8.10): one
 * COMPLETED quiz attempt. IN_PROGRESS/ABANDONED attempts are excluded by
 * design; submittedAt is non-null under the status filter.
 */
public record RecentQuizItem(
        UUID quizAttemptId,
        UUID topicId,
        String topicName,
        BigDecimal score,
        int correctCount,
        int totalQuestions,
        Instant submittedAt) {
}
