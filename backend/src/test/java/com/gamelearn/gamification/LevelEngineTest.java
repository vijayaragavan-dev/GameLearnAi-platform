package com.gamelearn.gamification;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Stage 2 — level formula anchors (Gamification Specification section 6.2
 * boundary table and worked transitions).
 */
class LevelEngineTest {

    @Test
    @DisplayName("Threshold table: T(2)=100, T(3)=300, T(10)=4500, T(50)=122500")
    void thresholds() {
        assertThat(LevelEngine.threshold(1)).isZero();
        assertThat(LevelEngine.threshold(2)).isEqualTo(100);
        assertThat(LevelEngine.threshold(3)).isEqualTo(300);
        assertThat(LevelEngine.threshold(10)).isEqualTo(4500);
        assertThat(LevelEngine.threshold(50)).isEqualTo(122_500);
    }

    @Test
    @DisplayName("Boundaries are lower-inclusive (spec examples 99/100/299/324)")
    void boundaries() {
        assertThat(LevelEngine.levelFor(0)).isEqualTo(1);
        assertThat(LevelEngine.levelFor(99)).isEqualTo(1);
        assertThat(LevelEngine.levelFor(100)).isEqualTo(2);
        assertThat(LevelEngine.levelFor(299)).isEqualTo(2);
        assertThat(LevelEngine.levelFor(300)).isEqualTo(3);
        assertThat(LevelEngine.levelFor(324)).isEqualTo(3);
    }

    @Test
    @DisplayName("Every exact threshold lands on the new level; one below stays")
    void allExactThresholds() {
        for (int level = 1; level <= GamificationConstants.MAX_LEVEL; level++) {
            long t = LevelEngine.threshold(level);
            if (level > 1) {
                assertThat(LevelEngine.levelFor(t - 1)).isEqualTo(level - 1);
            }
            assertThat(LevelEngine.levelFor(t)).isEqualTo(level);
        }
    }

    @Test
    @DisplayName("Level pins at 50 while XP keeps accumulating")
    void maxLevel() {
        assertThat(LevelEngine.levelFor(122_500)).isEqualTo(50);
        assertThat(LevelEngine.levelFor(5_000_000)).isEqualTo(50);
        assertThat(LevelEngine.nextThreshold(50)).isNull();
    }

    @Test
    @DisplayName("nextThreshold mirrors the boundary table; null at cap")
    void nextThreshold() {
        assertThat(LevelEngine.nextThreshold(1)).isEqualTo(100);
        assertThat(LevelEngine.nextThreshold(2)).isEqualTo(300);
        assertThat(LevelEngine.nextThreshold(49)).isEqualTo(122_500);
        assertThat(LevelEngine.nextThreshold(50)).isNull();
    }

    @Test
    @DisplayName("Monotonicity across a dense sweep")
    void monotonic() {
        int previous = 0;
        for (long xp = 0; xp <= 130_000; xp += 7) {
            int level = LevelEngine.levelFor(xp);
            assertThat(level).isBetween(previous, GamificationConstants.MAX_LEVEL);
            previous = level;
        }
        assertThat(previous).isEqualTo(GamificationConstants.MAX_LEVEL);
    }

    @Test
    @DisplayName("Multi-level jump in one award is handled by the pure function")
    void multiJump() {
        assertThat(LevelEngine.levelFor(0)).isEqualTo(1);
        // A single pass granting enough XP to cross several thresholds at once.
        assertThat(LevelEngine.levelFor(1_250)).isEqualTo(5);
    }
}
