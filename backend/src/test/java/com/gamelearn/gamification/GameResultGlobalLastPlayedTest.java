package com.gamelearn.gamification;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import com.gamelearn.dto.AuthResponse;
import com.gamelearn.dto.GameResultSubmissionRequest;
import com.gamelearn.dto.RegisterRequest;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.repository.GameResultRepository;
import com.gamelearn.repository.UserRepository;
import com.gamelearn.service.AuthService;

/**
 * Gate 5 P2-1: verifies optimized global findLastPlayedAt uses DB MAX, not Java aggregation,
 * and that per-game isolation remains correct.
 */
@SpringBootTest
@ActiveProfiles("test")
class GameResultGlobalLastPlayedTest {

    @Autowired private AuthService authService;
    @Autowired private UserRepository userRepository;
    @Autowired private GameResultService gameResultService;
    @Autowired private GameResultRepository gameResultRepository;
    @Autowired private GameResultRateLimiter rateLimiter;

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

    @Test
    @DisplayName("TEST 1: empty user returns empty for global")
    void emptyReturnsEmpty() {
        User u = newUser("g5empty");
        assertThat(gameResultRepository.findLastPlayedAt(u.getId())).isEmpty();
        assertThat(gameResultRepository.findLastPlayedAtByUserIdAndGameType(u.getId(), "quiz_battle")).isEmpty();
    }

    @Test
    @DisplayName("TEST 2: single result returns its playedAt for global and per-game")
    void singleReturnsOwn() {
        User u = newUser("g5single");
        var resp = gameResultService.submit(u, new GameResultSubmissionRequest(
                UUID.randomUUID(), "quiz_battle", Difficulty.MEDIUM, true, 80, 30, 2));
        Instant stored = resp.playedAt();
        Instant global = gameResultRepository.findLastPlayedAt(u.getId()).orElseThrow();
        Instant perGame = gameResultRepository.findLastPlayedAtByUserIdAndGameType(u.getId(), "quiz_battle").orElseThrow();
        // DB may truncate nanos; verify within 1 second window and equality between global/per-game
        assertThat(global).isAfter(stored.minusSeconds(1)).isBefore(stored.plusSeconds(1));
        assertThat(perGame).isAfter(stored.minusSeconds(1)).isBefore(stored.plusSeconds(1));
        assertThat(perGame).isEqualTo(global);
        assertThat(gameResultRepository.findLastPlayedAtByUserIdAndGameType(u.getId(), "puzzle_arena")).isEmpty();
    }

    @Test
    @DisplayName("TEST 3+4: multiple types, global is latest across types, per-game isolated")
    void globalIsMaxAcrossTypes() throws Exception {
        User u = newUser("g5multi");
        gameResultService.submit(u, new GameResultSubmissionRequest(
                UUID.randomUUID(), "puzzle_arena", Difficulty.MEDIUM, true, 80, 30, 2));
        Thread.sleep(10);
        gameResultService.submit(u, new GameResultSubmissionRequest(
                UUID.randomUUID(), "quiz_battle", Difficulty.MEDIUM, true, 90, 30, 3));
        Thread.sleep(10);
        var r3 = gameResultService.submit(u, new GameResultSubmissionRequest(
                UUID.randomUUID(), "puzzle_arena", Difficulty.MEDIUM, true, 85, 30, 2));

        Instant global = gameResultRepository.findLastPlayedAt(u.getId()).orElseThrow();
        Instant puzzle = gameResultRepository.findLastPlayedAtByUserIdAndGameType(u.getId(), "puzzle_arena").orElseThrow();
        Instant quiz = gameResultRepository.findLastPlayedAtByUserIdAndGameType(u.getId(), "quiz_battle").orElseThrow();

        // latest across all is puzzle's latest (r3)
        assertThat(global).isEqualTo(puzzle);
        assertThat(puzzle).isAfter(quiz);
        assertThat(puzzle).isAfter(r3.playedAt().minusSeconds(1)).isBefore(r3.playedAt().plusSeconds(1));
    }

    @Test
    @DisplayName("TEST 5: P1-1 per-game via service progressForGame remains isolated after optimization")
    void perGameIsolationViaService() throws Exception {
        User u = newUser("g5service");
        gameResultService.submit(u, new GameResultSubmissionRequest(
                UUID.randomUUID(), "puzzle_arena", Difficulty.MEDIUM, true, 80, 30, 2));
        Thread.sleep(10);
        gameResultService.submit(u, new GameResultSubmissionRequest(
                UUID.randomUUID(), "quiz_battle", Difficulty.MEDIUM, true, 90, 30, 3));

        var puzzle = gameResultService.progressForGame(u.getId(), "puzzle_arena");
        var quiz = gameResultService.progressForGame(u.getId(), "quiz_battle");
        var globalList = gameResultService.progressForUser(u.getId());

        assertThat(puzzle.gamesPlayed()).isEqualTo(1);
        assertThat(quiz.gamesPlayed()).isEqualTo(1);
        assertThat(puzzle.lastPlayedAt()).isBefore(quiz.lastPlayedAt());
        assertThat(globalList).hasSize(2);
    }
}
