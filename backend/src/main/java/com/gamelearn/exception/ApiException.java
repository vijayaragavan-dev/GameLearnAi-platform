package com.gamelearn.exception;

import java.util.Map;

/**
 * Base class for application-level exceptions. Carries the HTTP status and a
 * machine-readable error code so the global exception handler can translate
 * any subclass into a safe, consistent {@link ErrorResponse}.
 *
 * <p>Phase 10B (AI-TUTOR v1.0.0 section 6): an OPTIONAL fieldErrors map so
 * service-side referential/size rejections can surface the same
 * fieldErrors shape as bean-validation failures. Existing constructors are
 * unchanged; the map is null unless explicitly supplied.</p>
 */
public class ApiException extends RuntimeException {

    private final int httpStatus;
    private final String errorCode;
    private final Map<String, String> fieldErrors;

    public ApiException(int httpStatus, String errorCode, String message) {
        this(httpStatus, errorCode, message, null);
    }

    public ApiException(int httpStatus, String errorCode, String message,
                        Map<String, String> fieldErrors) {
        super(message);
        this.httpStatus = httpStatus;
        this.errorCode = errorCode;
        this.fieldErrors = fieldErrors == null || fieldErrors.isEmpty() ? null : Map.copyOf(fieldErrors);
    }

    public int getHttpStatus() {
        return httpStatus;
    }

    public String getErrorCode() {
        return errorCode;
    }

    /** Null when this exception carries no per-field details. */
    public Map<String, String> getFieldErrors() {
        return fieldErrors;
    }
}
