package com.gamelearn.ai.gemini;

/**
 * Bound when the AI-LP feature flag is disabled. The generation service
 * never calls it in that mode (it routes straight to the deterministic
 * path); if it were ever invoked anyway, it fails closed with a transient
 * unavailable classification.
 */
public class DisabledGeminiClient implements GeminiClient {

    @Override
    public String generate(GeminiPrompt prompt) {
        throw new GeminiTransientException("LP_GEMINI_DISABLED",
                "AI learning-path generation is disabled");
    }
}
