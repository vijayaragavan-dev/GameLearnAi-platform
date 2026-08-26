package com.gamelearn.exception;

import java.util.LinkedHashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.BindException;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;

/**
 * Central REST error translation. Every response is a safe
 * {@link ErrorResponse}; stack traces and infrastructure details stay in the
 * server log only.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ErrorResponse> handleApiException(ApiException ex, HttpServletRequest request) {
        // Phase 10B: service-raised rejections may carry per-field details;
        // the response stays a safe envelope either way.
        if (ex.getFieldErrors() != null) {
            ErrorResponse body = ErrorResponse.withFieldErrors(
                    ex.getHttpStatus(), ex.getErrorCode(), ex.getMessage(),
                    request.getRequestURI(), ex.getFieldErrors());
            return ResponseEntity.status(ex.getHttpStatus()).body(body);
        }
        return build(ex.getHttpStatus(), ex.getErrorCode(), ex.getMessage(), request);
    }

    @ExceptionHandler({MethodArgumentNotValidException.class, BindException.class})
    public ResponseEntity<ErrorResponse> handleValidation(BindException ex, HttpServletRequest request) {
        Map<String, String> fieldErrors = new LinkedHashMap<>();
        for (FieldError error : ex.getBindingResult().getFieldErrors()) {
            fieldErrors.putIfAbsent(error.getField(), error.getDefaultMessage());
        }
        ErrorResponse body = ErrorResponse.withFieldErrors(
                ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                ErrorCode.VALIDATION_FAILED.name(),
                "Request validation failed",
                request.getRequestURI(),
                fieldErrors);
        return ResponseEntity.badRequest().body(body);
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ErrorResponse> handleConstraintViolation(ConstraintViolationException ex,
                                                                   HttpServletRequest request) {
        Map<String, String> violations = new LinkedHashMap<>();
        for (ConstraintViolation<?> violation : ex.getConstraintViolations()) {
            violations.putIfAbsent(violation.getPropertyPath().toString(), violation.getMessage());
        }
        ErrorResponse body = ErrorResponse.withFieldErrors(
                ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                ErrorCode.VALIDATION_FAILED.name(),
                "Request validation failed",
                request.getRequestURI(),
                violations);
        return ResponseEntity.badRequest().body(body);
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ErrorResponse> handleUnreadable(HttpMessageNotReadableException ex,
                                                          HttpServletRequest request) {
        return build(ErrorCode.MALFORMED_REQUEST.getHttpStatus(),
                ErrorCode.MALFORMED_REQUEST.name(),
                "Malformed or unreadable request body",
                request);
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ErrorResponse> handleMissingParameter(MissingServletRequestParameterException ex,
                                                                HttpServletRequest request) {
        return build(ErrorCode.MALFORMED_REQUEST.getHttpStatus(),
                ErrorCode.MALFORMED_REQUEST.name(),
                "Missing required parameter: " + ex.getParameterName(),
                request);
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ErrorResponse> handleTypeMismatch(MethodArgumentTypeMismatchException ex,
                                                            HttpServletRequest request) {
        return build(ErrorCode.MALFORMED_REQUEST.getHttpStatus(),
                ErrorCode.MALFORMED_REQUEST.name(),
                "Invalid value for parameter: " + ex.getName(),
                request);
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(NoResourceFoundException ex,
                                                        HttpServletRequest request) {
        return build(ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                ErrorCode.RESOURCE_NOT_FOUND.name(),
                "Resource not found",
                request);
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ErrorResponse> handleMethodNotSupported(HttpRequestMethodNotSupportedException ex,
                                                                  HttpServletRequest request) {
        return build(ErrorCode.METHOD_NOT_ALLOWED.getHttpStatus(),
                ErrorCode.METHOD_NOT_ALLOWED.name(),
                "HTTP method not supported for this resource",
                request);
    }

    @ExceptionHandler(HttpMediaTypeNotSupportedException.class)
    public ResponseEntity<ErrorResponse> handleMediaTypeNotSupported(HttpMediaTypeNotSupportedException ex,
                                                                     HttpServletRequest request) {
        return build(ErrorCode.UNSUPPORTED_MEDIA_TYPE.getHttpStatus(),
                ErrorCode.UNSUPPORTED_MEDIA_TYPE.name(),
                "Unsupported media type",
                request);
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ErrorResponse> handleDataConflict(DataIntegrityViolationException ex,
                                                            HttpServletRequest request) {
        log.warn("Data integrity violation on {} {}: {}",
                request.getMethod(), request.getRequestURI(), ex.getClass().getSimpleName());
        return build(ErrorCode.DATA_CONFLICT.getHttpStatus(),
                ErrorCode.DATA_CONFLICT.name(),
                "The request conflicts with existing data",
                request);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleUnexpected(Exception ex, HttpServletRequest request) {
        log.error("Unhandled exception on {} {}", request.getMethod(), request.getRequestURI(), ex);
        return build(ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                ErrorCode.INTERNAL_ERROR.name(),
                "An unexpected internal error occurred",
                request);
    }

    private ResponseEntity<ErrorResponse> build(int status, String errorCode, String message,
                                                HttpServletRequest request) {
        ErrorResponse body = ErrorResponse.of(status, errorCode, message, request.getRequestURI());
        return ResponseEntity.status(status).body(body);
    }
}
