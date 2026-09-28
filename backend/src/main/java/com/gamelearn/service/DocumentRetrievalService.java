package com.gamelearn.service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.regex.Pattern;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamelearn.ai.documents.PdfExtractionClient;
import com.gamelearn.ai.documents.PdfExtractionException;
import com.gamelearn.ai.documents.QdrantClient;
import com.gamelearn.ai.documents.QdrantException;
import com.gamelearn.config.AiProperties;
import com.gamelearn.entity.UserDocument;
import com.gamelearn.entity.enums.DocumentStatus;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.logging.RequestCorrelationFilter;
import com.gamelearn.repository.UserDocumentRepository;

/**
 * USER-DOC RAG Phase G: owner-scoped semantic retrieval over
 * {@code user_doc_chunks} (retrieval ONLY — no Gemini, no answers).
 *
 * <p>Pipeline: server-resolved owner → query validation → pinned-model
 * query vector → Qdrant cosine search with a MANDATORY owner clause
 * (AND-combined document/version scope) → deterministic ordering →
 * artifact text resolution with six-field integrity cross-check →
 * evidence list. Qdrant is the vector index, never the ownership
 * authority: document authorization comes from MySQL first, and a
 * foreign/missing/inactive document behaves exactly like a missing one
 * (404, no existence leak).</p>
 *
 * <p>Failure semantics are explicit and never collapsed: valid-empty
 * returns an empty list; unauthorized scope is 404; embedding, Qdrant
 * and integrity faults are 500-class errors (an outage is never
 * reported as "no results"). Logs carry ids/counts/timings only —
 * never query text, chunk text, vectors or secrets.</p>
 */
@Service
public class DocumentRetrievalService {

    private static final Logger log = LoggerFactory.getLogger(DocumentRetrievalService.class);
    private static final ObjectMapper MAPPER = new ObjectMapper();
    private static final Pattern CONTROL_CHARS = Pattern.compile("\\p{Cntrl}");

    /** One grounded evidence candidate for later orchestration. */
    public record RetrievedChunk(String chunkId, UUID documentId, int docVersion, int pageNo,
                                 String citation, double score, String textHash, String text) {
    }

    private final UserDocumentRepository documentRepository;
    private final DocumentStorageService storageService;
    private final PdfExtractionClient extractionClient;
    private final QdrantClient qdrant;
    private final AiProperties properties;

    public DocumentRetrievalService(UserDocumentRepository documentRepository,
                                    DocumentStorageService storageService,
                                    PdfExtractionClient extractionClient,
                                    QdrantClient qdrant,
                                    AiProperties properties) {
        this.documentRepository = documentRepository;
        this.storageService = storageService;
        this.extractionClient = extractionClient;
        this.qdrant = qdrant;
        this.properties = properties;
    }

