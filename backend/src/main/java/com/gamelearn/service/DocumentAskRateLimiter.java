package com.gamelearn.service;

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
 * USER-DOC RAG Phase I: dedicated sliding-window rate limiter for
 * document Q&A — same approved algorithm shape as
 * {@link com.gamelearn.ai.gemini.TutorRateLimiter}, in its OWN bucket
 * that never touches tutor/upload/PATH-002 quotas.
 *
 * <p>Same documented limitation: single-instance/in-JVM enforcement only.</p>
 */
@Component
public class DocumentAskRateLimiter {

    private final AiProperties properties;
    private final Map<UUID, Deque<Instant>> attemptsByUser = new ConcurrentHashMap<>();

    public DocumentAskRateLimiter(AiProperties properties) {
        this.properties = properties;
    }

    /**
     * @return true when the caller may perform a document-QA request
     *         (a slot was consumed); false when the limit is exhausted.
     */
    public synchronized boolean tryAcquire(UUID userId) {
        purgeExpired(userId);
        int max = properties.getDocuments().getAskRateLimit().getMaxAsksPerHour();
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
                properties.getDocuments().getAskRateLimit().getWindowMinutes());
        Instant cutoff = Instant.now().minus(window);
        while (!attempts.isEmpty() && attempts.peekFirst().isBefore(cutoff)) {
            attempts.pollFirst();
        }
    }
}
