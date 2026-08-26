package com.gamelearn.dto;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * Authoritative result of a quiz submission. Correctness and score are
 * server-computed; correct answers are revealed here — only after the
 * submission has been evaluated.
 */
public record QuizResultResponse(
        UUID attemptId,
        UUID quizId,
        String status,
        BigDecimal score,
        int correctCount,
        int totalQuestions,
        Integer durationSeconds,
        List<AnswerReview> results,
        AdaptiveInsight adaptive) {

    public record AnswerReview(
            UUID questionId,
            String selectedAnswer,
            boolean isCorrect,
            String correctAnswer,
            String explanation) {
    }
}
