package com.gamelearn.dto;

import jakarta.validation.constraints.Size;

/**
 * PATH-002 request body (central API Contract section 5). Both fields are
 * optional; an absent body behaves like {@code {}}. learningGoal is
 * UNTRUSTED learner input (Learning Path AI Specification section 45) - it
 * can never carry authority over subject, mastery, difficulty, or ownership.
 * No other field is accepted as authoritative: userId, mastery, difficulty,
 * trend, recommendation, generatedBy, and topic selections supplied by a
 * client are ignored.
 */
public record PathGenerationRequest(
        Boolean regenerate,
        @Size(max = 300, message = "learningGoal must be at most 300 characters")
        String learningGoal) {

    public boolean regenerateOrDefault() {
        return Boolean.TRUE.equals(regenerate);
    }
}
