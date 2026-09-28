package com.gamelearn.service;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamelearn.ai.documents.PdfExtractionClient;
import com.gamelearn.ai.documents.QdrantClient;
import com.gamelearn.ai.documents.QdrantException;
import com.gamelearn.entity.UserDocument;
import com.gamelearn.entity.enums.DocumentStatus;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.repository.UserDocumentRepository;

/**
 * USER-DOC RAG Phase F: persistent Qdrant vector index for user documents.
 *
 * <p>Design (no ACID across MySQL + Qdrant — explicit sequencing instead):</p>
 * <ol>
 *   <li>validate metadata (owner-scoped row, CHUNKED or INDEXED for reindex)</li>
 *   <li>validate chunks.json + embeddings.json + cross-artifact binding</li>
 *   <li>verify Qdrant collection (384/Cosine + payload indexes; incompatible
 *   collections fail closed, never auto-migrated)</li>
 *   <li>upsert the complete version set in ONE batch ({@code wait=true})</li>
 *   <li>delete stale points of the exact owner/document/version</li>
 *   <li>verify the Qdrant count invariant (== N), else compensate + FAILED</li>
 *   <li>only then persist {@code INDEXED}</li>
 * </ol>
 *
 * <p>Ownership is the server-authenticated id throughout: point payloads
 * carry {@code owner_id}, every Qdrant filter includes it, and future
 * retrieval MUST filter on it (an ownerless user-document read is a
 * boundary violation). Qdrant holds vectors + retrieval metadata only —
 * MySQL stays authoritative for users, ownership, lifecycle and learner
 * state. No retrieval/ranking/Gemini vagy Flutter surface exists here.</p>
 *
 * <p>Split-brain rule: if the MySQL transition fails AFTER Qdrant
 * confirmed the full set, the error propagates WITHOUT marking FAILED
 * and WITHOUT deleting vectors — the Qdrant side is already exactly
 * right, so a retry converges (idempotent upsert + verify + transition).
 * All earlier failures compensate (version points removed) and mark
 * FAILED, so FAILED always means "no points for this version".</p>
 */
@Service
public class DocumentIndexService {

    private static final Logger log = LoggerFactory.getLogger(DocumentIndexService.class);
    private static final ObjectMapper MAPPER = new ObjectMapper();

    static final String EXPECTED_MODEL_ID = "sentence-transformers/all-MiniLM-L6-v2";
    static final String EXPECTED_MODEL_REVISION = "1110a243fdf4706b3f48f1d95db1a4f5529b4d41";
    static final String EXPECTED_CHUNK_CONFIG_VERSION = "udoc-chunk-v1";
    static final double NORM_TOLERANCE = 1e-3;

    /** Exact payload keys — nothing else may enter Qdrant. */
    static final Set<String> PAYLOAD_KEYS = Set.of(
            "owner_id", "document_id", "doc_version", "chunk_id", "page_no",
            "citation", "chunk_config_version", "text_hash",
            "embedding_fingerprint", "embedding_model_revision");

    /** Indexing outcome (counts/timings only — never vectors or text). */
    public record IndexResult(UUID documentId, int docVersion, int pointCount,
                              long upsertMs, long verifyMs, boolean reindexed) {
    }

    private final UserDocumentService documentService;
    private final UserDocumentRepository documentRepository;
    private final DocumentStorageService storageService;
    private final QdrantClient qdrant;

    public DocumentIndexService(UserDocumentService documentService,
                                UserDocumentRepository documentRepository,
                                DocumentStorageService storageService,
                                QdrantClient qdrant) {
        this.documentService = documentService;
        this.documentRepository = documentRepository;
        this.storageService = storageService;
        this.qdrant = qdrant;
    }

