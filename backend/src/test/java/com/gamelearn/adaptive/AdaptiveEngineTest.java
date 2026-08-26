package com.gamelearn.adaptive;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;

import org.junit.jupiter.api.Test;

import com.gamelearn.adaptive.AdaptiveEngine.Decision;
import com.gamelearn.adaptive.AdaptiveEngine.PreviousState;
import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.entity.enums.MasteryLevel;
import com.gamelearn.entity.enums.MasteryTrend;
import com.gamelearn.entity.enums.RecommendationActivityType;

/**
 * Acceptance matrix of GameLearn_AI_Adaptive_Engine_Specification.md
 * v1.0.0 section 28 (T01-T17, T22). Pure logic — no Spring context.
 */
class AdaptiveEngineTest {

    private PreviousState prev(String mastery, String recentAccuracy, Difficulty difficulty) {
        return new PreviousState(new BigDecimal(mastery), new BigDecimal(recentAccuracy), difficulty);
    }

    @Test
    void accuracyMatchesSpecSemantics() {
        assertThat(AdaptiveEngine.accuracy(3, 4)).isEqualByComparingTo("75.00");
        assertThat(AdaptiveEngine.accuracy(1, 3)).isEqualByComparingTo("33.33");
        assertThat(AdaptiveEngine.accuracy(2, 3)).isEqualByComparingTo("66.67");
        assertThat(AdaptiveEngine.accuracy(0, 5)).isEqualByComparingTo("0.00");
        assertThat(AdaptiveEngine.accuracy(5, 5)).isEqualByComparingTo("100.00");
    }

    // T01 — first attempt baseline
    @Test
    void t01_firstAttemptInitializesFromAccuracy() {
        Decision d = AdaptiveEngine.decide(null, new BigDecimal("75.00"), 1, Difficulty.MEDIUM);
        assertThat(d.previousMasteryScore()).isNull();
        assertThat(d.masteryScore()).isEqualByComparingTo("75.00");
        assertThat(d.masteryLevel()).isEqualTo(MasteryLevel.PROFICIENT);
        assertThat(d.trend()).isEqualTo(MasteryTrend.INSUFFICIENT_DATA);
        assertThat(d.nextDifficulty()).isEqualTo(Difficulty.MEDIUM);
        assertThat(d.activityType()).isEqualTo(RecommendationActivityType.PRACTICE);
        assertThat(d.priority()).isEqualTo(2);
        assertThat(d.reasonCode()).isEqualTo(AdaptiveEngine.FIRST_ATTEMPT_BASELINE_SET);
    }

    // T02 — strong second assessment
    @Test
    void t02_strongSecondAssessment() {
        Decision d = AdaptiveEngine.decide(prev("75.00", "75.00", Difficulty.MEDIUM),
                new BigDecimal("100.00"), 2, Difficulty.MEDIUM);
        assertThat(d.masteryScore()).isEqualByComparingTo("87.50");
        assertThat(d.masteryLevel()).isEqualTo(MasteryLevel.PROFICIENT);
        assertThat(d.trend()).isEqualTo(MasteryTrend.IMPROVING);
        assertThat(d.nextDifficulty()).isEqualTo(Difficulty.HARD);
        assertThat(d.activityType()).isEqualTo(RecommendationActivityType.QUIZ);
        assertThat(d.reasonCode()).isEqualTo(AdaptiveEngine.STRONG_PERFORMANCE_INCREASES_DIFFICULTY);
    }

    // T03 — weak second assessment
    @Test
    void t03_weakSecondAssessment() {
        Decision d = AdaptiveEngine.decide(prev("75.00", "75.00", Difficulty.MEDIUM),
                new BigDecimal("25.00"), 2, Difficulty.MEDIUM);
        assertThat(d.masteryScore()).isEqualByComparingTo("50.00");
        assertThat(d.masteryLevel()).isEqualTo(MasteryLevel.DEVELOPING);
        assertThat(d.trend()).isEqualTo(MasteryTrend.DECLINING);
        assertThat(d.nextDifficulty()).isEqualTo(Difficulty.EASY);
        assertThat(d.activityType()).isEqualTo(RecommendationActivityType.REMEDIATION);
        assertThat(d.priority()).isEqualTo(1);
        assertThat(d.reasonCode()).isEqualTo(AdaptiveEngine.RECENT_DECLINE_REMEDIATION);
    }

    // T04 — developing learner aces a quiz
    @Test
    void t04_developingLearnerStrongResult() {
        Decision d = AdaptiveEngine.decide(prev("50.00", "50.00", Difficulty.MEDIUM),
                new BigDecimal("100.00"), 2, Difficulty.MEDIUM);
        assertThat(d.masteryScore()).isEqualByComparingTo("75.00");
        assertThat(d.masteryLevel()).isEqualTo(MasteryLevel.PROFICIENT);
        assertThat(d.trend()).isEqualTo(MasteryTrend.IMPROVING);
        assertThat(d.nextDifficulty()).isEqualTo(Difficulty.HARD);
        assertThat(d.activityType()).isEqualTo(RecommendationActivityType.QUIZ);
    }

