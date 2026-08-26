package com.gamelearn.ai.gemini;

/**
 * Isolation seam for the Gemini API (Backend + AI Specification section 23;
 * Learning Path AI Specification section 4). The rest of the application
 * depends only on this interface - never on Gemini SDK/HTTP details. Tests
 * replace it with fakes; production binds the HTTP implementation.
 */
public interface GeminiClient {

    /**
     * Sends one structured-generation request and returns the raw model text.
     * Implementations MUST:
     * - force JSON response mode,
     * - apply configured timeouts,
     * - never log or embed the API key,
     * - classify failures into {@link GeminiTransientException} (retryable:
     *   timeout / network / 5xx / 429) and {@link GeminiPermanentException}
     *   (non-retryable 4xx).
     *
     * <p>Uses the Learning Path defaults (temperature, token budget, LP_
     * audit category prefix).</p>
     */
    String generate(GeminiPrompt prompt);

    /**
     * AI-TUTOR v1.0.0 section 10: same contract with per-call generation
     * options (temperature, maxOutputTokens, audit category prefix). Fakes
     * that only implement {@link #generate(GeminiPrompt)} keep working -
     * options-aware callers fall back to it by default.
     */
    default String generate(GeminiPrompt prompt, GenerationOptions options) {
        return generate(prompt);
    }
}
