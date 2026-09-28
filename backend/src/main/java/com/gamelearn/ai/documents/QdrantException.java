package com.gamelearn.ai.documents;

/**
 * USER-DOC RAG Phase F: localhost Qdrant failure. Categories are
 * audit-safe (collection names, counts and reason codes only — never
 * vectors, payloads, paths or internals). {@code transientFailure}
 * distinguishes retryable transport/timeout faults from deterministic
 * configuration/content faults; callers fail closed either way and never
 * fabricate index success.
 */
public class QdrantException extends RuntimeException {

    public static final String UNAVAILABLE = "DOCUMENT_INDEX_UNAVAILABLE";
    public static final String TIMEOUT = "DOCUMENT_INDEX_TIMEOUT";
    public static final String MISCONFIGURED = "DOCUMENT_INDEX_MISCONFIGURED";
    public static final String INVALID = "DOCUMENT_INDEX_INVALID";

    private final String category;
    private final boolean transientFailure;

    public QdrantException(String category, String message, boolean transientFailure) {
        super(message);
        this.category = category;
        this.transientFailure = transientFailure;
    }

    public QdrantException(String category, String message, boolean transientFailure,
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
