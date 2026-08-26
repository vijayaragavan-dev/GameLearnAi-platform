package com.gamelearn.dto;

/**
 * GAM-001 response (API Contract v1.1.0 section 5A.1). Plain-DTO envelope.
 * {@code nextLevelThresholdXp}/{@code xpToNextLevel} are null at MAX_LEVEL.
 */
public record GamificationSummaryResponse(
        int totalXp,
        int currentLevel,
        int maxLevel,
        Long nextLevelThresholdXp,
        Integer xpToNextLevel,
        int currentStreakDays,
        int longestStreakDays,
        long achievementCount) {
}
