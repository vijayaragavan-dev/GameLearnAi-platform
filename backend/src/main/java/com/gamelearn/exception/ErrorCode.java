package com.gamelearn.exception;

/**
 * HTTP status codes carried by {@link ErrorResponse}. Future phases extend
 * this enum with domain-specific codes (auth, business rules, AI failures).
 *
 * <p>Phase 6 adds the PATH-002 AI codes approved by the central API Contract
 * (section 4). AI_OUTPUT_INVALID / AI_CONTENT_REJECTED / AI_SERVICE_UNAVAILABLE /
 * AI_GENERATION_FAILED are RESERVED: the approved fallback-first policy means
 * learners normally receive a usable SYSTEM path instead of these errors.</p>
 */
public enum ErrorCode {
    VALIDATION_FAILED(400),
    MALFORMED_REQUEST(400),
    UNAUTHORIZED(401),
    FORBIDDEN(403),
    RESOURCE_NOT_FOUND(404),
    METHOD_NOT_ALLOWED(405),
    UNSUPPORTED_MEDIA_TYPE(415),
    DATA_CONFLICT(409),
    AI_OUTPUT_INVALID(422),
    AI_CONTENT_REJECTED(422),
    INTERNAL_ERROR(500),
    AI_SERVICE_UNAVAILABLE(503),
    AI_GENERATION_FAILED(503),
    AI_RATE_LIMITED(429),
    GAME_RATE_LIMITED(429),
    INSUFFICIENT_CREDITS(402),
    AVATAR_REQUIREMENTS_NOT_MET(403),
    AVATAR_ALREADY_OWNED(409),
    AVATAR_NOT_OWNED(403);

    private final int httpStatus;

    ErrorCode(int httpStatus) {
        this.httpStatus = httpStatus;
    }

    public int getHttpStatus() {
        return httpStatus;
    }
}
