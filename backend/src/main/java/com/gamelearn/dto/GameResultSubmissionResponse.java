package com.gamelearn.dto;

import java.time.Instant;
import java.util.UUID;

/**
 * PROG-101 response. The XP values are server-derived; the requestId echoes
 * the caller UUID so the client can reconcile a possibly-replayed request
 * against its own queue. {@code leveledUp} and {@code levelsGained} are
 * the delta from the run that just completed.
 */
public record GameResultSubmissionResponse(
        UUID requestId,
        int xpEarned,
        int previousLevel,
        int currentLevel,
        int previousTotalXp,
        int currentTotalXp,
        Long nextLevelThresholdXp,
        Integer xpToNextLevel,
        boolean leveledUp,
        int levelsGained,
        Instant playedAt) {
}