    /**
     * Indexes one owned document version (idempotent). Returns the verified
     * outcome; the row ends {@code INDEXED}. Any failure before the final
     * transition compensates (version points removed) and marks FAILED —
     * partial success is never reported as INDEXED.
     */
    public IndexResult index(UUID authenticatedUserId, UUID documentId) {
        long startedAt = System.currentTimeMillis();
        UserDocument row = documentRepository.findByIdAndUserId(documentId, authenticatedUserId)
                .orElseThrow(() -> notFound());
        if (!row.isActive()) {
            throw notFound();
        }
        if (row.getStatus() != DocumentStatus.CHUNKED
                && row.getStatus() != DocumentStatus.INDEXED) {
            throw validationFailure("status", "document is not ready for indexing");
        }
        boolean reindexed = row.getStatus() == DocumentStatus.INDEXED;
        int docVersion = row.getDocVersion();
        String ownerId = authenticatedUserId.toString();

        ValidatedArtifacts artifacts;
        try {
            artifacts = validateArtifacts(authenticatedUserId, row);
        } catch (ApiException validation) {
            throw failed(authenticatedUserId, documentId, docVersion, validation);
        }

        try {
            qdrant.ensureCollection();
        } catch (QdrantException ex) {
            throw failed(authenticatedUserId, documentId, docVersion, mapQdrant(ex));
        }

        long upsertMs;
        long verifyMs;
        try {
            long upsertStarted = System.currentTimeMillis();
            List<QdrantClient.QdrantPoint> points =
                    buildPoints(ownerId, documentId.toString(), docVersion, artifacts);
            qdrant.upsertPoints(points);
            upsertMs = System.currentTimeMillis() - upsertStarted;
            long verifyStarted = System.currentTimeMillis();
            removeStalePoints(ownerId, documentId.toString(), docVersion,
                    points.stream().map(QdrantClient.QdrantPoint::id).toList());
            long count = qdrant.countPoints(versionFilter(ownerId,
                    documentId.toString(), docVersion));
            verifyMs = System.currentTimeMillis() - verifyStarted;
            if (count != points.size()) {
                throw new QdrantException(QdrantException.INVALID,
                        "Vector store count does not match the indexed set", false);
            }
        } catch (QdrantException | ApiException ex) {
            throw failed(authenticatedUserId, documentId, docVersion,
                    ex instanceof ApiException api ? api : mapQdrant((QdrantException) ex));
        }

        try {
            if (!reindexed) {
                documentService.transitionStatus(authenticatedUserId, documentId,
                        DocumentStatus.INDEXED);
            }
        } catch (ApiException transitionFailure) {
            // Qdrant already holds exactly the right set: propagate WITHOUT
            // marking FAILED and WITHOUT deleting — retry converges.
            log.warn("DOC_INDEX_STATE_PENDING document={} version={}", documentId, docVersion);
            throw transitionFailure;
        }
        log.info("DOC_INDEX_OK points={} version={} upsertMs={} verifyMs={} totalMs={} reindexed={}",
                artifacts.chunkIds().size(), docVersion, upsertMs, verifyMs,
                System.currentTimeMillis() - startedAt, reindexed);
        return new IndexResult(documentId, docVersion, artifacts.chunkIds().size(),
                upsertMs, verifyMs, reindexed);
    }

    /**
     * Service-level delete of one owned document version's vectors.
     * The predicate always includes owner + document + version; ambiguous
     * deletes are refused. No lifecycle change. Verifies the points are
     * gone; unrelated points are never touched (same-filter scoping).
     */
    public long deleteDocumentVectors(UUID authenticatedUserId, UUID documentId,
                                      int docVersion) {
        if (docVersion < 1) {
            throw validationFailure("docVersion", "docVersion must be >= 1");
        }
        UserDocument row = documentRepository.findByIdAndUserId(documentId, authenticatedUserId)
                .orElseThrow(() -> notFound());
        if (docVersion != row.getDocVersion()) {
            throw validationFailure("docVersion",
                    "docVersion does not match the document version");
        }
        List<Map<String, Object>> filter = versionFilter(
                authenticatedUserId.toString(), documentId.toString(), docVersion);
        long before;
        try {
            before = qdrant.countPoints(filter);
            qdrant.deleteByFilter(filter);
            long after = qdrant.countPoints(filter);
            if (after != 0) {
                throw new QdrantException(QdrantException.INVALID,
                        "Vector store did not confirm deletion", false);
            }
        } catch (QdrantException ex) {
            throw mapQdrant(ex);
        }
        log.info("DOC_VECTORS_DELETED points={} version={}", before, docVersion);
        return before;
    }

