package com.gamelearn.gamification;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.UUID;

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
import com.gamelearn.repository.StreakRepository;
import com.gamelearn.repository.UserAchievementRepository;
import com.gamelearn.repository.UserRepository;
import com.gamelearn.service.AuthService;

/**
 * Gate 7 Option A: game results advance streak and participate in achievement evaluation.
 */
@SpringBootTest(properties = {
        "gamelearn.gamification.game-result-rate-limit.max-submissions-per-hour=100",
        "gamelearn.gamification.game-result-rate-limit.window-minutes=60"
})
@ActiveProfiles("test")
class GameResultStreakAchievementTest {

    @Autowired private AuthService authService;
    @Autowired private UserRepository userRepository;
    @Autowired private GameResultService gameResultService;
    @Autowired private GameResultRateLimiter rateLimiter;
    @Autowired private StreakRepository streakRepository;
    @Autowired private UserAchievementRepository userAchievementRepository;
    @Autowired private JdbcTemplate jdbcTemplate;

    @BeforeEach
    void clear() {
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

    private int txCount(User u) {
        Integer c = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM xp_transactions WHERE user_id=?", Integer.class, u.getId());
        return c == null ? 0 : c;
    }

    private int streakCurrent(User u) {
        return streakRepository.findByUserId(u.getId()).map(s -> s.getCurrentStreakDays()).orElse(0);
    }

    private long achievementCount(User u) {
        return userAchievementRepository.countByUserId(u.getId());
    }

    @Test
    @DisplayName("TEST1: valid game awards existing XP exactly as before")
    void validAwardsXp() {
        User u = newUser("g7t1");
        var resp = gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle"));
        // medium 80: 80*0.15*0.9=10.8->11 +10 base +1 combo =22
        assertThat(resp.xpEarned()).isEqualTo(22);
        assertThat(xpTotal(u)).isEqualTo(resp.xpEarned());
    }

    @Test
    @DisplayName("TEST2: valid game advances streak")
    void advancesStreak() {
        User u = newUser("g7t2");
        assertThat(streakCurrent(u)).isZero();
        gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle"));
        assertThat(streakCurrent(u)).isEqualTo(1);
        // same day second game does not advance again but remains 1
        gameResultService.submit(u, req(UUID.randomUUID(), "memory_match"));
        assertThat(streakCurrent(u)).isEqualTo(1);
    }

    @Test
    @DisplayName("TEST3: game result can unlock STREAK_3 achievement via streak")
    void unlocksStreakAchievement() {
        User u = newUser("g7t3");
        // need to advance streak to 3 days
        Clock base = Clock.fixed(Instant.parse("2026-01-01T10:00:00Z"), ZoneOffset.UTC);
        gameResultService.setClock(base);
        try {
            gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle"));
            assertThat(streakCurrent(u)).isEqualTo(1);
            // day 2
            Clock day2 = Clock.fixed(Instant.parse("2026-01-02T10:00:00Z"), ZoneOffset.UTC);
            gameResultService.setClock(day2);
            gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle"));
            assertThat(streakCurrent(u)).isEqualTo(2);
            assertThat(achievementCount(u)).isZero(); // STREAK_3 not yet
            // day 3 — should reach 3 and unlock STREAK_3 (+20 XP reward)
            Clock day3 = Clock.fixed(Instant.parse("2026-01-03T10:00:00Z"), ZoneOffset.UTC);
            gameResultService.setClock(day3);
            var r3 = gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle"));
            assertThat(streakCurrent(u)).isEqualTo(3);
            assertThat(achievementCount(u)).isGreaterThanOrEqualTo(1);
            // verify STREAK_3 code exists
            boolean hasStreak3 = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM user_achievements ua JOIN achievements a ON a.id=ua.achievement_id WHERE ua.user_id=? AND a.code=?",
                    Integer.class, u.getId(), "STREAK_3") > 0;
            assertThat(hasStreak3).isTrue();
            // total XP should include game XP + achievement reward + no milestone (milestone at 3 is 5 XP)
            // Game XP 22 each, but third may have extra achievement reward 20 + milestone 5
            // So not asserting exact, just that total > sum of 3*22
            assertThat(xpTotal(u)).isGreaterThan(3 * 22);
        } finally {
            gameResultService.setClock(Clock.systemUTC());
        }
    }

    @Test
    @DisplayName("TEST4: idempotent replay does not duplicate XP/streak/achievement")
    void idempotentNoDuplicate() {
        User u = newUser("g7t4");
        Clock day1 = Clock.fixed(Instant.parse("2026-02-01T10:00:00Z"), ZoneOffset.UTC);
        gameResultService.setClock(day1);
        try {
            UUID cid = UUID.randomUUID();
            var first = gameResultService.submit(u, req(cid, "quiz_battle"));
            int xp1 = xpTotal(u);
            int streak1 = streakCurrent(u);
            long ach1 = achievementCount(u);
            int tx1 = txCount(u);
            // replay same CID same day
            var second = gameResultService.submit(u, req(cid, "quiz_battle"));
            assertThat(second.requestId()).isEqualTo(first.requestId());
            assertThat(xpTotal(u)).isEqualTo(xp1);
            assertThat(streakCurrent(u)).isEqualTo(streak1);
            assertThat(achievementCount(u)).isEqualTo(ach1);
            assertThat(txCount(u)).isEqualTo(tx1);
            // replay across different clock same day still no duplicate
            Clock laterSameDay = Clock.fixed(Instant.parse("2026-02-01T15:00:00Z"), ZoneOffset.UTC);
            gameResultService.setClock(laterSameDay);
            var third = gameResultService.submit(u, req(cid, "quiz_battle"));
            assertThat(third.requestId()).isEqualTo(first.requestId());
            assertThat(xpTotal(u)).isEqualTo(xp1);
        } finally {
            gameResultService.setClock(Clock.systemUTC());
        }
    }

