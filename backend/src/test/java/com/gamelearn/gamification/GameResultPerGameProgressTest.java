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
import com.gamelearn.repository.UserRepository;
import com.gamelearn.service.AuthService;

@SpringBootTest
@ActiveProfiles("test")
class GameResultPerGameProgressTest {

    @Autowired private AuthService authService;
    @Autowired private UserRepository userRepository;
    @Autowired private GameResultService gameResultService;
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
    @DisplayName("P1-1: per-game lastPlayedAt is per-type, not global")
    void perGameLastPlayedIsIsolated() throws Exception {
        User u = newUser("pergame");
        // play puzzle_arena first
        gameResultService.submit(u, new GameResultSubmissionRequest(
                UUID.randomUUID(), "puzzle_arena", Difficulty.MEDIUM, true, 80, 30, 2));
        Thread.sleep(10);
        Instant beforeSecond = Instant.now();
        Thread.sleep(10);
        // play quiz_battle second — global last would be quiz_battle time
        gameResultService.submit(u, new GameResultSubmissionRequest(
                UUID.randomUUID(), "quiz_battle", Difficulty.MEDIUM, true, 90, 30, 3));

        var puzzle = gameResultService.progressForGame(u.getId(), "puzzle_arena");
        var quiz = gameResultService.progressForGame(u.getId(), "quiz_battle");

        assertThat(puzzle.gamesPlayed()).isEqualTo(1);
        assertThat(quiz.gamesPlayed()).isEqualTo(1);
        assertThat(puzzle.lastPlayedAt()).isNotNull();
        assertThat(quiz.lastPlayedAt()).isNotNull();
        // per-game isolation: puzzle's last is before quiz's last
        assertThat(puzzle.lastPlayedAt()).isBefore(quiz.lastPlayedAt());
        assertThat(puzzle.lastPlayedAt()).isBefore(beforeSecond.plusSeconds(5));
        assertThat(quiz.lastPlayedAt()).isAfter(puzzle.lastPlayedAt());
        // unknown game still zero-state
        var none = gameResultService.progressForGame(u.getId(), "no_such");
        assertThat(none.gamesPlayed()).isZero();
        assertThat(none.lastPlayedAt()).isNull();
    }
}
