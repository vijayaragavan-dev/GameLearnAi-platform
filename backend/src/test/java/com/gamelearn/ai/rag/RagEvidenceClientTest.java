package com.gamelearn.ai.rag;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.concurrent.atomic.AtomicReference;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import com.sun.net.httpserver.HttpServer;

import com.gamelearn.config.AiProperties;

/**
 * Gate 23: RagEvidenceClient boundary tests (no Spring context).
 * A JDK stub stands in for the sidecar; transport mapping, strict
 * parsing and citation-shape rejection are asserted here.
 */
class RagEvidenceClientTest {

    private HttpServer stub;
    private final AtomicReference<StubBehavior> behavior =
            new AtomicReference<>(StubBehavior.SERVED);
    private String baseUrl;

    enum StubBehavior {
        SERVED, UNSERVED, MALFORMED, BAD_CITATION, UNAUTHORIZED, SERVER_ERROR, SLOW
    }

    @BeforeEach
    void startStub() throws IOException {
        stub = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        stub.createContext("/retrieve", exchange -> {
            byte[] body;
            int status = 200;
            switch (behavior.get()) {
                case SERVED -> body = servedBundle().getBytes(StandardCharsets.UTF_8);
                case UNSERVED -> body = unservedBundle().getBytes(StandardCharsets.UTF_8);
                case MALFORMED -> body = "{not json".getBytes(StandardCharsets.UTF_8);
                case BAD_CITATION -> body = badCitationBundle().getBytes(StandardCharsets.UTF_8);
                case UNAUTHORIZED -> {
                    status = 401;
                    body = "{\"error\":\"unauthorized\"}".getBytes(StandardCharsets.UTF_8);
                }
                case SERVER_ERROR -> {
                    status = 503;
                    body = "{\"error\":\"retrieval_unavailable\"}".getBytes(StandardCharsets.UTF_8);
                }
                case SLOW -> {
                    try {
                        Thread.sleep(1500);
                    } catch (InterruptedException interrupted) {
                        Thread.currentThread().interrupt();
                    }
                    body = servedBundle().getBytes(StandardCharsets.UTF_8);
                }
                default -> body = new byte[0];
            }
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(status, body.length);
            try (OutputStream out = exchange.getResponseBody()) {
                out.write(body);
            }
        });
        stub.start();
        baseUrl = "http://127.0.0.1:" + stub.getAddress().getPort();
    }

    @AfterEach
    void stopStub() {
        stub.stop(0);
    }

    private AiProperties properties() {
        AiProperties properties = new AiProperties();
        properties.getRag().setBaseUrl(baseUrl);
        properties.getRag().setServiceToken("test-token");
        properties.getRag().setConnectTimeout(Duration.ofMillis(500));
        properties.getRag().setReadTimeout(Duration.ofMillis(500));
        return properties;
    }

    private RagEvidenceClient.RagQueryRequest query() {
        return new RagEvidenceClient.RagQueryRequest("req-1",
                "what is photosynthesis", "subject-1", null, null, 5);
    }

    @Test
    @DisplayName("served bundle parses with citations, scores and provenance")
    void servedBundleParses() {
        RagEvidence evidence = new RagEvidenceClient(properties()).retrieve(query());
        assertThat(evidence.served()).isTrue();
        assertThat(evidence.chunks()).hasSize(2);
        assertThat(evidence.chunks().get(0).citation())
                .isEqualTo("lessons:aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee#c0");
        assertThat(evidence.chunks().get(0).score()).isEqualTo(0.7911);
        assertThat(evidence.corpusFingerprint()).isEqualTo("fp-test");
        assertThat(evidence.retrieverVersion()).isNotBlank();
        assertThat(evidence.latencyMs()).isGreaterThanOrEqualTo(0);
    }

    @Test
    @DisplayName("explicit sidecar degraded state returns as data, not an exception")
    void unservedReturnsAsData() {
        behavior.set(StubBehavior.UNSERVED);
        RagEvidence evidence = new RagEvidenceClient(properties()).retrieve(query());
        assertThat(evidence.served()).isFalse();
        assertThat(evidence.emptyReason()).isEqualTo("insufficient_evidence");
        assertThat(evidence.chunks()).isEmpty();
    }

