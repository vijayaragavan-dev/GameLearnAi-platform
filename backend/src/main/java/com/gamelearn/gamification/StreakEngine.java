package com.gamelearn.gamification;

import java.time.LocalDate;
import java.util.Map;

/**
 * Pure streak-day decision logic (Gamification Specification section 8 —
 * APPROVED). Calendar-date arithmetic only; the caller supplies dates already
 * resolved in the learner's streak timezone (v1: UTC). DST-neutral by design.
 */
public final class StreakEngine {

    private StreakEngine() {
    }

    /**
     * Immutable outcome of one learning activity against persisted state.
     *
     * @param sameDayNoOp   true when lastLearningDate == today (nothing changes)
     * @param newCurrent    current_streak_days AFTER applying this activity
     * @param newLongest    longest_streak_days AFTER applying this activity
     * @param milestoneXp   STREAK_BONUS amount when newCurrent hits an exact
     *                      milestone, otherwise null (spec section 4.2 map)
     */
    public record Decision(
            boolean sameDayNoOp,
            boolean firstEver,
            int newCurrent,
            int newLongest,
            Integer milestoneXp) {
    }

    /**
     * @param lastLearningDate persisted date; null on first-ever activity
     * @param today            activity calendar date in the streak timezone
     */
    public static Decision decide(LocalDate lastLearningDate, LocalDate today,
                                  int currentStreak, int longestStreak) {
        if (lastLearningDate == null) {
            return new Decision(false, true, 1, Math.max(longestStreak, 1), null);
        }
        if (lastLearningDate.isEqual(today)) {
            // Same-day repeat: full no-op (milestones cannot re-fire).
            return new Decision(true, false, currentStreak, longestStreak, null);
        }
        if (lastLearningDate.isEqual(today.minusDays(1))) {
            int next = currentStreak + 1;
            return new Decision(false, false, next,
                    Math.max(longestStreak, next), milestoneXpFor(next));
        }
        if (lastLearningDate.isAfter(today)) {
            // Clock-rollback anomaly: treat as same day (spec section 8.1).
            return new Decision(true, false, currentStreak, longestStreak, null);
        }
        // Gap of >= 2 days: natural reset to 1; longest preserved.
        return new Decision(false, false, 1, longestStreak, null);
    }

    /** Exact-milestone lookup; reaching a value twice is impossible per reset semantics. */
    public static Integer milestoneXpFor(int reachedDay) {
        for (Map.Entry<Integer, Integer> milestone : GamificationConstants.streakMilestonesOrdered()
                .entrySet()) {
            if (milestone.getKey() == reachedDay) {
                return milestone.getValue();
            }
        }
        return null;
    }
}
