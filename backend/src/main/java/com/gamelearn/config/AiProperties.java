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

    private final Rag rag = new Rag();

    private final Documents documents = new Documents();

    public Gemini getGemini() {
        return gemini;
    }

    public LearningPath getLearningPath() {
        return learningPath;
    }

    public Tutor getTutor() {
        return tutor;
    }

    public Rag getRag() {
        return rag;
    }

    public Documents getDocuments() {
        return documents;
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

    /**
     * Gate 23: RAG evidence sidecar knobs (AI Tutor grounding). Disabled by
     * default - when false, AI-001 behaves exactly as before (no RAG call,
     * no prompt change, no audit change). The service token is injected
     * from the environment only and is never logged or persisted.
     */
    public static class Rag {

        /** Feature flag: false keeps the legacy ungrounded tutor path. */
        private boolean enabled = false;
        /** Localhost sidecar base URL (service boundary, never public). */
        private String baseUrl = "http://127.0.0.1:8431";
        /** RAG_SIDECAR_TOKEN - injected from the environment only. */
        private String serviceToken = "";
        private java.time.Duration connectTimeout = java.time.Duration.ofSeconds(1);
        private java.time.Duration readTimeout = java.time.Duration.ofSeconds(5);
        /** Top-K evidence chunks requested per tutor question. */
        private int topK = 5;
        /** Hard char budget for the rendered evidence block in the prompt. */
        private int evidenceBudgetChars = 4000;

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public String getBaseUrl() {
            return baseUrl;
        }

        public void setBaseUrl(String baseUrl) {
            this.baseUrl = baseUrl;
        }

        public String getServiceToken() {
            return serviceToken;
        }

        public void setServiceToken(String serviceToken) {
            this.serviceToken = serviceToken;
        }

        public java.time.Duration getConnectTimeout() {
            return connectTimeout;
        }

        public void setConnectTimeout(java.time.Duration connectTimeout) {
            this.connectTimeout = connectTimeout;
        }

        public java.time.Duration getReadTimeout() {
            return readTimeout;
        }

        public void setReadTimeout(java.time.Duration readTimeout) {
            this.readTimeout = readTimeout;
        }

        public int getTopK() {
            return topK;
        }

        public void setTopK(int topK) {
            this.topK = topK;
        }

        public int getEvidenceBudgetChars() {
            return evidenceBudgetChars;
        }

        public void setEvidenceBudgetChars(int evidenceBudgetChars) {
            this.evidenceBudgetChars = evidenceBudgetChars;
        }
    }

    /**
     * USER-DOC RAG Phase C: local PDF upload/ingestion knobs. All limits
     * are application-enforced (fail closed) before expensive parsing;
     * the sidecar carries matching backstop caps. Defaults are
     * conservative development values: a 5 MiB / 50-page ceiling keeps a
     * single upload's memory, parse time and future prompt footprint
     * small on a laptop, while covering real study documents. Production
     * overrides come from the environment; no paths or secrets live here.
     */
    public static class Documents {

        /** Application-controlled storage root (never a client path). */
        private String storageRoot = defaultStorageRoot();
        /** Hard ceiling for one uploaded PDF (bytes). */
        private long maxBytes = 5L * 1024 * 1024;
        /** Hard ceiling for parsed pages (server-counted, never claimed). */
        private int maxPages = 50;
        /** Hard ceiling for normalized characters of one page. */
        private int maxCharsPerPage = 20_000;
        /** Hard ceiling for normalized characters of the whole document. */
        private int maxTotalChars = 200_000;
        private java.time.Duration connectTimeout = java.time.Duration.ofSeconds(1);
        /** Wall-clock budget for one localhost extraction call. */
        private java.time.Duration extractTimeout = java.time.Duration.ofSeconds(30);
        /**
         * Localhost Qdrant base URL (Phase A infrastructure, Phase F
         * indexing). Localhost-only by deployment; never exposed to
         * Flutter or the internet. Timeouts reuse the connect/extract
         * budgets above (same localhost failure domain).
         */
        private String qdrantBaseUrl = "http://127.0.0.1:6333";
        private final UploadRateLimit rateLimit = new UploadRateLimit();

        private static String defaultStorageRoot() {
            return System.getProperty("user.home") + "/.gamelearn/documents";
        }

        public String getStorageRoot() {
            return storageRoot;
        }

        public void setStorageRoot(String storageRoot) {
            this.storageRoot = storageRoot;
        }

        public long getMaxBytes() {
            return maxBytes;
        }

        public void setMaxBytes(long maxBytes) {
            this.maxBytes = maxBytes;
        }

        public int getMaxPages() {
            return maxPages;
        }

        public void setMaxPages(int maxPages) {
            this.maxPages = maxPages;
        }

        public int getMaxCharsPerPage() {
            return maxCharsPerPage;
        }

        public void setMaxCharsPerPage(int maxCharsPerPage) {
            this.maxCharsPerPage = maxCharsPerPage;
        }

        public int getMaxTotalChars() {
            return maxTotalChars;
        }

        public void setMaxTotalChars(int maxTotalChars) {
            this.maxTotalChars = maxTotalChars;
        }

        public java.time.Duration getConnectTimeout() {
            return connectTimeout;
        }

        public void setConnectTimeout(java.time.Duration connectTimeout) {
            this.connectTimeout = connectTimeout;
        }

        public java.time.Duration getExtractTimeout() {
            return extractTimeout;
        }

        public void setExtractTimeout(java.time.Duration extractTimeout) {
            this.extractTimeout = extractTimeout;
        }

        public String getQdrantBaseUrl() {
            return qdrantBaseUrl;
        }

        public void setQdrantBaseUrl(String qdrantBaseUrl) {
            this.qdrantBaseUrl = qdrantBaseUrl;
        }

        /**
         * Phase G retrieval knobs. topK is bounded client input (default 5,
         * hard max 10, mirroring the RAG evidence limits); maxQueryChars
         * bounds query text before embedding (the sidecar backstop is
         * 2000); minScore is an UNCALIBRATED candidate filter, default off
         * (0.0) — candidate selection only, never answer-grounding
         * acceptance, which belongs to a later grounded-answering phase
         * with human-judged calibration.
         */
        private int retrievalTopKDefault = 5;
        private int retrievalTopKMax = 10;
        private int retrievalMaxQueryChars = 1000;
        private double retrievalMinScore = 0.0;

        public int getRetrievalTopKDefault() {
            return retrievalTopKDefault;
        }

        public void setRetrievalTopKDefault(int retrievalTopKDefault) {
            this.retrievalTopKDefault = retrievalTopKDefault;
        }

        public int getRetrievalTopKMax() {
            return retrievalTopKMax;
        }

        public void setRetrievalTopKMax(int retrievalTopKMax) {
            this.retrievalTopKMax = retrievalTopKMax;
        }

        public int getRetrievalMaxQueryChars() {
            return retrievalMaxQueryChars;
        }

        public void setRetrievalMaxQueryChars(int retrievalMaxQueryChars) {
            this.retrievalMaxQueryChars = retrievalMaxQueryChars;
        }

        public double getRetrievalMinScore() {
            return retrievalMinScore;
        }

        public void setRetrievalMinScore(double retrievalMinScore) {
            this.retrievalMinScore = retrievalMinScore;
        }

        /**
         * Phase H: strict maximum evidence records per grounding bundle.
         * Bounded default (20) sits above the retrieval topK ceiling (10)
         * so the normal path never hits it; direct assembly callers are
         * still capped and oversized bundles are rejected, never silently
         * truncated.
         */
        private int retrievalMaxEvidence = 20;

        public int getRetrievalMaxEvidence() {
            return retrievalMaxEvidence;
        }

        public void setRetrievalMaxEvidence(int retrievalMaxEvidence) {
            this.retrievalMaxEvidence = retrievalMaxEvidence;
        }

        /**
         * Phase I: user-document Q&A feature flag. Disabled by default —
         * ordinary AI Tutor traffic never routes through document RAG
         * merely because the feature exists. Only the new
         * {@code POST /api/v1/documents/ask} endpoint reads this flag.
         */
        private boolean documentRagEnabled = false;
        /** Question bound (mirrors the retrieval bound; both enforce). */
        private int askMaxQuestionChars = 1000;
        /** Faithfulness-first generation temperature for grounded answers. */
        private double askTemperature = 0.3;
        private int askMaxOutputTokens = 1024;
        /** Wall-clock budget for one grounded-answer call (incl. 1 retry). */
        private java.time.Duration askDeadline = java.time.Duration.ofSeconds(20);
        private final AskRateLimit askRateLimit = new AskRateLimit();

        public boolean isDocumentRagEnabled() {
            return documentRagEnabled;
        }

        public void setDocumentRagEnabled(boolean documentRagEnabled) {
            this.documentRagEnabled = documentRagEnabled;
        }

        public int getAskMaxQuestionChars() {
            return askMaxQuestionChars;
        }

        public void setAskMaxQuestionChars(int askMaxQuestionChars) {
            this.askMaxQuestionChars = askMaxQuestionChars;
        }

        public double getAskTemperature() {
            return askTemperature;
        }

        public void setAskTemperature(double askTemperature) {
            this.askTemperature = askTemperature;
        }

        public int getAskMaxOutputTokens() {
            return askMaxOutputTokens;
        }

        public void setAskMaxOutputTokens(int askMaxOutputTokens) {
            this.askMaxOutputTokens = askMaxOutputTokens;
        }

        public java.time.Duration getAskDeadline() {
            return askDeadline;
        }

        public void setAskDeadline(java.time.Duration askDeadline) {
            this.askDeadline = askDeadline;
        }

        public AskRateLimit getAskRateLimit() {
            return askRateLimit;
        }

        /** Dedicated ask bucket: never shared with tutor/upload quotas. */
        public static class AskRateLimit {

            private int maxAsksPerHour = 20;
            private int windowMinutes = 60;

            public int getMaxAsksPerHour() {
                return maxAsksPerHour;
            }

            public void setMaxAsksPerHour(int maxAsksPerHour) {
                this.maxAsksPerHour = maxAsksPerHour;
            }

            public int getWindowMinutes() {
                return windowMinutes;
            }

            public void setWindowMinutes(int windowMinutes) {
                this.windowMinutes = windowMinutes;
            }
        }

        public UploadRateLimit getRateLimit() {
            return rateLimit;
        }

        /** Conservative upload bucket: parsing is expensive, so the
         * default is tighter than the tutor/Gemini buckets. */
        public static class UploadRateLimit {

            private int maxUploadsPerHour = 10;
            private int windowMinutes = 60;

            public int getMaxUploadsPerHour() {
                return maxUploadsPerHour;
            }

            public void setMaxUploadsPerHour(int maxUploadsPerHour) {
                this.maxUploadsPerHour = maxUploadsPerHour;
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
