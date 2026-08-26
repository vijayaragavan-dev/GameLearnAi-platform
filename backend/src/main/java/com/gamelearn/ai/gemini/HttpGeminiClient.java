package com.gamelearn.ai.gemini;

import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.web.client.ClientHttpRequestFactories;
import org.springframework.boot.web.client.ClientHttpRequestFactorySettings;
import org.springframework.http.MediaType;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClientResponseException;

import com.gamelearn.config.AiProperties;

/**
 * Production {@link GeminiClient} backed by the REST generateContent API.
 *
 * <p>Security: the API key is injected as a request header from configuration
 * at call time - never logged, never serialized into prompts or audit rows.
 * Failure classification (Learning Path AI Specification section 26):
 * timeouts/network/5xx/429 are transient; other 4xx are permanent.</p>
 *
 * <p>Instantiated conditionally by {@link com.gamelearn.config.AiConfig} -
 * NOT a plain component - so that disabled deployments and tests can bind
 * fakes instead.</p>
 */
public class HttpGeminiClient implements GeminiClient {

    private static final Logger log = LoggerFactory.getLogger(HttpGeminiClient.class);

    private final RestClient restClient;
    private final AiProperties properties;

    public HttpGeminiClient(AiProperties properties) {
        this.properties = properties;
        this.restClient = RestClient.builder()
                .baseUrl(properties.getGemini().getBaseUrl())
                .requestFactory(ClientHttpRequestFactories.get(
                        ClientHttpRequestFactorySettings.DEFAULTS
                                .withConnectTimeout(properties.getGemini().getConnectTimeout())
                                .withReadTimeout(properties.getGemini().getReadTimeout())))
                .build();
    }

    @Override
    public String generate(GeminiPrompt prompt) {
        return generate(prompt, null);
    }

    /**
     * AI-TUTOR v1.0.0 section 10: options-aware overload. When {@code options}
     * is null every setting resolves exactly as before (Learning Path
     * defaults with LP_ audit categories), so PATH-002 behavior is
     * byte-for-byte unchanged.
     */
    @Override
    public String generate(GeminiPrompt prompt, GenerationOptions options) {
        String prefix = options == null || options.auditCategoryPrefix() == null
                ? GenerationOptions.DEFAULT_PREFIX : options.auditCategoryPrefix();
        double temperature = options != null && options.temperature() != null
                ? options.temperature() : properties.getLearningPath().getTemperature();
        int maxOutputTokens = options != null && options.maxOutputTokens() != null
                ? options.maxOutputTokens() : properties.getLearningPath().getMaxOutputTokens();
        String model = properties.getGemini().getModel();
        Map<String, Object> body = Map.of(
                "contents", List.of(Map.of("parts", List.of(Map.of("text", prompt.promptText())))),
                "generationConfig", Map.of(
                        "temperature", temperature,
                        "maxOutputTokens", maxOutputTokens,
                        "responseMimeType", "application/json"));

        try {
            GeminiHttpResponse response = restClient.post()
                    .uri("/v1beta/models/{model}:generateContent", model)
                    .contentType(MediaType.APPLICATION_JSON)
                    .header("x-goog-api-key", properties.getGemini().getApiKey())
                    .header("X-Request-ID", prompt.correlationId())
                    .body(body)
                    .retrieve()
                    .body(GeminiHttpResponse.class);
            return extractText(response, prefix);
        } catch (RestClientResponseException ex) {
            throw classifyStatus(ex, prefix);
        } catch (RestClientException ex) {
            // Connection refused / timeout without an HTTP status.
            throw wrap(prefix + "_GEMINI_UNAVAILABLE", "Gemini could not be reached", ex);
        }
    }

    private String extractText(GeminiHttpResponse response, String prefix) {
        if (response == null || response.candidates() == null || response.candidates().isEmpty()) {
            throw new GeminiTransientException(prefix + "_GEMINI_EMPTY_RESPONSE", "Gemini returned no candidates");
        }
        Candidate candidate = response.candidates().get(0);
        if (candidate == null || candidate.content() == null || candidate.content().parts() == null) {
            throw new GeminiTransientException(prefix + "_GEMINI_EMPTY_RESPONSE", "Gemini returned no content");
        }
        StringBuilder text = new StringBuilder();
        for (Part part : candidate.content().parts()) {
            if (part != null && part.text() != null) {
                text.append(part.text());
            }
        }
        if (text.isEmpty()) {
            throw new GeminiTransientException(prefix + "_GEMINI_EMPTY_RESPONSE", "Gemini returned empty text");
        }
        return text.toString();
    }

    private RuntimeException classifyStatus(RestClientResponseException ex, String prefix) {
        int value = ex.getStatusCode().value();
        log.info("Gemini call failed with HTTP {}", value);
        if (value == 429) {
            return wrap(prefix + "_GEMINI_RATE_LIMITED", "Gemini rate limit reached", ex);
        }
        if (value >= 500) {
            return wrap(prefix + "_GEMINI_UNAVAILABLE", "Gemini service unavailable", ex);
        }
        if (value >= 400) {
            return new GeminiPermanentException(prefix + "_GEMINI_REJECTED_CLIENT",
                    "Gemini rejected the request", ex);
        }
        return wrap(prefix + "_GEMINI_UNAVAILABLE", "Gemini could not be reached", ex);
    }

    private GeminiTransientException wrap(String category, String message, Exception cause) {
        return new GeminiTransientException(category, message, cause);
    }

    // Minimal response mapping of the generateContent payload.
    record GeminiHttpResponse(List<Candidate> candidates) {
    }

    record Candidate(Content content) {
    }

    record Content(List<Part> parts) {
    }

    record Part(String text) {
    }
}
