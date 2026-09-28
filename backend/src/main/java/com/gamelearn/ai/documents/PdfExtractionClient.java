package com.gamelearn.ai.documents;

import java.util.ArrayList;
import java.util.List;

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
 * USER-DOC RAG Phase C: typed client for the localhost PDF-extraction
 * sidecar ({@code POST /extract}, raw PDF bytes in, page texts out).
 *
 * <p>Boundary rules (mirroring {@code RagEvidenceClient}): single bounded
 * attempt per upload (no retries); explicit connect/extract timeouts;
 * Bearer service token reuses the existing sidecar token from
 * configuration — never logged, never persisted. The sidecar is
 * ownership-blind by design: it parses bytes only. Spring remains
 * authoritative for ownership, limits and lifecycle.</p>
 *
 * <p>Parser refusals ({@code ok:false + reason}) travel as data (HTTP
 * 200), exactly like the RAG {@code served:false} pattern — they are
 * returned, never thrown. Transport/shape faults throw
 * {@link PdfExtractionException}.</p>
 */
@Component
public class PdfExtractionClient {

    private static final Logger log = LoggerFactory.getLogger(PdfExtractionClient.class);
    private static final ObjectMapper MAPPER = new ObjectMapper();

    /** One extracted page: 1-based number plus normalized text. */
    public record ExtractionPage(int pageNo, String text) {
    }

    /** One provenance-preserving chunk (page-local, never cross-page). */
    public record DocChunk(String chunkId, String citation, int pageNo, int chunkIndex,
                           String text, String textHash, String ownerId) {
    }

    /** Chunking outcome: chunk records on success, a reason code on refusal. */
    public record ChunkResult(boolean ok, String reason, String documentId, int docVersion,
                              String configVersion, int chunkCount, List<DocChunk> chunks) {

        static ChunkResult refused(String reason) {
            return new ChunkResult(false, reason == null ? "unknown" : reason,
                    "", 0, "", 0, List.of());
        }
    }

    /** One embedded chunk: 384-d unit vector aligned with its chunk id. */
    public record EmbeddedChunk(String chunkId, double[] vector) {
    }

    /** Embedding outcome: vectors + binding manifest, or a reason code. */
    public record EmbedResult(boolean ok, String reason, String documentId, int docVersion,
                              String modelId, String modelRevision, String modelLicense,
                              int dimension, boolean normalized, String similarity,
                              String embedderVersion, String chunkConfigVersion,
                              String embeddingFingerprint, List<String> chunkIds,
                              int chunkCount, List<EmbeddedChunk> chunks) {

        static EmbedResult refused(String reason) {
            return new EmbedResult(false, reason == null ? "unknown" : reason,
                    "", 0, "", "", "", 0, false, "", "", "", "", List.of(), 0, List.of());
        }
    }

    /** Query embedding outcome: 384-d unit vector or a reason code. */
    public record QueryVector(boolean ok, String reason, double[] vector) {

        static QueryVector refused(String reason) {
            return new QueryVector(false, reason == null ? "unknown" : reason, new double[0]);
        }
    }

    /** Pinned query-embedding contract (mirror of the Python registry;
     * asserted live on every response, never assumed).
     */
    static final String EXPECTED_MODEL_ID = "sentence-transformers/all-MiniLM-L6-v2";
    static final String EXPECTED_MODEL_REVISION = "1110a243fdf4706b3f48f1d95db1a4f5529b4d41";
    static final int EXPECTED_DIMENSION = 384;

    /** Extraction outcome: pages on success, a reason code on refusal. */
    public record Extraction(boolean ok, String reason, List<String> reasonCodes,
                             int pageCount, List<ExtractionPage> pages) {

        static Extraction refused(String reason, List<String> reasonCodes) {
            return new Extraction(false, reason == null ? "unknown" : reason,
                    reasonCodes == null ? List.of() : List.copyOf(reasonCodes),
                    0, List.of());
        }
    }

    private final RestClient restClient;
    private final AiProperties properties;

