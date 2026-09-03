package com.gamelearn.gamification;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Component;

import com.gamelearn.config.GameResultRateLimitProperties;

/**
 * Per-user sliding-window rate limiter for PROG-101 NEW submissions (Gate 2).
 * Idempotent replays are checked before this limiter, so they never consume quota.
 * Thread-safe with per-user deque locking (no global bottleneck).
 * Single-instance/in-JVM, matching existing GenerationRateLimiter/TutorRateLimiter limitation.
 */
@Component
public class GameResultRateLimiter {

    private final GameResultRateLimitProperties properties;
    private final Map<UUID, Deque<Instant>> attemptsByUser = new ConcurrentHashMap<>();
    private Clock clock = Clock.systemUTC();

    public GameResultRateLimiter(GameResultRateLimitProperties properties) {
        this.properties = properties;
    }

    /** For tests to inject a controllable clock. */
    void setClock(Clock clock) {
        this.clock = clock;
    }

    /**
     * @return true if a NEW submission may proceed (slot consumed), false when limit exhausted.
     */
    public boolean tryAcquire(UUID userId) {
        Deque<Instant> deque = attemptsByUser.computeIfAbsent(userId, k -> new ArrayDeque<>());
        synchronized (deque) {
            purgeExpired(deque);
            int max = properties.getMaxSubmissionsPerHour();
            if (deque.size() >= max) {
                return false;
            }
            deque.addLast(Instant.now(clock));
            return true;
        }
    }

    /** Test/ops visibility — current slots consumed after purging expired. */
    public int currentUsage(UUID userId) {
        Deque<Instant> deque = attemptsByUser.get(userId);
        if (deque == null) {
            return 0;
        }
        synchronized (deque) {
            purgeExpired(deque);
            return deque.size();
        }
    }

    /** For tests to reset state between isolated scenarios. */
    public void clearAll() {
        attemptsByUser.clear();
    }

    private void purgeExpired(Deque<Instant> deque) {
        Duration window = Duration.ofMinutes(properties.getWindowMinutes());
        Instant cutoff = Instant.now(clock).minus(window);
        while (!deque.isEmpty() && deque.peekFirst().isBefore(cutoff)) {
            deque.pollFirst();
        }
    }
}
