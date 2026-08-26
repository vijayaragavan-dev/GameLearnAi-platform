package com.gamelearn.gamification;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Stage 4 — achievement rule mechanics (Gamification Specification
 * section 7.1): config parsing, predicates, fail-open semantics.
 */
class AchievementRulesTest {

    private static final AchievementRules.Snapshot SNAPSHOT =
            new AchievementRules.Snapshot(10, true, 2, 7);

    @Test
    @DisplayName("Config parsing: valid, malformed, missing, and sub-minimum thresholds")
    void thresholdParsing() {
        assertThat(AchievementRules.parseThreshold("{\"threshold\": 10}").getAsInt()).isEqualTo(10);
        assertThat(AchievementRules.parseThreshold("{\"threshold\": 1}").getAsInt()).isEqualTo(1);

        assertThat(AchievementRules.parseThreshold("{\"threshold\": \"ten\"}").isPresent()).isFalse();
        assertThat(AchievementRules.parseThreshold("{\"other\": 5}").isPresent()).isFalse();
        assertThat(AchievementRules.parseThreshold("not json at all").isPresent()).isFalse();
        assertThat(AchievementRules.parseThreshold(null).isPresent()).isFalse();
        assertThat(AchievementRules.parseThreshold("").isPresent()).isFalse();
        assertThat(AchievementRules.parseThreshold("{\"threshold\": 0}").isPresent()).isFalse();
        assertThat(AchievementRules.parseThreshold("{\"threshold\": -3}").isPresent()).isFalse();

        // Fixed-config rule type stores the canonical value.
        assertThat(AchievementRules.parseThreshold("{\"threshold\": 100}").getAsInt()).isEqualTo(100);
    }

    @Test
    @DisplayName("COUNT_QUIZ_ATTEMPTS: boundary is inclusive (>= threshold)")
    void countAttempts() {
        assertThat(AchievementRules.satisfied(
                AchievementRules.COUNT_QUIZ_ATTEMPTS, 10, SNAPSHOT)).isTrue();
        assertThat(AchievementRules.satisfied(
                AchievementRules.COUNT_QUIZ_ATTEMPTS, 11, SNAPSHOT)).isFalse();
        assertThat(AchievementRules.satisfied(
                AchievementRules.COUNT_QUIZ_ATTEMPTS, 1,
                new AchievementRules.Snapshot(1, false, 0, 0))).isTrue();
    }

    @Test
    @DisplayName("SINGLE_ATTEMPT_ACCURACY: exact perfect flag only")
    void singleAttemptAccuracy() {
        assertThat(AchievementRules.satisfied(
                AchievementRules.SINGLE_ATTEMPT_ACCURACY, 100,
                new AchievementRules.Snapshot(1, true, 0, 0))).isTrue();
        assertThat(AchievementRules.satisfied(
                AchievementRules.SINGLE_ATTEMPT_ACCURACY, 100,
                new AchievementRules.Snapshot(9, false, 0, 6))).isFalse();
    }

    @Test
    @DisplayName("TOPIC_MASTERY_COUNT: inclusive count comparison")
    void topicMasteryCount() {
        assertThat(AchievementRules.satisfied(
                AchievementRules.TOPIC_MASTERY_COUNT, 2, SNAPSHOT)).isTrue();
        assertThat(AchievementRules.satisfied(
                AchievementRules.TOPIC_MASTERY_COUNT, 3, SNAPSHOT)).isFalse();
    }

    @Test
    @DisplayName("STREAK_DAYS: uses the projected post-update streak of this pass")
    void streakDays() {
        assertThat(AchievementRules.satisfied(
                AchievementRules.STREAK_DAYS, 7, SNAPSHOT)).isTrue();
        assertThat(AchievementRules.satisfied(
                AchievementRules.STREAK_DAYS, 8, SNAPSHOT)).isFalse();
        // First-ever activity projects to day 1: STREAK_DAYS>=1 unlocks same pass.
        assertThat(AchievementRules.satisfied(
                AchievementRules.STREAK_DAYS, 1,
                new AchievementRules.Snapshot(1, false, 0, 1))).isTrue();
        assertThat(AchievementRules.satisfied(
                AchievementRules.STREAK_DAYS, 1,
                new AchievementRules.Snapshot(1, false, 0, 0))).isFalse();
    }

    @Test
    @DisplayName("Unknown rule types never unlock (defense in depth)")
    void unknownRuleType() {
        assertThat(AchievementRules.satisfied("MYSTERY_RULE", 1, SNAPSHOT)).isFalse();
    }
}
