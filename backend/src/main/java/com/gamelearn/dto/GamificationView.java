package com.gamelearn.dto;

/**
 * Dashboard section 4 (Dashboard Specification section 8.4): XP/level
 * headline, byte-equivalent to the GAM-001 fields computed from the same
 * columns by the same approved rules (Gamification Specification section 6,
 * implemented LevelEngine). Both next-level fields are null at MAX_LEVEL
 * while totalXp keeps accumulating.
 */
public record GamificationView(
        int totalXp,
        int currentLevel,
        int maxLevel,
        Long nextLevelThresholdXp,
        Integer xpToNextLevel) {
}
