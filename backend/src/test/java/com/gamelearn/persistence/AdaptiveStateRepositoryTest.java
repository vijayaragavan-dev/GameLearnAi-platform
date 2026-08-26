package com.gamelearn.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.math.BigDecimal;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import com.gamelearn.entity.Progress;
import com.gamelearn.entity.Recommendation;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.TopicMastery;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.MasteryLevel;
import com.gamelearn.entity.enums.MasteryTrend;
import com.gamelearn.entity.enums.ProgressStatus;
import com.gamelearn.entity.enums.RecommendationActivityType;
import com.gamelearn.entity.enums.RecommendationStatus;
import com.gamelearn.repository.LearningPathNodeRepository;
import com.gamelearn.repository.LearningPathRepository;
import com.gamelearn.repository.ProgressRepository;
import com.gamelearn.repository.RecommendationRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicMasteryRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.UserRepository;
import com.gamelearn.entity.LearningPath;
import com.gamelearn.entity.LearningPathNode;
import com.gamelearn.entity.enums.GeneratedBy;
import com.gamelearn.entity.enums.LearningPathStatus;
import com.gamelearn.entity.enums.PathNodeStatus;

@SpringBootTest
@ActiveProfiles("test")
class AdaptiveStateRepositoryTest {

    @Autowired
    private TopicMasteryRepository topicMasteryRepository;

    @Autowired
    private ProgressRepository progressRepository;

    @Autowired
    private RecommendationRepository recommendationRepository;

    @Autowired
    private LearningPathRepository learningPathRepository;

    @Autowired
    private LearningPathNodeRepository learningPathNodeRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SubjectRepository subjectRepository;

    @Autowired
    private TopicRepository topicRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void savesAndReloadsTopicMastery() {
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("mastery"));
        Subject subject = subjectRepository.saveAndFlush(PersistenceTestFixtures.subject("mastery"));
        Topic topic = topicRepository.saveAndFlush(PersistenceTestFixtures.topic("mastery", subject));

        TopicMastery mastery = PersistenceTestFixtures.topicMastery(user, topic);
        mastery.setMasteryScore(new BigDecimal("42.50"));
        mastery.setRecentAccuracy(new BigDecimal("80.00"));
        mastery.setAttemptCount(3);
        TopicMastery saved = topicMasteryRepository.saveAndFlush(mastery);

        assertThat(saved.getCreatedAt()).isNotNull();
        assertThat(saved.getUpdatedAt()).isNotNull();