    // ------------------------------------------------------------------
    // artifact validation (all pre-upsert, no Qdrant writes)
    // ------------------------------------------------------------------

    private record ValidatedArtifacts(List<String> chunkIds, List<double[]> vectors,
                                      Map<String, ChunkMeta> metaByChunkId,
                                      String embeddingFingerprint) {
    }

    private record ChunkMeta(int pageNo, String citation, String textHash) {
    }

    private ValidatedArtifacts validateArtifacts(UUID authenticatedUserId, UserDocument row) {
        String ownerId = authenticatedUserId.toString();
        String docId = row.getId().toString();
        JsonNode chunksRoot = parseArtifact(row.getId(), DocumentStorageService.CHUNKS_FILENAME);
        JsonNode embeddingsRoot =
                parseArtifact(row.getId(), DocumentStorageService.EMBEDDINGS_FILENAME);

        requireText(chunksRoot, "document_id", docId, "chunks");
        requireVersion(chunksRoot, row.getDocVersion(), "chunks");
        requireText(chunksRoot, "chunk_config_version", EXPECTED_CHUNK_CONFIG_VERSION, "chunks");
        requireText(embeddingsRoot, "document_id", docId, "embeddings");
        requireVersion(embeddingsRoot, row.getDocVersion(), "embeddings");
        requireText(embeddingsRoot, "chunk_config_version", EXPECTED_CHUNK_CONFIG_VERSION,
                "embeddings");
        requireText(embeddingsRoot, "model_id", EXPECTED_MODEL_ID, "embeddings");
        requireText(embeddingsRoot, "model_revision", EXPECTED_MODEL_REVISION, "embeddings");

        JsonNode chunksNode = chunksRoot.get("chunks");
        JsonNode vectorsNode = embeddingsRoot.get("embeddings");
        if (chunksNode == null || !chunksNode.isArray() || chunksNode.isEmpty()
                || vectorsNode == null || !vectorsNode.isArray() || vectorsNode.isEmpty()) {
            throw validationFailure("file", "document artifacts carry no chunks");
        }

        Map<String, ChunkMeta> metaByChunkId = new LinkedHashMap<>();
        List<String> chunkIds = new ArrayList<>();
        for (JsonNode node : chunksNode) {
            String chunkId = requiredField(node, "chunk_id");
            String citation = requiredField(node, "citation");
            String textHash = requiredField(node, "text_hash");
            JsonNode pageNode = node.get("page_no");
            JsonNode ownerNode = node.get("owner_id");
            if (pageNode == null || !pageNode.isInt() || pageNode.asInt() < 1
                    || ownerNode == null || !ownerNode.isTextual()
                    || !ownerId.equals(ownerNode.asText())) {
                throw validationFailure("file", "chunk carries invalid page or owner");
            }
            if (!metaByChunkId.containsKey(chunkId)) {
                metaByChunkId.put(chunkId, new ChunkMeta(pageNode.asInt(), citation, textHash));
                chunkIds.add(chunkId);
            } else {
                throw validationFailure("file", "duplicate chunk id in artifact");
            }
        }

        List<double[]> vectors = new ArrayList<>();
        List<String> embeddingIds = new ArrayList<>();
        for (JsonNode node : vectorsNode) {
            String chunkId = requiredField(node, "chunk_id");
            JsonNode vectorNode = node.get("vector");
            if (vectorNode == null || !vectorNode.isArray()
                    || vectorNode.size() != QdrantClient.VECTOR_SIZE) {
                throw validationFailure("file", "embedding vector must have 384 dimensions");
            }
            double[] vector = new double[QdrantClient.VECTOR_SIZE];
            int i = 0;
            for (JsonNode value : vectorNode) {
                if (!value.isNumber()) {
                    throw validationFailure("file", "embedding vector must be numeric");
                }
                double number = value.asDouble();
                if (!Double.isFinite(number)) {
                    throw validationFailure("file", "embedding vector must be finite");
                }
                vector[i++] = number;
            }
            double norm = 0.0;
            for (double value : vector) {
                norm += value * value;
            }
            if (Math.abs(Math.sqrt(norm) - 1.0) > NORM_TOLERANCE) {
                throw validationFailure("file", "embedding vector is not unit-normalized");
            }
            embeddingIds.add(chunkId);
            vectors.add(vector);
        }
        if (!embeddingIds.equals(chunkIds)) {
            throw validationFailure("file",
                    "embedding chunk ids do not match chunk records");
        }

        String fingerprint = textOrNull(embeddingsRoot, "embedding_fingerprint");
        List<PdfExtractionClient.EmbeddedChunk> check = new ArrayList<>(vectors.size());
        for (int i = 0; i < embeddingIds.size(); i++) {
            check.add(new PdfExtractionClient.EmbeddedChunk(embeddingIds.get(i), vectors.get(i)));
        }
        if (fingerprint == null || fingerprint.isBlank()
                || !fingerprint.equalsIgnoreCase(PdfExtractionClient.fingerprintHex(check))) {
            throw validationFailure("file", "embedding fingerprint mismatch");
        }
        return new ValidatedArtifacts(List.copyOf(chunkIds), List.copyOf(vectors),
                Map.copyOf(metaByChunkId), fingerprint);
    }

