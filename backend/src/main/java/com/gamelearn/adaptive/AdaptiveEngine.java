package com.gamelearn.adaptive;

import java.math.BigDecimal;
import java.math.RoundingMode;

import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.entity.enums.MasteryLevel;
import com.gamelearn.entity.enums.MasteryTrend;
import com.gamelearn.entity.enums.RecommendationActivityType;

/**
 * Pure decision core of the Adaptive Engine
 * (GameLearn_AI_Adaptive_Engine_Specification.md v1.0.0, sections 6-11, 16).
 *
 * <p>No Spring, no repositories, no I/O: identical inputs always produce
 * identical outputs (spec section 22). All arithmetic uses BigDecimal,
 * scale 2, HALF_UP.</p>
 */
public final class AdaptiveEngine {

    /** Stable machine-readable reason codes (spec section 21). */
    public static final String FIRST_ATTEMPT_BASELINE_SET = "FIRST_ATTEMPT_BASELINE_SET";
    public static final String BEGINNER_NEEDS_FOUNDATIONS = "BEGINNER_NEEDS_FOUNDATIONS";
    public static final String RECENT_DECLINE_REMEDIATION = "RECENT_DECLINE_REMEDIATION";
    public static final String STRONG_PERFORMANCE_INCREASES_DIFFICULTY =
            "STRONG_PERFORMANCE_INCREASES_DIFFICULTY";
    public static final String DEVELOPING_KEEP_PRACTICING = "DEVELOPING_KEEP_PRACTICING";
    public static final String PROFICIENT_CONFIRM_WITH_QUIZ = "PROFICIENT_CONFIRM_WITH_QUIZ";
    public static final String MASTERED_ADVANCE_CHALLENGE = "MASTERED_ADVANCE_CHALLENGE";

    /** Prior state of the learner for this topic; all null on first attempt. */
    public record PreviousState(
            BigDecimal previousMastery,
            BigDecimal previousRecentAccuracy,
            Difficulty currentDifficulty) {
    }

    /** Complete deterministic outcome of one processed attempt. */
    public record Decision(
            BigDecimal previousMasteryScore,
            BigDecimal masteryScore,
            MasteryLevel masteryLevel,
            MasteryTrend trend,
            Difficulty nextDifficulty,
            RecommendationActivityType activityType,
            int priority,
            String reasonCode) {
    }

    private AdaptiveEngine() {
    }

    /**
     * Spec section 6: accuracy = correct / total * 100, scale 2, HALF_UP.
     * Unanswered questions are part of total and therefore count as incorrect.
     */
    public static BigDecimal accuracy(int correctCount, int totalQuestions) {
        return BigDecimal.valueOf((long) correctCount * 100L)
                .divide(BigDecimal.valueOf(totalQuestions), AdaptiveConstants.SCALE, RoundingMode.HALF_UP);
    }

    /**
     * Spec sections 7-11: full deterministic decision for one attempt.
     *
     * @param previousState  prior topic state (all null when n == 1)
     * @param accuracy       current attempt accuracy (section 6)
     * @param attemptCountNew 1-based ordinal of this attempt on the topic
     * @param quizDifficulty difficulty of the submitted quiz (I11)
     */
    public static Decision decide(PreviousState previousState, BigDecimal accuracy,
                                  int attemptCountNew, Difficulty quizDifficulty) {
        if (attemptCountNew == 1) {
            return firstAttempt(accuracy, quizDifficulty);
        }
        return subsequentAttempt(previousState, accuracy, attemptCountNew);
    }

    private static Decision firstAttempt(BigDecimal accuracy, Difficulty quizDifficulty) {
        // Spec section 7.2: mastery = accuracy on the honest first estimate.
        return new Decision(null, accuracy, resolveLevel(accuracy),
                MasteryTrend.INSUFFICIENT_DATA, quizDifficulty,
                RecommendationActivityType.PRACTICE, 2, FIRST_ATTEMPT_BASELINE_SET);
    }

