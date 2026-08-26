package com.gamelearn.exception;

import java.time.Instant;
import java.util.Map;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.gamelearn.logging.RequestCorrelationFilter;

/**
 * Uniform error payload returned by every failed request. Never contains
 * stack traces, credentials or internal details.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ErrorResponse(
        Instant timestamp,
        int status,
        String errorCode,
        String message,
        String path,
        String requestId,
        Map<String, String> fieldErrors) {

    public static ErrorResponse of(int status, String errorCode, String message, String path) {
        return new ErrorResponse(Instant.now(), status, errorCode, message, path,
                RequestCorrelationFilter.currentRequestId(), null);
    }

    public static ErrorResponse withFieldErrors(int status, String errorCode, String message,
                                                String path, Map<String, String> fieldErrors) {
        return new ErrorResponse(Instant.now(), status, errorCode, message, path,
                RequestCorrelationFilter.currentRequestId(), fieldErrors);
    }
}
