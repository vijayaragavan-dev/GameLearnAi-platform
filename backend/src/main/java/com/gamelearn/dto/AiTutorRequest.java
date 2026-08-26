package com.gamelearn.dto;

import java.util.List;
import java.util.UUID;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * AI-001 request body (AI-TUTOR v1.0.0 section 6; API Contract v1.4.0
 * section 5D). Structural constraints are bean-validated BEFORE any
 * identity-dependent work, quota consumption or Gemini contact; per-string
 * length caps are enforced after control-character stripping inside the
 * service (spec section 8.1 ordering). There is NO field for a client
 * userId, and supplying authoritative learning values is rejected.
 */
public record AiTutorRequest(
        @NotBlank(message = "question is required")
        String question,
        UUID subjectId,
        UUID topicId,
        @Valid
        @Size(max = 8, message = "conversation must contain at most 8 messages")
        List<ConversationMessage> conversation) {

    public record ConversationMessage(
            @NotBlank(message = "role is required")
            @Pattern(regexp = "LEARNER|TUTOR", message = "role must be LEARNER or TUTOR")
            String role,
            @NotBlank(message = "content is required")
            String content) {
    }
}