    @Test
    @DisplayName("401 maps to non-transient misconfiguration (never retried, never faked)")
    void unauthorizedMapsToMisconfigured() {
        behavior.set(StubBehavior.UNAUTHORIZED);
        assertThatThrownBy(() -> new RagEvidenceClient(properties()).retrieve(query()))
                .isInstanceOf(RagException.class)
                .satisfies(ex -> assertThat(((RagException) ex).getCategory())
                        .isEqualTo(RagException.MISCONFIGURED))
                .satisfies(ex -> assertThat(((RagException) ex).isTransientFailure()).isFalse());
    }

    @Test
    @DisplayName("503 maps to transient unavailable")
    void serverErrorMapsToUnavailable() {
        behavior.set(StubBehavior.SERVER_ERROR);
        assertThatThrownBy(() -> new RagEvidenceClient(properties()).retrieve(query()))
                .isInstanceOf(RagException.class)
                .satisfies(ex -> assertThat(((RagException) ex).isTransientFailure()).isTrue());
    }

    @Test
    @DisplayName("slow sidecar trips the bounded read timeout")
    void slowSidecarTimesOut() {
        behavior.set(StubBehavior.SLOW);
        assertThatThrownBy(() -> new RagEvidenceClient(properties()).retrieve(query()))
                .isInstanceOf(RagException.class)
                .satisfies(ex -> assertThat(((RagException) ex).getCategory())
                        .isEqualTo(RagException.TIMEOUT));
    }

    @Test
    @DisplayName("malformed JSON is invalid evidence, never partial content")
    void malformedJsonRejected() {
        behavior.set(StubBehavior.MALFORMED);
        assertThatThrownBy(() -> new RagEvidenceClient(properties()).retrieve(query()))
                .isInstanceOf(RagException.class)
                .satisfies(ex -> assertThat(((RagException) ex).getCategory())
                        .isEqualTo(RagException.INVALID_EVIDENCE));
    }

    @Test
    @DisplayName("non-authoritative citation shape is rejected")
    void badCitationRejected() {
        behavior.set(StubBehavior.BAD_CITATION);
        assertThatThrownBy(() -> new RagEvidenceClient(properties()).retrieve(query()))
                .isInstanceOf(RagException.class)
                .satisfies(ex -> assertThat(((RagException) ex).getCategory())
                        .isEqualTo(RagException.INVALID_EVIDENCE));
    }

    @Test
    @DisplayName("missing service token fails before any HTTP contact")
    void missingTokenFailsFast() {
        AiProperties properties = properties();
        properties.getRag().setServiceToken("  ");
        assertThatThrownBy(() -> new RagEvidenceClient(properties).retrieve(query()))
                .isInstanceOf(RagException.class)
                .satisfies(ex -> assertThat(((RagException) ex).getCategory())
                        .isEqualTo(RagException.MISCONFIGURED));
    }

    private static String servedBundle() {
        return """
                {"served":true,"request_id":"req-1","empty_reason":"",
                "retriever_version":"hf-semantic-test","corpus_fingerprint":"fp-test",
                "citations":["lessons:aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee#c0"],
                "chunks":[
                {"chunk_id":"lessons:aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee#c0",
                "citation":"lessons:aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee#c0",
                "source_table":"lessons","source_id":"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
                "subject_id":"subject-1","topic_id":"topic-1","unit_id":null,
                "content_version":"v1","difficulty":"EASY","score":0.7911,
                "text":"Photosynthesis converts light into chemical energy."},
                {"chunk_id":"topics:aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee#c0",
                "citation":"topics:aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee#c0",
                "source_table":"topics","source_id":"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
                "subject_id":"subject-1","topic_id":"topic-1","unit_id":null,
                "content_version":"v1","difficulty":"EASY","score":0.342,
                "text":"How plants convert light to chemical energy."}],
                "latency_ms":63.2}""";
    }

    private static String unservedBundle() {
        return """
                {"served":false,"request_id":"req-1",
                "empty_reason":"insufficient_evidence",
                "retriever_version":"hf-semantic-test","corpus_fingerprint":"fp-test",
                "chunks":[],"latency_ms":61.0}""";
    }

    private static String badCitationBundle() {
        return """
                {"served":true,"request_id":"req-1","empty_reason":"",
                "retriever_version":"x","corpus_fingerprint":"fp-test",
                "chunks":[
                {"chunk_id":"x","citation":"AI generated source 42",
                "source_table":"lessons","source_id":"s",
                "subject_id":"subject-1","topic_id":null,"unit_id":null,
                "content_version":"v1","difficulty":null,"score":0.9,
                "text":"Fabricated citation must never be trusted."}],
                "latency_ms":60.0}""";
    }
}
