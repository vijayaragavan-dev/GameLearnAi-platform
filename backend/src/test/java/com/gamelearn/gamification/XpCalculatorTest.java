package com.gamelearn.gamification;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.util.Map;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Stage 1 — XP arithmetic anchors (Gamification Specification section 4.2
 * worked examples X1–X5 and boundary rules). Deterministic, no Spring.
 */
class XpCalculatorTest {

    @Test
    @DisplayName("X1: 66.67 accuracy -> +10 base, +10 performance (spec example)")
    void partialScoreMatchesSpecExample() {
        assertThat(XpCalculator.baseQuizXp()).isEqualTo(10);
        assertThat(XpCalculator.performanceXp(new BigDecimal("66.67"))).isEqualTo(10);
    }

    @Test
    @DisplayName("X3: zero accuracy awards the base only")
    void zeroAccuracy() {
        assertThat(XpCalculator.performanceXp(new BigDecimal("0.00"))).isZero();
    }

    @Test
    @DisplayName("X2: perfect accuracy caps performance at 15")
    void perfectAccuracy() {
        assertThat(XpCalculator.performanceXp(new BigDecimal("100.00"))).isEqualTo(15);
    }

    @Test
    @DisplayName("X4: rounding boundary 33.33 -> 5.00 -> 5")
    void roundingBoundary() {
        assertThat(XpCalculator.performanceXp(new BigDecimal("33.33"))).isEqualTo(5);
    }

    @Test
    @DisplayName("HALF_UP at exactly .005 of the product rounds upward before truncation")
    void halfUpBoundary() {
        // accuracy 83.33 * 0.15 = 12.4995 -> 12.50 -> 12; 86.66*0.15=12.999 -> 13.00 -> 13
        assertThat(XpCalculator.performanceXp(new BigDecimal("83.33"))).isEqualTo(12);
        assertThat(XpCalculator.performanceXp(new BigDecimal("86.66"))).isEqualTo(13);
    }

    @Test
    @DisplayName("Milestone map matches the approved table")
    void milestoneMap() {
        Map<Integer, Integer> ordered = GamificationConstants.streakMilestonesOrdered();
        assertThat(ordered).containsExactly(
                Map.entry(3, 5), Map.entry(7, 10), Map.entry(14, 25), Map.entry(30, 50));
        assertThat(StreakEngine.milestoneXpFor(3)).isEqualTo(5);
        assertThat(StreakEngine.milestoneXpFor(4)).isNull();
        assertThat(StreakEngine.milestoneXpFor(30)).isEqualTo(50);
    }

    @Test
    @DisplayName("Achievement reward passes through uncapped below cap; cap guards extremes")
    void eventCap() {
        assertThat(XpCalculator.capped(60)).isEqualTo(60);
        assertThat(XpCalculator.capped(100)).isEqualTo(100);
        assertThat(XpCalculator.capped(250)).isEqualTo(100);
    }

    @Test
    @DisplayName("Bounds: performance can never exceed 15 or go negative for valid accuracy range")
    void boundsHoldAcrossRange() {
        for (int i = 0; i <= 100; i++) {
            int xp = XpCalculator.performanceXp(BigDecimal.valueOf(i));
            assertThat(xp).isBetween(0, 15);
        }
    }
}
