package com.gamelearn.config;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.gamelearn.ai.gemini.DisabledGeminiClient;
import com.gamelearn.ai.gemini.GeminiClient;
import com.gamelearn.ai.gemini.HttpGeminiClient;

/**
 * Phase 6 AI wiring (Learning Path AI Specification sections 20 and 26).
 *
 * <p>The {@link GeminiClient} seam is bound conditionally: when the AI-LP
 * feature is enabled the production HTTP client requires a configured
 * API key AND model name and fails fast otherwise (mirroring the JWT_SECRET
 * discipline); when disabled, a never-callable stub is bound so that no
 * network client or secret is required at all.</p>
 */
@Configuration
@EnableConfigurationProperties(AiProperties.class)
public class AiConfig {

    @Bean
    public GeminiClient geminiClient(AiProperties properties) {
        boolean lpEnabled = properties.getLearningPath().isEnabled();
        // AI-TUTOR v1.0.0: the tutor flag is INDEPENDENT - a deployment may
        // run the tutor without PATH-002 and vice versa.
        boolean tutorEnabled = properties.getTutor().isEnabled();
        if (lpEnabled) {
            requireCredentials(properties,
                    "gamelearn.ai.learning-path.enabled=true requires GEMINI_API_KEY and GEMINI_MODEL");
            return new HttpGeminiClient(properties);
        }
        if (tutorEnabled) {
            requireCredentials(properties,
                    "gamelearn.ai.tutor.enabled=true requires GEMINI_API_KEY and GEMINI_MODEL");
            return new HttpGeminiClient(properties);
        }
        return new DisabledGeminiClient();
    }

    private void requireCredentials(AiProperties properties, String message) {
        if (properties.getGemini().getApiKey() == null
                || properties.getGemini().getApiKey().isBlank()
                || properties.getGemini().getModel() == null
                || properties.getGemini().getModel().isBlank()) {
            throw new IllegalStateException(message);
        }
    }
}
