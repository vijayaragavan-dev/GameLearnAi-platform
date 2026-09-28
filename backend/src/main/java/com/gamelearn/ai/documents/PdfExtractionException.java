package com.gamelearn.ai.documents;

/**
 * USER-DOC RAG Phase C: localhost PDF-extraction sidecar failure. The
 * category is audit-safe (byte counts and reason codes only — never PDF
 * bytes, page text, tokens or paths). {@code transientFailure}
 * distinguishes retryable transport/timeout faults from deterministic
 * parser/configuration faults; the upload flow never retries either way
 * (single bounded attempt), the flag only documents the cause.
 */
public class PdfExtractionException extends RuntimeException {

    public static final String UNAVAILABLE = "DOCUMENT_EXTRACTION_UNAVAILABLE";
    public static final String TIMEOUT = "DOCUMENT_EXTRACTION_TIMEOUT";
    public static final String MISCONFIGURED = "DOCUMENT_EXTRACTION_MISCONFIGURED";
    public static final String TOO_LARGE = "DOCUMENT_EXTRACTION_TOO_LARGE";
    public static final String INVALID = "DOCUMENT_EXTRACTION_INVALID";

    private final String category;
    private final boolean transientFailure;

    public PdfExtractionException(String category, String message, boolean transientFailure) {
        super(message);
        this.category = category;
        this.transientFailure = transientFailure;
    }

    public PdfExtractionException(String category, String message, boolean transientFailure,
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
