package com.gamelearn.ai.gemini;

/**
 * Retryable Gemini failure: connect/read timeout, network unavailability,
 * HTTP 5xx, or HTTP 429 rate limiting (Learning Path AI Specification
 * section 27). Carries the failure category for audit classification.
 */
public class GeminiTransientException extends RuntimeException {

    private final String category;

    public GeminiTransientException(String category, String message) {
        super(message);
        this.category = category;
    }

    public GeminiTransientException(String category, String message, Throwable cause) {
        super(message, cause);
        this.category = category;
    }

    /** Audit error-code fragment, e.g. LP_GEMINI_TIMEOUT. */
    public String getCategory() {
        return category;
    }
}
