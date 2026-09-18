package com.gamelearn.service;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Service;

/**
 * Server-authoritative think-time boundary (Gate 14.1).
 *
 * <p>Records the instant a quiz is delivered (QUIZ-001) per
 * (learner, quiz) and resolves elapsed seconds at submission (QUIZ-002).
 * Both instants use the server clock; the client supplies nothing and
 * cannot influence the measurement.</p>
 *
 * <p>Short-lived in-memory state only (consistent with the existing
 * single-instance in-JVM limiters): entries expire after
 * {@link #TTL_SECONDS} and are evicted lazily. A restart or a missed
 * delivery degrades to empty (NULL), never to an estimated value.</p>
 *
 * <p>Bounds: {@code 0 <= elapsed <= quiz time limit} when the quiz
 * defines one, else {@code 0 <= elapsed <= TTL_SECONDS}. Anything
 * outside bounds, or any missing/stale boundary, resolves empty so the
 * caller persists NULL rather than corrupting the learner signal.</p>
 */
@Service
public class ThinkTimeService {

    /** Delivery records older than this are stale (lazy eviction). */
    public static final long TTL_SECONDS = 24L * 3600L;

    /** Soft cap bounding map growth; oldest-expired entries go first. */
    static final int MAX_ENTRIES = 10_000;

    private record DeliveryKey(UUID userId, UUID quizId) {
    }

    private final Map<DeliveryKey, Instant> deliveries = new ConcurrentHashMap<>();
    private Clock clock = Clock.systemUTC();

    /** Test hook (mirrors the existing setClock pattern). */
    public void setClock(Clock clock) {
        this.clock = clock;
    }

    /**
     * Records a successful quiz delivery. Null-safe no-op; repeated
     * deliveries overwrite (latest wins) so retries stay consistent.
     */
    public void recordDelivery(UUID userId, UUID quizId) {
        if (userId == null || quizId == null) {
            return;
        }
        evictExpired(Instant.now(clock));
        if (deliveries.size() >= MAX_ENTRIES) {
            evictExpired(Instant.now(clock));
        }
        deliveries.put(new DeliveryKey(userId, quizId), Instant.now(clock));
    }

    /**
     * Resolves elapsed whole seconds between delivery and submission.
     * Empty when: no delivery record, stale record, negative elapsed
     * (clock anomaly), over the quiz limit, or over the TTL cap.
     */
    public Optional<Integer> resolveElapsedSeconds(UUID userId, UUID quizId,
            Instant submittedAt, Integer timeLimitSeconds) {
        if (userId == null || quizId == null || submittedAt == null) {
            return Optional.empty();
        }
        Instant deliveredAt = deliveries.get(new DeliveryKey(userId, quizId));
        if (deliveredAt == null) {
            return Optional.empty();
        }
        if (Duration.between(deliveredAt, Instant.now(clock)).getSeconds() > TTL_SECONDS) {
            deliveries.remove(new DeliveryKey(userId, quizId));
            return Optional.empty();
        }
        long elapsed = Duration.between(deliveredAt, submittedAt).getSeconds();
        if (elapsed < 0) {
            return Optional.empty();
        }
        long cap = timeLimitSeconds != null ? timeLimitSeconds.longValue() : TTL_SECONDS;
        if (elapsed > cap) {
            return Optional.empty();
        }
        return Optional.of((int) elapsed);
    }

    private void evictExpired(Instant now) {
        deliveries.entrySet().removeIf(entry ->
                Duration.between(entry.getValue(), now).getSeconds() > TTL_SECONDS);
    }
}
