package com.gamelearn.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.time.Duration;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

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
import com.gamelearn.ai.documents.PdfExtractionClient;
import com.gamelearn.ai.documents.QdrantClient;
import com.gamelearn.ai.documents.QdrantException;
import com.gamelearn.config.AiProperties;
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
 * USER-DOC RAG Phase G: owner-scoped semantic retrieval over the REAL
 * stack — real pinned MiniLM sidecar (started in-process), real local
 * Qdrant, real artifacts. Nothing retrieval-critical is mocked: query
 * vectors, cosine ranking, owner/document/version filters, artifact
 * resolution and integrity checks all execute for real. Aborts (not
 * fails) when Qdrant or the sidecar cannot start.
 */
@SpringBootTest
@ActiveProfiles("test")
class DocumentRetrievalServiceTest {

    static final ObjectMapper MAPPER = new ObjectMapper();
    static final String QDRANT = "http://127.0.0.1:6333";
    static final String COLLECTION = "user_doc_chunks";
    /** Clean probe token: no secret/injection shape. */
    static final String MARKER = "QdrantProbeG7XK";
    static final boolean QDRANT_UP = probeQdrant();

    static Path storageRoot;
    static Process sidecar;
    static String sidecarBase;
    static final String SIDECAR_TOKEN = "test-retrieval-token";

    @Autowired
    private DocumentRetrievalService retrievalService;
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
    @Autowired
    private AiProperties properties;
    @Autowired
    private QdrantClient qdrantClient;

    // ------------------------------------------------------------------
    // infrastructure: real Qdrant gate + real sidecar process
    // ------------------------------------------------------------------

    private static boolean probeQdrant() {
        try (java.net.Socket socket = new java.net.Socket()) {
            socket.connect(new InetSocketAddress("127.0.0.1", 6333), 3000);
            return true;
        } catch (IOException unreachable) {
            return false;
        }
    }

    private static Path repoRoot() {
        Path dir = Path.of(System.getProperty("user.dir")).toAbsolutePath();
        for (int i = 0; i < 4; i++) {
            if (Files.isRegularFile(dir.resolve("mlrag/serving/rag_sidecar.py"))) {
                return dir;
            }
            dir = dir.getParent();
        }
        throw new IllegalStateException("repository root not found");
    }

