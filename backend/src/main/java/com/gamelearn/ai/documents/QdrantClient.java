package com.gamelearn.ai.documents;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
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
 * USER-DOC RAG Phase F: minimal raw-REST client for the localhost Qdrant
 * service (Phase A infrastructure). No Qdrant SDK dependency — the few
 * endpoints Phase F needs (collection describe/create, payload indexes,
 * points upsert/count/scroll/delete) are plain JSON over HTTP, following
 * the existing {@code RestClient} conventions.
 *
 * <p>Localhost-only by deployment ({@code gamelearn.ai.documents.qdrant-base-url},
 * default {@code http://127.0.0.1:6333}); this client never leaves the
 * backend process, and Qdrant is never exposed to Flutter. There is no
 * authentication in this phase (Phase A decision, documented for
 * localhost development); production must add API key + TLS + policy.</p>
 *
 * <p>Collection mismatches fail closed: an existing collection with the
 * wrong dimension/distance is never auto-migrated — that requires
 * explicit operator action (manual collection handling outside the app).
 * No collection delete exists here by design.</p>
 */
@Component
public class QdrantClient {

    private static final Logger log = LoggerFactory.getLogger(QdrantClient.class);
    private static final ObjectMapper MAPPER = new ObjectMapper();

    /** The single user-document chunk collection (exact name). */
    public static final String COLLECTION = "user_doc_chunks";
    public static final int VECTOR_SIZE = 384;
    public static final String DISTANCE = "Cosine";

    /** One point to upsert: deterministic id, validated vector, payload. */
    public record QdrantPoint(UUID id, double[] vector, Map<String, Object> payload) {
    }

    /** Observed collection configuration (for verify-or-fail-closed). */
    public record CollectionInfo(boolean exists, int vectorSize, String distance,
                                 Map<String, String> payloadSchema) {
    }

    private final RestClient restClient;

    @Autowired
    public QdrantClient(AiProperties properties) {
        this(properties.getDocuments().getQdrantBaseUrl(),
                properties.getDocuments().getConnectTimeout(),
                properties.getDocuments().getExtractTimeout());
    }

    /** Direct construction (tests/tools); the Spring bean uses config. */
    public QdrantClient(String baseUrl, java.time.Duration connectTimeout,
                        java.time.Duration readTimeout) {
        this.restClient = RestClient.builder()
                .baseUrl(baseUrl)
                .requestFactory(ClientHttpRequestFactories.get(
                        ClientHttpRequestFactorySettings.DEFAULTS
                                .withConnectTimeout(connectTimeout)
                                .withReadTimeout(readTimeout)))
                .build();
    }

    // ------------------------------------------------------------------
    // collections
    // ------------------------------------------------------------------

    /** Describes the collection, or returns empty when absent (no throw). */
    public java.util.Optional<CollectionInfo> describeCollection() {
        String raw;
        try {
            raw = restClient.get()
                    .uri("/collections/{collection}", COLLECTION)
                    .retrieve()
                    .body(String.class);
        } catch (RestClientResponseException ex) {
            if (ex.getStatusCode().value() == 404) {
                return java.util.Optional.empty();
            }
            throw classifyStatus(ex);
        } catch (RestClientException ex) {
            throw classifyTransport(ex);
        }
        JsonNode root = parseJson(raw, "collection description");
        JsonNode result = root.path("result");
        JsonNode vectors = result.path("config").path("params").path("vectors");
        int size = vectors.path("size").asInt(-1);
        String distance = vectors.path("distance").asText("");
        Map<String, String> schema = new LinkedHashMap<>();
        JsonNode payloadSchema = result.path("payload_schema");
        if (payloadSchema.isObject()) {
            payloadSchema.fields().forEachRemaining(entry ->
                    schema.put(entry.getKey(),
                            entry.getValue().path("data_type").asText("")));
        }
        return java.util.Optional.of(new CollectionInfo(true, size, distance, schema));
    }

    /**
     * Verifies the collection exists with exactly size 384 / Cosine and
     * the required payload indexes, creating what is absent. An existing
     * incompatible collection fails closed (never deleted/recreated here).
     */
    public void ensureCollection() {
        java.util.Optional<CollectionInfo> existing = describeCollection();
        if (existing.isEmpty()) {
            put("/collections/{collection}",
                    Map.of("vectors", Map.of("size", VECTOR_SIZE, "distance", DISTANCE)));
            log.info("QDRANT_COLLECTION_CREATED collection={}", COLLECTION);
        } else {
            CollectionInfo info = existing.get();
            if (info.vectorSize() != VECTOR_SIZE
                    || !DISTANCE.equalsIgnoreCase(info.distance())) {
                throw new QdrantException(QdrantException.MISCONFIGURED,
                        "Vector store collection has incompatible configuration", false);
            }
        }
        ensurePayloadIndex("owner_id", "keyword");
        ensurePayloadIndex("document_id", "keyword");
        ensurePayloadIndex("doc_version", "integer");
    }

    private void ensurePayloadIndex(String field, String schema) {
        java.util.Optional<CollectionInfo> info = describeCollection();
        if (info.isPresent() && info.get().payloadSchema().containsKey(field)) {
            return;
        }
        try {
            put("/collections/{collection}/index",
                    Map.of("field_name", field, "field_schema", schema));
        } catch (QdrantException ex) {
            // Created concurrently or already present: re-read and confirm.
            java.util.Optional<CollectionInfo> reread = describeCollection();
            if (reread.isEmpty() || !reread.get().payloadSchema().containsKey(field)) {
                throw ex;
            }
        }
    }

    // ------------------------------------------------------------------
    // points
    // ------------------------------------------------------------------

    /** Single-batch upsert ({@code wait=true}); verifies server completion. */
    public void upsertPoints(List<QdrantPoint> points) {
        if (points == null || points.isEmpty()) {
            throw new QdrantException(QdrantException.INVALID,
                    "No points to upsert", false);
        }
        List<Map<String, Object>> serialized = new ArrayList<>(points.size());
        for (QdrantPoint point : points) {
            List<Double> vector = new ArrayList<>(point.vector().length);
            for (double value : point.vector()) {
                vector.add(value);
            }
            serialized.add(Map.of("id", point.id().toString(),
                    "vector", vector, "payload", point.payload()));
        }
        JsonNode response = put("/collections/{collection}/points?wait=true",
                Map.of("points", serialized));
        String status = response.path("result").path("status").asText("");
        if (!"completed".equalsIgnoreCase(status)) {
            throw new QdrantException(QdrantException.INVALID,
                    "Vector store did not confirm upsert completion", false);
        }
    }

    /** Exact filtered count (used for the count invariant + verification). */
    public long countPoints(List<Map<String, Object>> must) {
        JsonNode response = post("/collections/{collection}/points/count",
                Map.of("filter", Map.of("must", must), "exact", true));
        JsonNode count = response.path("result").path("count");
        if (!count.isNumber()) {
            throw new QdrantException(QdrantException.INVALID,
                    "Vector store returned a malformed count", false);
        }
        return count.asLong();
    }

    /** Point ids matching a filter (paginated internally; vectors excluded). */
    public List<UUID> scrollPointIds(List<Map<String, Object>> must) {
        List<UUID> ids = new ArrayList<>();
        Object offset = null;
        while (true) {
            Map<String, Object> body = new LinkedHashMap<>();
            body.put("filter", Map.of("must", must));
            body.put("limit", 1000);
            body.put("with_payload", false);
            body.put("with_vector", false);
            if (offset != null) {
                body.put("offset", offset);
            }
            JsonNode response = post("/collections/{collection}/points/scroll", body);
            JsonNode result = response.path("result");
            JsonNode points = result.path("points");
            if (!points.isArray()) {
                throw new QdrantException(QdrantException.INVALID,
                        "Vector store returned a malformed scroll page", false);
            }
            for (JsonNode point : points) {
                try {
                    ids.add(UUID.fromString(point.path("id").asText()));
                } catch (IllegalArgumentException ex) {
                    throw new QdrantException(QdrantException.INVALID,
                            "Vector store returned a malformed point id", false);
                }
            }
            JsonNode next = result.path("next_page_offset");
            if (next.isNull() || next.isMissingNode()) {
                break;
            }
            offset = next.isNumber() ? next.asLong() : next.asText();
        }
        return ids;
    }

    /** One ranked hit: stable id, cosine score, full payload for validation. */
    public record SearchHit(UUID id, double score, JsonNode payload) {
    }

    /**
     * Owner-scoped cosine search over {@code user_doc_chunks} via the
     * {@code /points/query} API (single request, vectors excluded from the
     * response — only scores + payloads travel). The caller MUST supply a
     * filter containing the owner clause; this method refuses
     * ownerless/empty filters instead of running an unrestricted search.
     * An optional score threshold narrows candidates server-side; final
     * deterministic ordering stays caller-side (never depend on Qdrant
     * tie behavior).
     */
    public List<SearchHit> searchPoints(double[] query, List<Map<String, Object>> must,
                                        int limit, Double scoreThreshold) {
        if (query == null || query.length != VECTOR_SIZE) {
            throw new QdrantException(QdrantException.INVALID,
                    "Search query must have exactly 384 dimensions", false);
        }
        if (must == null || must.isEmpty() || !hasOwnerClause(must)) {
            throw new QdrantException(QdrantException.INVALID,
                    "Refusing ownerless vector search", false);
        }
        if (limit < 1) {
            throw new QdrantException(QdrantException.INVALID,
                    "Search limit must be positive", false);
        }
        List<Double> vector = new ArrayList<>(query.length);
        for (double value : query) {
            if (!Double.isFinite(value)) {
                throw new QdrantException(QdrantException.INVALID,
                        "Search query must be finite", false);
            }
            vector.add(value);
        }
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("query", vector);
        body.put("filter", Map.of("must", must));
        body.put("limit", limit);
        body.put("with_payload", true);
        body.put("with_vector", false);
        if (scoreThreshold != null) {
            body.put("score_threshold", scoreThreshold);
        }
        JsonNode response = post("/collections/{collection}/points/query", body);
        JsonNode points = response.path("result").path("points");
        if (!points.isArray()) {
            throw new QdrantException(QdrantException.INVALID,
                    "Vector store returned a malformed search result", false);
        }
        List<SearchHit> hits = new ArrayList<>();
        for (JsonNode point : points) {
            UUID id;
            try {
                id = UUID.fromString(point.path("id").asText());
            } catch (IllegalArgumentException ex) {
                throw new QdrantException(QdrantException.INVALID,
                        "Vector store returned a malformed point id", false);
            }
            JsonNode score = point.path("score");
            JsonNode payload = point.path("payload");
            if (!score.isNumber() || !Double.isFinite(score.asDouble())
                    || !payload.isObject()) {
                throw new QdrantException(QdrantException.INVALID,
                        "Vector store returned a malformed search hit", false);
            }
            hits.add(new SearchHit(id, score.asDouble(), payload));
        }
        return hits;
    }

    private static boolean hasOwnerClause(List<Map<String, Object>> must) {
        for (Map<String, Object> clause : must) {
            if ("owner_id".equals(clause.get("key"))) {
                return true;
            }
        }
        return false;
    }

    /** Deletes exactly the given point ids ({@code wait=true}). */
    public void deleteByIds(List<UUID> ids) {
        if (ids == null || ids.isEmpty()) {
            return;
        }
        List<String> raw = new ArrayList<>(ids.size());
        for (UUID id : ids) {
            raw.add(id.toString());
        }
        post("/collections/{collection}/points/delete?wait=true", Map.of("points", raw));
    }

    /** Deletes exactly the filtered set ({@code wait=true}). */
    public void deleteByFilter(List<Map<String, Object>> must) {
        if (must == null || must.isEmpty()) {
            throw new QdrantException(QdrantException.INVALID,
                    "Refusing ambiguous delete without a full filter", false);
        }
        post("/collections/{collection}/points/delete?wait=true",
                Map.of("filter", Map.of("must", must)));
    }

    /** Mandatory ownership filter clause (Qdrant enforces, not the app). */
    public static Map<String, Object> ownerClause(String ownerId) {
        return Map.of("key", "owner_id", "match", Map.of("value", ownerId));
    }

    /** Mandatory document filter clause. */
    public static Map<String, Object> documentClause(String documentId) {
        return Map.of("key", "document_id", "match", Map.of("value", documentId));
    }

    /** Mandatory version filter clause. */
    public static Map<String, Object> versionClause(int docVersion) {
        return Map.of("key", "doc_version", "match", Map.of("value", docVersion));
    }

    // ------------------------------------------------------------------
    // transport
    // ------------------------------------------------------------------

    private JsonNode put(String uri, Object body) {
        return exchange("PUT", uri, body);
    }

    private JsonNode post(String uri, Object body) {
        return exchange("POST", uri, body);
    }

    private JsonNode exchange(String method, String uri, Object body) {
        String raw;
        try {
            RestClient.RequestBodySpec spec = (method.equals("PUT") ? restClient.put() : restClient.post())
                    .uri(uri, Map.of("collection", COLLECTION))
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body);
            raw = spec.retrieve().body(String.class);
        } catch (RestClientResponseException ex) {
            throw classifyStatus(ex);
        } catch (RestClientException ex) {
            throw classifyTransport(ex);
        }
        JsonNode root = parseJson(raw, method + " " + uri);
        String status = root.path("status").asText("");
        if (!"ok".equalsIgnoreCase(status)) {
            throw new QdrantException(QdrantException.INVALID,
                    "Vector store returned a non-ok status", false);
        }
        return root;
    }

    private static JsonNode parseJson(String raw, String context) {
        try {
            JsonNode root = MAPPER.readTree(raw);
            if (root == null || !root.isObject()) {
                throw new IllegalArgumentException("not an object");
            }
            return root;
        } catch (Exception ex) {
            throw new QdrantException(QdrantException.INVALID,
                    "Vector store returned malformed JSON for " + context, false);
        }
    }

    private QdrantException classifyStatus(RestClientResponseException ex) {
        int value = ex.getStatusCode().value();
        log.info("Qdrant call failed with HTTP {}", value);
        if (value == 404) {
            return new QdrantException(QdrantException.INVALID,
                    "Vector store resource not found", false, ex);
        }
        if (value >= 500) {
            return new QdrantException(QdrantException.UNAVAILABLE,
                    "Vector store unavailable (HTTP " + value + ")", true, ex);
        }
        return new QdrantException(QdrantException.INVALID,
                "Vector store rejected the request (HTTP " + value + ")", false, ex);
    }

    private static QdrantException classifyTransport(RestClientException ex) {
        for (Throwable current = ex; current != null; current = current.getCause()) {
            String name = current.getClass().getName();
            if (name.equals("java.net.http.HttpTimeoutException")
                    || current instanceof java.net.SocketTimeoutException
                    || current instanceof java.util.concurrent.TimeoutException) {
                return new QdrantException(QdrantException.TIMEOUT,
                        "Vector store call timed out", true, ex);
            }
        }
        return new QdrantException(QdrantException.UNAVAILABLE,
                "Vector store could not be reached", true, ex);
    }
}