    // T05 — mixed sequence third step (75 -> 61.11)
    @Test
    void t05_decliningThirdAttempt() {
        Decision d = AdaptiveEngine.decide(prev("75.00", "100.00", Difficulty.HARD),
                new BigDecimal("33.33"), 3, Difficulty.HARD);
        assertThat(d.masteryScore()).isEqualByComparingTo("61.11");
        assertThat(d.masteryLevel()).isEqualTo(MasteryLevel.DEVELOPING);
        assertThat(d.trend()).isEqualTo(MasteryTrend.DECLINING);
        assertThat(d.nextDifficulty()).isEqualTo(Difficulty.MEDIUM);
        assertThat(d.activityType()).isEqualTo(RecommendationActivityType.REMEDIATION);
    }

    // T06 — boundary landing exactly on 70.00
    @Test
    void t06_boundarySeventyIsProficient() {
        Decision d = AdaptiveEngine.decide(prev("60.00", "60.00", Difficulty.EASY),
                new BigDecimal("100.00"), 4, Difficulty.EASY);
        assertThat(d.masteryScore()).isEqualByComparingTo("70.00");
        assertThat(d.masteryLevel()).isEqualTo(MasteryLevel.PROFICIENT);
    }

    // T07 — crossing into MASTERED advances
    @Test
    void t07_ninetyIsMasteredAndAdvances() {
        Decision d = AdaptiveEngine.decide(prev("80.00", "80.00", Difficulty.MEDIUM),
                new BigDecimal("100.00"), 2, Difficulty.MEDIUM);
        assertThat(d.masteryScore()).isEqualByComparingTo("90.00");
        assertThat(d.masteryLevel()).isEqualTo(MasteryLevel.MASTERED);
        assertThat(d.activityType()).isEqualTo(RecommendationActivityType.ADVANCE);
        assertThat(d.priority()).isEqualTo(4);
    }

    // T08/T09 — HARD ceiling and diminishing grind
    @Test
    void t08_t09_hardCeilingHeldWithDiminishingSteps() {
        Decision atHard = AdaptiveEngine.decide(prev("87.50", "100.00", Difficulty.HARD),
                new BigDecimal("100.00"), 3, Difficulty.HARD);
        assertThat(atHard.masteryScore()).isEqualByComparingTo("91.67");
        assertThat(atHard.nextDifficulty()).isEqualTo(Difficulty.HARD);

        Decision grinded = AdaptiveEngine.decide(prev("91.67", "100.00", Difficulty.HARD),
                new BigDecimal("100.00"), 4, Difficulty.HARD);
        assertThat(grinded.masteryScore()).isEqualByComparingTo("93.75");
        assertThat(grinded.nextDifficulty()).isEqualTo(Difficulty.HARD);
    }

    // T10 — EASY floor held for weak learner
    @Test
    void t10_easyFloorHeldForBeginner() {
        Decision d = AdaptiveEngine.decide(prev("30.00", "30.00", Difficulty.EASY),
                new BigDecimal("0.00"), 2, Difficulty.EASY);
        assertThat(d.masteryScore()).isEqualByComparingTo("15.00");
        assertThat(d.masteryLevel()).isEqualTo(MasteryLevel.BEGINNER);
        assertThat(d.nextDifficulty()).isEqualTo(Difficulty.EASY);
        assertThat(d.activityType()).isEqualTo(RecommendationActivityType.REVIEW);
        assertThat(d.reasonCode()).isEqualTo(AdaptiveEngine.BEGINNER_NEEDS_FOUNDATIONS);
    }

    // T11-T13 — level boundary table (pure function)
    @Test
    void t11_t13_levelBoundariesHaveNoGapsOrOverlaps() {
        assertThat(AdaptiveEngine.resolveLevel(new BigDecimal("0.00"))).isEqualTo(MasteryLevel.BEGINNER);
        assertThat(AdaptiveEngine.resolveLevel(new BigDecimal("39.99"))).isEqualTo(MasteryLevel.BEGINNER);
        assertThat(AdaptiveEngine.resolveLevel(new BigDecimal("40.00"))).isEqualTo(MasteryLevel.DEVELOPING);
        assertThat(AdaptiveEngine.resolveLevel(new BigDecimal("69.99"))).isEqualTo(MasteryLevel.DEVELOPING);
        assertThat(AdaptiveEngine.resolveLevel(new BigDecimal("70.00"))).isEqualTo(MasteryLevel.PROFICIENT);
        assertThat(AdaptiveEngine.resolveLevel(new BigDecimal("89.99"))).isEqualTo(MasteryLevel.PROFICIENT);
        assertThat(AdaptiveEngine.resolveLevel(new BigDecimal("90.00"))).isEqualTo(MasteryLevel.MASTERED);
        assertThat(AdaptiveEngine.resolveLevel(new BigDecimal("100.00"))).isEqualTo(MasteryLevel.MASTERED);
    }

