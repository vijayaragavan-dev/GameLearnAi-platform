package com.gamelearn.gamification;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicInteger;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import com.gamelearn.dto.AuthResponse;
import com.gamelearn.dto.GameResultSubmissionRequest;
import com.gamelearn.dto.RegisterRequest;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.repository.LearnerProfileRepository;
import com.gamelearn.repository.UserRepository;
import com.gamelearn.service.AuthService;

/**
 * Gate 2 regression: per-user NEW-submission rate limiting for PROG-101.
 * Verifies idempotent replays are quota-free, quotas are independent per user,
 * rejected requests create no row and award no XP, and concurrent requests
 * cannot bypass the limit.
 */
@SpringBootTest(properties = {
        "gamelearn.gamification.game-result-rate-limit.max-submissions-per-hour=3",
        "gamelearn.gamification.game-result-rate-limit.window-minutes=60"
})
@ActiveProfiles("test")
class GameResultRateLimitTest {

    @Autowired private AuthService authService;
    @Autowired private UserRepository userRepository;
    @Autowired private GameResultService gameResultService;
    @Autowired private GameResultRateLimiter rateLimiter;
    @Autowired private LearnerProfileRepository learnerProfileRepository;
    @Autowired private JdbcTemplate jdbcTemplate;

    @BeforeEach
    void resetLimiter() {
        rateLimiter.clearAll();
    }

    private User newUser(String label) {
        AuthResponse auth = authService.register(new RegisterRequest(
                label + "-" + UUID.randomUUID() + "@example.test",
                "Str0ng-Passw0rd!", "Learner " + label));
        return userRepository.findById(auth.user().id()).orElseThrow();
    }

    private static GameResultSubmissionRequest req(UUID id, String type) {
        return new GameResultSubmissionRequest(id, type, Difficulty.MEDIUM, true, 80, 30, 2);
    }

    private int xpTotal(User u) {
        Integer sum = jdbcTemplate.queryForObject(
                "SELECT COALESCE(SUM(amount),0) FROM xp_transactions WHERE user_id=?",
                Integer.class, u.getId());
        return sum == null ? 0 : sum;
    }

