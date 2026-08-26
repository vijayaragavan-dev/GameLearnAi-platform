package com.gamelearn.gamification;

/**
 * Pure level mathematics (Gamification Specification section 6 — APPROVED).
 *
 * <p>Cumulative quadratic thresholds: T(n) = 50 × (n−1) × n XP are required
 * to BE level n (lower-inclusive). Levels start at 1, never decrease, and
 * pin at MAX_LEVEL=50 while total_xp keeps accumulating.</p>
 */
public final class LevelEngine {

    private LevelEngine() {
    }

    /** Cumulative XP required to BE the given level (lower-inclusive). */
    public static long threshold(int level) {
        if (level < 1 || level > GamificationConstants.MAX_LEVEL) {
            throw new IllegalArgumentException("level out of range: " + level);
        }
        return 50L * (long) (level - 1) * level;
    }

    /**
     * level(totalXp) = max n in [1..MAX_LEVEL] with T(n) ≤ totalXp.
     * Monotonic non-decreasing in totalXp by construction.
     */
    public static int levelFor(long totalXp) {
        if (totalXp < 0) {
            return 1; // defensive invariant; negative XP is forbidden upstream
        }
        // Closed-form estimate from T(n) <= xp  <=>  n <= (1+sqrt(1+xp/12.5))/2,
        // then clamp BEFORE adjusting so extreme totals cannot index past MAX_LEVEL.
        int candidate = (int) ((1L + (long) Math.sqrt(1.0 + totalXp / 12.5)) / 2);
        candidate = Math.max(1, Math.min(GamificationConstants.MAX_LEVEL, candidate));
        while (candidate < GamificationConstants.MAX_LEVEL
                && threshold(candidate + 1) <= totalXp) {
            candidate++;
        }
        while (candidate > 1 && threshold(candidate) > totalXp) {
            candidate--;
        }
        return candidate;
    }

    /**
     * Cumulative threshold of the NEXT level, or null when the learner is at
     * MAX_LEVEL (contract GAM-001 nullability rule).
     */
    public static Long nextThreshold(int currentLevel) {
        if (currentLevel >= GamificationConstants.MAX_LEVEL) {
            return null;
        }
        return threshold(currentLevel + 1);
    }
}