    // T14 — delta of exactly +5.00 is STABLE
    @Test
    void t14_deltaPlusFiveIsStable() {
        Decision d = AdaptiveEngine.decide(prev("50.00", "50.00", Difficulty.MEDIUM),
                new BigDecimal("55.00"), 3, Difficulty.MEDIUM);
        assertThat(d.masteryScore()).isEqualByComparingTo("51.67");
        assertThat(d.trend()).isEqualTo(MasteryTrend.STABLE);
        assertThat(d.nextDifficulty()).isEqualTo(Difficulty.MEDIUM);
        assertThat(d.activityType()).isEqualTo(RecommendationActivityType.PRACTICE);
    }

    // T15 — delta below -5.00 is DECLINING
    @Test
    void t15_deltaMinusSixDeclines() {
        Decision d = AdaptiveEngine.decide(prev("50.00", "50.00", Difficulty.MEDIUM),
                new BigDecimal("44.00"), 3, Difficulty.MEDIUM);
        assertThat(d.masteryScore()).isEqualByComparingTo("48.00");
        assertThat(d.trend()).isEqualTo(MasteryTrend.DECLINING);
        assertThat(d.nextDifficulty()).isEqualTo(Difficulty.EASY);
        assertThat(d.activityType()).isEqualTo(RecommendationActivityType.REMEDIATION);
    }

    // Trend boundaries: exactly -5.00 STABLE, beyond IMPROVING
    @Test
    void trendBoundariesMatchSpecification() {
        assertThat(AdaptiveEngine.resolveTrend(new BigDecimal("55.00"), new BigDecimal("50.00")))
                .isEqualTo(MasteryTrend.STABLE);
        assertThat(AdaptiveEngine.resolveTrend(new BigDecimal("45.00"), new BigDecimal("50.00")))
                .isEqualTo(MasteryTrend.STABLE);
        assertThat(AdaptiveEngine.resolveTrend(new BigDecimal("55.01"), new BigDecimal("50.00")))
                .isEqualTo(MasteryTrend.IMPROVING);
        assertThat(AdaptiveEngine.resolveTrend(new BigDecimal("44.99"), new BigDecimal("50.00")))
                .isEqualTo(MasteryTrend.DECLINING);
    }

    // T16 — strong result lifts DEVELOPING into PROFICIENT with up-step
    @Test
    void t16_strongResultCrossesIntoProficient() {
        Decision d = AdaptiveEngine.decide(prev("45.00", "45.00", Difficulty.EASY),
                new BigDecimal("95.00"), 2, Difficulty.EASY);
        assertThat(d.masteryScore()).isEqualByComparingTo("70.00");
        assertThat(d.masteryLevel()).isEqualTo(MasteryLevel.PROFICIENT);
        assertThat(d.trend()).isEqualTo(MasteryTrend.IMPROVING);
        assertThat(d.nextDifficulty()).isEqualTo(Difficulty.MEDIUM);
        assertThat(d.activityType()).isEqualTo(RecommendationActivityType.QUIZ);
    }

    // T17 — BEGINNER priority beats strong performance (P2 > P4)
    @Test
    void t17_beginnerPriorityBeatsStrongPerformance() {
        Decision d = AdaptiveEngine.decide(prev("20.00", "20.00", Difficulty.MEDIUM),
                new BigDecimal("100.00"), 5, Difficulty.MEDIUM);
        assertThat(d.masteryScore()).isEqualByComparingTo("36.00");
        assertThat(d.masteryLevel()).isEqualTo(MasteryLevel.BEGINNER);
        assertThat(d.trend()).isEqualTo(MasteryTrend.IMPROVING);
        assertThat(d.nextDifficulty()).isEqualTo(Difficulty.EASY);
        assertThat(d.activityType()).isEqualTo(RecommendationActivityType.REVIEW);
        assertThat(d.reasonCode()).isEqualTo(AdaptiveEngine.BEGINNER_NEEDS_FOUNDATIONS);
    }

    // T22 — determinism: identical inputs produce byte-identical outputs
    @Test
    void t22_identicalInputsProduceIdenticalDecisions() {
        for (int i = 0; i < 25; i++) {
            Decision d = AdaptiveEngine.decide(prev("75.00", "100.00", Difficulty.HARD),
                    new BigDecimal("33.33"), 3, Difficulty.HARD);
            assertThat(d.masteryScore()).isEqualByComparingTo("61.11");
            assertThat(d.masteryLevel()).isEqualTo(MasteryLevel.DEVELOPING);
            assertThat(d.trend()).isEqualTo(MasteryTrend.DECLINING);
            assertThat(d.nextDifficulty()).isEqualTo(Difficulty.MEDIUM);
            assertThat(d.activityType()).isEqualTo(RecommendationActivityType.REMEDIATION);
            assertThat(d.reasonCode()).isEqualTo(AdaptiveEngine.RECENT_DECLINE_REMEDIATION);
        }
    }
}
