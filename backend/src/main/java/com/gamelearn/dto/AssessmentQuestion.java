package com.gamelearn.dto;

import java.util.List;
import java.util.UUID;

/**
 * ASMT-001 response element (API Contract v1.2.0 section 5B). Correct
 * answers and explanations are intentionally absent.
 */
public record AssessmentQuestion(
        UUID questionId,
        UUID topicId,
        String questionText,
        List<String> options,
        String difficulty) {
}