    private int gameRows(User u) {
        Integer c = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM game_results WHERE user_id=?",
                Integer.class, u.getId());
        return c == null ? 0 : c;
    }

    @Test
    @DisplayName("TEST 1: under limit NEW submissions succeed")
    void underLimitSucceeds() {
        User u = newUser("rl1");
        gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle"));
        gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle"));
        gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle"));
        assertThat(gameRows(u)).isEqualTo(3);
        assertThat(rateLimiter.currentUsage(u.getId())).isEqualTo(3);
    }

    @Test
    @DisplayName("TEST 2: exceeding limit returns 429 GAME_RATE_LIMITED")
    void exceedingLimitReturns429() {
        User u = newUser("rl2");
        gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle"));
        gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle"));
        gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle"));
        assertThatThrownBy(() -> gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle")))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException ae = (ApiException) ex;
                    assertThat(ae.getHttpStatus()).isEqualTo(429);
                    assertThat(ae.getErrorCode()).isEqualTo(ErrorCode.GAME_RATE_LIMITED.name());
                });
    }

    @Test
    @DisplayName("TEST 3: second user has independent quota")
    void independentQuotaPerUser() {
        User a = newUser("rl3a");
        User b = newUser("rl3b");
        // fill A's quota
        gameResultService.submit(a, req(UUID.randomUUID(), "quiz_battle"));
        gameResultService.submit(a, req(UUID.randomUUID(), "quiz_battle"));
        gameResultService.submit(a, req(UUID.randomUUID(), "quiz_battle"));
        assertThatThrownBy(() -> gameResultService.submit(a, req(UUID.randomUUID(), "quiz_battle")))
                .isInstanceOf(ApiException.class);
        // B still has full quota
        gameResultService.submit(b, req(UUID.randomUUID(), "quiz_battle"));
        gameResultService.submit(b, req(UUID.randomUUID(), "quiz_battle"));
        gameResultService.submit(b, req(UUID.randomUUID(), "quiz_battle"));
        assertThat(gameRows(b)).isEqualTo(3);
        // B's 4th also blocked, but A's block didn't affect B's limit
        assertThatThrownBy(() -> gameResultService.submit(b, req(UUID.randomUUID(), "quiz_battle")))
                .isInstanceOf(ApiException.class);
    }

    @Test
    @DisplayName("TEST 4+5: replay same clientRequestId after limit is quota-free and does not double award XP")
    void replayIsQuotaFreeAndNoDoubleXp() {
        User u = newUser("rl45");
        UUID cid = UUID.randomUUID();
        var first = gameResultService.submit(u, req(cid, "puzzle_arena"));
        gameResultService.submit(u, req(UUID.randomUUID(), "puzzle_arena"));
        gameResultService.submit(u, req(UUID.randomUUID(), "puzzle_arena"));
        // at limit 3, next NEW would be 429
        assertThatThrownBy(() -> gameResultService.submit(u, req(UUID.randomUUID(), "puzzle_arena")))
                .isInstanceOf(ApiException.class);
        int xpBefore = xpTotal(u);
        int rowsBefore = gameRows(u);
        // replay same cid must succeed and not consume quota
        var replay = gameResultService.submit(u, req(cid, "puzzle_arena"));
        assertThat(replay.requestId()).isEqualTo(first.requestId());
        assertThat(replay.xpEarned()).isEqualTo(first.xpEarned());
        assertThat(xpTotal(u)).isEqualTo(xpBefore);
        assertThat(gameRows(u)).isEqualTo(rowsBefore);
        // still at limit, NEW still blocked
        assertThatThrownBy(() -> gameResultService.submit(u, req(UUID.randomUUID(), "puzzle_arena")))
                .isInstanceOf(ApiException.class);
    }

    @Test
    @DisplayName("TEST 6: different clientRequestIds consume separate slots")
    void differentIdsConsumeSlots() {
        User u = newUser("rl6");
        gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle"));
        assertThat(rateLimiter.currentUsage(u.getId())).isEqualTo(1);
        gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle"));
        assertThat(rateLimiter.currentUsage(u.getId())).isEqualTo(2);
    }

    @Test
    @DisplayName("TEST 7+8: rate-limited request creates no row and awards no XP")
    void rejectedCreatesNoRowAndNoXp() {
        User u = newUser("rl78");
        int xp0 = xpTotal(u);
        gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle"));
        gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle"));
        gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle"));
        int xpAtLimit = xpTotal(u);
        int rowsAtLimit = gameRows(u);
        UUID extra = UUID.randomUUID();
        assertThatThrownBy(() -> gameResultService.submit(u, req(extra, "quiz_battle")))
                .isInstanceOf(ApiException.class);
        assertThat(gameRows(u)).isEqualTo(rowsAtLimit);
        assertThat(xpTotal(u)).isEqualTo(xpAtLimit);
        // ensure no row with that extra UUID
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM game_results WHERE user_id=? AND client_request_id=?",
                Integer.class, u.getId(), extra)).isEqualTo(0);
        // also verify limit did not affect profile beyond xp
        assertThat(xpTotal(u)).isEqualTo(xpAtLimit);
        assertThat(xpAtLimit).isGreaterThan(xp0);
    }

    @Autowired private com.gamelearn.repository.StreakRepository streakRepository;

    @Test
    @DisplayName("concurrency: parallel NEW requests cannot exceed limit")
    void concurrentRequestsCannotExceedLimit() throws Exception {
        User u = newUser("rlconc");
        // Pre-create streak to avoid concurrent first-ever insert race (Gate 7 adds streak on first game)
        com.gamelearn.entity.Streak pre = new com.gamelearn.entity.Streak();
        pre.setUser(u);
        pre.setCurrentStreakDays(1);
        pre.setLongestStreakDays(1);
        pre.setLastLearningDate(java.time.LocalDate.now(java.time.ZoneOffset.UTC));
        pre.setTimezone("UTC");
        streakRepository.save(pre);
        rateLimiter.clearAll();
        int limit = 3;
        int threads = 10;
        ExecutorService pool = Executors.newFixedThreadPool(threads);
        CountDownLatch start = new CountDownLatch(1);
        List<Future<Boolean>> futures = new ArrayList<>();
        AtomicInteger successes = new AtomicInteger();
        AtomicInteger rejections = new AtomicInteger();
        for (int i = 0; i < threads; i++) {
            futures.add(pool.submit(() -> {
                start.await();
                try {
                    gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle"));
                    successes.incrementAndGet();
                    return true;
                } catch (ApiException ae) {
                    if (ae.getHttpStatus() == 429) {
                        rejections.incrementAndGet();
                    }
                    return false;
                }
            }));
        }
        start.countDown();
        for (Future<Boolean> f : futures) {
            f.get();
        }
        pool.shutdown();
        assertThat(successes.get()).isEqualTo(limit);
        assertThat(rejections.get()).isEqualTo(threads - limit);
        assertThat(gameRows(u)).isEqualTo(limit);
    }
}