    /**
     * Retrieves evidence candidates for the authenticated owner.
     *
     * @param authenticatedUserId server-resolved principal id (never client input)
     * @param query raw query text (validated + bounded here)
     * @param documentId optional authorized document scope (null = all owned indexed docs)
     * @param docVersion optional authorized version scope (null = each doc's current version)
     * @param topKOrNull requested limit (null = configured default, hard max enforced)
     * @return deterministically ordered candidates; empty = valid but no authorized results
     */
    public List<RetrievedChunk> retrieve(UUID authenticatedUserId, String query,
                                         UUID documentIdOrNull, Integer docVersionOrNull,
                                         Integer topKOrNull) {
        long startedAt = System.currentTimeMillis();
        if (authenticatedUserId == null) {
            throw new ApiException(ErrorCode.UNAUTHORIZED.getHttpStatus(),
                    ErrorCode.UNAUTHORIZED.name(), "Authentication required");
        }
        String cleanQuery = validateQuery(query);
        int topK = resolveTopK(topKOrNull);
        double minScore = resolveMinScore();
        Map<UUID, ScopedDoc> scope = resolveScope(
                authenticatedUserId, documentIdOrNull, docVersionOrNull);
        if (scope.isEmpty()) {
            return List.of();
        }

        long embedStarted = System.currentTimeMillis();
        double[] queryVector;
        try {
            PdfExtractionClient.QueryVector embedded = extractionClient.embedQuery(
                    RequestCorrelationFilter.currentRequestId(), cleanQuery);
            if (!embedded.ok()) {
                throw new PdfExtractionException(PdfExtractionException.INVALID,
                        "Query embedding refused", false);
            }
            queryVector = embedded.vector();
        } catch (PdfExtractionException ex) {
            throw internal("Document search is temporarily unavailable", ex);
        }
        long embedMs = System.currentTimeMillis() - embedStarted;

        List<Map<String, Object>> filter = buildFilter(
                authenticatedUserId.toString(), scope.values());
        long searchStarted = System.currentTimeMillis();
        List<QdrantClient.SearchHit> hits;
        try {
            hits = qdrant.searchPoints(queryVector, filter, topK,
                    minScore > 0.0 ? minScore : null);
        } catch (QdrantException ex) {
            throw internal("Document search is temporarily unavailable", ex);
        }
        long searchMs = System.currentTimeMillis() - searchStarted;

        List<ScoredHit> ranked = new ArrayList<>(hits.size());
        for (QdrantClient.SearchHit hit : hits) {
            if (minScore > 0.0 && hit.score() < minScore) {
                continue;
            }
            ranked.add(new ScoredHit(hit, hit.score()));
        }
        ranked.sort(Comparator.comparingDouble(ScoredHit::score).reversed()
                .thenComparing(hit -> hit.hit().id().toString()));
        List<ScoredHit> limited = ranked.subList(0, Math.min(topK, ranked.size()));

        long resolveStarted = System.currentTimeMillis();
        List<RetrievedChunk> evidence = new ArrayList<>(limited.size());
        for (ScoredHit scored : limited) {
            evidence.add(resolveChunk(authenticatedUserId, scope, scored.hit()));
        }
        long resolveMs = System.currentTimeMillis() - resolveStarted;
        log.info("DOC_RETRIEVE_OK chunks={} embedMs={} searchMs={} resolveMs={} totalMs={}",
                evidence.size(), embedMs, searchMs, resolveMs,
                System.currentTimeMillis() - startedAt);
        return List.copyOf(evidence);
    }

    // ------------------------------------------------------------------
    // scope (MySQL is the ownership authority, never Qdrant)
    // ------------------------------------------------------------------

    private record ScopedDoc(UUID documentId, int docVersion) {
    }

    private record ScoredHit(QdrantClient.SearchHit hit, double score) {
    }

    /**
     * Phase H: the authorized (document, version) scope for a retrieval
     * request, derived EXACTLY like {@link #retrieve} derives it (same
     * MySQL authority, same INDEXED gating, same 404/400 semantics), so a
     * downstream grounding layer can verify evidence against the identical
     * scope without duplicating authorization logic.
     */
    public Map<UUID, Integer> authorizedScope(UUID authenticatedUserId, UUID documentIdOrNull,
                                              Integer docVersionOrNull) {
        if (authenticatedUserId == null) {
            throw new ApiException(ErrorCode.UNAUTHORIZED.getHttpStatus(),
                    ErrorCode.UNAUTHORIZED.name(), "Authentication required");
        }
        Map<UUID, Integer> scope = new LinkedHashMap<>();
        resolveScope(authenticatedUserId, documentIdOrNull, docVersionOrNull)
                .forEach((id, scoped) -> scope.put(id, scoped.docVersion()));
        return scope;
    }

