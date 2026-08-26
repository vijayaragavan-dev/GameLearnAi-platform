package com.gamelearn.service.context;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

import com.gamelearn.entity.LearningPath;
import com.gamelearn.entity.Recommendation;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.TopicMastery;
import com.gamelearn.entity.enums.MasteryLevel;

/**
 * Server-built generation context (Learning Path AI Specification section 6).
 * Everything comes from verified persisted state; topics are addressed by
 * pseudonymized refs; the learner goal is already sanitized untrusted text.
 */
public record LearnerPathContext(
        Subject subject,
        List<TopicCatalogEntry> catalog,
        BigDecimal overallMastery,
        int currentLevel,
        List<TopicMastery> masteries,
        List<Recommendation> activeRecommendations,
        LearningPath previousActivePath,
        String learningGoal) {

    /** Stable catalog order: display_order ASC, then name ASC. Refs are 1-based positions. */
    public LearnerPathContext {
        catalog = catalog.stream()
                .sorted((a, b) -> {
                    int byOrder = Integer.compare(a.displayOrder(), b.displayOrder());
                    return byOrder != 0 ? byOrder : a.name().compareToIgnoreCase(b.name());
                })
                .toList();
    }

    public Map<UUID, TopicCatalogEntry> entriesByTopicId() {
        return catalog.stream()
                .collect(Collectors.toMap(TopicCatalogEntry::topicId, Function.identity()));
    }

    public Map<Integer, TopicCatalogEntry> entriesByRef() {
        return catalog.stream()
                .collect(Collectors.toMap(TopicCatalogEntry::ref, Function.identity()));
    }

    public List<Integer> weakTopicRefs() {
        return masteries.stream()
                .filter(m -> m.getMasteryLevel() == MasteryLevel.BEGINNER)
                .map(m -> refOf(m.getTopic().getId()))
                .distinct()
                .toList();
    }

    public List<Integer> strongTopicRefs() {
        return masteries.stream()
                .filter(m -> m.getMasteryLevel() == MasteryLevel.PROFICIENT
                        || m.getMasteryLevel() == MasteryLevel.MASTERED)
                .map(m -> refOf(m.getTopic().getId()))
                .distinct()
                .toList();
    }

    private int refOf(UUID topicId) {
        TopicCatalogEntry entry = entriesByTopicId().get(topicId);
        return entry == null ? -1 : entry.ref();
    }
}
