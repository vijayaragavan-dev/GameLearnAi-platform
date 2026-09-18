package com.gamelearn.service;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Unit tests for the server-authoritative think-time boundary (Gate 14.1).
 * No Spring context, no database: pure wall-clock semantics.
 */
class ThinkTimeServiceTest {

    private ThinkTimeService thinkTimeService;
    private final UUID userId = UUID.randomUUID();
    private final UUID quizId = UUID.randomUUID();
    private final Instant now = Instant.parse("2026-09-13T12:00:00Z");

    @BeforeEach
    void setUp() {
        thinkTimeService = new ThinkTimeService();
        thinkTimeService.setClock(Clock.fixed(now, ZoneOffset.UTC));
    }

    @Test
    void normalPositiveThinkTimeResolves() {
        thinkTimeService.setClock(Clock.fixed(now.minusSeconds(90), ZoneOffset.UTC));
        thinkTimeService.recordDelivery(userId, quizId);
        thinkTimeService.setClock(Clock.fixed(now, ZoneOffset.UTC));

        assertThat(thinkTimeService.resolveElapsedSeconds(userId, quizId, now, 600))
                .hasValue(90);
    }

    @Test
    void zeroDurationIsValid() {
        thinkTimeService.recordDelivery(userId, quizId);

        assertThat(thinkTimeService.resolveElapsedSeconds(userId, quizId, now, 600))
                .hasValue(0);
    }

    @Test
    void missingDeliveryResolvesEmpty() {
        assertThat(thinkTimeService
                .resolveElapsedSeconds(userId, quizId, now, 600)).isEmpty();
    }

    @Test
    void negativeElapsedResolvesEmpty() {
        thinkTimeService.recordDelivery(userId, quizId);

        assertThat(thinkTimeService.resolveElapsedSeconds(
                userId, quizId, now.minusSeconds(5), 600)).isEmpty();
    }

    @Test
    void overLimitResolvesEmpty() {
        thinkTimeService.setClock(Clock.fixed(now.minusSeconds(3600), ZoneOffset.UTC));
        thinkTimeService.recordDelivery(userId, quizId);
        thinkTimeService.setClock(Clock.fixed(now, ZoneOffset.UTC));

        assertThat(thinkTimeService.resolveElapsedSeconds(userId, quizId, now, 60))
                .isEmpty();
    }

    @Test
    void staleDeliveryResolvesEmptyAndEvicts() {
        thinkTimeService.setClock(
                Clock.fixed(now.minusSeconds(ThinkTimeService.TTL_SECONDS + 10), ZoneOffset.UTC));
        thinkTimeService.recordDelivery(userId, quizId);
        thinkTimeService.setClock(Clock.fixed(now, ZoneOffset.UTC));

        assertThat(thinkTimeService.resolveElapsedSeconds(userId, quizId, now, null))
                .isEmpty();
        // Second attempt without a fresh delivery stays empty (evicted, not reused).
        assertThat(thinkTimeService.resolveElapsedSeconds(userId, quizId, now, null))
                .isEmpty();
    }

    @Test
    void nullLimitFallsBackToTtlCap() {
        thinkTimeService.setClock(Clock.fixed(now.minusSeconds(3600), ZoneOffset.UTC));
        thinkTimeService.recordDelivery(userId, quizId);
        thinkTimeService.setClock(Clock.fixed(now, ZoneOffset.UTC));

        assertThat(thinkTimeService.resolveElapsedSeconds(userId, quizId, now, null))
                .hasValue(3600);
    }

    @Test
    void nullInputsResolveEmpty() {
        thinkTimeService.recordDelivery(userId, quizId);

        assertThat(thinkTimeService.resolveElapsedSeconds(null, quizId, now, 60)).isEmpty();
        assertThat(thinkTimeService.resolveElapsedSeconds(userId, null, now, 60)).isEmpty();
        assertThat(thinkTimeService.resolveElapsedSeconds(userId, quizId, null, 60)).isEmpty();
    }

    @Test
    void latestDeliveryWinsAndRecordsArePerLearnerQuiz() {
        UUID otherQuiz = UUID.randomUUID();
        thinkTimeService.setClock(Clock.fixed(now.minusSeconds(500), ZoneOffset.UTC));
        thinkTimeService.recordDelivery(userId, quizId);
        thinkTimeService.setClock(Clock.fixed(now.minusSeconds(30), ZoneOffset.UTC));
        thinkTimeService.recordDelivery(userId, quizId);
        thinkTimeService.setClock(Clock.fixed(now, ZoneOffset.UTC));

        assertThat(thinkTimeService.resolveElapsedSeconds(userId, quizId, now, 600))
                .hasValue(30);
        assertThat(thinkTimeService.resolveElapsedSeconds(userId, otherQuiz, now, 600))
                .isEmpty();
    }

    @Test
    void nullRecordCallsAreNoOps() {
        thinkTimeService.recordDelivery(null, quizId);
        thinkTimeService.recordDelivery(userId, null);

        assertThat(thinkTimeService.resolveElapsedSeconds(userId, quizId, now, 600))
                .isEmpty();
    }
}
