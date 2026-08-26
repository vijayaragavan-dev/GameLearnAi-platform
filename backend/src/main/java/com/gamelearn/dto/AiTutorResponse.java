package com.gamelearn.dto;

import java.util.UUID;

/**
 * AI-001 response (AI-TUTOR v1.0.0 section 11.2; API Contract v1.4.0
 * section 5D). Plain-DTO envelope; nulls always serialized. Never contains
 * prompts, model names, token counts, latency, or audit identifiers.
 *
 * @param answer   Gemini text (sanitized + scanned), or the deterministic
 *                 refusal/degraded template when refused/degraded is true
 * @param refused  true when the platform declined THIS question on policy
 *                 grounds before any AI involvement
 * @param degraded true when the answer is a deterministic template because
 *                 Gemini output was rejected/unusable
 */
public record AiTutorResponse(
        String answer,
        boolean refused,
        boolean degraded,
        ContextView context) {

    /** Echo of the RESOLVED focus; all-null in GENERIC mode. */
    public record ContextView(
            UUID subjectId,
            UUID topicId,
            String subjectName,
            String topicName) {
    }
}
