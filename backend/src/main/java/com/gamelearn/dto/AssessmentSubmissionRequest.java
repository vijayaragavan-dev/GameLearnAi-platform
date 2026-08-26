package com.gamelearn.dto;

import java.util.List;
import java.util.UUID;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * ASMT-002 request (API Contract v1.2.0 section 5B). The client states only
 * which option it selected; correctness/score/baselines are computed
 * exclusively by the backend (Assessment Spec section 18).
 */
public record AssessmentSubmissionRequest(
        @Valid
        @NotEmpty(message = "Answers must not be empty")
        List<SubmittedAnswer> answers) {

    public record SubmittedAnswer(
            @NotNull(message = "Question id is required")
            UUID questionId,

            @NotBlank(message = "Selected answer is required")
            @Size(max = 255, message = "Selected answer must not exceed 255 characters")
            String selectedAnswer) {
    }
}
