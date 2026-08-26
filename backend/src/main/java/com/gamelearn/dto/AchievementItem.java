package com.gamelearn.dto;

import java.time.Instant;

/**
 * GAM-002 array element (API Contract v1.1.0 section 5A.1).
 * {@code unlockedAt} is null for locked achievements.
 */
public record AchievementItem(
        String code,
        String name,
        String description,
        String iconKey,
        int xpReward,
        Instant unlockedAt) {
}
