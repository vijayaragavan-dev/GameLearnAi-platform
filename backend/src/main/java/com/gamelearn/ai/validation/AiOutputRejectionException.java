package com.gamelearn.ai.validation;

/**
 * A generated candidate failed schema, content-safety, or business
 * validation. Carries the audit error-code category (Learning Path AI
 * Specification sections 23-25) and a learner-safe message. These failures
 * are deterministic: they are NEVER retried against Gemini; the pipeline
 * falls back to the deterministic SYSTEM path instead.
 */
public class AiOutputRejectionException extends RuntimeException {

    private final String auditErrorCode;

    public AiOutputRejectionException(String auditErrorCode, String safeMessage) {
        super(safeMessage);
        this.auditErrorCode = auditErrorCode;
    }

    /** e.g. LP_MALFORMED_RESPONSE, LP_SCHEMA_VALIDATION_FAILED, LP_UNSAFE_CONTENT, LP_BUSINESS_VALIDATION_FAILED. */
    public String getAuditErrorCode() {
        return auditErrorCode;
    }
}