    public PdfExtractionClient(AiProperties properties) {
        this.properties = properties;
        this.restClient = RestClient.builder()
                .baseUrl(properties.getRag().getBaseUrl())
                .requestFactory(ClientHttpRequestFactories.get(
                        ClientHttpRequestFactorySettings.DEFAULTS
                                .withConnectTimeout(properties.getDocuments().getConnectTimeout())
                                .withReadTimeout(properties.getDocuments().getExtractTimeout())))
                .build();
    }

    /**
     * Extracts page texts for one upload. Parser refusals are returned as
     * data; only transport/integrity faults throw.
     */
    public Extraction extract(String requestId, byte[] pdfBytes) {
        String token = properties.getRag().getServiceToken();
        if (token == null || token.isBlank()) {
            throw new PdfExtractionException(PdfExtractionException.MISCONFIGURED,
                    "Extraction service token is not configured", false);
        }
        if (pdfBytes == null || pdfBytes.length == 0) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "Empty PDF bytes cannot be extracted", false);
        }
        String raw;
        try {
            raw = restClient.post()
                    .uri("/extract")
                    .contentType(MediaType.APPLICATION_PDF)
                    .header("Authorization", "Bearer " + token)
                    .header("X-Request-ID", requestId)
                    .body(pdfBytes)
                    .retrieve()
                    .body(String.class);
        } catch (RestClientResponseException ex) {
            throw classifyStatus(ex);
        } catch (RestClientException ex) {
            if (isTimeout(ex)) {
                throw new PdfExtractionException(PdfExtractionException.TIMEOUT,
                        "Extraction call timed out", true, ex);
            }
            throw new PdfExtractionException(PdfExtractionException.UNAVAILABLE,
                    "Extraction service could not be reached", true, ex);
        }
        return parse(raw);
    }

    /**
     * Chunks extracted pages into provenance records via {@code POST /chunk}.
     * The document id/version/owner are server-generated values the caller
     * passes through; chunk refusals return as data, transport/shape faults
     * throw. Page-locality and identity rules live in the sidecar; this
     * method additionally verifies the response echoes the requested
     * document and only references supplied pages.
     */
    public ChunkResult chunk(String requestId, java.util.UUID documentId, int docVersion,
                             java.util.UUID ownerId, List<ExtractionPage> pages) {
        String token = properties.getRag().getServiceToken();
        if (token == null || token.isBlank()) {
            throw new PdfExtractionException(PdfExtractionException.MISCONFIGURED,
                    "Extraction service token is not configured", false);
        }
        if (pages == null || pages.isEmpty()) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "No pages to chunk", false);
        }
        com.fasterxml.jackson.databind.node.ObjectNode body = MAPPER.createObjectNode();
        body.put("document_id", documentId.toString());
        body.put("doc_version", docVersion);
        body.put("owner_id", ownerId.toString());
        com.fasterxml.jackson.databind.node.ArrayNode pageNodes = body.putArray("pages");
        java.util.Set<Integer> pageNos = new java.util.HashSet<>();
        for (ExtractionPage page : pages) {
            com.fasterxml.jackson.databind.node.ObjectNode node = pageNodes.addObject();
            node.put("page_no", page.pageNo());
            node.put("text", page.text() == null ? "" : page.text());
            pageNos.add(page.pageNo());
        }
        String raw;
        try {
            raw = restClient.post()
                    .uri("/chunk")
                    .contentType(MediaType.APPLICATION_JSON)
                    .header("Authorization", "Bearer " + token)
                    .header("X-Request-ID", requestId)
                    .body(body.toString())
                    .retrieve()
                    .body(String.class);
        } catch (RestClientResponseException ex) {
            throw classifyStatus(ex);
        } catch (RestClientException ex) {
            if (isTimeout(ex)) {
                throw new PdfExtractionException(PdfExtractionException.TIMEOUT,
                        "Chunking call timed out", true, ex);
            }
            throw new PdfExtractionException(PdfExtractionException.UNAVAILABLE,
                    "Chunking service could not be reached", true, ex);
        }
        return parseChunks(raw, documentId.toString(), docVersion, pageNos);
    }

    private ChunkResult parseChunks(String raw, String documentId, int docVersion,
                                    java.util.Set<Integer> pageNos) {
        JsonNode root;
        try {
            root = MAPPER.readTree(raw);
        } catch (Exception ex) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "Chunking service returned malformed JSON", false, ex);
        }
        if (!root.isObject() || !root.has("ok") || !root.get("ok").isBoolean()) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "Chunking service returned a malformed result", false);
        }
        if (!root.get("ok").asBoolean()) {
            return ChunkResult.refused(textOrNull(root, "reason"));
        }
        if (!documentId.equals(textOrNull(root, "document_id"))) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "Chunking result references another document", false);
        }
        JsonNode versionNode = root.get("doc_version");
        if (versionNode == null || !versionNode.isInt()
                || versionNode.asInt() != docVersion) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "Chunking result references another document version", false);
        }
        JsonNode chunksNode = root.get("chunks");
        if (chunksNode == null || !chunksNode.isArray() || chunksNode.isEmpty()) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "Successful chunking carries no chunks", false);
        }
        List<DocChunk> chunks = new ArrayList<>();
        for (JsonNode node : chunksNode) {
            String chunkId = requiredChunkText(node, "chunk_id");
            String citation = requiredChunkText(node, "citation");
            String text = requiredChunkText(node, "text");
            String textHash = requiredChunkText(node, "text_hash");
            JsonNode pageNode = node.get("page_no");
            JsonNode indexNode = node.get("chunk_index");
            if (pageNode == null || !pageNode.isInt() || indexNode == null
                    || !indexNode.isInt() || indexNode.asInt() < 0
                    || !pageNos.contains(pageNode.asInt())) {
                throw new PdfExtractionException(PdfExtractionException.INVALID,
                        "Chunk references an unknown page", false);
            }
            // Owner travels as metadata only; the sidecar must echo the
            // server-supplied value, never one derived from document text.
            JsonNode ownerNode = node.get("owner_id");
            String owner = ownerNode != null && ownerNode.isTextual()
                    ? ownerNode.asText() : null;
            chunks.add(new DocChunk(chunkId, citation, pageNode.asInt(),
                    indexNode.asInt(), text, textHash, owner));
        }
        String configVersion = textOrNull(root, "chunk_config_version");
        return new ChunkResult(true, "", documentId, docVersion,
                configVersion == null ? "" : configVersion,
                chunks.size(), List.copyOf(chunks));
    }

    private static String requiredChunkText(JsonNode node, String field) {
        String value = textOrNull(node, field);
        if (value == null || value.isBlank()) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "Chunk is missing required field: " + field, false);
        }
        return value;
    }

    /**
     * Embeds validated chunk texts via {@code POST /embed} using the
     * sidecar's startup-loaded pinned model (inference-only, one load per
     * process). Only bare chunk texts travel; owner/document metadata
     * rides alongside for bookkeeping and is echoed back, never embedded.
     * Every vector is validated here (384/finite/unit-norm) and the
     * embedding fingerprint is recomputed and compared — mismatches fail
     * closed. Refusals return as data; transport/shape faults throw.
     */
    public EmbedResult embed(String requestId, java.util.UUID documentId, int docVersion,
                             java.util.UUID ownerId, List<DocChunk> chunks) {
        String token = properties.getRag().getServiceToken();
        if (token == null || token.isBlank()) {
            throw new PdfExtractionException(PdfExtractionException.MISCONFIGURED,
                    "Extraction service token is not configured", false);
        }
        if (chunks == null || chunks.isEmpty()) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "No chunks to embed", false);
        }
        com.fasterxml.jackson.databind.node.ObjectNode body = MAPPER.createObjectNode();
        body.put("document_id", documentId.toString());
        body.put("doc_version", docVersion);
        body.put("owner_id", ownerId.toString());
        com.fasterxml.jackson.databind.node.ArrayNode chunkNodes = body.putArray("chunks");
        for (DocChunk chunk : chunks) {
            com.fasterxml.jackson.databind.node.ObjectNode node = chunkNodes.addObject();
            node.put("chunk_id", chunk.chunkId());
            node.put("text", chunk.text() == null ? "" : chunk.text());
        }
        String raw;
        try {
            raw = restClient.post()
                    .uri("/embed")
                    .contentType(MediaType.APPLICATION_JSON)
                    .header("Authorization", "Bearer " + token)
                    .header("X-Request-ID", requestId)
                    .body(body.toString())
                    .retrieve()
                    .body(String.class);
        } catch (RestClientResponseException ex) {
            throw classifyStatus(ex);
        } catch (RestClientException ex) {
            if (isTimeout(ex)) {
                throw new PdfExtractionException(PdfExtractionException.TIMEOUT,
                        "Embedding call timed out", true, ex);
            }
            throw new PdfExtractionException(PdfExtractionException.UNAVAILABLE,
                    "Embedding service could not be reached", true, ex);
        }
        return parseEmbeddings(raw, documentId.toString(), docVersion);
    }

    private EmbedResult parseEmbeddings(String raw, String documentId, int docVersion) {
        JsonNode root;
        try {
            root = MAPPER.readTree(raw);
        } catch (Exception ex) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "Embedding service returned malformed JSON", false, ex);
        }
        if (!root.isObject() || !root.has("ok") || !root.get("ok").isBoolean()) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "Embedding service returned a malformed result", false);
        }
        if (!root.get("ok").asBoolean()) {
            return EmbedResult.refused(textOrNull(root, "reason"));
        }
        if (!documentId.equals(textOrNull(root, "document_id"))) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "Embedding result references another document", false);
        }
        JsonNode versionNode = root.get("doc_version");
        if (versionNode == null || !versionNode.isInt()
                || versionNode.asInt() != docVersion) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "Embedding result references another document version", false);
        }
        JsonNode vectorsNode = root.get("embeddings");
        if (vectorsNode == null || !vectorsNode.isArray() || vectorsNode.isEmpty()) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "Successful embedding carries no vectors", false);
        }
        List<EmbeddedChunk> chunks = new ArrayList<>();
        for (JsonNode node : vectorsNode) {
            String chunkId = requiredChunkText(node, "chunk_id");
            JsonNode vectorNode = node.get("vector");
            if (vectorNode == null || !vectorNode.isArray()
                    || vectorNode.size() != 384) {
                throw new PdfExtractionException(PdfExtractionException.INVALID,
                        "Embedding vector must have exactly 384 dimensions", false);
            }
            double[] vector = new double[384];
            int i = 0;
            for (JsonNode value : vectorNode) {
                if (!value.isNumber()) {
                    throw new PdfExtractionException(PdfExtractionException.INVALID,
                            "Embedding vector must be numeric", false);
                }
                double number = value.asDouble();
                if (!Double.isFinite(number)) {
                    throw new PdfExtractionException(PdfExtractionException.INVALID,
                            "Embedding vector must be finite", false);
                }
                vector[i++] = number;
            }
            double norm = 0.0;
            for (double value : vector) {
                norm += value * value;
            }
            norm = Math.sqrt(norm);
            if (Math.abs(norm - 1.0) > 1e-3) {
                throw new PdfExtractionException(PdfExtractionException.INVALID,
                        "Embedding vector is not unit-normalized", false);
            }
            chunks.add(new EmbeddedChunk(chunkId, vector));
        }
        String fingerprint = textOrNull(root, "embedding_fingerprint");
        if (fingerprint == null || fingerprint.isBlank()) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "Embedding result carries no fingerprint", false);
        }
        if (!fingerprint.equalsIgnoreCase(fingerprintHex(chunks))) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "Embedding fingerprint mismatch", false);
        }
        List<String> chunkIds = new ArrayList<>();
        for (EmbeddedChunk chunk : chunks) {
            chunkIds.add(chunk.chunkId());
        }
        String modelId = textOrNull(root, "model_id");
        String modelRevision = textOrNull(root, "model_revision");
        String modelLicense = textOrNull(root, "model_license");
        String similarity = textOrNull(root, "similarity_metric");
        JsonNode normalizedNode = root.get("normalize_embeddings");
        if (modelId == null || modelId.isBlank() || modelRevision == null
                || modelRevision.isBlank() || modelLicense == null
                || modelLicense.isBlank() || similarity == null
                || similarity.isBlank() || normalizedNode == null
                || !normalizedNode.isBoolean()) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "Embedding result carries incomplete model binding", false);
        }
        return new EmbedResult(true, "", documentId, docVersion,
                modelId, modelRevision, modelLicense,
                384, normalizedNode.asBoolean(), similarity,
                textOrNull(root, "embedder_version"),
                textOrNull(root, "chunk_config_version"), fingerprint,
                List.copyOf(chunkIds), chunks.size(), List.copyOf(chunks));
    }

    /**
     * Recomputes the embedding fingerprint exactly like
     * {@code mlrag.embeddings.pipeline.embedding_fingerprint}: SHA-256 hex
     * over the little-endian float32 matrix bytes in chunk order. Shared
     * verification routine (also used by tests to build stub fixtures).
     */
    public static String fingerprintHex(List<EmbeddedChunk> chunks) {
        java.nio.ByteBuffer buffer =
                java.nio.ByteBuffer.allocate(chunks.size() * 384 * 4)
                        .order(java.nio.ByteOrder.LITTLE_ENDIAN);
        for (EmbeddedChunk chunk : chunks) {
            for (double value : chunk.vector()) {
                buffer.putFloat((float) value);
            }
        }
        try {
            java.security.MessageDigest digest =
                    java.security.MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(buffer.array());
            StringBuilder hex = new StringBuilder(hash.length * 2);
            for (byte b : hash) {
                hex.append(Character.forDigit((b >> 4) & 0xF, 16));
                hex.append(Character.forDigit(b & 0xF, 16));
            }
            return hex.toString();
        } catch (java.security.NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 unavailable", ex);
        }
    }

    /**
     * Embeds one retrieval query with the sidecar's startup-loaded pinned
     * model (same model/revision/normalization as document chunks, so
     * cosine scores are comparable). Refusals return as data;
     * transport/shape/binding faults throw. The revision is asserted on
     * every response — a wrong model can never silently serve queries.
     */
    public QueryVector embedQuery(String requestId, String query) {
        String token = properties.getRag().getServiceToken();
        if (token == null || token.isBlank()) {
            throw new PdfExtractionException(PdfExtractionException.MISCONFIGURED,
                    "Extraction service token is not configured", false);
        }
        com.fasterxml.jackson.databind.node.ObjectNode body = MAPPER.createObjectNode();
        body.put("query", query == null ? "" : query);
        String raw;
        try {
            raw = restClient.post()
                    .uri("/embed_query")
                    .contentType(MediaType.APPLICATION_JSON)
                    .header("Authorization", "Bearer " + token)
                    .header("X-Request-ID", requestId)
                    .body(body.toString())
                    .retrieve()
                    .body(String.class);
        } catch (RestClientResponseException ex) {
            throw classifyStatus(ex);
        } catch (RestClientException ex) {
            if (isTimeout(ex)) {
                throw new PdfExtractionException(PdfExtractionException.TIMEOUT,
                        "Query embedding call timed out", true, ex);
            }
            throw new PdfExtractionException(PdfExtractionException.UNAVAILABLE,
                    "Embedding service could not be reached", true, ex);
        }
        return parseQueryVector(raw);
    }

    private QueryVector parseQueryVector(String raw) {
        JsonNode root;
        try {
            root = MAPPER.readTree(raw);
        } catch (Exception ex) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "Embedding service returned malformed JSON", false, ex);
        }
        if (!root.isObject() || !root.has("ok") || !root.get("ok").isBoolean()) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "Embedding service returned a malformed result", false);
        }
        if (!root.get("ok").asBoolean()) {
            return QueryVector.refused(textOrNull(root, "reason"));
        }
        if (!EXPECTED_MODEL_ID.equals(textOrNull(root, "model_id"))
                || !EXPECTED_MODEL_REVISION.equals(textOrNull(root, "model_revision"))) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "Query embedding used an unexpected model", false);
        }
        JsonNode vectorNode = root.get("vector");
        if (vectorNode == null || !vectorNode.isArray()
                || vectorNode.size() != EXPECTED_DIMENSION) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "Query embedding must have exactly 384 dimensions", false);
        }
        double[] vector = new double[EXPECTED_DIMENSION];
        int i = 0;
        for (JsonNode value : vectorNode) {
            if (!value.isNumber()) {
                throw new PdfExtractionException(PdfExtractionException.INVALID,
                        "Query embedding must be numeric", false);
            }
            double number = value.asDouble();
            if (!Double.isFinite(number)) {
                throw new PdfExtractionException(PdfExtractionException.INVALID,
                        "Query embedding must be finite", false);
            }
            vector[i++] = number;
        }
        double norm = 0.0;
        for (double value : vector) {
            norm += value * value;
        }
        if (Math.abs(Math.sqrt(norm) - 1.0) > 1e-3) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "Query embedding is not unit-normalized", false);
        }
        return new QueryVector(true, "", vector);
    }

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

    private PdfExtractionException classifyStatus(RestClientResponseException ex) {
        int value = ex.getStatusCode().value();
        log.info("Extraction call failed with HTTP {}", value);
        if (value == 401) {
            return new PdfExtractionException(PdfExtractionException.MISCONFIGURED,
                    "Extraction service rejected credentials", false, ex);
        }
        if (value == 413) {
            return new PdfExtractionException(PdfExtractionException.TOO_LARGE,
                    "Extraction service rejected oversized input", false, ex);
        }
        return new PdfExtractionException(PdfExtractionException.UNAVAILABLE,
                "Extraction service unavailable (HTTP " + value + ")", true, ex);
    }

    private Extraction parse(String raw) {
        JsonNode root;
        try {
            root = MAPPER.readTree(raw);
        } catch (Exception ex) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "Extraction service returned malformed JSON", false, ex);
        }
        if (!root.isObject() || !root.has("ok") || !root.get("ok").isBoolean()) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "Extraction service returned a malformed result", false);
        }
        if (!root.get("ok").asBoolean()) {
            return Extraction.refused(textOrNull(root, "reason"), codes(root));
        }
        JsonNode pagesNode = root.get("pages");
        if (pagesNode == null || !pagesNode.isArray() || pagesNode.isEmpty()) {
            throw new PdfExtractionException(PdfExtractionException.INVALID,
                    "Successful extraction carries no pages", false);
        }
        List<ExtractionPage> pages = new ArrayList<>();
        int expectedNo = 1;
        for (JsonNode node : pagesNode) {
            int pageNo = node.has("page_no") && node.get("page_no").isInt()
                    ? node.get("page_no").asInt() : -1;
            if (pageNo != expectedNo) {
                throw new PdfExtractionException(PdfExtractionException.INVALID,
                        "Extraction pages are not sequentially numbered", false);
            }
            JsonNode textNode = node.get("text");
            if (textNode == null || !textNode.isTextual()) {
                throw new PdfExtractionException(PdfExtractionException.INVALID,
                        "Extraction page carries no text", false);
            }
            pages.add(new ExtractionPage(pageNo, textNode.asText()));
            expectedNo++;
        }
        return new Extraction(true, "", codes(root), pages.size(), List.copyOf(pages));
    }

    private static List<String> codes(JsonNode root) {
        JsonNode codes = root.get("reason_codes");
        List<String> result = new ArrayList<>();
        if (codes != null && codes.isArray()) {
            for (JsonNode code : codes) {
                if (code.isTextual() && !code.asText().isBlank()) {
                    result.add(code.asText());
                }
            }
        }
        return result;
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
