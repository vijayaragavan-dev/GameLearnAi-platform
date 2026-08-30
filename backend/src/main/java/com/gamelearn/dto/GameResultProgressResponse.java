package com.gamelearn.dto;

import java.time.Instant;

/**
 * PROG-102 per-game progress summary for the Game Hub and dashboard widgets.
 * All values are zero when the learner has never played that game type.
 */
public record GameResultProgressResponse(
        String gameType,
        long gamesPlayed,
        long gamesCompleted,
        int bestScore,
        int bestCombo,
        int totalXpEarned,
        Instant lastPlayedAt) {
}
