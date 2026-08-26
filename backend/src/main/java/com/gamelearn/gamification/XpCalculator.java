package com.gamelearn.gamification;

import java.math.BigDecimal;

/**
 * Pure, deterministic XP arithmetic (Gamification Specification section 4.2).
 * No Spring state; unit-testable without a database (spec section 17 style,
 * mirroring the Adaptive Engine's pure-function mandate).
 */
public final class XpCalculator {

    private XpCalculator() {
    }

    /** QUIZ_COMPLETED flat component. */
    public static int baseQuizXp() {
        return GamificationConstants.BASE_QUIZ_XP;
    }

    /**
     * QUIZ_PERFORMANCE component: round_half_up_2(accuracy × 0.15) truncated
     * to integer. The accuracy input MUST be the attempt's persisted 2dp
     * score — the same value the Adaptive Engine consumed (single source of
     * truth). Result is inherently 0..15 for 0..100 accuracy inputs.
     */
    public static int performanceXp(BigDecimal twoDpAccuracy) {
        BigDecimal scaled = twoDpAccuracy
                .multiply(GamificationConstants.PERFORMANCE_FACTOR)
                .setScale(2, java.math.RoundingMode.HALF_UP);
        return scaled.intValue(); // non-negative: truncation == floor
    }

    /** Defensive single-event cap (spec section 4.2: amount ≤ 100). */
    public static int capped(int amount) {
        return Math.min(amount, GamificationConstants.EVENT_XP_CAP);
    }
}
