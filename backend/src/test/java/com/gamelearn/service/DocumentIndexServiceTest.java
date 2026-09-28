package com.gamelearn.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Map;
import java.util.HexFormat;
import java.util.List;
import java.util.UUID;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.gamelearn.ai.documents.QdrantClient;
import com.gamelearn.entity.User;
import com.gamelearn.entity.UserDocument;
import com.gamelearn.entity.enums.DocumentStatus;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.persistence.PersistenceTestFixtures;
import com.gamelearn.repository.UserDocumentRepository;
import com.gamelearn.repository.UserRepository;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;

/**
 * USER-DOC RAG Phase F: persistent Qdrant index over real local Qdrant.
 *
 * <p>Nothing here is mocked at the Qdrant boundary: collection lifecycle,
 * upserts, counts, scrolls, deletes and restarts all hit the real
 * localhost container from Phase A. Aborts (not fails) when that infra
 * is unreachable. Covers: collection config, payload indexes,
 * deterministic ids, N→N upserts, idempotent reindex + stale cleanup,
 * validation gates, fingerprint/model binding, owner/document/version
 * isolation, cross-user refusal, delete semantics, restart persistence,
 * count invariants, payload minimality, log hygiene and performance.</p>
 */
@SpringBootTest
@ActiveProfiles("test")
class DocumentIndexServiceTest {

    static final ObjectMapper MAPPER = new ObjectMapper();
    static final String QDRANT = "http://127.0.0.1:6333";
    static final String COLLECTION = "user_doc_chunks";
    /** Clean probe token: no secret/injection shape. */
    static final String MARKER = "QdrantProbeF7XK";
    static final boolean QDRANT_UP = probeQdrant();

    static Path storageRoot;

    @Autowired
    private DocumentIndexService indexService;
    @Autowired
    private UserDocumentService documentService;
    @Autowired
    private UserDocumentRepository documentRepository;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private DocumentStorageService storageService;

    // ------------------------------------------------------------------
    // infrastructure helpers (raw REST; test-only, never app code)
    // ------------------------------------------------------------------

    private static boolean probeQdrant() {
        try (java.net.Socket socket = new java.net.Socket()) {
            socket.connect(new InetSocketAddress("127.0.0.1", 6333), 3000);
            return true;
        } catch (IOException unreachable) {
            return false;
        }
    }

    private static final java.net.http.HttpClient HTTP =
            java.net.http.HttpClient.newBuilder()
                    .connectTimeout(Duration.ofSeconds(5)).build();

    private static JsonNode qdrant(String method, String path, String body) throws Exception {
        var builder = java.net.http.HttpRequest.newBuilder()
                .uri(java.net.URI.create(QDRANT + path))
                .timeout(Duration.ofSeconds(15));
        if (method.equals("GET") || method.equals("DELETE")) {
            builder.method(method, java.net.http.HttpRequest.BodyPublishers.noBody());
        } else {
            builder.method(method, java.net.http.HttpRequest.BodyPublishers.ofString(
                    body == null ? "" : body));
            builder.header("Content-Type", "application/json");
        }
        var response = HTTP.send(builder.build(),
                java.net.http.HttpResponse.BodyHandlers.ofString());
        return MAPPER.readTree(response.body());
    }

    private static void deleteCollectionIfExists() throws Exception {
        try {
            qdrant("DELETE", "/collections/" + COLLECTION, null);
        } catch (Exception alreadyGone) {
            // Absent collection is the desired start state either way.
        }
    }

    private static JsonNode collectionConfig() throws Exception {
        return qdrant("GET", "/collections/" + COLLECTION, null).path("result");
    }

    private static long countAll() throws Exception {
        return qdrant("POST", "/collections/" + COLLECTION + "/points/count",
                "{\"exact\":true}").path("result").path("count").asLong();
    }