    private static Decision subsequentAttempt(PreviousState previous, BigDecimal accuracy,
                                              int n) {
        BigDecimal old = previous.previousMastery();

        // Spec section 7.3: step = round_half_up_2(delta / min(n, 5)).
        BigDecimal delta = accuracy.subtract(old);
        BigDecimal divisor = BigDecimal.valueOf(Math.min(n, AdaptiveConstants.WEIGHT_DIVISOR_CAP));
        BigDecimal step = delta.divide(divisor, AdaptiveConstants.SCALE, RoundingMode.HALF_UP);
        BigDecimal mastery = clamp(old.add(step));

        MasteryLevel level = resolveLevel(mastery);
        MasteryTrend trend = resolveTrend(accuracy, previous.previousRecentAccuracy());

        // Spec sections 10/11: strict top-down rule order R1-R4.
        if (level == MasteryLevel.BEGINNER) {
            return new Decision(old, mastery, level, trend, stepDown(previous.currentDifficulty()),
                    RecommendationActivityType.REVIEW, 1, BEGINNER_NEEDS_FOUNDATIONS);
        }
        if (trend == MasteryTrend.DECLINING) {
            return new Decision(old, mastery, level, trend, stepDown(previous.currentDifficulty()),
                    RecommendationActivityType.REMEDIATION, 1, RECENT_DECLINE_REMEDIATION);
        }
        if (accuracy.compareTo(AdaptiveConstants.STRONG_ACCURACY) >= 0) {
            if (level == MasteryLevel.MASTERED) {
                return new Decision(old, mastery, level, trend, stepUp(previous.currentDifficulty()),
                        RecommendationActivityType.ADVANCE, 4, STRONG_PERFORMANCE_INCREASES_DIFFICULTY);
            }
            return new Decision(old, mastery, level, trend, stepUp(previous.currentDifficulty()),
                    RecommendationActivityType.QUIZ, 3, STRONG_PERFORMANCE_INCREASES_DIFFICULTY);
        }
        if (level == MasteryLevel.DEVELOPING) {
            return new Decision(old, mastery, level, trend, previous.currentDifficulty(),
                    RecommendationActivityType.PRACTICE, 2, DEVELOPING_KEEP_PRACTICING);
        }
        if (level == MasteryLevel.PROFICIENT) {
            return new Decision(old, mastery, level, trend, previous.currentDifficulty(),
                    RecommendationActivityType.QUIZ, 3, PROFICIENT_CONFIRM_WITH_QUIZ);
        }
        return new Decision(old, mastery, level, trend, previous.currentDifficulty(),
                RecommendationActivityType.ADVANCE, 4, MASTERED_ADVANCE_CHALLENGE);
    }

    /** Spec section 8: lower-inclusive / upper-exclusive bands. */
    public static MasteryLevel resolveLevel(BigDecimal mastery) {
        if (mastery.compareTo(AdaptiveConstants.THRESHOLD_BEGINNER_MAX) < 0) {
            return MasteryLevel.BEGINNER;
        }
        if (mastery.compareTo(AdaptiveConstants.THRESHOLD_DEVELOPING_MAX) < 0) {
            return MasteryLevel.DEVELOPING;
        }
        if (mastery.compareTo(AdaptiveConstants.THRESHOLD_PROFICIENT_MAX) < 0) {
            return MasteryLevel.PROFICIENT;
        }
        return MasteryLevel.MASTERED;
    }

    /** Spec section 9: last-attempt delta against the stored recent accuracy. */
    public static MasteryTrend resolveTrend(BigDecimal currentAccuracy, BigDecimal previousRecentAccuracy) {
        BigDecimal delta = currentAccuracy.subtract(previousRecentAccuracy);
        if (delta.compareTo(AdaptiveConstants.TREND_DELTA) > 0) {
            return MasteryTrend.IMPROVING;
        }
        if (delta.compareTo(AdaptiveConstants.TREND_DELTA.negate()) < 0) {
            return MasteryTrend.DECLINING;
        }
        return MasteryTrend.STABLE;
    }

    /** EASY is the floor. */
    public static Difficulty stepDown(Difficulty current) {
        return switch (current) {
            case HARD -> Difficulty.MEDIUM;
            default -> Difficulty.EASY;
        };
    }

    /** HARD is the ceiling. */
    public static Difficulty stepUp(Difficulty current) {
        return switch (current) {
            case EASY -> Difficulty.MEDIUM;
            default -> Difficulty.HARD;
        };
    }

    private static BigDecimal clamp(BigDecimal value) {
        return value.min(AdaptiveConstants.MASTERY_MAX).max(AdaptiveConstants.MASTERY_MIN);
    }
}
