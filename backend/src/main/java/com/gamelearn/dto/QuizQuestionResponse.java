package com.gamelearn.dto;

import java.util.List;
import java.util.UUID;

/**
 * Question as delivered to the learner. Deliberately excludes
 * correctAnswer/explanation: the backend evaluates correctness.
 */
public record QuizQuestionResponse(
        UUID id,
        String questionText,
        List<String> options,
        String difficulty) {
}