    private static List<JsonNode> scrollPayloads(String ownerId, String documentId,
                                                 int docVersion) throws Exception {
        ObjectNode filter = MAPPER.createObjectNode();
        ArrayNode must = filter.putObject("filter").putArray("must");
        must.addObject().put("key", "owner_id").putObject("match").put("value", ownerId);
        must.addObject().put("key", "document_id").putObject("match").put("value", documentId);
        must.addObject().put("key", "doc_version").putObject("match").put("value", docVersion);
        ObjectNode body = MAPPER.createObjectNode();
        body.set("filter", filter.get("filter"));
        body.put("limit", 100);
        body.put("with_payload", true);
        body.put("with_vector", true);
        JsonNode result = qdrant("POST",
                "/collections/" + COLLECTION + "/points/scroll", body.toString())
                .path("result").path("points");
        List<JsonNode> out = new ArrayList<>();
        result.forEach(out::add);
        return out;
    }

    @BeforeAll
    static void cleanSlate() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        storageRoot = Files.createTempDirectory("gamelearn-doc-index-test");
        deleteCollectionIfExists();
    }

    @AfterAll
    static void cleanUp() throws Exception {
        if (QDRANT_UP) {
            deleteCollectionIfExists();
        }
    }

    @DynamicPropertySource
    static void docProps(DynamicPropertyRegistry registry) {
        registry.add("gamelearn.ai.documents.storage-root", () -> storageRoot.toString());
    }

    // ------------------------------------------------------------------
    // artifact fixtures (production writers, deterministic vectors)
    // ------------------------------------------------------------------

    private record Fixture(User user, UserDocument row, List<String> chunkIds) {
    }

    private static double[] unitAt(int index) {
        double[] vector = new double[384];
        vector[index % 384] = 1.0;
        return vector;
    }

    private static String sha256Hex(String text) throws Exception {
        return HexFormat.of().formatHex(
                MessageDigest.getInstance("SHA-256").digest(text.getBytes(StandardCharsets.UTF_8)));
    }

    private Fixture setupDoc(String label, List<String> pageTexts) throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user(label));
        UserDocument row = documentService.register(user.getId(), label + ".pdf",
                "application/pdf", 1024);
        documentService.transitionStatus(user.getId(), row.getId(), DocumentStatus.EXTRACTING);
        documentService.setPageCount(user.getId(), row.getId(), pageTexts.size());
        documentService.transitionStatus(user.getId(), row.getId(), DocumentStatus.CHUNKED);

        String docId = row.getId().toString();
        String ownerId = user.getId().toString();
        List<String> chunkIds = new ArrayList<>();
        List<double[]> vectors = new ArrayList<>();
        ObjectNode chunksRoot = MAPPER.createObjectNode();
        chunksRoot.put("document_id", docId);
        chunksRoot.put("doc_version", 1);
        chunksRoot.put("chunk_config_version", "udoc-chunk-v1");
        ArrayNode chunks = chunksRoot.putArray("chunks");
        int ordinal = 0;
        for (int p = 0; p < pageTexts.size(); p++) {
            String chunkId = "doc:" + docId + ":v1:p" + (p + 1) + ":c0";
            String text = pageTexts.get(p) + " " + MARKER;
            chunkIds.add(chunkId);
            vectors.add(unitAt(ordinal * 53));
            ordinal++;
            ObjectNode node = chunks.addObject();
            node.put("chunk_id", chunkId);
            node.put("document_id", docId);
            node.put("doc_version", 1);
            node.put("page_no", p + 1);
            node.put("chunk_index", 0);
            node.put("citation", "doc:" + docId + ":v1#p" + (p + 1) + "c0");
            node.put("text", text);
            node.put("chars", text.length());
            node.put("text_hash", sha256Hex(text));
            node.put("owner_id", ownerId);
            node.put("chunk_config_version", "udoc-chunk-v1");
        }
        chunksRoot.put("chunk_count", chunkIds.size());
        storageService.writeChunks(row.getId(), chunksRoot.toString());

        ObjectNode embeddingsRoot = MAPPER.createObjectNode();
        embeddingsRoot.put("document_id", docId);
        embeddingsRoot.put("doc_version", 1);
        embeddingsRoot.put("chunk_config_version", "udoc-chunk-v1");
        embeddingsRoot.put("model_id", "sentence-transformers/all-MiniLM-L6-v2");
        embeddingsRoot.put("model_revision", "1110a243fdf4706b3f48f1d95db1a4f5529b4d41");
        embeddingsRoot.put("model_license", "Apache-2.0");
        embeddingsRoot.put("embedding_dimension", 384);
        embeddingsRoot.put("normalize_embeddings", true);
        embeddingsRoot.put("similarity_metric", "cosine");
        embeddingsRoot.put("embedder_version", "test-embedder-v1");
        embeddingsRoot.put("chunk_count", chunkIds.size());
        ArrayNode ids = embeddingsRoot.putArray("chunk_ids");
        chunkIds.forEach(ids::add);
        java.util.List<com.gamelearn.ai.documents.PdfExtractionClient.EmbeddedChunk> check =
                new java.util.ArrayList<>();
        ArrayNode entries = embeddingsRoot.putArray("embeddings");
        for (int i = 0; i < chunkIds.size(); i++) {
            ObjectNode node = entries.addObject();
            node.put("chunk_id", chunkIds.get(i));
            ArrayNode values = node.putArray("vector");
            for (double value : vectors.get(i)) {
                values.add(value);
            }
            check.add(new com.gamelearn.ai.documents.PdfExtractionClient.EmbeddedChunk(
                    chunkIds.get(i), vectors.get(i)));
        }
        embeddingsRoot.put("embedding_fingerprint",
                com.gamelearn.ai.documents.PdfExtractionClient.fingerprintHex(check));
        storageService.writeEmbeddings(row.getId(), embeddingsRoot.toString());
        return new Fixture(user, row, chunkIds);
    }

    private void rewriteEmbeddings(UserDocument row,
                                   java.util.function.UnaryOperator<ObjectNode> mutate)
            throws Exception {
        ObjectNode root = (ObjectNode) MAPPER.readTree(
                storageService.readArtifact(row.getId(), "embeddings.json"));
        storageService.writeEmbeddings(row.getId(), mutate.apply(root).toString());
    }

    // ------------------------------------------------------------------
    // 1-8: collection, ids, upsert, idempotency
    // ------------------------------------------------------------------

    @Test
    void collectionIsCreatedWithCorrectConfigAndIndexes() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        Fixture fixture = setupDoc("idxcfg", List.of("Config probe page."));
        indexService.index(fixture.user().getId(), fixture.row().getId());

        JsonNode config = collectionConfig();
        assertThat(config.path("config").path("params").path("vectors")
                .path("size").asInt()).isEqualTo(384);
        assertThat(config.path("config").path("params").path("vectors")
                .path("distance").asText()).isEqualTo("Cosine");
        JsonNode schema = config.path("payload_schema");
        assertThat(schema.path("owner_id").path("data_type").asText()).isEqualTo("keyword");
        assertThat(schema.path("document_id").path("data_type").asText()).isEqualTo("keyword");
        assertThat(schema.path("doc_version").path("data_type").asText()).isEqualTo("integer");
    }

    @Test
    void pointIdsAreDeterministicAndChunksMapOneToOne() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        Fixture fixture = setupDoc("idxdet",
                List.of("Deterministic one.", "Deterministic two.", "Deterministic three."));
        var result = indexService.index(fixture.user().getId(), fixture.row().getId());
        assertThat(result.pointCount()).isEqualTo(3);
        assertThat(result.reindexed()).isFalse();

        List<UUID> expected = fixture.chunkIds().stream()
                .map(id -> UUID.nameUUIDFromBytes(id.getBytes(StandardCharsets.UTF_8)))
                .sorted().toList();
        List<UUID> stored = scrollIds(fixture).stream().sorted().toList();
        assertThat(stored).isEqualTo(expected);
        // Same chunk ids re-derive the same point ids (mapping is stable).
        assertThat(expected).doesNotHaveDuplicates();
    }

    private List<UUID> scrollIds(Fixture fixture) throws Exception {
        ObjectNode filter = MAPPER.createObjectNode();
        ArrayNode must = filter.putObject("filter").putArray("must");
        must.addObject().put("key", "owner_id").putObject("match")
                .put("value", fixture.user().getId().toString());
        must.addObject().put("key", "document_id").putObject("match")
                .put("value", fixture.row().getId().toString());
        must.addObject().put("key", "doc_version").putObject("match").put("value", 1);
        ObjectNode body = MAPPER.createObjectNode();
        body.set("filter", filter.get("filter"));
        body.put("limit", 100);
        body.put("with_payload", false);
        body.put("with_vector", false);
        JsonNode points = qdrant("POST",
                "/collections/" + COLLECTION + "/points/scroll", body.toString())
                .path("result").path("points");
        List<UUID> ids = new ArrayList<>();
        points.forEach(point -> ids.add(UUID.fromString(point.path("id").asText())));
        return ids;
    }

    @Test
    void reindexIsIdempotentAndCleansStalePoints() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        Fixture fixture = setupDoc("idxre",
                List.of("Reindex page one.", "Reindex page two."));
        indexService.index(fixture.user().getId(), fixture.row().getId());

        // A stale point for the exact version (e.g. from an older chunking).
        UUID stale = UUID.randomUUID();
        qdrant("PUT", "/collections/" + COLLECTION + "/points?wait=true",
                MAPPER.createObjectNode()
                        .putPOJO("points", List.of(Map.of(
                                "id", stale.toString(),
                                "vector", unitList(5),
                                "payload", Map.of(
                                        "owner_id", fixture.user().getId().toString(),
                                        "document_id", fixture.row().getId().toString(),
                                        "doc_version", 1,
                                        "chunk_id", "stale-unknown"))))
                        .toString());

        var second = indexService.index(fixture.user().getId(), fixture.row().getId());
        assertThat(second.reindexed()).isTrue();
        assertThat(second.pointCount()).isEqualTo(2);
        List<UUID> ids = scrollIds(fixture);
        assertThat(ids).hasSize(2).doesNotContain(stale);
        // Third run changes nothing: true idempotency.
        indexService.index(fixture.user().getId(), fixture.row().getId());
        assertThat(scrollIds(fixture)).containsExactlyInAnyOrderElementsOf(ids);
    }

    private static List<Double> unitList(int index) {
        List<Double> vector = new ArrayList<>(384);
        for (int i = 0; i < 384; i++) {
            vector.add(i == index % 384 ? 1.0 : 0.0);
        }
        return vector;
    }

    // ------------------------------------------------------------------
    // 9-13, 19-20, 29-32: validation gates fail closed, never INDEXED
    // ------------------------------------------------------------------

    private void assertFailedClosed(Fixture fixture) {
        UserDocument row =
                documentRepository.findById(fixture.row().getId()).orElseThrow();
        assertThat(row.getStatus().name()).isEqualTo("FAILED");
    }

    @Test
    void wrongDimensionRejected() throws Exception {
        Fixture fixture = setupDoc("idxdim", List.of("Dimension probe."));
        rewriteEmbeddings(fixture.row(), root -> {
            ArrayNode vectors = (ArrayNode) root.withArray("embeddings").get(0).get("vector");
            vectors.removeAll();
            for (int i = 0; i < 10; i++) {
                vectors.add(0.0);
            }
            return root;
        });
        assertThatThrownBy(
                () -> indexService.index(fixture.user().getId(), fixture.row().getId()))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.VALIDATION_FAILED.name()));
        assertFailedClosed(fixture);
    }

    @Test
    void nonUnitNormRejected() throws Exception {
        Fixture fixture = setupDoc("idxnorm", List.of("Norm probe."));
        rewriteEmbeddings(fixture.row(), root -> {
            ArrayNode entries = root.withArray("embeddings");
            for (JsonNode entry : entries) {
                ArrayNode vector = (ArrayNode) entry.get("vector");
                for (int i = 0; i < vector.size(); i++) {
                    vector.set(i, MAPPER.getNodeFactory().numberNode(10.0));
                }
            }
            return root;
        });
        assertThatThrownBy(
                () -> indexService.index(fixture.user().getId(), fixture.row().getId()))
                .isInstanceOf(ApiException.class);
        assertFailedClosed(fixture);
    }

    @Test
    void wrongModelRevisionRejected() throws Exception {
        Fixture fixture = setupDoc("idxmodel", List.of("Model probe."));
        rewriteEmbeddings(fixture.row(), root -> {
            root.put("model_revision", "deadbeef".repeat(5));
            return root;
        });
        assertThatThrownBy(
                () -> indexService.index(fixture.user().getId(), fixture.row().getId()))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.VALIDATION_FAILED.name()));
        assertFailedClosed(fixture);
    }

    @Test
    void fingerprintMismatchRejected() throws Exception {
        Fixture fixture = setupDoc("idxfp", List.of("Fingerprint probe."));
        rewriteEmbeddings(fixture.row(), root -> {
            root.put("embedding_fingerprint", "0".repeat(64));
            return root;
        });
        assertThatThrownBy(
                () -> indexService.index(fixture.user().getId(), fixture.row().getId()))
                .isInstanceOf(ApiException.class);
        assertFailedClosed(fixture);
    }

    @Test
    void versionMismatchFailsClosed() throws Exception {
        Fixture fixture = setupDoc("idxver", List.of("Version probe."));
        rewriteEmbeddings(fixture.row(), root -> {
            root.put("doc_version", 2);
            return root;
        });
        assertThatThrownBy(
                () -> indexService.index(fixture.user().getId(), fixture.row().getId()))
                .isInstanceOf(ApiException.class);
        assertFailedClosed(fixture);
    }

    @Test
    void malformedArtifactRejected() throws Exception {
        Fixture fixture = setupDoc("idxmal", List.of("Malformed probe."));
        storageService.writeEmbeddings(fixture.row().getId(), "not json{{{");
        assertThatThrownBy(
                () -> indexService.index(fixture.user().getId(), fixture.row().getId()))
                .isInstanceOf(ApiException.class);
        assertFailedClosed(fixture);
    }

    @Test
    void notReadyDocumentRejected() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("idxnotready"));
        UserDocument row = documentService.register(user.getId(), "early.pdf",
                "application/pdf", 64);
        assertThatThrownBy(() -> indexService.index(user.getId(), row.getId()))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.VALIDATION_FAILED.name()));
    }

    // ------------------------------------------------------------------
    // 14-18, 23-24, 33: isolation, delete, payload minimality
    // ------------------------------------------------------------------

    @Test
    void crossUserAccessAndDeleteRefused() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        Fixture fixtureA = setupDoc("idxa1", List.of("Owner A secrets."));
        User userB = userRepository.saveAndFlush(PersistenceTestFixtures.user("idxb1"));
        indexService.index(fixtureA.user().getId(), fixtureA.row().getId());

        assertThatThrownBy(
                () -> indexService.index(userB.getId(), fixtureA.row().getId()))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.RESOURCE_NOT_FOUND.name()));
        assertThatThrownBy(() -> indexService.deleteDocumentVectors(userB.getId(),
                        fixtureA.row().getId(), 1))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.RESOURCE_NOT_FOUND.name()));
        // A's points are untouched by B's attempts.
        assertThat(scrollIds(fixtureA)).hasSize(1);
    }

    @Test
    void documentsIsolateAndDeleteRemovesOnlyTarget() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        Fixture doc1 = setupDoc("idxd1", List.of("Doc one a.", "Doc one b."));
        Fixture doc2 = setupDoc("idxd2", List.of("Doc two a."));
        Fixture other = setupDoc("idxd3", List.of("Other owner doc."));
        indexService.index(doc1.user().getId(), doc1.row().getId());
        indexService.index(doc2.user().getId(), doc2.row().getId());
        indexService.index(other.user().getId(), other.row().getId());

        long deleted = indexService.deleteDocumentVectors(
                doc1.user().getId(), doc1.row().getId(), 1);
        assertThat(deleted).isEqualTo(2);
        assertThat(scrollIds(doc1)).isEmpty();
        assertThat(scrollIds(doc2)).hasSize(1);
        assertThat(scrollIds(other)).hasSize(1);
    }

    @Test
    void sameVectorsAcrossUsersStayEqual() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        Fixture fixtureA = setupDoc("idxeqa", List.of("Shared sentence."));
        Fixture fixtureB = setupDoc("idxeqb", List.of("Shared sentence."));
        indexService.index(fixtureA.user().getId(), fixtureA.row().getId());
        indexService.index(fixtureB.user().getId(), fixtureB.row().getId());

        List<JsonNode> payloadsA = scrollPayloads(
                fixtureA.user().getId().toString(), fixtureA.row().getId().toString(), 1);
        List<JsonNode> payloadsB = scrollPayloads(
                fixtureB.user().getId().toString(), fixtureB.row().getId().toString(), 1);
        assertThat(payloadsA).hasSize(1);
        assertThat(payloadsB).hasSize(1);
        // Same text => same vector in both owners' namespaces (shared space).
        assertThat(payloadsA.get(0).path("vector").toString())
                .isEqualTo(payloadsB.get(0).path("vector").toString());
        // ... but namespaces do not leak into each other.
        assertThat(payloadsA.get(0).path("payload").path("owner_id").asText())
                .isEqualTo(fixtureA.user().getId().toString());
        assertThat(payloadsB.get(0).path("payload").path("owner_id").asText())
                .isEqualTo(fixtureB.user().getId().toString());
    }

    @Test
    void payloadSchemaIsMinimalAndTextFree() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        Fixture fixture = setupDoc("idxpay", List.of("Payload probe text."));
        indexService.index(fixture.user().getId(), fixture.row().getId());

        List<JsonNode> payloads = scrollPayloads(
                fixture.user().getId().toString(), fixture.row().getId().toString(), 1);
        assertThat(payloads).hasSize(1);
        JsonNode payload = payloads.get(0).path("payload");
        List<String> keys = new ArrayList<>();
        payload.fieldNames().forEachRemaining(keys::add);
        assertThat(keys).containsExactlyInAnyOrder("owner_id", "document_id", "doc_version",
                "chunk_id", "page_no", "citation", "chunk_config_version", "text_hash",
                "embedding_fingerprint", "embedding_model_revision");
        String serialized = payload.toString();
        assertThat(serialized).doesNotContain("Payload probe text");
        assertThat(serialized).doesNotContain(MARKER);
    }

    @Test
    void indexedContentNeverReachesLogs() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        ListAppender<ILoggingEvent> appender = new ListAppender<>();
        appender.start();
        ((Logger) org.slf4j.LoggerFactory.getLogger(DocumentIndexService.class))
                .addAppender(appender);
        ((Logger) org.slf4j.LoggerFactory.getLogger(QdrantClient.class)).addAppender(appender);
        try {
            Fixture fixture = setupDoc("idxlog", List.of("Log probe page."));
            indexService.index(fixture.user().getId(), fixture.row().getId());
            indexService.deleteDocumentVectors(
                    fixture.user().getId(), fixture.row().getId(), 1);
            assertThat(appender.list)
                    .filteredOn(e -> e.getFormattedMessage().contains(MARKER))
                    .isEmpty();
        } finally {
            ((Logger) org.slf4j.LoggerFactory.getLogger(DocumentIndexService.class))
                    .detachAppender(appender);
            ((Logger) org.slf4j.LoggerFactory.getLogger(QdrantClient.class))
                    .detachAppender(appender);
            appender.stop();
        }
    }

    // ------------------------------------------------------------------
    // 21-22, 27: failure handling, incompatibility, restart
    // ------------------------------------------------------------------

    @Test
    void qdrantUnavailableFailsClosed() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        Fixture fixture = setupDoc("idxdown", List.of("Down probe."));
        QdrantClient dead = new QdrantClient("http://127.0.0.1:9",
                Duration.ofSeconds(1), Duration.ofSeconds(2));
        DocumentIndexService isolated = new DocumentIndexService(documentService,
                documentRepository, storageService, dead);
        assertThatThrownBy(
                () -> isolated.index(fixture.user().getId(), fixture.row().getId()))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.INTERNAL_ERROR.name()));
        UserDocument row =
                documentRepository.findById(fixture.row().getId()).orElseThrow();
        assertThat(row.getStatus().name()).isEqualTo("FAILED");
    }

    @Test
    void incompatibleCollectionFailsClosedWithoutMigration() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        // Start from absent: a leftover correct collection from earlier
        // tests would make the wrong-config PUT a silent no-op.
        deleteCollectionIfExists();
        qdrant("PUT", "/collections/" + COLLECTION,
                "{\"vectors\":{\"size\":128,\"distance\":\"Dot\"}}");
        try {
            Fixture fixture = setupDoc("idxincompat", List.of("Incompatible probe."));
            assertThatThrownBy(() -> indexService.index(
                            fixture.user().getId(), fixture.row().getId()))
                    .isInstanceOf(ApiException.class);
            assertFailedClosedStatus(fixture);
            // Collection untouched: still the incompatible config, no data.
            JsonNode config = collectionConfig();
            assertThat(config.path("config").path("params").path("vectors")
                    .path("size").asInt()).isEqualTo(128);
        } finally {
            deleteCollectionIfExists();
        }
    }

    private void assertFailedClosedStatus(Fixture fixture) {
        UserDocument reloaded =
                documentRepository.findById(fixture.row().getId()).orElseThrow();
        assertThat(reloaded.getStatus().name()).isEqualTo("FAILED");
    }

    @Test
    void restartPreservesIndexedData() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        Process probe;
        try {
            probe = new ProcessBuilder("docker", "--version").start();
            if (probe.waitFor() != 0) {
                Assumptions.abort("Docker CLI unavailable");
            }
        } catch (IOException | InterruptedException noDocker) {
            Assumptions.abort("Docker CLI unavailable");
            return;
        }
        Fixture fixture = setupDoc("idxrestart", List.of("Restart probe one.", "Restart probe two."));
        var result = indexService.index(fixture.user().getId(), fixture.row().getId());
        assertThat(result.pointCount()).isEqualTo(2);

        Process restart = new ProcessBuilder("docker", "restart", "gamelearn-qdrant").start();
        Assumptions.assumeTrue(restart.waitFor() == 0, "Container restart failed");
        boolean healthy = false;
        for (int i = 0; i < 24; i++) {
            try {
                JsonNode health = qdrant("GET", "/collections", null);
                if (health.path("status").asText().equals("ok")) {
                    healthy = true;
                    break;
                }
            } catch (Exception notYet) {
                Thread.sleep(5000);
            }
        }
        Assumptions.assumeTrue(healthy, "Qdrant did not recover after restart");
        assertThat(scrollIds(fixture)).hasSize(2);
        JsonNode config = collectionConfig();
        assertThat(config.path("config").path("params").path("vectors")
                .path("size").asInt()).isEqualTo(384);
    }

    @Test
    void indexingPerformanceIsRecorded() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        List<String> pages = new ArrayList<>();
        for (int i = 0; i < 10; i++) {
            pages.add("Performance probe page " + i + " with stable content.");
        }
        Fixture fixture = setupDoc("idxperf", pages);
        var result = indexService.index(fixture.user().getId(), fixture.row().getId());
        assertThat(result.pointCount()).isEqualTo(10);
        System.out.println("[phase-f] points=10 upsertMs=" + result.upsertMs()
                + " verifyMs=" + result.verifyMs() + " reindexed=" + result.reindexed());
    }
}
