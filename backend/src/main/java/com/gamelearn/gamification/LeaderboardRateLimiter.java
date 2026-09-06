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

@Component
public class LeaderboardRateLimiter {

    private final Map<UUID, Deque<Instant>> attemptsByUser = new ConcurrentHashMap<>();
    private Clock clock = Clock.systemUTC();
    private final int maxPerMinute = 30;
    private final Duration window = Duration.ofMinutes(1);

    void setClock(Clock clock) { this.clock = clock; }

    public boolean tryAcquire(UUID userId) {
        Deque<Instant> deque = attemptsByUser.computeIfAbsent(userId, k -> new ArrayDeque<>());
        synchronized (deque) {
            purge(deque);
            if (deque.size() >= maxPerMinute) return false;
            deque.addLast(Instant.now(clock));
            return true;
        }
    }

    public void clearAll() { attemptsByUser.clear(); }

    private void purge(Deque<Instant> deque) {
        Instant cutoff = Instant.now(clock).minus(window);
        while (!deque.isEmpty() && deque.peekFirst().isBefore(cutoff)) deque.pollFirst();
    }
}
