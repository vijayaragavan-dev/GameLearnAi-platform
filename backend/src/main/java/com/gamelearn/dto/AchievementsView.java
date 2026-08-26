package com.gamelearn.dto;

import java.util.List;

/**
 * Dashboard section 6 (Dashboard Specification section 8.6): unlock total +
 * most recent unlocks. Locked achievements are NOT listed (catalog browsing
 * is GAM-002's job).
 */
public record AchievementsView(
        long unlockedCount,
        List<AchievementUnlockItem> recentUnlocks) {
}
