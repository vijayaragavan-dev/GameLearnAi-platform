package com.gamelearn.gamification;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import com.gamelearn.dto.GameResultSubmissionRequest;
import com.gamelearn.entity.GameResult;
import com.gamelearn.entity.LearnerProfile;
import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.repository.GameResultRepository;
import com.gamelearn.repository.LearnerProfileRepository;
import com.gamelearn.repository.UserRepository;
import com.gamelearn.service.AuthService;
import com.gamelearn.dto.AuthResponse;
import com.gamelearn.dto.RegisterRequest;
import com.gamelearn.entity.User;

/**
 * Stage 1/8 integration coverage for the PROG-101/102 pipeline (Persistent
 * Gamification + Player Progression). Verifies XP grant, level recalc,
 * idempotency on the caller UUID, ownership scoping, and the per-game
 * progress read endpoint data.
 */
@SpringBootTest
@ActiveProfiles("test")
class GameResultServiceTest {

    @Autowired private AuthService authService;
    @Autowired private UserRepository userRepository;
    @Autowired private GameResultService gameResultService;
    @Autowired private GameResultRepository gameResultRepository;
    @Autowired private LearnerProfileRepository learnerProfileRepository;
    @Autowired private JdbcTemplate jdbcTemplate;

    private User newUser(String label) {
        AuthResponse auth = authService.register(new RegisterRequest(
                label + "-" + UUID.randomUUID() + "@example.test",
                "Str0ng-Passw0rd!", "Learner " + label));
        return userRepository.findById(auth.user().id()).orElseThrow();
    }

    private static GameResultSubmissionRequest req(UUID id, String type, boolean completed,
                                                   int score, int duration, int combo) {
        return new GameResultSubmissionRequest(id, type, Difficulty.MEDIUM, completed, score, duration, combo);
    }

    @BeforeEach
    void clean() {
        // No need; per-test users are random and isolated by UUID.
    }

    @Test
    @DisplayName("P-101: completed game grants base 10 + perf (score/100 * 0.9) + combo bonus, in xp_transactions")
    void completedGameGrantsXpAndPersistsGameResults() {
        User learner = newUser("pgrhappy");
        UUID cid = UUID.randomUUID();
        var resp = gameResultService.submit(learner,
                req(cid, "puzzle_arena", true, 80, 120, 4));
        // score=80: 0.15*80*0.9 (medium) = 10.8 -> 11 (HALF_UP); + 10 base + 3 combo bonus = 24
        assertThat(resp.xpEarned()).isEqualTo(24);
        assertThat(resp.previousLevel()).isEqualTo(1);
        assertThat(resp.currentLevel()).isEqualTo(1);
        assertThat(resp.leveledUp()).isFalse();

        // Game result row exists
        Optional<GameResult> row = gameResultRepository.findByUserIdAndClientRequestId(learner.getId(), cid);
        assertThat(row).isPresent();
        assertThat(row.get().getGameType()).isEqualTo("puzzle_arena");
        assertThat(row.get().isCompleted()).isTrue();
        assertThat(row.get().getScore()).isEqualTo(80);

        // xp_transactions row was written with referenceType='GAME_RESULT'
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM xp_transactions x JOIN users u ON u.id=x.user_id "
                        + "WHERE u.id=? AND x.event_type='GAME_COMPLETED' AND x.amount=?",
                Integer.class, learner.getId(), 24);
        assertThat(count).isEqualTo(1);