        TopicMastery reloaded = topicMasteryRepository.findById(saved.getId()).orElseThrow();
        assertThat(reloaded.getMasteryScore()).isEqualByComparingTo(new BigDecimal("42.50"));
        assertThat(reloaded.getMasteryLevel()).isEqualTo(MasteryLevel.BEGINNER);
        assertThat(reloaded.getCurrentDifficulty().name()).isEqualTo("EASY");
        assertThat(reloaded.getTrend()).isEqualTo(MasteryTrend.INSUFFICIENT_DATA);
        assertThat(reloaded.getLastAssessedAt()).isNull();
    }

    @Test
    void duplicateUserTopicMasteryIsRejectedByDatabase() {
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("mdup"));
        Subject subject = subjectRepository.saveAndFlush(PersistenceTestFixtures.subject("mdup"));
        Topic topic = topicRepository.saveAndFlush(PersistenceTestFixtures.topic("mdup", subject));

        topicMasteryRepository.saveAndFlush(PersistenceTestFixtures.topicMastery(user, topic));

        assertThatThrownBy(() -> topicMasteryRepository.saveAndFlush(
                PersistenceTestFixtures.topicMastery(user, topic)))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void masteryEnumsArePersistedAsStringNotOrdinal() {
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("menum"));
        Subject subject = subjectRepository.saveAndFlush(PersistenceTestFixtures.subject("menum"));
        Topic topic = topicRepository.saveAndFlush(PersistenceTestFixtures.topic("menum", subject));

        TopicMastery mastery = PersistenceTestFixtures.topicMastery(user, topic);
        mastery.setMasteryLevel(MasteryLevel.PROFICIENT);
        mastery.setTrend(MasteryTrend.IMPROVING);
        mastery = topicMasteryRepository.saveAndFlush(mastery);

        var raw = jdbcTemplate.queryForMap(
                "SELECT mastery_level, trend, current_difficulty FROM topic_mastery WHERE id = ?",
                mastery.getId());
        assertThat(raw.get("mastery_level")).isEqualTo("PROFICIENT");
        assertThat(raw.get("trend")).isEqualTo("IMPROVING");
        assertThat(raw.get("current_difficulty")).isEqualTo("EASY");
    }

    @Test
    void progressStatusTransitionsPersist() {
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("prog"));
        Subject subject = subjectRepository.saveAndFlush(PersistenceTestFixtures.subject("prog"));
        Topic topic = topicRepository.saveAndFlush(PersistenceTestFixtures.topic("prog", subject));

        Progress progress = progressRepository.saveAndFlush(
                PersistenceTestFixtures.progress(user, topic));
        assertThat(progress.getStatus()).isEqualTo(ProgressStatus.NOT_STARTED);

        progress.setStatus(ProgressStatus.COMPLETED);
        progress.setCompletionPercentage(new BigDecimal("100.00"));
        progress.setCompletedAt(java.time.Instant.now());
        progress.setLastActivityAt(java.time.Instant.now());
        progressRepository.saveAndFlush(progress);

        Progress reloaded = progressRepository.findById(progress.getId()).orElseThrow();
        assertThat(reloaded.getStatus()).isEqualTo(ProgressStatus.COMPLETED);
        assertThat(reloaded.getCompletionPercentage()).isEqualByComparingTo(new BigDecimal("100.00"));
        assertThat(reloaded.getCompletedAt()).isNotNull();
    }

    @Test
    void progressCanLinkToLearningPathNode() {
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("pnode"));
        Subject subject = subjectRepository.saveAndFlush(PersistenceTestFixtures.subject("pnode"));
        Topic topic = topicRepository.saveAndFlush(PersistenceTestFixtures.topic("pnode", subject));

        LearningPath path = new LearningPath();
        path.setUser(user);
        path.setSubject(subject);
        path.setTitle("Progress Path " + java.util.UUID.randomUUID());
        path.setStatus(LearningPathStatus.ACTIVE);
        path.setGeneratedBy(GeneratedBy.SYSTEM);
        path = learningPathRepository.saveAndFlush(path);

        LearningPathNode node = new LearningPathNode();
        node.setLearningPath(path);
        node.setTopic(topic);
        node.setSequenceNumber(1);
        node.setStatus(PathNodeStatus.AVAILABLE);
        node = learningPathNodeRepository.saveAndFlush(node);

        Progress progress = PersistenceTestFixtures.progress(user, topic);
        progress.setLearningPathNode(node);
        progress = progressRepository.saveAndFlush(progress);

        Progress reloaded = progressRepository.findById(progress.getId()).orElseThrow();
        assertThat(reloaded.getLearningPathNode().getId()).isEqualTo(node.getId());
    }

    @Test
    void recommendationEnumsRoundTripAsString() {
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("rec"));
        Subject subject = subjectRepository.saveAndFlush(PersistenceTestFixtures.subject("rec"));
        Topic topic = topicRepository.saveAndFlush(PersistenceTestFixtures.topic("rec", subject));

        Recommendation recommendation = PersistenceTestFixtures.recommendation(user, topic);
        recommendation.setActivityType(RecommendationActivityType.REMEDIATION);
        Recommendation saved = recommendationRepository.saveAndFlush(recommendation);

        assertThat(saved.getCreatedAt()).isNotNull();
        assertThat(saved.getUpdatedAt()).isNotNull();

        var raw = jdbcTemplate.queryForMap(
                "SELECT activity_type, status FROM recommendations WHERE id = ?",
                saved.getId());
        assertThat(raw.get("activity_type")).isEqualTo("REMEDIATION");
        assertThat(raw.get("status")).isEqualTo("ACTIVE");

        saved.setStatus(RecommendationStatus.CONSUMED);
        saved.setConsumedAt(java.time.Instant.now());
        recommendationRepository.saveAndFlush(saved);

        Recommendation reloaded = recommendationRepository.findById(saved.getId()).orElseThrow();
        assertThat(reloaded.getStatus()).isEqualTo(RecommendationStatus.CONSUMED);
        assertThat(reloaded.getConsumedAt()).isNotNull();
    }
}