    private Map<UUID, ScopedDoc> resolveScope(UUID authenticatedUserId, UUID documentIdOrNull,
                                              Integer docVersionOrNull) {
        if (docVersionOrNull != null && docVersionOrNull < 1) {
            throw validationFailure("docVersion", "docVersion must be >= 1");
        }
        Map<UUID, ScopedDoc> scope = new LinkedHashMap<>();
        if (documentIdOrNull != null) {
            UserDocument row = documentRepository
                    .findByIdAndUserIdAndActiveTrue(documentIdOrNull, authenticatedUserId)
                    .orElseThrow(() -> notFound());
            int version = docVersionOrNull != null ? docVersionOrNull : row.getDocVersion();
            if (docVersionOrNull != null && docVersionOrNull != row.getDocVersion()) {
                throw notFound();
            }
            if (row.getStatus() != DocumentStatus.INDEXED) {
                return Map.of();
            }
            scope.put(row.getId(), new ScopedDoc(row.getId(), version));
            return scope;
        }
        for (UserDocument row : documentRepository
                .findAllByUserIdAndActiveTrueOrderByCreatedAtDesc(authenticatedUserId)) {
            if (row.getStatus() == DocumentStatus.INDEXED) {
                scope.put(row.getId(), new ScopedDoc(row.getId(), row.getDocVersion()));
            }
        }
        return scope;
    }

    private static List<Map<String, Object>> buildFilter(
            String ownerId, java.util.Collection<ScopedDoc> docs) {
        List<Map<String, Object>> docGroups = new ArrayList<>(docs.size());
        for (ScopedDoc doc : docs) {
            docGroups.add(Map.of("must", List.of(
                    QdrantClient.documentClause(doc.documentId().toString()),
                    QdrantClient.versionClause(doc.docVersion()))));
        }
        if (docGroups.size() == 1) {
            List<Map<String, Object>> must = new ArrayList<>(3);
            must.add(QdrantClient.ownerClause(ownerId));
            must.addAll((List<Map<String, Object>>) (List<?>) docGroups.get(0).get("must"));
            return must;
        }
        return List.of(QdrantClient.ownerClause(ownerId),
                Map.of("min_should", Map.of("conditions", docGroups, "min_count", 1)));
    }

    // ------------------------------------------------------------------
    // evidence resolution + integrity (artifacts are authoritative)
    // ------------------------------------------------------------------

    private RetrievedChunk resolveChunk(UUID authenticatedUserId, Map<UUID, ScopedDoc> scope,
                                        QdrantClient.SearchHit hit) {
        JsonNode payload = hit.payload();
        String chunkId = requiredPayloadText(payload, "chunk_id");
        String payloadDocId = requiredPayloadText(payload, "document_id");
        JsonNode versionNode = payload.get("doc_version");
        if (versionNode == null || !versionNode.isInt()) {
            throw integrityFailure("payload carries no doc_version");
        }
        UUID payloadDocUuid;
        try {
            payloadDocUuid = UUID.fromString(payloadDocId);
        } catch (IllegalArgumentException ex) {
            throw integrityFailure("payload carries a malformed document id");
        }
        ScopedDoc scoped = scope.get(payloadDocUuid);
        if (scoped == null || scoped.docVersion() != versionNode.asInt()) {
            throw integrityFailure("hit is outside the authorized scope");
        }
        JsonNode chunksRoot = parseChunksArtifact(payloadDocUuid);
        JsonNode record = null;
        for (JsonNode node : chunksRoot.withArray("chunks")) {
            if (chunkId.equals(node.path("chunk_id").asText(null))) {
                record = node;
                break;
            }
        }
        if (record == null) {
            throw integrityFailure("chunk id is unknown to the artifact");
        }
        int pageNo = record.path("page_no").asInt(-1);
        String citation = record.path("citation").asText(null);
        String textHash = record.path("text_hash").asText(null);
        String text = record.path("text").asText(null);
        if (pageNo < 1 || citation == null || citation.isBlank()
                || textHash == null || textHash.isBlank()
                || text == null || text.isBlank()) {
            throw integrityFailure("artifact chunk record is incomplete");
        }
        // The hash is recomputed over the resolved text: a tampered text
        // with a copied-over hash field must still fail closed.
        if (!textHash.equalsIgnoreCase(sha256Hex(text))) {
            throw integrityFailure("artifact text hash mismatch");
        }
        if (!String.valueOf(pageNo).equals(payload.path("page_no").asText(null))
                || !citation.equals(payload.path("citation").asText(null))
                || !textHash.equals(payload.path("text_hash").asText(null))) {
            throw integrityFailure("artifact and index metadata disagree");
        }
        if (!authenticatedUserId.toString().equals(payload.path("owner_id").asText(null))) {
            throw integrityFailure("hit owner does not match the caller");
        }
        return new RetrievedChunk(chunkId, payloadDocUuid, scoped.docVersion(), pageNo,
                citation, hit.score(), textHash, text);
    }

