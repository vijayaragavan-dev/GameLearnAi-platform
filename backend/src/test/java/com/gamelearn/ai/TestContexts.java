package com.gamelearn.ai;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.springframework.test.util.ReflectionTestUtils;

import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.TopicMastery;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.entity.enums.MasteryLevel;
import com.gamelearn.entity.enums.MasteryTrend;
import com.gamelearn.service.context.LearnerPathContext;
import com.gamelearn.service.context.TopicCatalogEntry;

/**
 * Shared in-memory fixtures for AI-LP unit tests. No Spring context; ids are
 * injected via reflection because BaseEntity generates them.
 */
final class TestContexts {

    private TestContexts() {
    }

    record CatalogTopic(String name, Difficulty difficulty, int displayOrder) {
    }

    static LearnerPathContext context(List<String> topicNames, BigDecimal overallMastery,
                                      List<TopicMastery> masteries, String goal) {
        List<CatalogTopic> plain = new ArrayList<>();
        for (int i = 0; i < topicNames.size(); i++) {
            plain.add(new CatalogTopic(topicNames.get(i),
                    i == 0 ? Difficulty.EASY : Difficulty.MEDIUM, i + 1));
        }
        return contextFromTopics(plain, overallMastery, masteries, goal);
    }

    static LearnerPathContext contextFromTopics(List<CatalogTopic> topics,
                                                BigDecimal overallMastery,
                                                List<TopicMastery> masteries, String goal) {
        Subject subject = new Subject();
        subject.setName("Test Subject");
        User user = new User();
        user.setEmail("learner@example.test");

        List<TopicCatalogEntry> entries = new ArrayList<>();
        int ref = 1;
        List<CatalogTopic> ordered = topics.stream()
                .sorted(java.util.Comparator.comparingInt(CatalogTopic::displayOrder))
                .toList();
        for (CatalogTopic topic : ordered) {
            entries.add(new TopicCatalogEntry(ref++, UUID.randomUUID(), topic.name(),
                    topic.name() + " description", topic.difficulty(), topic.displayOrder()));
        }

        if (masteries == null) {
            // Default mixed profile: first entry weak/declining, second strong if present.
            masteries = new ArrayList<>();
            masteries.add(mastery(user, entries.get(0).topicId(), new BigDecimal("22.00"),
                    MasteryLevel.BEGINNER, MasteryTrend.DECLINING));
            if (entries.size() > 1) {
                masteries.add(mastery(user, entries.get(1).topicId(), new BigDecimal("95.00"),
                        MasteryLevel.MASTERED, MasteryTrend.IMPROVING));
            }
        }

        return new LearnerPathContext(subject, entries, overallMastery, 3,
                masteries, List.of(), null, goal);
    }

    /** Context whose learner-data block exercises mastery serialization (LP03/LP04). */
    static LearnerPathContext contextWithMastery(List<String> topicNames) {
        return context(topicNames, new BigDecimal("40.00"), null, null);
    }

    private static TopicMastery mastery(User user, UUID topicId, BigDecimal score,
                                        MasteryLevel level, MasteryTrend trend) {
        TopicMastery mastery = new TopicMastery();
        Topic topic = new Topic();
        ReflectionTestUtils.setField(topic, "id", topicId);
        mastery.setUser(user);
        mastery.setTopic(topic);
        mastery.setMasteryScore(score);
        mastery.setMasteryLevel(level);
        mastery.setTrend(trend);
        mastery.setCurrentDifficulty(Difficulty.EASY);
        mastery.setAttemptCount(2);
        mastery.setRecentAccuracy(BigDecimal.ZERO);
        return mastery;
    }
}
