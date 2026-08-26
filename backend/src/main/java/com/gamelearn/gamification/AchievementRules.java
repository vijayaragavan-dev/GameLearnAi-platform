package com.gamelearn.gamification;

import java.util.OptionalInt;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Pure achievement rule mechanics (Gamification Specification section 7.1 —
 * APPROVED). Exactly four rule types; single-key integer configuration;
 * invalid configuration yields an empty parse so callers can fail open for
 * THAT achievement only (never rolls back the host transaction).
 */
public final class AchievementRules {

    /** The four approved rule_type values (VARCHAR stored verbatim). */
    public static final String COUNT_QUIZ_ATTEMPTS = "COUNT_QUIZ_ATTEMPTS";
    public static final String SINGLE_ATTEMPT_ACCURACY = "SINGLE_ATTEMPT_ACCURACY";
    public static final String TOPIC_MASTERY_COUNT = "TOPIC_MASTERY_COUNT";
    public static final String STREAK_DAYS = "STREAK_DAYS";

    private static final ObjectMapper JSON = new ObjectMapper();

    private AchievementRules() {
    }

    /** Parses {"threshold": <int>} — absent/non-integer/&lt;1 ⇒ empty. */
    public static OptionalInt parseThreshold(String ruleConfigJson) {
        if (ruleConfigJson == null || ruleConfigJson.isBlank()) {
            return OptionalInt.empty();
        }
        try {
            JsonNode node = JSON.readTree(ruleConfigJson).get("threshold");
            if (node == null || !node.canConvertToInt() || node.asInt() < 1) {
                return OptionalInt.empty();
            }
            return OptionalInt.of(node.asInt());
        } catch (Exception malformed) {
            return OptionalInt.empty();
        }
    }

    /**
     * Server-state predicate. {@code streakDays} is the PROJECTED post-update
     * value of this transaction (spec section 9 ordering note), so
     * STREAK_DAYS observes the day this very pass creates.
     */
    public static boolean satisfied(String ruleType, int threshold, Snapshot snapshot) {
        return switch (ruleType) {
            case COUNT_QUIZ_ATTEMPTS -> snapshot.attemptCount() >= threshold;
            case SINGLE_ATTEMPT_ACCURACY -> snapshot.perfectAccuracyAchieved();
            case TOPIC_MASTERY_COUNT -> snapshot.masteredTopicCount() >= threshold;
            case STREAK_DAYS -> snapshot.streakDays() >= threshold;
            default -> false; // unknown rule type never unlocks
        };
    }

    /** Server-authoritative state inputs for one evaluation pass. */
    public record Snapshot(
            long attemptCount,
            boolean perfectAccuracyAchieved,
            long masteredTopicCount,
            int streakDays) {
    }
}
