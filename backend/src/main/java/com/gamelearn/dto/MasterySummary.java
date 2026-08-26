package com.gamelearn.dto;

import java.util.List;

/**
 * Dashboard section 3 (Dashboard Specification section 8.3): at-a-glance
 * coverage of the learner's per-topic mastery state. Counts are row counts
 * over the principal's topic_mastery rows using approved enum values; the
 * Dashboard never derives mastery semantics itself.
 */
public record MasterySummary(
        int topicsAssessed,
        int topicsMastered,
        List<RecentTopicItem> recentTopics) {
}
