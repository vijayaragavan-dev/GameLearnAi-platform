package com.gamelearn.gamification;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Stage 3 — streak decision anchors (Gamification Specification section 8.3
 * examples S1–S6 plus year boundary and anomaly guard).
 */
class StreakEngineTest {

    private static final LocalDate D21 = LocalDate.of(2026, 8, 21);

    @Test
    @DisplayName("S1: first-ever activity creates a one-day streak")
    void firstEver() {
        var d = StreakEngine.decide(null, D21, 0, 0);
        assertThat(d.firstEver()).isTrue();
        assertThat(d.newCurrent()).isEqualTo(1);
        assertThat(d.newLongest()).isEqualTo(1);
        assertThat(d.milestoneXp()).isNull();
    }

    @Test
    @DisplayName("S2: consecutive day increments; S3: same-day repeat is a no-op")
    void consecutiveAndSameDay() {
        var nextDay = StreakEngine.decide(D21, D21.plusDays(1), 1, 1);
        assertThat(nextDay.sameDayNoOp()).isFalse();
        assertThat(nextDay.newCurrent()).isEqualTo(2);
        assertThat(nextDay.newLongest()).isEqualTo(2);

        var sameDay = StreakEngine.decide(D21, D21, 4, 9);
        assertThat(sameDay.sameDayNoOp()).isTrue();
        assertThat(sameDay.newCurrent()).isEqualTo(4);
        assertThat(sameDay.newLongest()).isEqualTo(9);
        assertThat(sameDay.milestoneXp()).isNull();
    }

    @Test
    @DisplayName("S4: gap >= 2 resets current to 1 and preserves longest")
    void missedDayResets() {
        var d = StreakEngine.decide(D21, D21.plusDays(2), 6, 12);
        assertThat(d.newCurrent()).isEqualTo(1);
        assertThat(d.newLongest()).isEqualTo(12);
        assertThat(d.milestoneXp()).isNull();
    }

    @Test
    @DisplayName("S5/S7: milestones fire exactly on reaching 3/7/14/30")
    void milestones() {
        // Non-milestone crossing first: current 3 -> 4 awards nothing.
        var toFour = StreakEngine.decide(D21, D21.plusDays(1), 3, 3);
        assertThat(toFour.newCurrent()).isEqualTo(4);
        assertThat(toFour.milestoneXp()).isNull();

        // reaching 3 from current=2
        var toThree = StreakEngine.decide(D21.minusDays(1), D21, 2, 2);
        assertThat(toThree.newCurrent()).isEqualTo(3);
        assertThat(toThree.milestoneXp()).isEqualTo(5);

        var toSeven = StreakEngine.decide(D21.minusDays(1), D21, 6, 6);
        assertThat(toSeven.milestoneXp()).isEqualTo(10);
        var toFourteen = StreakEngine.decide(D21.minusDays(1), D21, 13, 13);
        assertThat(toFourteen.milestoneXp()).isEqualTo(25);
        var toThirty = StreakEngine.decide(D21.minusDays(1), D21, 29, 29);
        assertThat(toThirty.milestoneXp()).isEqualTo(50);
        var toEight = StreakEngine.decide(D21.minusDays(1), D21, 7, 7);
        assertThat(toEight.milestoneXp()).isNull();
    }

    @Test
    @DisplayName("S6: month and G-year boundaries are ordinary calendar days")
    void monthAndYearBoundaries() {
        var monthEnd = StreakEngine.decide(LocalDate.of(2026, 8, 31),
                LocalDate.of(2026, 9, 1), 5, 5);
        assertThat(monthEnd.newCurrent()).isEqualTo(6); // consecutive

        var yearEnd = StreakEngine.decide(LocalDate.of(2026, 12, 31),
                LocalDate.of(2027, 1, 1), 5, 5);
        assertThat(yearEnd.newCurrent()).isEqualTo(6); // consecutive

        var skippedOverNewYear = StreakEngine.decide(LocalDate.of(2026, 12, 30),
                LocalDate.of(2027, 1, 1), 5, 5);
        assertThat(skippedOverNewYear.newCurrent()).isEqualTo(1); // gap reset
    }

    @Test
    @DisplayName("Anomaly: future-dated last activity treated as same-day no-op")
    void clockRollbackGuard() {
        var d = StreakEngine.decide(D21.plusDays(3), D21, 4, 7);
        assertThat(d.sameDayNoOp()).isTrue();
        assertThat(d.newCurrent()).isEqualTo(4);
    }

    @Test
    @DisplayName("Longest never shrinks even after long inactivity")
    void longestPreserved() {
        var d = StreakEngine.decide(D21, D21.plusDays(90), 30, 30);
        assertThat(d.newCurrent()).isEqualTo(1);
        assertThat(d.newLongest()).isEqualTo(30);
    }
}
