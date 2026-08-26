package com.gamelearn.ai.gemini;

/**
 * Per-call generation settings for surfaces that own their own approved
 * parameters (AI-TUTOR v1.0.0 section 10: temperature 0.4, 1024 tokens,
 * TUTOR_ audit prefix). Null members fall back to the Learning Path
 * defaults, preserving PATH-002 behavior byte-for-byte.
 */
public record GenerationOptions(
        Double temperature,
        Integer maxOutputTokens,
        String auditCategoryPrefix) {

    public static final String DEFAULT_PREFIX = "LP";
}
