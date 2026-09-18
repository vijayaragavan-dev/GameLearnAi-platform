package com.gamelearn.ai.rag;

/**
 * Gate 23: RAG evidence-sidecar failure. The category is audit-safe
 * (no query text, no evidence text, no tokens). {@code transientFailure}
 * distinguishes retryable transport/timeout faults from deterministic
 * configuration/bundle faults - the tutor never retries RAG either way
 * (single attempt; no retry storms), the flag only documents the cause.
 */
public class RagException extends RuntimeException {

    public static final String UNAVAILABLE = "TUTOR_RAG_UNAVAILABLE";
    public static final String TIMEOUT = "TUTOR_RAG_TIMEOUT";
    public static final String MISCONFIGURED = "TUTOR_RAG_MISCONFIGURED";
    public static final String INVALID_EVIDENCE = "TUTOR_RAG_INVALID_EVIDENCE";

    private final String category;
    private final boolean transientFailure;

    public RagException(String category, String message, boolean transientFailure) {
        super(message);
        this.category = category;
        this.transientFailure = transientFailure;
    }

    public RagException(String category, String message, boolean transientFailure,
                        Throwable cause) {
        super(message, cause);
        this.category = category;
        this.transientFailure = transientFailure;
    }

    public String getCategory() {
        return category;
    }

    public boolean isTransientFailure() {
        return transientFailure;
    }
}
