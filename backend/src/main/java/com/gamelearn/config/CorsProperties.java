package com.gamelearn.config;

import java.util.ArrayList;
import java.util.List;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Environment-driven CORS settings. Origins are interpreted as Spring
 * origin patterns so development can allow a local port range while
 * production pins exact origins.
 */
@ConfigurationProperties(prefix = "gamelearn.cors")
public class CorsProperties {

    /**
     * Allowed origin patterns, e.g. {@code https://app.example.com} or
     * {@code http://localhost:[*]} for local Flutter web development.
     * A bare {@code "*"} is rejected at startup by {@link CorsConfig}.
     */
    private List<String> allowedOrigins = new ArrayList<>();

    private List<String> allowedMethods = List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS");

    private List<String> allowedHeaders = List.of(
            "Authorization", "Content-Type", "Accept", "X-Request-ID");

    private long maxAgeSeconds = 3600;

    public List<String> getAllowedOrigins() {
        return allowedOrigins;
    }

    public void setAllowedOrigins(List<String> allowedOrigins) {
        this.allowedOrigins = allowedOrigins;
    }

    public List<String> getAllowedMethods() {
        return allowedMethods;
    }

    public void setAllowedMethods(List<String> allowedMethods) {
        this.allowedMethods = allowedMethods;
    }

    public List<String> getAllowedHeaders() {
        return allowedHeaders;
    }

    public void setAllowedHeaders(List<String> allowedHeaders) {
        this.allowedHeaders = allowedHeaders;
    }

    public long getMaxAgeSeconds() {
        return maxAgeSeconds;
    }

    public void setMaxAgeSeconds(long maxAgeSeconds) {
        this.maxAgeSeconds = maxAgeSeconds;
    }
}
