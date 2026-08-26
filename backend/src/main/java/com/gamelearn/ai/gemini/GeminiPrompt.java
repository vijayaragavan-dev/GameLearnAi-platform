package com.gamelearn.ai.gemini;

/**
 * One immutable Gemini request: the fully rendered prompt text plus the
 * correlation id for traceability. No secrets travel inside this object.
 */
public record GeminiPrompt(String promptText, String promptVersion, String correlationId) {
}
