package com.gamelearn.dto;

import java.util.List;
import java.util.UUID;

/**
 * Active quiz of a topic with its ordered questions (QUIZ-001).
 */
public record QuizResponse(
        UUID id,
        UUID topicId,
        String title,
        String description,
        String difficulty,
        Integer timeLimitSeconds,
        int questionCount,
        List<QuizQuestionResponse> questions) {
}
