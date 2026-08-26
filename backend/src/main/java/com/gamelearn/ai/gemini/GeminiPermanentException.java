package com.gamelearn.ai.gemini;

/**
 * Non-retryable Gemini failure: HTTP 4xx other than 429 (invalid key, bad
 * request). Deterministic - retrying the identical prompt cannot succeed.
 */
public class GeminiPermanentException extends RuntimeException {

    private final String category;

    public GeminiPermanentException(String category, String message) {
        super(message);
        this.category = category;
    }

    public GeminiPermanentException(String category, String message, Throwable cause) {
        super(message, cause);
        this.category = category;
    }

    /** Audit error-code fragment, e.g. LP_GEMINI_REJECTED_CLIENT. */
    public String getCategory() {
        return category;
    }
}
