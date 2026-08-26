package com.gamelearn.config;

import java.time.Duration;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Phase 6 AI configuration (Learning Path AI Specification sections 20-21,
 * 27, 40; central API Contract section 5.6). Every value is
 * environment/application driven - no magic numbers in code, no secrets in
 * source control.
 */
@ConfigurationProperties(prefix = "gamelearn.ai")
public class AiProperties {

    private final Gemini gemini = new Gemini();
    private final LearningPath learningPath = new LearningPath();
    private final Tutor tutor = new Tutor();

    public Gemini getGemini() {
        return gemini;
    }

    public LearningPath getLearningPath() {
        return learningPath;
    }

    public Tutor getTutor() {
        return tutor;
    }

    public static class Gemini {

        /** GEMINI_API_KEY - injected from the environment only. */
        private String apiKey = "";
        /** GEMINI_MODEL - configurable model id, never hard-coded. */
        private String model = "";
        private String baseUrl = "https://generativelanguage.googleapis.com";
        private Duration connectTimeout = Duration.ofSeconds(3);
        private Duration readTimeout = Duration.ofSeconds(15);

        public String getApiKey() {
            return apiKey;
        }

        public void setApiKey(String apiKey) {
            this.apiKey = apiKey;
        }

        public String getModel() {
            return model;
        }

        public void setModel(String model) {
            this.model = model;
        }

        public String getBaseUrl() {
            return baseUrl;
        }

        public void setBaseUrl(String baseUrl) {
            this.baseUrl = baseUrl;
        }

        public Duration getConnectTimeout() {
            return connectTimeout;
        }

        public void setConnectTimeout(Duration connectTimeout) {
            this.connectTimeout = connectTimeout;
        }

        public Duration getReadTimeout() {
            return readTimeout;
        }

        public void setReadTimeout(Duration readTimeout) {
            this.readTimeout = readTimeout;
        }
    }

    public static class LearningPath {

        /** Feature flag: false routes PATH-002 straight to deterministic mode. */
        private boolean enabled = false;
        private double temperature = 0.3;
        private int maxOutputTokens = 2048;
        /** Overall wall-clock budget across all attempts (spec: 20 s). */
        private Duration deadline = Duration.ofSeconds(20);
        private final Retry retry = new Retry();
        private final RateLimit rateLimit = new RateLimit();

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public double getTemperature() {
            return temperature;
        }

        public void setTemperature(double temperature) {
            this.temperature = temperature;
        }

        public int getMaxOutputTokens() {
            return maxOutputTokens;
        }

        public void setMaxOutputTokens(int maxOutputTokens) {
            this.maxOutputTokens = maxOutputTokens;
        }

        public Duration getDeadline() {
            return deadline;
        }

        public void setDeadline(Duration deadline) {
            this.deadline = deadline;
        }

        public Retry getRetry() {
            return retry;
        }

        public RateLimit getRateLimit() {
            return rateLimit;
        }
    }

    public static class Retry {

        /** Approved policy: 1 automatic retry for transient failures only. */
        private int maxRetries = 1;
        private Duration backoffBase = Duration.ofSeconds(2);
    /** +/- 25% jitter around the backoff base. */
        private double jitterFraction = 0.25;

        public int getMaxRetries() {
            return maxRetries;
        }

        public void setMaxRetries(int maxRetries) {
            this.maxRetries = maxRetries;
        }

        public Duration getBackoffBase() {
            return backoffBase;
        }

        public void setBackoffBase(Duration backoffBase) {
            this.backoffBase = backoffBase;
        }

        public double getJitterFraction() {
            return jitterFraction;
        }

        public void setJitterFraction(double jitterFraction) {
            this.jitterFraction = jitterFraction;
        }
    }

    public static class RateLimit {

        /** D10: max Gemini-backed generations per user per rolling window. */
        private int maxRequestsPerHour = 10;
        private int windowMinutes = 60;

        public int getMaxRequestsPerHour() {
            return maxRequestsPerHour;
        }

        public void setMaxRequestsPerHour(int maxRequestsPerHour) {
            this.maxRequestsPerHour = maxRequestsPerHour;
        }

        public int getWindowMinutes() {
            return windowMinutes;
        }

        public void setWindowMinutes(int windowMinutes) {
            this.windowMinutes = windowMinutes;
        }
    }

    /**
     * AI-TUTOR v1.0.0 section 10 (owner-approved 2026-08-24, OT-4/OT-5):
     * tutor-scoped operational knobs. Numeric values are configuration
     * driven - never hardcoded - and changing them does not alter business
     * semantics. The feature flag is independent of the Learning Path flag.
     */
    public static class Tutor {

        /** Feature flag: false routes AI-001 straight to the controlled 503. */
        private boolean enabled = false;
        private double temperature = 0.4;
        private int maxOutputTokens = 1024;
        /** Overall wall-clock budget across all attempts (spec: 15 s). */
        private Duration deadline = Duration.ofSeconds(15);
        private final TutorRetry retry = new TutorRetry();
        private final TutorRateLimit rateLimit = new TutorRateLimit();

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public double getTemperature() {
            return temperature;
        }

        public void setTemperature(double temperature) {
            this.temperature = temperature;
        }

        public int getMaxOutputTokens() {
            return maxOutputTokens;
        }

        public void setMaxOutputTokens(int maxOutputTokens) {
            this.maxOutputTokens = maxOutputTokens;
        }

        public Duration getDeadline() {
            return deadline;
        }

        public void setDeadline(Duration deadline) {
            this.deadline = deadline;
        }

        public TutorRetry getRetry() {
            return retry;
        }

        public TutorRateLimit getRateLimit() {
            return rateLimit;
        }

        /** Approved policy shape reused from LP-AI section 27 (operational knobs). */
        public static class TutorRetry {

            /** 1 automatic retry for transient failures only. */
            private int maxRetries = 1;
            private Duration backoffBase = Duration.ofSeconds(2);
            /** +/- 25% jitter around the backoff base. */
            private double jitterFraction = 0.25;

            public int getMaxRetries() {
                return maxRetries;
            }

            public void setMaxRetries(int maxRetries) {
                this.maxRetries = maxRetries;
            }

            public Duration getBackoffBase() {
                return backoffBase;
            }

            public void setBackoffBase(Duration backoffBase) {
                this.backoffBase = backoffBase;
            }

            public double getJitterFraction() {
                return jitterFraction;
            }

            public void setJitterFraction(double jitterFraction) {
                this.jitterFraction = jitterFraction;
            }
        }

        /** OT-4: dedicated tutor bucket - never shared with PATH-002. */
        public static class TutorRateLimit {

            /** Max Gemini-backed tutor requests per user per rolling window. */
            private int maxRequestsPerHour = 20;
            private int windowMinutes = 60;

            public int getMaxRequestsPerHour() {
                return maxRequestsPerHour;
            }

            public void setMaxRequestsPerHour(int maxRequestsPerHour) {
                this.maxRequestsPerHour = maxRequestsPerHour;
            }

            public int getWindowMinutes() {
                return windowMinutes;
            }

            public void setWindowMinutes(int windowMinutes) {
                this.windowMinutes = windowMinutes;
            }
        }
    }
}
