package com.gamelearn.ai.gemini;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Component;

import com.gamelearn.config.AiProperties;

/**
 * D10 sliding-window rate limiter: max Gemini-backed generation requests per
 * authenticated user per rolling window (default 10/hour). Idempotent
 * returns never reach this component. KNOWN LIMITATION (documented in the
 * approved specifications): enforcement is single-instance/in-JVM - a
 * multi-replica deployment multiplies the effective limit and requires an
 * owner decision before scaling. No distributed infrastructure is used.
 */
@Component
public class GenerationRateLimiter {

    private final AiProperties properties;
    private final Map<UUID, Deque<Instant>> attemptsByUser = new ConcurrentHashMap<>();

    public GenerationRateLimiter(AiProperties properties) {
        this.properties = properties;
    }

    /**
     * @return true when the caller may perform a Gemini-backed generation
     *         (a slot was consumed); false when the limit is exhausted.
     */
    public synchronized boolean tryAcquire(UUID userId) {
        purgeExpired(userId);
        int max = properties.getLearningPath().getRateLimit().getMaxRequestsPerHour();
        Deque<Instant> attempts = attemptsByUser.computeIfAbsent(userId, key -> new ArrayDeque<>());
        if (attempts.size() >= max) {
            return false;
        }
        attempts.addLast(Instant.now());
        return true;
    }

    /** Test/ops visibility: how many slots the user currently consumes. */
    public synchronized int currentUsage(UUID userId) {
        purgeExpired(userId);
        Deque<Instant> attempts = attemptsByUser.get(userId);
        return attempts == null ? 0 : attempts.size();
    }

    private void purgeExpired(UUID userId) {
        Deque<Instant> attempts = attemptsByUser.get(userId);
        if (attempts == null) {
            return;
        }
        Duration window = Duration.ofMinutes(
                properties.getLearningPath().getRateLimit().getWindowMinutes());
        Instant cutoff = Instant.now().minus(window);
        while (!attempts.isEmpty() && attempts.peekFirst().isBefore(cutoff)) {
            attempts.pollFirst();
        }
    }
}
