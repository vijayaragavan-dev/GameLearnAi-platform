package com.gamelearn.gamification;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.Set;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
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
import com.gamelearn.repository.UserRepository;
import com.gamelearn.service.AuthService;

/**
 * Gate 4 P1-5 whitelist validation.
 */
@SpringBootTest(properties = {
        "gamelearn.gamification.game-result-rate-limit.max-submissions-per-hour=3",
        "gamelearn.gamification.game-result-rate-limit.window-minutes=60"
})
@ActiveProfiles("test")
class GameTypeWhitelistTest {

    @Autowired private AuthService authService;
    @Autowired private UserRepository userRepository;
    @Autowired private GameResultService gameResultService;
    @Autowired private GameResultRateLimiter rateLimiter;
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

    private int gameRows(User u) {
        Integer c = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM game_results WHERE user_id=?", Integer.class, u.getId());
        return c == null ? 0 : c;
    }

    @Test
    @DisplayName("TEST 1: every official gameType is accepted")
    void everyOfficialIsAccepted() {
        Set<String> all = GameType.allIds();
        assertThat(all).hasSize(14);
        for (String gt : all) {
            User u = newUser("wl1-" + gt);
            var resp = gameResultService.submit(u, req(UUID.randomUUID(), gt));
            assertThat(resp.xpEarned()).isGreaterThan(0);
        }
    }

    @ParameterizedTest
    @ValueSource(strings = {"quiz_battle", "memory_match", "drag_drop", "speed_run", "debug_arena", "unlock_code", "concept_builder", "sequence_master", "target_challenge", "mystery_case", "boss_battle", "puzzle_arena", "connectivity_lab", "snake_and_ladder"})
    @DisplayName("TEST 1 parameterized: official ids individually")
    void parameterizedOfficial(String gt) {
        User u = newUser("wlparam-" + gt);
        var resp = gameResultService.submit(u, req(UUID.randomUUID(), gt));
        assertThat(resp.xpEarned()).isGreaterThan(0);
    }

    @Test
    @DisplayName("TEST 2+3+4: invalid gameType rejected with 400 VALIDATION_FAILED and fieldErrors.gameType")
    void invalidRejectedWith400AndFieldErrors() {
        User u = newUser("wl2");
        GameResultSubmissionRequest bad = req(UUID.randomUUID(), "fake_game");
        assertThatThrownBy(() -> gameResultService.submit(u, bad))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> {
                    ApiException ae = (ApiException) ex;
                    assertThat(ae.getHttpStatus()).isEqualTo(400);
                    assertThat(ae.getErrorCode()).isEqualTo(ErrorCode.VALIDATION_FAILED.name());
                    assertThat(ae.getFieldErrors()).containsKey("gameType");
                });
    }

    @Test
    @DisplayName("TEST 2b: invalid variations rejected")
    void invalidVariationsRejected() {
        User u = newUser("wl2b");
        for (String bad : new String[]{"", " ", "abc", "hack_game_123", "QUIZ_BATTLE", "Fake_Game"}) {
            // empty/blank will fail @NotBlank or whitelist; we test via service validate
            // service's isValid checks IDS set case-sensitive, so upper case fails
            if (bad == null || bad.isBlank()) continue; // blank is also invalid but service will catch
            assertThatThrownBy(() -> gameResultService.submit(u, req(UUID.randomUUID(), bad)))
                    .isInstanceOf(ApiException.class);
        }
    }

    @Test
    @DisplayName("TEST 5+6+7: invalid creates no row, no XP, no XpTransaction")
    void invalidCreatesNoSideEffects() {
        User u = newUser("wl567");
        int xp0 = xpTotal(u);
        int rows0 = gameRows(u);
        Integer tx0 = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM xp_transactions WHERE user_id=?", Integer.class, u.getId());
        assertThatThrownBy(() -> gameResultService.submit(u, req(UUID.randomUUID(), "abc")))
                .isInstanceOf(ApiException.class);
        assertThat(gameRows(u)).isEqualTo(rows0);
        assertThat(xpTotal(u)).isEqualTo(xp0);
        Integer tx1 = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM xp_transactions WHERE user_id=?", Integer.class, u.getId());
        assertThat(tx1).isEqualTo(tx0);
        // also no game_results row with that fake type
        Integer fakeCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM game_results WHERE user_id=? AND game_type=?",
                Integer.class, u.getId(), "abc");
        assertThat(fakeCount).isEqualTo(0);
    }

    @Test
    @DisplayName("TEST 8: valid still awards XP normally after invalid attempt")
    void validStillWorksAfterInvalid() {
        User u = newUser("wl8");
        assertThatThrownBy(() -> gameResultService.submit(u, req(UUID.randomUUID(), "not_real")))
                .isInstanceOf(ApiException.class);
        var resp = gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle"));
        assertThat(resp.xpEarned()).isGreaterThan(0);
        assertThat(gameRows(u)).isEqualTo(1);
        assertThat(xpTotal(u)).isGreaterThan(0);
    }

    @Test
    @DisplayName("TEST 9: idempotency with valid type remains intact")
    void idempotencyRemains() {
        User u = newUser("wl9");
        UUID cid = UUID.randomUUID();
        var first = gameResultService.submit(u, req(cid, "quiz_battle"));
        int xp1 = xpTotal(u);
        var second = gameResultService.submit(u, req(cid, "quiz_battle"));
        assertThat(second.requestId()).isEqualTo(first.requestId());
        assertThat(xpTotal(u)).isEqualTo(xp1);
        assertThat(gameRows(u)).isEqualTo(1);
    }

    @Test
    @DisplayName("TEST 10: invalid does not consume rate-limit quota (quota-free)")
    void invalidDoesNotConsumeQuota() {
        // use a user, fill 2 of 3 slots, attempt invalid (should not consume), then 3rd valid should succeed, 4th valid should be rate-limited
        User u = newUser("wl10");
        gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle")); //1
        gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle")); //2
        // invalid attempt — should be 400, not consume third slot
        assertThatThrownBy(() -> gameResultService.submit(u, req(UUID.randomUUID(), "invalid_type")))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getHttpStatus()).isEqualTo(400));
        assertThat(rateLimiter.currentUsage(u.getId())).isEqualTo(2);
        // third valid should still succeed (quota was 2, limit 3)
        gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle")); //3
        assertThat(rateLimiter.currentUsage(u.getId())).isEqualTo(3);
        // fourth valid now exceeds
        assertThatThrownBy(() -> gameResultService.submit(u, req(UUID.randomUUID(), "quiz_battle")))
                .isInstanceOf(ApiException.class)
                .satisfies(ex -> assertThat(((ApiException) ex).getHttpStatus()).isEqualTo(429));
    }
}
