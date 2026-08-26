package com.gamelearn.gamification;

import java.math.BigDecimal;
import java.util.Map;
import java.util.TreeMap;

/**
 * Immutable compiled constants of the Gamification Engine (Gamification
 * Specification section 4.2/6.1 — APPROVED v1.0.0). Mirrors the Adaptive
 * Engine convention (section 23): values live here, never in configuration.
 * Changing any value requires a specification version bump.
 */
public final class GamificationConstants {

    private GamificationConstants() {
    }

    /** QUIZ_COMPLETED flat award (spec section 4.2). */
    public static final int BASE_QUIZ_XP = 10;

    /** Performance factor applied to the 2dp attempt accuracy (spec section 4.2). */
    public static final BigDecimal PERFORMANCE_FACTOR = new BigDecimal("0.15");

    /** Hard cap for a single XP event amount (spec section 4.2). */
    public static final int EVENT_XP_CAP = 100;

    /** Maximum reachable level; XP keeps accumulating beyond it (spec section 6.1). */
    public static final int MAX_LEVEL = 50;

    /** Exact streak lengths at which the one-shot STREAK_BONUS fires (spec section 4.2). */
    public static final Map<Integer, Integer> STREAK_MILESTONE_XP = Map.of(
            3, 5,
            7, 10,
            14, 25,
            30, 50);

    /** Deterministic iteration order for milestones (ascending day). */
    public static Map<Integer, Integer> streakMilestonesOrdered() {
        return new TreeMap<>(STREAK_MILESTONE_XP);
    }
}