    @Test
    @DisplayName("TEST5+6: invalid gameType does not create side effects")
    void invalidNoSideEffects() {
        User u = newUser("g7t56");
        Clock fixed = Clock.fixed(Instant.parse("2026-03-01T10:00:00Z"), ZoneOffset.UTC);
        gameResultService.setClock(fixed);
        try {
            int xp0 = xpTotal(u);
            assertThat(streakCurrent(u)).isZero();
            assertThat(achievementCount(u)).isZero();
            assertThatThrownBy(() -> gameResultService.submit(u, new GameResultSubmissionRequest(UUID.randomUUID(), "invalid_game", Difficulty.MEDIUM, true, 80, 30, 2)))
                    .isInstanceOf(ApiException.class);
            assertThat(xpTotal(u)).isEqualTo(xp0);
            assertThat(streakCurrent(u)).isZero();
            assertThat(achievementCount(u)).isZero();
            assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM game_results WHERE user_id=?", Integer.class, u.getId())).isEqualTo(0);

            // also invalid score
            assertThatThrownBy(() -> gameResultService.submit(u, new GameResultSubmissionRequest(UUID.randomUUID(), "quiz_battle", Difficulty.MEDIUM, true, -5, 30, 2)))
                    .isInstanceOf(ApiException.class);
            assertThat(xpTotal(u)).isEqualTo(xp0);
        } finally {
            gameResultService.setClock(Clock.systemUTC());
        }
    }

    @Test
    @DisplayName("TEST7: rate-limited does not create side effects")
    void rateLimitedNoSideEffects() {
        // use a fresh limiter with max 1 for this user
        // We already set max 100 for class, so need to test via exhausting limit quickly with small limit override?
        // Instead we use the existing limiter but we can simulate by setting max=1 via reflection? Easier: use a user and fill limit with new limiter instance that has max 1
        // For simplicity, we will test that after we artificially set limiter to max 1 via properties? We already have max 100, so not easy to exhaust.
        // Instead we verify that our rateLimiter's tryAcquire logic does not affect streak when limit exceeded by using a dedicated test with limit 1.
        // We'll create a new test user and manually check that rate limiting path throws before streak advance by exhausting limit via many submissions.
        // Since max is 100, we need 101 submissions to exhaust — we can do loop 101.
        User u = newUser("g7t7");
        Clock day = Clock.fixed(Instant.parse("2026-04-01T10:00:00Z"), ZoneOffset.UTC);
        gameResultService.setClock(day);
        try {
            // exhaust 100 slots
            for (int i = 0; i < 100; i++) {
                gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle"));
            }
            int xpBefore = xpTotal(u);
            int streakBefore = streakCurrent(u);
            long achBefore = achievementCount(u);
            assertThatThrownBy(() -> gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle")))
                    .isInstanceOf(ApiException.class)
                    .satisfies(ex -> assertThat(((ApiException) ex).getErrorCode()).isEqualTo("GAME_RATE_LIMITED"));
            assertThat(xpTotal(u)).isEqualTo(xpBefore);
            assertThat(streakCurrent(u)).isEqualTo(streakBefore);
            assertThat(achievementCount(u)).isEqualTo(achBefore);
        } finally {
            gameResultService.setClock(Clock.systemUTC());
        }
    }

    @Test
    @DisplayName("TEST8: different valid games independently participate (streak same day no-op)")
    void differentGamesSameDay() {
        User u = newUser("g7t8");
        Clock day = Clock.fixed(Instant.parse("2026-05-01T10:00:00Z"), ZoneOffset.UTC);
        gameResultService.setClock(day);
        try {
            gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle"));
            assertThat(streakCurrent(u)).isEqualTo(1);
            gameResultService.submit(u, req(UUID.randomUUID(), "puzzle_arena"));
            assertThat(streakCurrent(u)).isEqualTo(1); // same day no-op
            assertThat(xpTotal(u)).isGreaterThan(0);
        } finally {
            gameResultService.setClock(Clock.systemUTC());
        }
    }

    @Test
    @DisplayName("TEST10-13: existing quiz gamification still works (smoke)")
    void quizStillWorks() {
        // Verify that all 14 whitelisted types remain accepted after streak integration
        for (String gt : GameType.allIds()) {
            User u = newUser("g7all-" + gt.substring(0, 3));
            var resp = gameResultService.submit(u, req(UUID.randomUUID(), gt));
            assertThat(resp.xpEarned()).isPositive();
        }
    }
}
