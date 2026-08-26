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
 * OT-4 (AI-TUTOR v1.0.0 section 14): dedicated sliding-window rate limiter
 * for AI-001 - 20 Gemini-backed tutor requests per user per rolling 60
 * minutes by default, in its OWN bucket that never touches PATH-002's
 * quota. Same approved algorithm shape as {@link GenerationRateLimiter}.
 *
 * <p>KNOWN LIMITATION (documented in the approved specifications): single-
 * instance/in-JVM enforcement only; a multi-replica deployment multiplies
 * the effective limit and requires an owner decision before scaling.</p>
 */
@Component
public class TutorRateLimiter {

    private final AiProperties properties;
    private final Map<UUID, Deque<Instant>> attemptsByUser = new ConcurrentHashMap<>();

    public TutorRateLimiter(AiProperties properties) {
        this.properties = properties;
    }

    /**
     * @return true when the caller may perform a Gemini-backed tutor request
     *         (a slot was consumed); false when the limit is exhausted.
     */
    public synchronized boolean tryAcquire(UUID userId) {
        purgeExpired(userId);
        int max = properties.getTutor().getRateLimit().getMaxRequestsPerHour();
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
                properties.getTutor().getRateLimit().getWindowMinutes());
        Instant cutoff = Instant.now().minus(window);
        while (!attempts.isEmpty() && attempts.peekFirst().isBefore(cutoff)) {
            attempts.pollFirst();
        }
    }
}