    private JsonNode parseArtifact(UUID documentId, String filename) {
        String raw;
        try {
            raw = storageService.readArtifact(documentId, filename);
        } catch (ApiException ex) {
            throw validationFailure("file", "document artifact is missing: " + filename);
        }
        try {
            JsonNode root = MAPPER.readTree(raw);
            if (root == null || !root.isObject()) {
                throw new IllegalArgumentException("not an object");
            }
            return root;
        } catch (Exception ex) {
            throw validationFailure("file", "document artifact is malformed: " + filename);
        }
    }

    // ------------------------------------------------------------------
    // upsert + verification
    // ------------------------------------------------------------------

    private List<QdrantClient.QdrantPoint> buildPoints(String ownerId, String documentId,
                                                       int docVersion,
                                                       ValidatedArtifacts artifacts) {
        List<QdrantClient.QdrantPoint> points = new ArrayList<>(artifacts.chunkIds().size());
        Set<UUID> seen = new LinkedHashSet<>();
        for (int i = 0; i < artifacts.chunkIds().size(); i++) {
            String chunkId = artifacts.chunkIds().get(i);
            UUID pointId = UUID.nameUUIDFromBytes(chunkId.getBytes(StandardCharsets.UTF_8));
            if (!seen.add(pointId)) {
                throw validationFailure("file", "duplicate point id derived from chunks");
            }
            ChunkMeta meta = artifacts.metaByChunkId().get(chunkId);
            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("owner_id", ownerId);
            payload.put("document_id", documentId);
            payload.put("doc_version", docVersion);
            payload.put("chunk_id", chunkId);
            payload.put("page_no", meta.pageNo());
            payload.put("citation", meta.citation());
            payload.put("chunk_config_version", EXPECTED_CHUNK_CONFIG_VERSION);
            payload.put("text_hash", meta.textHash());
            payload.put("embedding_fingerprint", artifacts.embeddingFingerprint());
            payload.put("embedding_model_revision", EXPECTED_MODEL_REVISION);
            if (!payload.keySet().equals(PAYLOAD_KEYS)) {
                throw new IllegalStateException("payload schema drift");
            }
            points.add(new QdrantClient.QdrantPoint(pointId, artifacts.vectors().get(i),
                    Map.copyOf(payload)));
        }
        return points;
    }