    @BeforeAll
    static void startSidecar() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        storageRoot = Files.createTempDirectory("gamelearn-doc-retrieval-test");
        Path script = repoRoot().resolve("mlrag/serving/rag_sidecar.py");
        ProcessBuilder builder = new ProcessBuilder("python", script.toString());
        builder.directory(repoRoot().toFile());
        builder.environment().put("RAG_SIDECAR_TOKEN", SIDECAR_TOKEN);
        builder.environment().put("RAG_SIDECAR_PORT", "0");
        builder.redirectErrorStream(true);
        sidecar = builder.start();
        AtomicReference<String> base = new AtomicReference<>();
        long deadline = System.currentTimeMillis() + 300_000;
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(sidecar.getInputStream(), StandardCharsets.UTF_8))) {
            String line;
            while (System.currentTimeMillis() < deadline
                    && (line = reader.readLine()) != null) {
                int at = line.indexOf("\"base\": \"http");
                if (at >= 0) {
                    int end = line.indexOf('"', at + 9);
                    base.set(line.substring(at + 9, end));
                    break;
                }
            }
        }
        Assumptions.assumeTrue(base.get() != null, "Sidecar did not become ready");
        sidecarBase = base.get();
    }

    @AfterAll
    static void stopSidecar() throws Exception {
        if (sidecar != null && sidecar.isAlive()) {
            sidecar.destroy();
            sidecar.waitFor(30, TimeUnit.SECONDS);
            sidecar.destroyForcibly();
        }
        if (QDRANT_UP) {
            deleteCollectionIfExists();
        }
    }

    @DynamicPropertySource
    static void docProps(DynamicPropertyRegistry registry) {
        registry.add("gamelearn.ai.documents.storage-root", () -> storageRoot.toString());
        registry.add("gamelearn.ai.rag.base-url", () -> sidecarBase);
        registry.add("gamelearn.ai.rag.service-token", () -> SIDECAR_TOKEN);
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
            // Absent collection is the desired state either way.
        }
    }

    private static long filteredCount(String ownerId, String documentId, int version)
            throws Exception {
        ObjectNode body = MAPPER.createObjectNode();
        ArrayNode must = body.putObject("filter").putArray("must");
        must.addObject().put("key", "owner_id").putObject("match").put("value", ownerId);
        must.addObject().put("key", "document_id").putObject("match").put("value", documentId);
        must.addObject().put("key", "doc_version").putObject("match").put("value", version);
        body.put("exact", true);
        return qdrant("POST", "/collections/" + COLLECTION + "/points/count", body.toString())
                .path("result").path("count").asLong();
    }

    // ------------------------------------------------------------------
    // fixtures: real sidecar vectors, production writers, Phase F index
    // ------------------------------------------------------------------

    private record Fixture(User user, UserDocument row, List<String> chunkIds) {
    }

    private static String sha256Hex(String text) throws Exception {
        return HexFormat.of().formatHex(
                MessageDigest.getInstance("SHA-256").digest(text.getBytes(StandardCharsets.UTF_8)));
    }

    private List<double[]> embedViaSidecar(List<String> texts) throws Exception {
        ObjectNode body = MAPPER.createObjectNode();
        body.put("document_id", "fixture");
        body.put("doc_version", 1);
        ArrayNode chunks = body.putArray("chunks");
        for (int i = 0; i < texts.size(); i++) {
            ObjectNode node = chunks.addObject();
            node.put("chunk_id", "c" + i);
            node.put("text", texts.get(i));
        }
        var request = java.net.http.HttpRequest.newBuilder()
                .uri(java.net.URI.create(sidecarBase + "/embed"))
                .timeout(Duration.ofSeconds(120))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + SIDECAR_TOKEN)
                .POST(java.net.http.HttpRequest.BodyPublishers.ofString(body.toString()))
                .build();
        JsonNode root = MAPPER.readTree(
                HTTP.send(request, java.net.http.HttpResponse.BodyHandlers.ofString()).body());
        if (!root.path("ok").asBoolean()) {
            throw new IllegalStateException("fixture embedding refused");
        }
        List<double[]> vectors = new ArrayList<>();
        for (JsonNode entry : root.withArray("embeddings")) {
            double[] vector = new double[384];
            int i = 0;
            for (JsonNode value : entry.withArray("vector")) {
                vector[i++] = value.asDouble();
            }
            vectors.add(vector);
        }
        return vectors;
    }

    private Fixture setupIndexedDoc(String label, List<String> pageTexts) throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user(label));
        UserDocument row = documentService.register(user.getId(), label + ".pdf",
                "application/pdf", 1024);
        documentService.transitionStatus(user.getId(), row.getId(), DocumentStatus.EXTRACTING);
        documentService.setPageCount(user.getId(), row.getId(), pageTexts.size());
        documentService.transitionStatus(user.getId(), row.getId(), DocumentStatus.CHUNKED);

        String docId = row.getId().toString();
        String ownerId = user.getId().toString();
        List<String> texts = new ArrayList<>(pageTexts.size());
        for (String page : pageTexts) {
            texts.add(page + " " + MARKER);
        }
        List<double[]> vectors = embedViaSidecar(texts);

        List<String> chunkIds = new ArrayList<>();
        ObjectNode chunksRoot = MAPPER.createObjectNode();
        chunksRoot.put("document_id", docId);
        chunksRoot.put("doc_version", 1);
        chunksRoot.put("chunk_config_version", "udoc-chunk-v1");
        ArrayNode chunks = chunksRoot.putArray("chunks");
        for (int p = 0; p < texts.size(); p++) {
            String chunkId = "doc:" + docId + ":v1:p" + (p + 1) + ":c0";
            chunkIds.add(chunkId);
            ObjectNode node = chunks.addObject();
            node.put("chunk_id", chunkId);
            node.put("document_id", docId);
            node.put("doc_version", 1);
            node.put("page_no", p + 1);
            node.put("chunk_index", 0);
            node.put("citation", "doc:" + docId + ":v1#p" + (p + 1) + "c0");
            node.put("text", texts.get(p));
            node.put("chars", texts.get(p).length());
            node.put("text_hash", sha256Hex(texts.get(p)));
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
        java.util.List<PdfExtractionClient.EmbeddedChunk> check = new java.util.ArrayList<>();
        ArrayNode entries = embeddingsRoot.putArray("embeddings");
        for (int i = 0; i < chunkIds.size(); i++) {
            ObjectNode node = entries.addObject();
            node.put("chunk_id", chunkIds.get(i));
            ArrayNode values = node.putArray("vector");
            for (double value : vectors.get(i)) {
                values.add(value);
            }
            check.add(new PdfExtractionClient.EmbeddedChunk(chunkIds.get(i), vectors.get(i)));
        }
        embeddingsRoot.put("embedding_fingerprint",
                PdfExtractionClient.fingerprintHex(check));
        storageService.writeEmbeddings(row.getId(), embeddingsRoot.toString());

        var result = indexService.index(user.getId(), row.getId());
        if (result.pointCount() != chunkIds.size()) {
            throw new IllegalStateException("fixture indexing failed");
        }
        return new Fixture(user, row, chunkIds);
    }

    // ------------------------------------------------------------------
    // retrieval: ranking + scope
    // ------------------------------------------------------------------

    @Test
    void collectionPreconditionHolds() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        Fixture fixture = setupIndexedDoc("retpre",
                List.of("Precondition probe photosynthesis sunlight."));
        JsonNode config = qdrant("GET", "/collections/" + COLLECTION, null)
                .path("result").path("config").path("params").path("vectors");
        assertThat(config.path("size").asInt()).isEqualTo(384);
        assertThat(config.path("distance").asText()).isEqualTo("Cosine");
        assertThat(filteredCount(fixture.user().getId().toString(),
                fixture.row().getId().toString(), 1)).isEqualTo(1);
    }

    @Test
    void ownerRetrievesOwnDocumentRankedFirst() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        Fixture docA1 = setupIndexedDoc("retra1", List.of(
                "Photosynthesis converts sunlight into chemical energy in green leaves.",
                "Mitochondria generate energy currency for the living cell.",
                "Volcanoes erupt molten rock from deep chambers."));
        var hits = retrievalService.retrieve(docA1.user().getId(),
                "how do plants make food from sunlight", docA1.row().getId(), null, null);
        assertThat(hits).isNotEmpty();
        assertThat(hits.get(0).chunkId()).isEqualTo(docA1.chunkIds().get(0));
        assertThat(hits).allMatch(hit -> hit.documentId().equals(docA1.row().getId()));
        assertThat(hits.get(0).score()).isGreaterThan(0.25);
        assertThat(hits.get(0).citation()).contains(docA1.row().getId().toString());
        System.out.println("[phase-g] rank1-score=" + hits.get(0).score()
                + " count=" + hits.size());
    }

    @Test
    void identicalTextAcrossOwnersStaysIsolated() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        String shared = "Shared isolation sentence about river deltas.";
        Fixture docA = setupIndexedDoc("retisoa", List.of(shared, "Owner A second page."));
        Fixture docB = setupIndexedDoc("retisob", List.of(shared, "Owner B second page."));

        var hitsA = retrievalService.retrieve(docA.user().getId(),
                "river deltas shared sentence", null, null, 10);
        assertThat(hitsA).isNotEmpty();
        assertThat(hitsA).allMatch(hit -> hit.documentId().equals(docA.row().getId()));

        var hitsB = retrievalService.retrieve(docB.user().getId(),
                "river deltas shared sentence", null, null, 10);
        assertThat(hitsB).isNotEmpty();
        assertThat(hitsB).allMatch(hit -> hit.documentId().equals(docB.row().getId()));

        // Foreign scope behaves like missing: 404, never the row.
        assertThatThrownBy(() -> retrievalService.retrieve(
                        docA.user().getId(), "river deltas", docB.row().getId(), null, null))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.RESOURCE_NOT_FOUND.name()));
        assertThatThrownBy(() -> retrievalService.retrieve(
                        docB.user().getId(), "river deltas", docA.row().getId(), null, null))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.RESOURCE_NOT_FOUND.name()));
    }

    @Test
    void documentScopeExcludesSibling() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        Fixture docA1 = setupIndexedDoc("retsco1",
                List.of("Sibling scope photosynthesis page."));
        Fixture docA2 = setupIndexedDoc("retsco2",
                List.of("Sibling scope fractions page."));
        var hits = retrievalService.retrieve(docA1.user().getId(), "sibling scope",
                docA1.row().getId(), null, 10);
        // Both docs belong to different owners here (helper creates one user
        // per document), so scope on A1 can only ever return A1.
        assertThat(hits).allMatch(hit -> hit.documentId().equals(docA1.row().getId()));
        assertThat(docA2.row().getId()).isNotEqualTo(docA1.row().getId());
    }

    @Test
    void sameOwnerSiblingExcludedByDocumentScope() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("retsib"));
        Fixture first = setupIndexedDocFor(user, "sibone",
                List.of("First sibling photosynthesis content here."));
        Fixture second = setupIndexedDocFor(user, "sibtwo",
                List.of("Second sibling photosynthesis content here."));
        var hits = retrievalService.retrieve(user.getId(), "sibling photosynthesis",
                first.row().getId(), null, 10);
        assertThat(hits).isNotEmpty();
        assertThat(hits).allMatch(hit -> hit.documentId().equals(first.row().getId()));
        assertThat(second.chunkIds()).isNotEmpty();
    }

    private Fixture setupIndexedDocFor(User user, String label, List<String> pageTexts)
            throws Exception {
        UserDocument row = documentService.register(user.getId(), label + ".pdf",
                "application/pdf", 1024);
        documentService.transitionStatus(user.getId(), row.getId(), DocumentStatus.EXTRACTING);
        documentService.setPageCount(user.getId(), row.getId(), pageTexts.size());
        documentService.transitionStatus(user.getId(), row.getId(), DocumentStatus.CHUNKED);
        String docId = row.getId().toString();
        String ownerId = user.getId().toString();
        List<String> texts = new ArrayList<>(pageTexts.size());
        for (String page : pageTexts) {
            texts.add(page + " " + MARKER);
        }
        List<double[]> vectors = embedViaSidecar(texts);
        List<String> chunkIds = new ArrayList<>();
        ObjectNode chunksRoot = MAPPER.createObjectNode();
        chunksRoot.put("document_id", docId);
        chunksRoot.put("doc_version", 1);
        chunksRoot.put("chunk_config_version", "udoc-chunk-v1");
        ArrayNode chunks = chunksRoot.putArray("chunks");
        for (int p = 0; p < texts.size(); p++) {
            String chunkId = "doc:" + docId + ":v1:p" + (p + 1) + ":c0";
            chunkIds.add(chunkId);
            ObjectNode node = chunks.addObject();
            node.put("chunk_id", chunkId);
            node.put("document_id", docId);
            node.put("doc_version", 1);
            node.put("page_no", p + 1);
            node.put("chunk_index", 0);
            node.put("citation", "doc:" + docId + ":v1#p" + (p + 1) + "c0");
            node.put("text", texts.get(p));
            node.put("chars", texts.get(p).length());
            node.put("text_hash", sha256Hex(texts.get(p)));
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
        java.util.List<PdfExtractionClient.EmbeddedChunk> check = new java.util.ArrayList<>();
        ArrayNode entries = embeddingsRoot.putArray("embeddings");
        for (int i = 0; i < chunkIds.size(); i++) {
            ObjectNode node = entries.addObject();
            node.put("chunk_id", chunkIds.get(i));
            ArrayNode values = node.putArray("vector");
            for (double value : vectors.get(i)) {
                values.add(value);
            }
            check.add(new PdfExtractionClient.EmbeddedChunk(chunkIds.get(i), vectors.get(i)));
        }
        embeddingsRoot.put("embedding_fingerprint",
                PdfExtractionClient.fingerprintHex(check));
        storageService.writeEmbeddings(row.getId(), embeddingsRoot.toString());
        var result = indexService.index(user.getId(), row.getId());
        if (result.pointCount() != chunkIds.size()) {
            throw new IllegalStateException("fixture indexing failed");
        }
        return new Fixture(user, row, chunkIds);
    }

    @Test
    void versionScopeRespected() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        Fixture fixture = setupIndexedDoc("retver", List.of("Version scope page."));
        var explicit = retrievalService.retrieve(fixture.user().getId(), "version scope",
                fixture.row().getId(), 1, null);
        assertThat(explicit).isNotEmpty();
        assertThatThrownBy(() -> retrievalService.retrieve(fixture.user().getId(),
                        "version scope", fixture.row().getId(), 2, null))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.RESOURCE_NOT_FOUND.name()));
    }

    @Test
    void unscopedSearchCoversAllOwnedIndexedDocs() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("retall"));
        setupIndexedDocFor(user, "allone", List.of("Fractions divide wholes equally."));
        setupIndexedDocFor(user, "alltwo", List.of("Volcanoes erupt molten rock."));
        var hits = retrievalService.retrieve(user.getId(), "fractions divide wholes", null,
                null, 10);
        assertThat(hits).isNotEmpty();
        assertThat(hits.stream().anyMatch(hit ->
                hit.textHash() != null && hit.score() > 0.2)).isTrue();
    }

    @Test
    void nonIndexedDocumentYieldsEmptyWithoutError() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("retnoidx"));
        UserDocument row = documentService.register(user.getId(), "plain.pdf",
                "application/pdf", 64);
        documentService.transitionStatus(user.getId(), row.getId(), DocumentStatus.EXTRACTING);
        documentService.transitionStatus(user.getId(), row.getId(), DocumentStatus.CHUNKED);
        var hits = retrievalService.retrieve(user.getId(), "anything at all",
                row.getId(), null, null);
        assertThat(hits).isEmpty();
    }

    // ------------------------------------------------------------------
    // input validation
    // ------------------------------------------------------------------

    @Test
    void ownerlessCallFailsClosed() {
        assertThatThrownBy(() -> retrievalService.retrieve(
                        null, "some query", null, null, null))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.UNAUTHORIZED.name()));
    }

    @Test
    void queryBoundsEnforced() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        Fixture fixture = setupIndexedDoc("retbounds", List.of("Bounds probe page."));
        UUID owner = fixture.user().getId();
        UUID doc = fixture.row().getId();
        assertThatThrownBy(() -> retrievalService.retrieve(owner, "  ", doc, null, null))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.VALIDATION_FAILED.name()));
        assertThatThrownBy(() -> retrievalService.retrieve(owner, null, doc, null, null))
                .isInstanceOf(ApiException.class);
        assertThatThrownBy(() -> retrievalService.retrieve(owner, "x".repeat(1001), doc,
                        null, null))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.VALIDATION_FAILED.name()));
        assertThatThrownBy(() -> retrievalService.retrieve(owner, "badquery", doc, null,
                        null))
                .isInstanceOf(ApiException.class);
        assertThatThrownBy(() -> retrievalService.retrieve(owner, "fine query", doc, null, 0))
                .isInstanceOf(ApiException.class);
        assertThatThrownBy(() -> retrievalService.retrieve(owner, "fine query", doc, null,
                        999))
                .isInstanceOf(ApiException.class);
        assertThatThrownBy(() -> retrievalService.retrieve(owner, "fine query", doc, 0, null))
                .isInstanceOf(ApiException.class);
        assertThatThrownBy(() -> retrievalService.retrieve(owner, "fine query",
                        UUID.randomUUID(), null, null))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                        .isEqualTo(ErrorCode.RESOURCE_NOT_FOUND.name()));
    }

    // ------------------------------------------------------------------
    // determinism + score policy
    // ------------------------------------------------------------------

    @Test
    void sameQueryProducesStableRanking() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        Fixture fixture = setupIndexedDoc("retdet", List.of(
                "Stability probe photosynthesis page.",
                "Stability probe mitochondria page.",
                "Stability probe volcano page."));
        var first = retrievalService.retrieve(fixture.user().getId(), "stability probe energy",
                fixture.row().getId(), null, 10);
        var second = retrievalService.retrieve(fixture.user().getId(), "stability probe energy",
                fixture.row().getId(), null, 10);
        assertThat(first).isNotEmpty();
        assertThat(first.stream().map(hit -> hit.chunkId()).toList())
                .isEqualTo(second.stream().map(hit -> hit.chunkId()).toList());
        assertThat(first.stream().mapToDouble(hit -> hit.score()).toArray())
                .isEqualTo(second.stream().mapToDouble(hit -> hit.score()).toArray());
        double previous = Double.POSITIVE_INFINITY;
        String previousId = "";
        for (var hit : first) {
            assertThat(hit.score() <= previous + 1e-12).isTrue();
            assertThat(hit.score() >= -1.0 - 1e-6 && hit.score() <= 1.0 + 1e-6).isTrue();
            if (Math.abs(hit.score() - previous) < 1e-12) {
                assertThat(hit.chunkId().compareTo(previousId) > 0).isTrue();
            }
            previous = hit.score();
            previousId = hit.chunkId();
        }
    }

    @Test
    void minScorePolicyFiltersCandidatesExplicitly() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        Fixture fixture = setupIndexedDoc("retscore", List.of("Score policy page."));
        properties.getDocuments().setRetrievalMinScore(0.99);
        try {
            var filtered = retrievalService.retrieve(fixture.user().getId(), "score policy",
                    fixture.row().getId(), null, null);
            assertThat(filtered).isEmpty();
        } finally {
            properties.getDocuments().setRetrievalMinScore(0.0);
        }
        var unfiltered = retrievalService.retrieve(fixture.user().getId(), "score policy",
                fixture.row().getId(), null, null);
        assertThat(unfiltered).isNotEmpty();
    }

    @Test
    void queryEmbeddingContractHoldsLive() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        var request = java.net.http.HttpRequest.newBuilder()
                .uri(java.net.URI.create(sidecarBase + "/embed_query"))
                .timeout(Duration.ofSeconds(60))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + SIDECAR_TOKEN)
                .POST(java.net.http.HttpRequest.BodyPublishers.ofString(
                        "{\"query\":\"live contract photosynthesis\"}"))
                .build();
        JsonNode root = MAPPER.readTree(HTTP.send(request,
                java.net.http.HttpResponse.BodyHandlers.ofString()).body());
        assertThat(root.path("ok").asBoolean()).isTrue();
        assertThat(root.path("model_revision").asText())
                .isEqualTo("1110a243fdf4706b3f48f1d95db1a4f5529b4d41");
        assertThat(root.path("embedding_dimension").asInt()).isEqualTo(384);
        assertThat(root.withArray("vector").size()).isEqualTo(384);
        double norm = 0.0;
        for (JsonNode value : root.withArray("vector")) {
            assertThat(value.isNumber()).isTrue();
            norm += value.asDouble() * value.asDouble();
        }
        assertThat(Math.sqrt(norm)).isCloseTo(1.0,
                org.assertj.core.data.Offset.offset(1e-4));
    }

    @Test
    void wrongEmbedRevisionFailsClosed() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        com.sun.net.httpserver.HttpServer stub = com.sun.net.httpserver.HttpServer.create(
                new InetSocketAddress("127.0.0.1", 0), 0);
        stub.createContext("/embed_query", exchange -> {
            exchange.getRequestBody().readAllBytes();
            String body = """
                    {"ok":true,"vector":[%s],\
                    "model_id":"sentence-transformers/all-MiniLM-L6-v2",\
                    "model_revision":"0000000000000000000000000000000000000000",\
                    "embedding_dimension":384}"""
                    .formatted("0.0,".repeat(383) + "1.0");
            byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, bytes.length);
            try (var out = exchange.getResponseBody()) {
                out.write(bytes);
            }
        });
        stub.start();
        // NOTE: the service client binds its base URL at construction, so
        // mutating AiProperties cannot redirect it — wire a dedicated
        // service instance to the stub instead (proves the revision check
        // is live in the parsing path, not dead code).
        com.gamelearn.config.AiProperties stubProps = new com.gamelearn.config.AiProperties();
        stubProps.getRag().setBaseUrl(
                "http://127.0.0.1:" + stub.getAddress().getPort());
        stubProps.getRag().setServiceToken("stub-token");
        DocumentRetrievalService stubService = new DocumentRetrievalService(
                documentRepository, storageService,
                new PdfExtractionClient(stubProps), qdrantClient, stubProps);
        try {
            Fixture fixture = setupIndexedDoc("retwrong", List.of("Wrong model probe."));
            assertThatThrownBy(() -> stubService.retrieve(
                            fixture.user().getId(), "wrong model", fixture.row().getId(),
                            null, null))
                    .isInstanceOf(ApiException.class)
                    .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                            .isEqualTo(ErrorCode.INTERNAL_ERROR.name()));
        } finally {
            stub.stop(0);
        }
    }

    // ------------------------------------------------------------------
    // integrity + outage + logging
    // ------------------------------------------------------------------

    @Test
    void tamperedPayloadFailsClosed() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        Fixture fixture = setupIndexedDoc("rettamper", List.of("Tamper probe page."));
        String ownerId = fixture.user().getId().toString();
        String docId = fixture.row().getId().toString();
        // Point with a deficient payload (no citation) inside our own scope.
        ObjectNode point = MAPPER.createObjectNode();
        point.put("id", UUID.randomUUID().toString());
        ArrayNode vector = point.putArray("vector");
        for (int i = 0; i < 384; i++) {
            vector.add(i == 0 ? 1.0 : 0.0);
        }
        ObjectNode payload = point.putObject("payload");
        payload.put("owner_id", ownerId);
        payload.put("document_id", docId);
        payload.put("doc_version", 1);
        payload.put("chunk_id", fixture.chunkIds().get(0));
        payload.put("page_no", 1);
        payload.put("text_hash", "tampered");
        ObjectNode upsert = MAPPER.createObjectNode();
        upsert.putArray("points").add(point);
        qdrant("PUT", "/collections/" + COLLECTION + "/points?wait=true", upsert.toString());
        try {
            assertThatThrownBy(() -> retrievalService.retrieve(
                            fixture.user().getId(), "tamper probe", fixture.row().getId(),
                            null, 10))
                    .isInstanceOf(ApiException.class)
                    .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                            .isEqualTo(ErrorCode.INTERNAL_ERROR.name()));
        } finally {
            qdrant("POST", "/collections/" + COLLECTION + "/points/delete?wait=true",
                    "{\"filter\":{\"must\":["
                            + "{\"key\":\"owner_id\",\"match\":{\"value\":\"" + ownerId + "\"}},"
                            + "{\"key\":\"document_id\",\"match\":{\"value\":\"" + docId + "\"}},"
                            + "{\"key\":\"doc_version\",\"match\":{\"value\":1}}]}}");
            // Reindex restores the exact valid set for later tests.
            indexService.index(fixture.user().getId(), fixture.row().getId());
        }
    }

    @Test
    void hashMismatchFailsClosedAndRecovers() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        Fixture fixture = setupIndexedDoc("rethash", List.of("Hash probe original text."));
        Path chunksFile = storageRoot.resolve(fixture.row().getId().toString())
                .resolve("chunks.json");
        String original = Files.readString(chunksFile);
        ObjectNode root = (ObjectNode) MAPPER.readTree(original);
        ((ObjectNode) root.withArray("chunks").get(0)).put("text", "ALTERED TEXT");
        Files.writeString(chunksFile, root.toString());
        try {
            assertThatThrownBy(() -> retrievalService.retrieve(
                            fixture.user().getId(), "hash probe", fixture.row().getId(),
                            null, null))
                    .isInstanceOf(ApiException.class)
                    .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                            .isEqualTo(ErrorCode.INTERNAL_ERROR.name()));
        } finally {
            Files.writeString(chunksFile, original);
        }
        var recovered = retrievalService.retrieve(fixture.user().getId(), "hash probe",
                fixture.row().getId(), null, null);
        assertThat(recovered).isNotEmpty();
    }

    @Test
    void missingChunkLookupFailsClosed() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        Fixture fixture = setupIndexedDoc("retmiss", List.of("Missing chunk page."));
        Path chunksFile = storageRoot.resolve(fixture.row().getId().toString())
                .resolve("chunks.json");
        String original = Files.readString(chunksFile);
        ObjectNode root = (ObjectNode) MAPPER.readTree(original);
        ((ArrayNode) root.withArray("chunks")).remove(0);
        Files.writeString(chunksFile, root.toString());
        try {
            assertThatThrownBy(() -> retrievalService.retrieve(
                            fixture.user().getId(), "missing chunk", fixture.row().getId(),
                            null, null))
                    .isInstanceOf(ApiException.class)
                    .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                            .isEqualTo(ErrorCode.INTERNAL_ERROR.name()));
        } finally {
            Files.writeString(chunksFile, original);
        }
    }

    @Test
    void qdrantOutageIsExplicitNeverEmpty() throws Exception {
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
        Fixture fixture = setupIndexedDoc("retoutage", List.of("Outage probe page."));
        Process stop = new ProcessBuilder("docker", "stop", "gamelearn-qdrant").start();
        Assumptions.assumeTrue(stop.waitFor() == 0, "Container stop failed");
        try {
            assertThatThrownBy(() -> retrievalService.retrieve(
                            fixture.user().getId(), "outage probe", fixture.row().getId(),
                            null, null))
                    .isInstanceOf(ApiException.class)
                    .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode())
                            .isEqualTo(ErrorCode.INTERNAL_ERROR.name()));
        } finally {
            Process start = new ProcessBuilder("docker", "start", "gamelearn-qdrant").start();
            Assumptions.assumeTrue(start.waitFor() == 0, "Container start failed");
            boolean healthy = false;
            for (int i = 0; i < 24; i++) {
                try {
                    if (qdrant("GET", "/collections", null).path("status").asText()
                            .equals("ok")) {
                        healthy = true;
                        break;
                    }
                } catch (Exception notYet) {
                    Thread.sleep(5000);
                }
            }
            Assumptions.assumeTrue(healthy, "Qdrant did not recover");
        }
        var recovered = retrievalService.retrieve(fixture.user().getId(), "outage probe",
                fixture.row().getId(), null, null);
        assertThat(recovered).isNotEmpty();
    }

    @Test
    void indexedContentNeverReachesLogs() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        ListAppender<ILoggingEvent> appender = new ListAppender<>();
        appender.start();
        ((Logger) org.slf4j.LoggerFactory.getLogger(DocumentRetrievalService.class))
                .addAppender(appender);
        ((Logger) org.slf4j.LoggerFactory.getLogger(QdrantClient.class)).addAppender(appender);
        ((Logger) org.slf4j.LoggerFactory.getLogger(PdfExtractionClient.class))
                .addAppender(appender);
        try {
            Fixture fixture = setupIndexedDoc("retlog", List.of("Log probe page."));
            retrievalService.retrieve(fixture.user().getId(), "log probe",
                    fixture.row().getId(), null, null);
            assertThat(appender.list)
                    .filteredOn(e -> e.getFormattedMessage().contains(MARKER))
                    .isEmpty();
        } finally {
            ((Logger) org.slf4j.LoggerFactory.getLogger(DocumentRetrievalService.class))
                    .detachAppender(appender);
            ((Logger) org.slf4j.LoggerFactory.getLogger(QdrantClient.class))
                    .detachAppender(appender);
            ((Logger) org.slf4j.LoggerFactory.getLogger(PdfExtractionClient.class))
                    .detachAppender(appender);
            appender.stop();
        }
    }

    @Test
    void pointIdsStayInternal() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        Fixture fixture = setupIndexedDoc("retpid", List.of("Point identity page."));
        var hits = retrievalService.retrieve(fixture.user().getId(), "point identity",
                fixture.row().getId(), null, null);
        assertThat(hits).isNotEmpty();
        // Evidence carries document chunk ids (needed for grounding), never
        // Qdrant point UUIDs.
        for (var hit : hits) {
            assertThat(hit.chunkId()).startsWith("doc:");
            try {
                UUID.fromString(hit.chunkId());
                assertThat(false).as("chunk id must not be a bare UUID").isTrue();
            } catch (IllegalArgumentException expected) {
                // Expected: chunk ids are provenance strings, not point ids.
            }
        }
    }

    @Test
    void ownerFilterGateIsLive() {
        assertThatThrownBy(() -> qdrantClient.searchPoints(new double[384],
                        List.of(), 5, null))
                .isInstanceOf(QdrantException.class)
                .satisfies(ex -> assertThat(((QdrantException) ex).getCategory())
                        .isEqualTo(QdrantException.INVALID));
    }

    @Test
    void phaseFIdempotencyIntact() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        Fixture fixture = setupIndexedDoc("retidem", List.of("Idempotent page one.",
                "Idempotent page two."));
        String ownerId = fixture.user().getId().toString();
        String docId = fixture.row().getId().toString();
        long before = filteredCount(ownerId, docId, 1);
        indexService.index(fixture.user().getId(), fixture.row().getId());
        assertThat(filteredCount(ownerId, docId, 1)).isEqualTo(before);
    }

    @Test
    void retrievalPerformanceIsRecorded() throws Exception {
        Assumptions.assumeTrue(QDRANT_UP, "Qdrant localhost infra not running");
        Fixture fixture = setupIndexedDoc("retperf",
                List.of("Performance page one.", "Performance page two.",
                        "Performance page three."));
        long started = System.currentTimeMillis();
        var hits = retrievalService.retrieve(fixture.user().getId(), "performance pages",
                fixture.row().getId(), null, 5);
        long totalMs = System.currentTimeMillis() - started;
        assertThat(hits).isNotEmpty();
        System.out.println("[phase-g] chunks=" + hits.size() + " totalMs=" + totalMs);
    }
}
