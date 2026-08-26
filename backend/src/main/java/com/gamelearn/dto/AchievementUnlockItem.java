package com.gamelearn.dto;

import java.time.Instant;

/**
 * Dashboard section 6 element (Dashboard Specification section 8.6): one
 * unlock row joined with its catalog entry. Ordered unlocked_at DESC,
 * achievement_id ASC; bounded at 5.
 */
public record AchievementUnlockItem(
        String code,
        String name,
        String iconKey,
        Instant unlockedAt) {
}
