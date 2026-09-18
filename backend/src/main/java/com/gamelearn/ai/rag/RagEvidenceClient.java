package com.gamelearn.ai.rag;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.web.client.ClientHttpRequestFactories;
import org.springframework.boot.web.client.ClientHttpRequestFactorySettings;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClientResponseException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamelearn.config.AiProperties;

/**
 * Gate 23: typed client for the localhost RAG evidence sidecar.
 *
 * <p>Boundary rules: single attempt per tutor question (no retries, no
 * retry storms); explicit connect/read timeouts from configuration;
 * Bearer service token injected per call from configuration - never
 * logged, never persisted, never placed inside prompts or audit rows.
 * Transport/bundle failures raise {@link RagException} with audit-safe
 * categories; explicit sidecar degraded states (served=false) are
 * returned as data, not exceptions.</p>
 */
@Component
public class RagEvidenceClient {

    private static final Logger log = LoggerFactory.getLogger(RagEvidenceClient.class);
    private static final ObjectMapper MAPPER = new ObjectMapper();

    /**
     * Authoritative citation shape (Gate 21 lineage {@code table:id#cN}).
     * Anything else is rejected as invalid evidence - never trusted.
     */
    static final Pattern CITATION_PATTERN =
            Pattern.compile("^(lessons|topics|questions):[^#\\s]+#c\\d+$");

    private final RestClient restClient;
    private final AiProperties properties;

    public RagEvidenceClient(AiProperties properties) {
        this.properties = properties;
        this.restClient = RestClient.builder()
                .baseUrl(properties.getRag().getBaseUrl())
                .requestFactory(ClientHttpRequestFactories.get(
                        ClientHttpRequestFactorySettings.DEFAULTS
                                .withConnectTimeout(properties.getRag().getConnectTimeout())
                                .withReadTimeout(properties.getRag().getReadTimeout())))
                .build();
    }

    /** Scoped retrieval request; scope IDs are server-derived, never parsed from text. */
    public record RagQueryRequest(
            String requestId,
            String query,
            String subjectId,
            String topicId,
            String unitId,
            int topK) {
    }

    /**
     * Requests scoped evidence. Never throws for explicit sidecar degraded
     * states (served=false travels inside the returned evidence).
     */
    public RagEvidence retrieve(RagQueryRequest request) {
        String token = properties.getRag().getServiceToken();
        if (token == null || token.isBlank()) {
            throw new RagException(RagException.MISCONFIGURED,
                    "RAG service token is not configured", false);
        }
        long startedAt = System.currentTimeMillis();
        String raw;
        try {
            raw = restClient.post()
                    .uri("/retrieve")
                    .contentType(MediaType.APPLICATION_JSON)
                    .header("Authorization", "Bearer " + token)
                    .header("X-Request-ID", request.requestId())
                    .body(Map.of(
                            "request_id", request.requestId(),
                            "query", request.query(),
                            "subject_id", request.subjectId(),
                            "topic_id", request.topicId() == null ? "" : request.topicId(),
                            "unit_id", request.unitId() == null ? "" : request.unitId(),
                            "top_k", request.topK()))
                    .retrieve()
                    .body(String.class);
        } catch (RestClientResponseException ex) {
            throw classifyStatus(ex);
        } catch (RestClientException ex) {
            // Bounded by configuration: timeouts (connect/read) map to
            // TIMEOUT, refusals and other transport faults to UNAVAILABLE.
            if (isTimeout(ex)) {
                throw new RagException(RagException.TIMEOUT,
                        "RAG sidecar call timed out", true, ex);
            }
            throw new RagException(RagException.UNAVAILABLE,
                    "RAG sidecar could not be reached", true, ex);
        }
        long latencyMs = System.currentTimeMillis() - startedAt;
        return parse(request, raw, latencyMs);
    }