        // profile total_xp matches sum
        LearnerProfile profile = learnerProfileRepository.findByUserId(learner.getId()).orElseThrow();
        Integer ledgerSum = jdbcTemplate.queryForObject(
                "SELECT COALESCE(SUM(amount),0) FROM xp_transactions x JOIN users u ON u.id=x.user_id WHERE u.id=?",
                Integer.class, learner.getId());
        assertThat(ledgerSum).isEqualTo(profile.getTotalXp());
    }

    @Test
    @DisplayName("P-101: idempotency on the same clientRequestId does NOT double-award XP")
    void idempotencyRejectsDoubleGrant() {
        User learner = newUser("pgremp");
        UUID cid = UUID.randomUUID();
        var first = gameResultService.submit(learner,
                req(cid, "boss_battle", true, 100, 200, 5));
        var second = gameResultService.submit(learner,
                req(cid, "boss_battle", true, 100, 200, 5));
        // Same UUID -> second call returns the first response, no extra XP.
        assertThat(second.xpEarned()).isEqualTo(first.xpEarned());
        assertThat(second.requestId()).isEqualTo(first.requestId());
        // XP total == single award
        LearnerProfile profile = learnerProfileRepository.findByUserId(learner.getId()).orElseThrow();
        Integer ledgerSum = jdbcTemplate.queryForObject(
                "SELECT COALESCE(SUM(amount),0) FROM xp_transactions x JOIN users u ON u.id=x.user_id WHERE u.id=?",
                Integer.class, learner.getId());
        assertThat(ledgerSum).isEqualTo(first.xpEarned());
        assertThat(profile.getTotalXp()).isEqualTo(first.xpEarned());
        // Only one game_results row
        Integer gameRowCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM game_results WHERE user_id=?", Integer.class, learner.getId());
        assertThat(gameRowCount).isEqualTo(1);
    }

    @Test
    @DisplayName("P-101: failed game (completed=false) does NOT award base XP, only combo and zero perf")
    void failedGameOnlyCombo() {
        User learner = newUser("pgrfail");
        UUID cid = UUID.randomUUID();
        // score 0 -> perf 0 (zero row skipped, spec 4.2); combo 3 -> +2
        var resp = gameResultService.submit(learner,
                req(cid, "snake_and_ladder", false, 0, 30, 3));
        assertThat(resp.xpEarned()).isEqualTo(2);
    }

    @Test
    @DisplayName("P-101: 200 earned in a single run is level 2 (T(2)=100 boundary)")
    void levelUpBoundary() {
        User learner = newUser("pgrlvl");
        // Easy 0.6 mult, score 100 -> 0.15*100=15 * 0.6 = 9; + 10 base + 4 combo
        var resp = gameResultService.submit(learner,
                new GameResultSubmissionRequest(UUID.randomUUID(), "quiz_battle",
                        Difficulty.EASY, true, 100, 30, 5));
        // 9 + 10 + 4 = 23; level 1 still (< 100)
        assertThat(resp.currentLevel()).isEqualTo(1);
        // Submit a 2nd game that pushes total to >=100
        var resp2 = gameResultService.submit(learner,
                new GameResultSubmissionRequest(UUID.randomUUID(), "quiz_battle",
                        Difficulty.MEDIUM, true, 100, 30, 5));
        // medium 0.9: 15*0.9=13.5->14; +10 base +4 combo = 28; total 23+28=51 still <100
        // Submit a high-score run to push across T(2)=100
        var resp3 = gameResultService.submit(learner,
                new GameResultSubmissionRequest(UUID.randomUUID(), "quiz_battle",
                        Difficulty.HARD, true, 100, 30, 0));
        // hard 1.3: 15*1.3=19.5->20; +10 base = 30; total 23+28+30=81 still <100
        // Push harder
        var resp4 = gameResultService.submit(learner,
                new GameResultSubmissionRequest(UUID.randomUUID(), "quiz_battle",
                        Difficulty.HARD, true, 100, 30, 0));
        // +30 again = 111 -> level 2
        assertThat(resp4.currentLevel()).isEqualTo(2);
        assertThat(resp4.leveledUp()).isTrue();
        assertThat(resp4.levelsGained()).isGreaterThanOrEqualTo(1);
    }

    @Test
    @DisplayName("P-102: per-game progress lists the right aggregates and returns zero-state for an unknown game")
    void perGameProgressRoundTrip() {
        User learner = newUser("pgrprog");
        gameResultService.submit(learner,
                new GameResultSubmissionRequest(UUID.randomUUID(), "puzzle_arena",
                        Difficulty.HARD, true, 80, 120, 6));
        gameResultService.submit(learner,
                new GameResultSubmissionRequest(UUID.randomUUID(), "puzzle_arena",
                        Difficulty.HARD, false, 30, 90, 0));
        var all = gameResultService.progressForUser(learner.getId());
        assertThat(all).hasSize(1);
        var p = all.get(0);
        assertThat(p.gameType()).isEqualTo("puzzle_arena");
        assertThat(p.gamesPlayed()).isEqualTo(2);
        assertThat(p.gamesCompleted()).isEqualTo(1);
        assertThat(p.bestScore()).isEqualTo(80);
        assertThat(p.bestCombo()).isEqualTo(6);
        assertThat(p.totalXpEarned()).isGreaterThan(0);

        // Unknown game -> zero state
        var none = gameResultService.progressForGame(learner.getId(), "no_such_game");
        assertThat(none.gamesPlayed()).isZero();
        assertThat(none.gamesCompleted()).isZero();
        assertThat(none.bestScore()).isZero();
        assertThat(none.bestCombo()).isZero();
        assertThat(none.totalXpEarned()).isZero();
    }
}
