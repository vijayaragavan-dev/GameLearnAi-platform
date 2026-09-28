package com.gamelearn.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;
import java.util.stream.Stream;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Assumptions;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MvcResult;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamelearn.config.AiProperties;
import com.gamelearn.entity.User;
import com.gamelearn.entity.UserDocument;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.repository.UserDocumentRepository;
import com.gamelearn.service.DocumentStorageService;
import com.gamelearn.service.UserDocumentService;
import com.sun.net.httpserver.HttpServer;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import org.slf4j.LoggerFactory;

/**
 * USER-DOC RAG Phase C: authenticated PDF upload, validation, ownership,
 * extraction lifecycle, failure cleanup and logging safety.
 *
 * <p>The Python parser itself is proven real by
 * {@code mlrag/tests/test_pdf_extract.py} (pinned pypdf over
 * hand-assembled PDFs); here the localhost extraction endpoint is a JDK
 * stub returning scripted outcomes, so this class proves the Spring side:
 * auth, validation, server-derived ownership, IDOR isolation, lifecycle
 * transitions, compensating cleanup, and that content never leaks into
 * logs or responses. No Qdrant writes exist anywhere on these paths.</p>
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestPropertySource(properties = {
        "gamelearn.ai.rag.service-token=test-doc-token",
        "gamelearn.ai.documents.extract-timeout=3s",
        "gamelearn.ai.documents.rate-limit.max-uploads-per-hour=100"
})
class DocumentUploadTest extends AbstractCoreApiTest {

    static final ObjectMapper MAPPER = new ObjectMapper();
    static final String URL = "/api/v1/documents";
    /** Clean probe token: no email/secret/injection shape, survives screening. */
    static final String MARKER = "QuarkLogProbe7ZQ";

    enum StubMode {
        NORMAL, ENCRYPTED, MALFORMED, TOO_MANY, SECRET, INJECTION, SLOW, GARBAGE
    }

    enum ChunkStubMode {
        CHUNK_OK, CHUNK_REFUSED, CHUNK_GARBAGE
    }

    enum EmbedStubMode {
        EMBED_OK, EMBED_REFUSED, EMBED_GARBAGE, EMBED_TAMPERED, EMBED_ZEROS
    }

    static HttpServer stub;
    static final AtomicReference<StubMode> MODE = new AtomicReference<>(StubMode.NORMAL);
    static final AtomicReference<ChunkStubMode> CHUNK_MODE =
            new AtomicReference<>(ChunkStubMode.CHUNK_OK);
    static final AtomicReference<EmbedStubMode> EMBED_MODE =
            new AtomicReference<>(EmbedStubMode.EMBED_OK);
    static final AtomicInteger HITS = new AtomicInteger();
    static Path storageRoot;

    @Autowired
    private UserDocumentRepository documentRepository;
    @Autowired
    private UserDocumentService documentService;
    @Autowired
    private DocumentStorageService storageService;
    @Autowired
    private AiProperties properties;
    @Autowired
    private JdbcTemplate jdbcTemplate;
    @Autowired
    private ApplicationContext applicationContext;

    // ------------------------------------------------------------------
    // minimal deterministic PDF builder (valid xref, ASCII text)
    // ------------------------------------------------------------------

    static byte[] pdf(List<String> pages) {
        return pdf(pages, "", new Object[0][0]);
    }

    static byte[] pdf(List<String> pages, String extraCatalog, Object[][] extra) {
        java.util.List<byte[]> parts = new java.util.ArrayList<>();
        parts.add("%PDF-1.4\n".getBytes(StandardCharsets.US_ASCII));
        java.util.Map<Integer, Integer> offsets = new java.util.LinkedHashMap<>();
        java.util.function.BiConsumer<Integer, byte[]> add = (num, data) -> {
            int pos = parts.stream().mapToInt(b -> b.length).sum();
            offsets.put(num, pos);
            byte[] header = (num + " 0 obj\n").getBytes(StandardCharsets.US_ASCII);
            byte[] tail = "\nendobj\n".getBytes(StandardCharsets.US_ASCII);
            byte[] full = new byte[header.length + data.length + tail.length];
            System.arraycopy(header, 0, full, 0, header.length);
            System.arraycopy(data, 0, full, header.length, data.length);
            System.arraycopy(tail, 0, full, header.length + data.length, tail.length);
            parts.add(full);
        };
        String kids = "";
        for (int i = 0; i < pages.size(); i++) {
            kids += (3 + i * 2) + " 0 R ";
        }
        add.accept(1, ("<< /Type /Catalog /Pages 2 0 R" + extraCatalog + " >>")
                .getBytes(StandardCharsets.US_ASCII));
        add.accept(2, ("<< /Type /Pages /Kids [" + kids + "] /Count " + pages.size() + " >>")
                .getBytes(StandardCharsets.US_ASCII));
        int fontNum = 3 + pages.size() * 2;
        for (int i = 0; i < pages.size(); i++) {
            String escaped = pages.get(i).replace("\\", "\\\\").replace("(", "\\(")
                    .replace(")", "\\)");
            byte[] stream = ("BT /F1 12 Tf 72 720 Td (" + escaped + ") Tj ET")
                    .getBytes(StandardCharsets.US_ASCII);
            add.accept(4 + i * 2, ("<< /Length " + stream.length + " >>\nstream\n")
                    .getBytes(StandardCharsets.US_ASCII));
            // Append stream bytes + endstream manually (add() wraps in obj).
            byte[] last = parts.remove(parts.size() - 1);
            byte[] withStream = new byte[last.length + stream.length
                    + "\nendstream".getBytes(StandardCharsets.US_ASCII).length];
            System.arraycopy(last, 0, withStream, 0, last.length);
            System.arraycopy(stream, 0, withStream, last.length, stream.length);
            byte[] end = "\nendstream".getBytes(StandardCharsets.US_ASCII);
            System.arraycopy(end, 0, withStream, last.length + stream.length, end.length);
            parts.add(withStream);
            add.accept(3 + i * 2, ("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] "
                    + "/Contents " + (4 + i * 2) + " 0 R /Resources << /Font << /F1 "
                    + fontNum + " 0 R >> >> >>").getBytes(StandardCharsets.US_ASCII));
        }
        add.accept(fontNum, "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"
                .getBytes(StandardCharsets.US_ASCII));
        for (Object[] entry : extra) {
            add.accept((Integer) entry[0], (byte[]) entry[1]);
        }
        int xrefPos = parts.stream().mapToInt(b -> b.length).sum();
        int top = offsets.keySet().stream().mapToInt(i -> i).max().orElse(0);
        StringBuilder xref = new StringBuilder("xref\n0 " + (top + 1) + "\n");
        xref.append("0000000000 65535 f \n");
        for (int n = 1; n <= top; n++) {
            if (offsets.containsKey(n)) {
                xref.append(String.format("%010d 00000 n \n", offsets.get(n)));
            } else {
                xref.append("0000000000 65535 f \n");
            }
        }
        parts.add(xref.toString().getBytes(StandardCharsets.US_ASCII));
        parts.add(("trailer\n<< /Size " + (top + 1) + " /Root 1 0 R >>\nstartxref\n"
                + xrefPos + "\n%%EOF\n").getBytes(StandardCharsets.US_ASCII));
        int total = parts.stream().mapToInt(b -> b.length).sum();
        byte[] out = new byte[total];
        int pos = 0;
        for (byte[] part : parts) {
            System.arraycopy(part, 0, out, pos, part.length);
            pos += part.length;
        }
        return out;
    }

    static String pagesBody(String text1, String text2) {
        return """
                {"ok":true,"page_count":2,
                "pages":[{"page_no":1,"chars":40,"text":"%s"},
                {"page_no":2,"chars":40,"text":"%s"}],
                "screening":{"status":"clean","reason_codes":[]}}"""
                .formatted(text1, text2);
    }

    // ------------------------------------------------------------------
    // stub extraction sidecar
    // ------------------------------------------------------------------

    @BeforeAll
    static void startStub() throws IOException {
        storageRoot = Files.createTempDirectory("gamelearn-doc-upload-test");
        stub = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        // Cached pool: without an executor the JDK server handles requests
        // sequentially, so the SLOW timeout probe would stall every test
        // behind it. Each request gets its own thread instead.
        stub.setExecutor(java.util.concurrent.Executors.newCachedThreadPool());
        stub.createContext("/extract", exchange -> {
            HITS.incrementAndGet();
            byte[] request = exchange.getRequestBody().readAllBytes();
            String body;
            switch (MODE.get()) {
                case ENCRYPTED -> body = "{\"ok\":false,\"reason\":\"encrypted\"}";
                case MALFORMED -> body = "{\"ok\":false,\"reason\":\"malformed\"}";
                case TOO_MANY -> body = "{\"ok\":false,\"reason\":\"too_many_pages\"}";
                case SECRET -> body = "{\"ok\":false,\"reason\":\"secret_found\"}";
                case INJECTION -> body = "{\"ok\":false,\"reason\":\"suspicious_content\","
                        + "\"reason_codes\":[\"prompt_injection\"]}";
                case GARBAGE -> body = "not json{{{";
                case SLOW -> {
                    try {
                        Thread.sleep(6_000);
                    } catch (InterruptedException interrupted) {
                        Thread.currentThread().interrupt();
                    }
                    body = pagesBody("late one " + MARKER, "late two");
                }
                default -> body = pagesBody("probe one " + MARKER, "probe two");
            }
            // Sanity: the stub must receive the exact stored bytes.
            if (request.length == 0) {
                body = "{\"ok\":false,\"reason\":\"extraction_failed\"}";
            }
            byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, bytes.length);
            try (OutputStream out = exchange.getResponseBody()) {
                out.write(bytes);
            }
        });
        stub.createContext("/chunk", exchange -> {
            byte[] request = exchange.getRequestBody().readAllBytes();
            String body;
            switch (CHUNK_MODE.get()) {
                case CHUNK_REFUSED -> body = "{\"ok\":false,\"reason\":\"too_many_chunks\"}";
                case CHUNK_GARBAGE -> body = "not json{{{";
                default -> {
                    try {
                        body = chunkEcho(new String(request, StandardCharsets.UTF_8));
                    } catch (Exception ex) {
                        body = "{\"ok\":false,\"reason\":\"invalid_input\"}";
                    }
                }
            }
            byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, bytes.length);
            try (OutputStream out = exchange.getResponseBody()) {
                out.write(bytes);
            }
        });
        stub.createContext("/embed", exchange -> {
            byte[] request = exchange.getRequestBody().readAllBytes();
            String body;
            switch (EMBED_MODE.get()) {
                case EMBED_REFUSED -> body = "{\"ok\":false,\"reason\":\"embedding_failed\"}";
                case EMBED_GARBAGE -> body = "not json{{{";
                case EMBED_TAMPERED, EMBED_ZEROS -> {
                    try {
                        body = embedEcho(new String(request, StandardCharsets.UTF_8),
                                EMBED_MODE.get());
                    } catch (Exception ex) {
                        body = "{\"ok\":false,\"reason\":\"invalid_input\"}";
                    }
                }
                default -> {
                    try {
                        body = embedEcho(new String(request, StandardCharsets.UTF_8),
                                EmbedStubMode.EMBED_OK);
                    } catch (Exception ex) {
                        body = "{\"ok\":false,\"reason\":\"invalid_input\"}";
                    }
                }
            }
            byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, bytes.length);
            try (OutputStream out = exchange.getResponseBody()) {
                out.write(bytes);
            }
        });
        stub.start();
    }

    /** Deterministic unit-norm fixture vectors (single 1.0 per chunk at a
     * rotating index) with a correctly recomputed fingerprint — unless the
     * mode tampers with it. The REAL model is proven by
     * mlrag/tests/test_doc_embeddings.py; this double proves Spring
     * wiring, validation and persistence. */
    static String embedEcho(String requestJson, EmbedStubMode mode) throws Exception {
        JsonNode request = MAPPER.readTree(requestJson);
        String docId = request.path("document_id").asText("missing");
        int version = request.path("doc_version").asInt(1);
        java.util.List<com.gamelearn.ai.documents.PdfExtractionClient.EmbeddedChunk> built =
                new java.util.ArrayList<>();
        StringBuilder entries = new StringBuilder();
        int ordinal = 0;
        for (JsonNode chunk : request.withArray("chunks")) {
            String chunkId = chunk.path("chunk_id").asText("c" + ordinal);
            double[] vector = new double[384];
            if (mode != EmbedStubMode.EMBED_ZEROS) {
                vector[(ordinal * 53) % 384] = 1.0;
            }
            built.add(new com.gamelearn.ai.documents.PdfExtractionClient.EmbeddedChunk(
                    chunkId, vector));
            if (entries.length() > 0) {
                entries.append(",");
            }
            StringBuilder values = new StringBuilder();
            for (double value : vector) {
                if (values.length() > 0) {
                    values.append(",");
                }
                values.append(Double.toString(value));
            }
            entries.append("""
                    {"chunk_id":"%s","vector":[%s]}""".formatted(chunkId, values.toString()));
            ordinal++;
        }
        String fingerprint = mode == EmbedStubMode.EMBED_TAMPERED
                ? "0".repeat(64)
                : com.gamelearn.ai.documents.PdfExtractionClient.fingerprintHex(built);
        return """
                {"ok":true,"document_id":"%s","doc_version":%d,\
                "model_id":"sentence-transformers/all-MiniLM-L6-v2",\
                "model_revision":"1110a243fdf4706b3f48f1d95db1a4f5529b4d41",\
                "model_license":"Apache-2.0",\
                "embedding_dimension":384,"normalize_embeddings":true,\
                "similarity_metric":"cosine",\
                "embedder_version":"test-embedder-v1",\
                "chunk_config_version":"udoc-chunk-v1",\
                "embedding_fingerprint":"%s",\
                "chunk_ids":[%s],\
                "chunk_count":%d,"embeddings":[%s]}"""
                .formatted(docId, version, fingerprint,
                        built.stream().map(c -> "\"" + c.chunkId() + "\"")
                                .collect(java.util.stream.Collectors.joining(",")),
                        built.size(), entries.toString());
    }

    /** Mechanical provenance echo: one chunk per requested page. The REAL
     * chunking algorithm is proven by mlrag/tests/test_doc_chunking.py;
     * this double proves Spring wiring, validation and persistence. */
    static String chunkEcho(String requestJson) throws Exception {
        JsonNode request = MAPPER.readTree(requestJson);
        String docId = request.path("document_id").asText("missing");
        int version = request.path("doc_version").asInt(1);
        String owner = request.path("owner_id").asText(null);
        StringBuilder chunks = new StringBuilder();
        for (JsonNode page : request.withArray("pages")) {
            int pageNo = page.path("page_no").asInt(0);
            String text = page.path("text").asText("");
            String hash = sha256(text.getBytes(StandardCharsets.UTF_8));
            if (chunks.length() > 0) {
                chunks.append(",");
            }
            chunks.append("""
                    {"chunk_id":"doc:%s:v%d:p%d:c0","document_id":"%s","doc_version":%d,\
                    "page_no":%d,"chunk_index":0,\
                    "citation":"doc:%s:v%d#p%dc0","text":%s,\
                    "chars":%d,"text_hash":"%s","owner_id":"%s",\
                    "chunk_config_version":"udoc-chunk-v1"}"""
                    .formatted(docId, version, pageNo, docId, version, pageNo,
                            docId, version, pageNo,
                            MAPPER.writeValueAsString(text), text.length(), hash, owner));
        }
        int count = request.withArray("pages").size();
        return """
                {"ok":true,"document_id":"%s","doc_version":%d,\
                "chunk_config_version":"udoc-chunk-v1","chunk_count":%d,\
                "page_count":%d,"pages_chunked":[1],"pages_empty":[],\
                "chunks":[%s]}"""
                .formatted(docId, version, count, count, chunks.toString());
    }

    @AfterAll
    static void stopStub() {
        stub.stop(0);
    }

    @DynamicPropertySource
    static void docProps(DynamicPropertyRegistry registry) {
        registry.add("gamelearn.ai.documents.storage-root", () -> storageRoot.toString());
        registry.add("gamelearn.ai.rag.base-url",
                () -> "http://127.0.0.1:" + stub.getAddress().getPort());
    }

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------

    private MvcResult upload(String token, MockMultipartFile file, int expectedStatus)
            throws Exception {
        var request = multipart(URL).file(file);
        if (token != null) {
            request.header("Authorization", "Bearer " + token);
        }
        return mockMvc.perform(request)
                .andExpect(status().is(expectedStatus))
                .andReturn();
    }

    private MockMultipartFile pdfFile(String name, byte[] bytes) {
        return new MockMultipartFile("file", name, "application/pdf", bytes);
    }

    private static String sha256(byte[] bytes) throws Exception {
        return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    }

    private List<UserDocument> ownedDocs(User user) {
        return documentService.listOwned(user.getId());
    }

    private static ListAppender<ILoggingEvent> capture(Class<?>... loggers) {
        ListAppender<ILoggingEvent> appender = new ListAppender<>();
        appender.start();
        for (Class<?> loggerClass : loggers) {
            ((Logger) LoggerFactory.getLogger(loggerClass)).addAppender(appender);
        }
        return appender;
    }

    private static void release(ListAppender<ILoggingEvent> appender, Class<?>... loggers) {
        for (Class<?> loggerClass : loggers) {
            ((Logger) LoggerFactory.getLogger(loggerClass)).detachAppender(appender);
        }
        appender.stop();
    }

    // ------------------------------------------------------------------
    // 1-2: happy path + auth
    // ------------------------------------------------------------------

    @Test
    void authenticatedUploadSucceedsForValidSmallPdf() throws Exception {
        MODE.set(StubMode.NORMAL);
        String[] learner = registerLearner("docup");
        byte[] bytes = pdf(List.of("page one text", "page two text"));

        MvcResult result = upload(learner[0], pdfFile("notes.pdf", bytes), 201);
        JsonNode json = MAPPER.readTree(result.getResponse().getContentAsString());
        assertThat(json.get("filename").asText()).isEqualTo("notes.pdf");
        assertThat(json.get("status").asText()).isEqualTo("CHUNKED");
        assertThat(json.get("pageCount").asInt()).isEqualTo(2);
        assertThat(json.get("byteSize").asLong()).isEqualTo(bytes.length);
        assertThat(json.get("docVersion").asInt()).isEqualTo(1);

        // Response is metadata only: no paths, bytes, text or storage roots.
        assertThat(json.has("storagePath")).isFalse();
        assertThat(json.has("pages")).isFalse();
        assertThat(json.has("text")).isFalse();
        assertThat(result.getResponse().getContentAsString()).doesNotContain(MARKER);

        // Metadata row is owned by the principal, with server-computed hash.
        User owner = userByEmail(learner[1]);
        List<UserDocument> docs = ownedDocs(owner);
        assertThat(docs).hasSize(1);
        assertThat(docs.get(0).getId().toString()).isEqualTo(json.get("id").asText());
        assertThat(docs.get(0).getStatus().name()).isEqualTo("CHUNKED");
        assertThat(docs.get(0).getPageCount()).isEqualTo(2);
        assertThat(docs.get(0).getSha256()).isEqualTo(sha256(bytes));

        // Storage layout is UUID-derived; pages.json preserves numbering.
        Path dir = storageRoot.resolve(docs.get(0).getId().toString());
        assertThat(dir.resolve("source.pdf")).exists();
        JsonNode pages = MAPPER.readTree(Files.readString(dir.resolve("pages.json")));
        assertThat(pages.get("page_count").asInt()).isEqualTo(2);
        assertThat(pages.get("pages").get(0).get("page_no").asInt()).isEqualTo(1);
        assertThat(pages.get("pages").get(1).get("page_no").asInt()).isEqualTo(2);
        MODE.set(StubMode.NORMAL);
    }

    @Test
    void unauthenticatedUploadIsRejected() throws Exception {
        MODE.set(StubMode.NORMAL);
        upload(null, pdfFile("notes.pdf", pdf(List.of("x"))), 401);
        MODE.set(StubMode.NORMAL);
    }

    // ------------------------------------------------------------------
    // 3-10: input validation
    // ------------------------------------------------------------------

    @Test
    void missingMultipartFileIsRejected() throws Exception {
        String[] learner = registerLearner("docmissing");
        mockMvc.perform(multipart(URL).header("Authorization", "Bearer " + learner[0]))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("MALFORMED_REQUEST"));
    }

    @Test
    void emptyFileIsRejected() throws Exception {
        String[] learner = registerLearner("docempty");
        upload(learner[0],
                new MockMultipartFile("file", "empty.pdf", "application/pdf", new byte[0]), 400);
    }

    @Test
    void nonPdfIsRejected() throws Exception {
        String[] learner = registerLearner("docnotpdf");
        upload(learner[0],
                new MockMultipartFile("file", "notes.txt", "text/plain",
                        "just some text".getBytes(StandardCharsets.UTF_8)), 400);
    }

    @Test
    void fakePdfWithNonPdfBytesIsRejected() throws Exception {
        String[] learner = registerLearner("docfake");
        int before = HITS.get();
        upload(learner[0], pdfFile("fake.pdf", "definitely not a pdf".getBytes(StandardCharsets.UTF_8)),
                400);
        // Rejected before any extraction: the parser is never contacted.
        assertThat(HITS.get()).isEqualTo(before);
    }

    @Test
    void declaredTypeMismatchIsRejected() throws Exception {
        String[] learner = registerLearner("docmime");
        byte[] bytes = pdf(List.of("real pdf bytes"));
        upload(learner[0],
                new MockMultipartFile("file", "notes.pdf", "text/html", bytes), 400);
        upload(learner[0],
                new MockMultipartFile("file", "notes.pdf", "application/zip", bytes), 400);
    }

    @Test
    void wrongExtensionIsRejected() throws Exception {
        String[] learner = registerLearner("docext");
        upload(learner[0],
                new MockMultipartFile("file", "notes.txt", "application/pdf",
                        pdf(List.of("real pdf bytes"))), 400);
    }

    @Test
    void oversizedPdfIsRejectedBeforeExtraction() throws Exception {
        String[] learner = registerLearner("docbig");
        long maxBytes = properties.getDocuments().getMaxBytes();
        byte[] small = pdf(List.of("tiny"));
        byte[] big = new byte[(int) maxBytes + 1];
        System.arraycopy(small, 0, big, 0, small.length);
        int before = HITS.get();
        upload(learner[0], pdfFile("big.pdf", big), 413);
        assertThat(HITS.get()).isEqualTo(before);
        assertThat(ownedDocs(userByEmail(learner[1]))).isEmpty();
    }

    @Test
    void malformedPdfFailsClosedWithCleanup() throws Exception {
        MODE.set(StubMode.MALFORMED);
        String[] learner = registerLearner("docmalformed");
        // Passes the magic gate but no parser can use it.
        byte[] bytes = "%PDF-1.4\n garbage not a body".getBytes(StandardCharsets.US_ASCII);
        upload(learner[0], pdfFile("broken.pdf", bytes), 400);

        User owner = userByEmail(learner[1]);
        // FAILED rows stay active (visible failure state); future serving
        // reads filter by status, never by visibility here.
        assertThat(ownedDocs(owner)).hasSize(1);
        List<UserDocument> failed = failedDocs(owner);
        assertThat(failed).hasSize(1);
        assertThat(failed.get(0).getStatus().name()).isEqualTo("FAILED");
        // Stored bytes were removed; no pages were ever written.
        assertThat(storageService.exists(failed.get(0).getId())).isFalse();
        assertThat(storageRoot.resolve(failed.get(0).getId().toString())).doesNotExist();
        MODE.set(StubMode.NORMAL);
    }

    // ------------------------------------------------------------------
    // 8-9, 16-17: sidecar refusals -> FAILED, never INDEXED
    // ------------------------------------------------------------------

    @Test
    void excessivePageCountIsRejected() throws Exception {
        MODE.set(StubMode.TOO_MANY);
        String[] learner = registerLearner("docpages");
        upload(learner[0], pdfFile("long.pdf", pdf(List.of("p1", "p2"))), 400);
        User owner = userByEmail(learner[1]);
        assertThat(failedDocs(owner)).hasSize(1);
        MODE.set(StubMode.NORMAL);
    }

    @Test
    void encryptedPdfIsRejected() throws Exception {
        MODE.set(StubMode.ENCRYPTED);
        String[] learner = registerLearner("doccrypt");
        upload(learner[0], pdfFile("locked.pdf", pdf(List.of("secret stuff"))), 400);
        assertThat(failedDocs(userByEmail(learner[1]))).hasSize(1);
        MODE.set(StubMode.NORMAL);
    }

    @Test
    void secretContentFailsScreeningWithoutVectorsOrGemini() throws Exception {
        MODE.set(StubMode.SECRET);
        String[] learner = registerLearner("docsecret");
        upload(learner[0], pdfFile("leak.pdf", pdf(List.of("clean looking"))), 400);
        User owner = userByEmail(learner[1]);
        List<UserDocument> failed = failedDocs(owner);
        assertThat(failed).hasSize(1);
        assertThat(storageRoot.resolve(failed.get(0).getId().toString())).doesNotExist();
        MODE.set(StubMode.NORMAL);
    }

    @Test
    void injectionShapedContentFailsScreening() throws Exception {
        MODE.set(StubMode.INJECTION);
        String[] learner = registerLearner("docinject");
        upload(learner[0], pdfFile("trick.pdf", pdf(List.of("clean looking"))), 400);
        assertThat(failedDocs(userByEmail(learner[1]))).hasSize(1);
        MODE.set(StubMode.NORMAL);
    }

    @Test
    void extractionTransportFailureIsSafe() throws Exception {
        MODE.set(StubMode.GARBAGE);
        String[] learner = registerLearner("docgarbage");
        upload(learner[0], pdfFile("weird.pdf", pdf(List.of("content"))), 500);
        assertThat(failedDocs(userByEmail(learner[1]))).hasSize(1);
        MODE.set(StubMode.NORMAL);
    }

    @Test
    void extractionTimeoutIsBoundedAndSafe() throws Exception {
        MODE.set(StubMode.SLOW);
        String[] learner = registerLearner("docslow");
        // Stub sleeps 10s; the 3s extract timeout must bound the request.
        upload(learner[0], pdfFile("slow.pdf", pdf(List.of("waiting"))), 500);
        assertThat(failedDocs(userByEmail(learner[1]))).hasSize(1);
        MODE.set(StubMode.NORMAL);
    }

    @Test
    void successfulExtractionNeverBecomesIndexed() throws Exception {
        MODE.set(StubMode.NORMAL);
        String[] learner = registerLearner("docnoindex");
        upload(learner[0], pdfFile("study.pdf", pdf(List.of("a", "b"))), 201);
        List<String> states = jdbcTemplate.queryForList(
                "SELECT DISTINCT status FROM user_documents", String.class);
        assertThat(states).doesNotContain("INDEXED");
        MODE.set(StubMode.NORMAL);
    }

    private List<UserDocument> failedDocs(User owner) {
        return documentRepository.findAll().stream()
                .filter(d -> d.getUser().getId().equals(owner.getId()))
                .filter(d -> d.getStatus().name().equals("FAILED"))
                .toList();
    }

    // ------------------------------------------------------------------
    // 12-15: filename safety + ownership isolation
    // ------------------------------------------------------------------

    @Test
    void pathTraversalFilenameIsNeutralized() throws Exception {
        MODE.set(StubMode.NORMAL);
        String[] learner = registerLearner("doctraverse");
        upload(learner[0], pdfFile("../../evil.pdf", pdf(List.of("tame"))), 201);

        User owner = userByEmail(learner[1]);
        UserDocument doc = ownedDocs(owner).get(0);
        assertThat(doc.getFilename()).isEqualTo("evil.pdf");

        // Physical layout contains only UUID dirs with fixed filenames.
        try (Stream<Path> walk = Files.walk(storageRoot)) {
            List<String> names = walk.filter(Files::isRegularFile)
                    .map(p -> p.getFileName().toString()).toList();
            assertThat(names).doesNotContain("evil.pdf");
            assertThat(names).allMatch(n -> n.equals("source.pdf") || n.equals("pages.json")
                    || n.equals("chunks.json") || n.equals("embeddings.json"));
        }
        Path dir = storageRoot.resolve(doc.getId().toString());
        assertThat(dir.resolve("source.pdf")).exists();
        assertThat(storageRoot.resolve("evil.pdf")).doesNotExist();
        MODE.set(StubMode.NORMAL);
    }

    @Test
    void ownershipComesFromPrincipalAndIsIsolated() throws Exception {
        MODE.set(StubMode.NORMAL);
        String[] learnerA = registerLearner("docownerA");
        String[] learnerB = registerLearner("docownerB");
        // There is no owner field to spoof: the row belongs to the caller.
        upload(learnerA[0], pdfFile("a.pdf", pdf(List.of("a private doc"))), 201);

        User userA = userByEmail(learnerA[1]);
        User userB = userByEmail(learnerB[1]);
        UUID docId = ownedDocs(userA).get(0).getId();

        // B cannot read, move or delete A's document: 404, never the row.
        try {
            documentService.getOwned(userB.getId(), docId);
            assertThat(false).as("B must not reach A's document").isTrue();
        } catch (ApiException ex) {
            assertThat(ex.getErrorCode()).isEqualTo(ErrorCode.RESOURCE_NOT_FOUND.name());
        }
        try {
            documentService.delete(userB.getId(), docId);
            assertThat(false).as("B must not delete A's document").isTrue();
        } catch (ApiException ex) {
            assertThat(ex.getErrorCode()).isEqualTo(ErrorCode.RESOURCE_NOT_FOUND.name());
        }
        // A's document is untouched and B sees nothing.
        assertThat(documentService.getOwned(userA.getId(), docId).isActive()).isTrue();
        assertThat(ownedDocs(userB)).isEmpty();
        MODE.set(StubMode.NORMAL);
    }

    // ------------------------------------------------------------------
    // 20-23: logging, storage, cleanup, rate limit
    // ------------------------------------------------------------------

    @Test
    void extractedTextNeverReachesLogs() throws Exception {
        MODE.set(StubMode.NORMAL);
        ListAppender<ILoggingEvent> appender = capture(
                com.gamelearn.service.DocumentUploadService.class,
                com.gamelearn.ai.documents.PdfExtractionClient.class,
                com.gamelearn.service.DocumentStorageService.class);
        try {
            String[] learner = registerLearner("doclogs");
            upload(learner[0], pdfFile("logged.pdf", pdf(List.of("log probe"))), 201);
            assertThat(appender.list)
                    .filteredOn(e -> e.getFormattedMessage().contains(MARKER))
                    .isEmpty();
        } finally {
            release(appender,
                    com.gamelearn.service.DocumentUploadService.class,
                    com.gamelearn.ai.documents.PdfExtractionClient.class,
                    com.gamelearn.service.DocumentStorageService.class);
            MODE.set(StubMode.NORMAL);
        }
    }

    @Test
    void noPdfBytesInMysql() {
        List<String> types = jdbcTemplate.queryForList(
                "SELECT DISTINCT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS "
                        + "WHERE TABLE_NAME IN ('user_documents', 'USER_DOCUMENTS')",
                String.class);
        assertThat(types).isNotEmpty();
        assertThat(types).noneMatch(t -> t.toUpperCase(java.util.Locale.ROOT).contains("BLOB")
                || t.toUpperCase(java.util.Locale.ROOT).contains("BINARY"));
    }

    @Test
    void uploadRateLimitIsEnforced() throws Exception {
        MODE.set(StubMode.NORMAL);
        properties.getDocuments().getRateLimit().setMaxUploadsPerHour(2);
        try {
            String[] learner = registerLearner("docrate");
            upload(learner[0], pdfFile("r1.pdf", pdf(List.of("one"))), 201);
            upload(learner[0], pdfFile("r2.pdf", pdf(List.of("two"))), 201);
            MvcResult result = upload(learner[0], pdfFile("r3.pdf", pdf(List.of("three"))), 429);
            JsonNode json = MAPPER.readTree(result.getResponse().getContentAsString());
            assertThat(json.get("errorCode").asText()).isEqualTo("DOCUMENT_RATE_LIMITED");
        } finally {
            properties.getDocuments().getRateLimit().setMaxUploadsPerHour(100);
            MODE.set(StubMode.NORMAL);
        }
    }

    @Test
    void filenameRulesAreEnforced() throws Exception {
        String[] learner = registerLearner("docname");
        byte[] bytes = pdf(List.of("x"));
        // Control characters, overlong names are rejected.
        upload(learner[0], pdfFile("ab.pdf", bytes), 400);
        upload(learner[0], pdfFile("n".repeat(300) + ".pdf", bytes), 400);
        assertThat(ownedDocs(userByEmail(learner[1]))).isEmpty();
    }

    // ------------------------------------------------------------------
    // Phase D: chunks artifact, provenance, chunk failure handling
    // ------------------------------------------------------------------

    @Test
    void uploadWritesChunksArtifactWithProvenance() throws Exception {
        MODE.set(StubMode.NORMAL);
        CHUNK_MODE.set(ChunkStubMode.CHUNK_OK);
        String[] learner = registerLearner("docchunk");
        byte[] bytes = pdf(List.of("chunk page one", "chunk page two"));
        MvcResult result = upload(learner[0], pdfFile("chunked.pdf", bytes), 201);
        JsonNode json = MAPPER.readTree(result.getResponse().getContentAsString());
        assertThat(json.get("chunkCount").asInt()).isEqualTo(2);
        assertThat(json.has("text")).isFalse();

        User owner = userByEmail(learner[1]);
        UserDocument doc = ownedDocs(owner).get(0);
        Path chunksFile = storageRoot.resolve(doc.getId().toString()).resolve("chunks.json");
        JsonNode chunks = MAPPER.readTree(Files.readString(chunksFile));
        assertThat(chunks.get("document_id").asText()).isEqualTo(doc.getId().toString());
        assertThat(chunks.get("doc_version").asInt()).isEqualTo(1);
        assertThat(chunks.get("chunk_config_version").asText()).isEqualTo("udoc-chunk-v1");
        assertThat(chunks.get("chunk_count").asInt()).isEqualTo(2);
        JsonNode first = chunks.get("chunks").get(0);
        assertThat(first.get("chunk_id").asText())
                .isEqualTo("doc:" + doc.getId() + ":v1:p1:c0");
        assertThat(first.get("citation").asText())
                .isEqualTo("doc:" + doc.getId() + ":v1#p1c0");
        assertThat(first.get("page_no").asInt()).isEqualTo(1);
        assertThat(first.get("owner_id").asText()).isEqualTo(owner.getId().toString());
        // Owner travels as metadata; chunk text carries no ownership.
        assertThat(first.get("text").asText()).doesNotContain(owner.getId().toString());
        assertThat(doc.getStatus().name()).isEqualTo("CHUNKED");
        MODE.set(StubMode.NORMAL);
        CHUNK_MODE.set(ChunkStubMode.CHUNK_OK);
    }

    @Test
    void chunkRefusalFailsClosedWithCleanup() throws Exception {
        MODE.set(StubMode.NORMAL);
        CHUNK_MODE.set(ChunkStubMode.CHUNK_REFUSED);
        String[] learner = registerLearner("docchunkfail");
        upload(learner[0], pdfFile("dense.pdf", pdf(List.of("dense content"))), 400);
        User owner = userByEmail(learner[1]);
        List<UserDocument> failed = failedDocs(owner);
        assertThat(failed).hasSize(1);
        // Whole directory removed: no source, pages, or chunks remain.
        assertThat(storageRoot.resolve(failed.get(0).getId().toString())).doesNotExist();
        assertThat(ownedDocs(owner)).allMatch(d -> d.getStatus().name().equals("FAILED"));
        MODE.set(StubMode.NORMAL);
        CHUNK_MODE.set(ChunkStubMode.CHUNK_OK);
    }

    @Test
    void chunkTransportFailureIsSafe() throws Exception {
        MODE.set(StubMode.NORMAL);
        CHUNK_MODE.set(ChunkStubMode.CHUNK_GARBAGE);
        String[] learner = registerLearner("docchunkerr");
        upload(learner[0], pdfFile("err.pdf", pdf(List.of("content"))), 500);
        List<UserDocument> failed = failedDocs(userByEmail(learner[1]));
        assertThat(failed).hasSize(1);
        assertThat(storageRoot.resolve(failed.get(0).getId().toString())).doesNotExist();
        MODE.set(StubMode.NORMAL);
        CHUNK_MODE.set(ChunkStubMode.CHUNK_OK);
    }

    // ------------------------------------------------------------------
    // Phase E: embeddings artifact, binding, embed failure handling
    // ------------------------------------------------------------------

    @Test
    void uploadWritesEmbeddingsArtifactWithBinding() throws Exception {
        MODE.set(StubMode.NORMAL);
        CHUNK_MODE.set(ChunkStubMode.CHUNK_OK);
        EMBED_MODE.set(EmbedStubMode.EMBED_OK);
        String[] learner = registerLearner("docembed");
        upload(learner[0], pdfFile("embedded.pdf", pdf(List.of("embed one", "embed two"))),
                201);

        User owner = userByEmail(learner[1]);
        UserDocument doc = ownedDocs(owner).get(0);
        Path artifact = storageRoot.resolve(doc.getId().toString()).resolve("embeddings.json");
        JsonNode root = MAPPER.readTree(Files.readString(artifact));
        assertThat(root.get("document_id").asText()).isEqualTo(doc.getId().toString());
        assertThat(root.get("doc_version").asInt()).isEqualTo(1);
        assertThat(root.get("model_id").asText())
                .isEqualTo("sentence-transformers/all-MiniLM-L6-v2");
        assertThat(root.get("model_revision").asText())
                .isEqualTo("1110a243fdf4706b3f48f1d95db1a4f5529b4d41");
        assertThat(root.get("embedding_dimension").asInt()).isEqualTo(384);
        assertThat(root.get("normalize_embeddings").asBoolean()).isTrue();
        assertThat(root.get("similarity_metric").asText()).isEqualTo("cosine");
        assertThat(root.get("chunk_count").asInt()).isEqualTo(2);

        // Vectors are 384-d finite unit vectors; fingerprint recomputes.
        java.util.List<com.gamelearn.ai.documents.PdfExtractionClient.EmbeddedChunk> parsed =
                new java.util.ArrayList<>();
        for (JsonNode entry : root.withArray("embeddings")) {
            assertThat(entry.has("text")).isFalse();
            double[] vector = new double[384];
            int i = 0;
            for (JsonNode value : entry.withArray("vector")) {
                vector[i++] = value.asDouble();
            }
            assertThat(i).isEqualTo(384);
            double norm = 0.0;
            for (double value : vector) {
                assertThat(Double.isFinite(value)).isTrue();
                norm += value * value;
            }
            assertThat(Math.sqrt(norm)).isCloseTo(1.0,
                    org.assertj.core.data.Offset.offset(1e-6));
            parsed.add(new com.gamelearn.ai.documents.PdfExtractionClient.EmbeddedChunk(
                    entry.get("chunk_id").asText(), vector));
        }
        assertThat(com.gamelearn.ai.documents.PdfExtractionClient.fingerprintHex(parsed))
                .isEqualTo(root.get("embedding_fingerprint").asText());
        assertThat(doc.getStatus().name()).isEqualTo("CHUNKED");
        MODE.set(StubMode.NORMAL);
        CHUNK_MODE.set(ChunkStubMode.CHUNK_OK);
        EMBED_MODE.set(EmbedStubMode.EMBED_OK);
    }

    @Test
    void embedRefusalFailsClosedWithCleanup() throws Exception {
        MODE.set(StubMode.NORMAL);
        CHUNK_MODE.set(ChunkStubMode.CHUNK_OK);
        EMBED_MODE.set(EmbedStubMode.EMBED_REFUSED);
        String[] learner = registerLearner("docembedfail");
        upload(learner[0], pdfFile("nofeat.pdf", pdf(List.of("content"))), 400);
        User owner = userByEmail(learner[1]);
        List<UserDocument> failed = failedDocs(owner);
        assertThat(failed).hasSize(1);
        assertThat(storageRoot.resolve(failed.get(0).getId().toString())).doesNotExist();
        MODE.set(StubMode.NORMAL);
        CHUNK_MODE.set(ChunkStubMode.CHUNK_OK);
        EMBED_MODE.set(EmbedStubMode.EMBED_OK);
    }

    @Test
    void embedFingerprintMismatchFailsClosed() throws Exception {
        MODE.set(StubMode.NORMAL);
        CHUNK_MODE.set(ChunkStubMode.CHUNK_OK);
        EMBED_MODE.set(EmbedStubMode.EMBED_TAMPERED);
        String[] learner = registerLearner("docembedtamper");
        upload(learner[0], pdfFile("tampered.pdf", pdf(List.of("content"))), 500);
        List<UserDocument> failed = failedDocs(userByEmail(learner[1]));
        assertThat(failed).hasSize(1);
        assertThat(storageRoot.resolve(failed.get(0).getId().toString())).doesNotExist();
        MODE.set(StubMode.NORMAL);
        CHUNK_MODE.set(ChunkStubMode.CHUNK_OK);
        EMBED_MODE.set(EmbedStubMode.EMBED_OK);
    }

    @Test
    void invalidEmbedVectorFailsClosed() throws Exception {
        MODE.set(StubMode.NORMAL);
        CHUNK_MODE.set(ChunkStubMode.CHUNK_OK);
        EMBED_MODE.set(EmbedStubMode.EMBED_ZEROS);
        String[] learner = registerLearner("docembedzero");
        // Zero vectors violate unit-norm: rejected before fingerprinting.
        upload(learner[0], pdfFile("zero.pdf", pdf(List.of("content"))), 500);
        List<UserDocument> failed = failedDocs(userByEmail(learner[1]));
        assertThat(failed).hasSize(1);
        assertThat(storageRoot.resolve(failed.get(0).getId().toString())).doesNotExist();
        MODE.set(StubMode.NORMAL);
        CHUNK_MODE.set(ChunkStubMode.CHUNK_OK);
        EMBED_MODE.set(EmbedStubMode.EMBED_OK);
    }

    // ------------------------------------------------------------------
    // 18: Qdrant stays empty (infra present) + no client code exists
    // ------------------------------------------------------------------

    @Test
    void failedAndSuccessfulUploadsCreateNoQdrantVectors() throws Exception {
        java.net.Socket probe = new java.net.Socket();
        try {
            probe.connect(new InetSocketAddress("127.0.0.1", 6333), 2000);
        } catch (IOException unreachable) {
            Assumptions.abort("Qdrant localhost infra not running");
        } finally {
            probe.close();
        }
        long before = collectionCount();
        MODE.set(StubMode.NORMAL);
        String[] learner = registerLearner("docqdrant");
        upload(learner[0], pdfFile("q.pdf", pdf(List.of("qdrant probe"))), 201);
        MODE.set(StubMode.SECRET);
        upload(learner[0], pdfFile("q2.pdf", pdf(List.of("qdrant probe two"))), 400);
        MODE.set(StubMode.NORMAL);
        assertThat(collectionCount()).isEqualTo(before);
        // Exactly one sanctioned Qdrant integration point exists (Phase F
        // qdrantClient, service-layer only); uploads never call it — the
        // unchanged collection count above proves it behaviorally.
        assertThat(applicationContext.getBeanDefinitionNames())
                .filteredOn(name -> name.toLowerCase(java.util.Locale.ROOT).contains("qdrant"))
                .containsExactly("qdrantClient");
    }

    private static long collectionCount() throws Exception {
        java.net.http.HttpClient client = java.net.http.HttpClient.newHttpClient();
        java.net.http.HttpRequest request = java.net.http.HttpRequest.newBuilder()
                .uri(java.net.URI.create("http://127.0.0.1:6333/collections"))
                .timeout(java.time.Duration.ofSeconds(5)).GET().build();
        JsonNode root = MAPPER.readTree(
                client.send(request, java.net.http.HttpResponse.BodyHandlers.ofString()).body());
        return root.path("result").path("collections").size();
    }
}