    private void removeStalePoints(String ownerId, String documentId, int docVersion,
                                   List<UUID> currentIds) {
        List<Map<String, Object>> filter = versionFilter(ownerId, documentId, docVersion);
        Set<UUID> current = new LinkedHashSet<>(currentIds);
        List<UUID> stale = new ArrayList<>();
        for (UUID id : qdrant.scrollPointIds(filter)) {
            if (!current.contains(id)) {
                stale.add(id);
            }
        }
        if (!stale.isEmpty()) {
            qdrant.deleteByIds(stale);
            log.info("DOC_INDEX_STALE_REMOVED points={} version={}", stale.size(), docVersion);
        }
    }

    private static List<Map<String, Object>> versionFilter(String ownerId, String documentId,
                                                           int docVersion) {
        return List.of(QdrantClient.ownerClause(ownerId),
                QdrantClient.documentClause(documentId),
                QdrantClient.versionClause(docVersion));
    }

    // ------------------------------------------------------------------
    // failure mapping + compensation
    // ------------------------------------------------------------------

    private ApiException failed(UUID authenticatedUserId, UUID documentId, int docVersion,
                                ApiException error) {
        try {
            documentService.transitionStatus(authenticatedUserId, documentId,
                    com.gamelearn.entity.enums.DocumentStatus.FAILED);
        } catch (RuntimeException ignored) {
            // Status write is best-effort on the failure path.
        }
        try {
            qdrant.deleteByFilter(versionFilter(authenticatedUserId.toString(),
                    documentId.toString(), docVersion));
        } catch (RuntimeException ignored) {
            // Compensation is best-effort; retry converges (same version
            // points are overwritten, strays are removed, count verified).
        }
        log.info("DOC_INDEX_FAILED reason={} version={}",
                error.getErrorCode(), docVersion);
        return error;
    }

    private ApiException mapQdrant(QdrantException ex) {
        return switch (ex.getCategory()) {
            case QdrantException.MISCONFIGURED -> new ApiException(
                    ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                    ErrorCode.INTERNAL_ERROR.name(),
                    "Vector store configuration mismatch");
            default -> new ApiException(ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                    ErrorCode.INTERNAL_ERROR.name(),
                    "Document indexing is temporarily unavailable");
        };
    }

    private static ApiException notFound() {
        return new ApiException(ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                ErrorCode.RESOURCE_NOT_FOUND.name(), "Document not found");
    }

    private static ApiException validationFailure(String field, String message) {
        return new ApiException(ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                ErrorCode.VALIDATION_FAILED.name(), "Request validation failed",
                Map.of(field, message));
    }

    private static String textOrNull(JsonNode node, String field) {
        JsonNode child = node.get(field);
        if (child == null || child.isNull() || !child.isTextual()) {
            return null;
        }
        String value = child.asText();
        return value.isBlank() ? null : value;
    }

    private static String requiredField(JsonNode node, String field) {
        String value = textOrNull(node, field);
        if (value == null || value.isBlank()) {
            throw validationFailure("file", "chunk is missing required field: " + field);
        }
        return value;
    }

    private static void requireText(JsonNode root, String field, String expected,
                                    String artifact) {
        if (!expected.equals(textOrNull(root, field))) {
            throw validationFailure("file",
                    "artifact binding mismatch in " + artifact + ": " + field);
        }
    }

    private static void requireVersion(JsonNode root, int expected, String artifact) {
        JsonNode node = root.get("doc_version");
        if (node == null || !node.isInt() || node.asInt() != expected) {
            throw validationFailure("file",
                    "artifact binding mismatch in " + artifact + ": doc_version");
        }
    }
}
