package com.gamelearn.dto;

import java.util.List;
import java.util.UUID;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * Quiz submission (QUIZ-002). The client may ONLY state which option it
 * selected; score/correctness are computed exclusively by the backend.
 */
public record QuizSubmissionRequest(
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