    /**
     * Walks the cause chain for timeout signatures (JDK HTTP client
     * {@code HttpTimeoutException}, socket/read timeouts). Connection
     * refusals and other transport faults stay UNAVAILABLE.
     */
    private static boolean isTimeout(Throwable failure) {
        for (Throwable current = failure; current != null;
                current = current.getCause()) {
            String name = current.getClass().getName();
            if (name.equals("java.net.http.HttpTimeoutException")
                    || current instanceof java.net.SocketTimeoutException
                    || current instanceof java.util.concurrent.TimeoutException) {
                return true;
            }
        }
        return false;
    }

    private RagException classifyStatus(RestClientResponseException ex) {        int value = ex.getStatusCode().value();
        log.info("RAG sidecar call failed with HTTP {}", value);
        if (value == 401) {
            return new RagException(RagException.MISCONFIGURED,
                    "RAG sidecar rejected credentials", false, ex);
        }
        if (value == 400 || value == 404) {
            return new RagException(RagException.MISCONFIGURED,
                    "RAG sidecar rejected the request shape", false, ex);
        }
        return new RagException(RagException.UNAVAILABLE,
                "RAG sidecar unavailable (HTTP " + value + ")", true, ex);
    }

    private RagEvidence parse(RagQueryRequest request, String raw, long latencyMs) {
        JsonNode root;
        try {
            root = MAPPER.readTree(raw);
        } catch (Exception ex) {
            throw new RagException(RagException.INVALID_EVIDENCE,
                    "RAG sidecar returned malformed JSON", false, ex);
        }
        if (!root.isObject() || !root.has("served") || !root.get("served").isBoolean()) {
            throw new RagException(RagException.INVALID_EVIDENCE,
                    "RAG sidecar returned a malformed bundle", false);
        }
        boolean served = root.get("served").asBoolean();
        String emptyReason = textOrNull(root, "empty_reason");
        String corpusFingerprint = textOrNull(root, "corpus_fingerprint");
        String retrieverVersion = textOrNull(root, "retriever_version");
        List<RagEvidence.Chunk> chunks = new ArrayList<>();
        JsonNode chunksNode = root.get("chunks");
        if (chunksNode != null && chunksNode.isArray()) {
            for (JsonNode node : chunksNode) {
                chunks.add(parseChunk(node));
            }
        } else if (served) {
            throw new RagException(RagException.INVALID_EVIDENCE,
                    "served RAG bundle carries no chunks", false);
        }
        return new RagEvidence(served, emptyReason == null ? "" : emptyReason,
                List.copyOf(chunks),
                corpusFingerprint == null ? "" : corpusFingerprint,
                retrieverVersion == null ? "" : retrieverVersion, latencyMs);
    }

    private RagEvidence.Chunk parseChunk(JsonNode node) {
        String citation = requiredText(node, "citation");
        if (!CITATION_PATTERN.matcher(citation).matches()) {
            throw new RagException(RagException.INVALID_EVIDENCE,
                    "RAG chunk carries a non-authoritative citation", false);
        }
        String text = requiredText(node, "text");
        if (text.isBlank()) {
            throw new RagException(RagException.INVALID_EVIDENCE,
                    "RAG chunk carries empty text", false);
        }
        return new RagEvidence.Chunk(
                textOrNull(node, "chunk_id"),
                citation,
                textOrNull(node, "source_table"),
                textOrNull(node, "source_id"),
                requiredText(node, "subject_id"),
                textOrNull(node, "topic_id"),
                textOrNull(node, "unit_id"),
                textOrNull(node, "content_version"),
                textOrNull(node, "difficulty"),
                node.has("score") && node.get("score").isNumber()
                        ? node.get("score").asDouble() : 0.0,
                text);
    }

    private static String requiredText(JsonNode node, String field) {
        String value = textOrNull(node, field);
        if (value == null || value.isBlank()) {
            throw new RagException(RagException.INVALID_EVIDENCE,
                    "RAG chunk is missing required field: " + field, false);
        }
        return value;
    }

    private static String textOrNull(JsonNode node, String field) {
        JsonNode child = node.get(field);
        if (child == null || child.isNull() || !child.isTextual()) {
            return null;
        }
        String value = child.asText();
        return value.isBlank() ? null : value;
    }
}