    private JsonNode parseChunksArtifact(UUID documentId) {
        String raw;
        try {
            raw = storageService.readArtifact(documentId,
                    DocumentStorageService.CHUNKS_FILENAME);
        } catch (ApiException ex) {
            throw integrityFailure("chunk artifact is missing");
        }
        try {
            JsonNode root = MAPPER.readTree(raw);
            if (root == null || !root.isObject() || !root.path("chunks").isArray()) {
                throw new IllegalArgumentException("not a chunks artifact");
            }
            return root;
        } catch (Exception ex) {
            throw integrityFailure("chunk artifact is malformed");
        }
    }

    // ------------------------------------------------------------------
    // input validation
    // ------------------------------------------------------------------

    private String validateQuery(String query) {
        if (query == null || query.isBlank()) {
            throw validationFailure("query", "query is required");
        }
        String clean = query.strip();
        if (clean.length() > properties.getDocuments().getRetrievalMaxQueryChars()) {
            throw validationFailure("query", "query exceeds the maximum allowed length");
        }
        if (CONTROL_CHARS.matcher(clean).find()) {
            throw validationFailure("query", "query contains unsupported characters");
        }
        return clean;
    }

    private int resolveTopK(Integer topKOrNull) {
        int max = properties.getDocuments().getRetrievalTopKMax();
        int fallback = properties.getDocuments().getRetrievalTopKDefault();
        if (topKOrNull == null) {
            return Math.min(Math.max(fallback, 1), Math.max(max, 1));
        }
        if (topKOrNull < 1 || topKOrNull > max) {
            throw validationFailure("topK", "topK must be within 1.." + max);
        }
        return topKOrNull;
    }

    private double resolveMinScore() {
        double minScore = properties.getDocuments().getRetrievalMinScore();
        if (Double.isNaN(minScore) || minScore < -1.0 || minScore > 1.0) {
            throw new ApiException(ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                    ErrorCode.INTERNAL_ERROR.name(),
                    "Document search is misconfigured");
        }
        return minScore;
    }

    private static String sha256Hex(String text) {
        try {
            byte[] digest = java.security.MessageDigest.getInstance("SHA-256")
                    .digest(text.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder(digest.length * 2);
            for (byte b : digest) {
                hex.append(Character.forDigit((b >> 4) & 0xF, 16));
                hex.append(Character.forDigit(b & 0xF, 16));
            }
            return hex.toString();
        } catch (java.security.NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 unavailable", ex);
        }
    }

    private static String requiredPayloadText(JsonNode payload, String field) {
        JsonNode child = payload.get(field);
        if (child == null || !child.isTextual() || child.asText().isBlank()) {
            throw integrityFailure("payload is missing " + field);
        }
        return child.asText();
    }

    private static ApiException integrityFailure(String reason) {
        // Never details: reasons stay operator-safe (no ids, no content).
        log.warn("DOC_RETRIEVE_INTEGRITY reason={}", reason);
        return new ApiException(ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                ErrorCode.INTERNAL_ERROR.name(),
                "Document search encountered inconsistent data");
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

    private ApiException internal(String message, Throwable cause) {
        log.warn("Document search fault: {}", cause.toString());
        return new ApiException(ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                ErrorCode.INTERNAL_ERROR.name(), message);
    }
}
