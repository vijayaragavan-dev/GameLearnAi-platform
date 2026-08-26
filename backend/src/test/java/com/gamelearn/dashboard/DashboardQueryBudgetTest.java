package com.gamelearn.dashboard;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import org.hibernate.engine.spi.SessionFactoryImplementor;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import com.gamelearn.dto.AuthResponse;
import com.gamelearn.dto.QuizSubmissionRequest;
import com.gamelearn.dto.RegisterRequest;
import com.gamelearn.entity.Achievement;
import com.gamelearn.entity.LearningPath;
import com.gamelearn.entity.Question;
import com.gamelearn.entity.Quiz;
import com.gamelearn.entity.QuizQuestion;
import com.gamelearn.entity.Recommendation;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.TopicMastery;
import com.gamelearn.entity.User;
import com.gamelearn.entity.UserAchievement;
import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.entity.enums.GeneratedBy;
import com.gamelearn.entity.enums.LearningPathStatus;
import com.gamelearn.entity.enums.MasteryLevel;
import com.gamelearn.entity.enums.MasteryTrend;
import com.gamelearn.entity.enums.PathNodeStatus;
import com.gamelearn.entity.enums.QuestionType;
import com.gamelearn.entity.enums.RecommendationActivityType;
import com.gamelearn.entity.enums.RecommendationStatus;
import com.gamelearn.entity.enums.SourceType;
import com.gamelearn.repository.AchievementRepository;
import com.gamelearn.repository.LearningPathNodeRepository;
import com.gamelearn.repository.LearningPathRepository;
import com.gamelearn.repository.QuestionRepository;
import com.gamelearn.repository.QuizQuestionRepository;
import com.gamelearn.repository.QuizRepository;
import com.gamelearn.repository.RecommendationRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicMasteryRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.UserAchievementRepository;
import com.gamelearn.repository.UserRepository;
import com.gamelearn.service.AuthService;
import com.gamelearn.service.QuizSubmissionService;

/**
 * Phase 9B — DASH-TEST-028: query-budget / N+1 protection. The dashboard
 * request issues a CONSTANT number of statements regardless of how much
 * data the learner owns; names are join-fetched or batched, never lazily
 * per-row loaded. Hibernate statement statistics prove flat scaling.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestPropertySource(properties = "spring.jpa.properties.hibernate.generate_statistics=true")
class DashboardQueryBudgetTest {

    /** Hard ceiling consistent with Dashboard Spec section 20 (~12 targeted reads). */
    private static final long STATEMENT_CEILING = 20;

    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private AuthService authService;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private SubjectRepository subjectRepository;
    @Autowired
    private TopicRepository topicRepository;
    @Autowired
    private QuizRepository quizRepository;
    @Autowired
    private QuestionRepository questionRepository;
    @Autowired
    private QuizQuestionRepository quizQuestionRepository;
    @Autowired
    private TopicMasteryRepository topicMasteryRepository;
    @Autowired
    private RecommendationRepository recommendationRepository;
    @Autowired
    private AchievementRepository achievementRepository;
    @Autowired
    private UserAchievementRepository userAchievementRepository;
    @Autowired
    private LearningPathRepository learningPathRepository;
    @Autowired
    private LearningPathNodeRepository learningPathNodeRepository;
    @Autowired
    private QuizSubmissionService quizSubmissionService;
    @Autowired
    private JdbcTemplate jdbcTemplate;
    @Autowired
    private jakarta.persistence.EntityManagerFactory entityManagerFactory;

    private record Principal(String token, UUID userId) {
    }

    private Principal principal(String label) {
        AuthResponse auth = authService.register(new RegisterRequest(
                label + "-" + UUID.randomUUID() + "@example.test",
                "Str0ng-Passw0rd!", "Learner " + label));
        return new Principal(auth.token(), auth.user().id());
    }

    @Test
    @DisplayName("DASH-TEST-028: statement count is bounded and flat under 3x data growth")
    void queryBudgetIsFlatUnderDataGrowth() throws Exception {
        Principal learner = principal("budget");
        seedLearnerData(learner.userId(), 1);

        long smallDataStatements = dashboardStatementCount(learner);
        assertThat(smallDataStatements).isLessThanOrEqualTo(STATEMENT_CEILING);

        // Seed 3x more data for the SAME learner, then re-measure.
        seedLearnerData(learner.userId(), 2);

        long bigDataStatements = dashboardStatementCount(learner);
        assertThat(bigDataStatements).isLessThanOrEqualTo(STATEMENT_CEILING);
        assertThat(bigDataStatements)
                .as("statement count must stay flat under data growth")
                .isEqualTo(smallDataStatements);
        org.slf4j.LoggerFactory.getLogger(getClass())
                .info("DASH_QUERY_BUDGET small={} big={} ceiling={}",
                        smallDataStatements, bigDataStatements, STATEMENT_CEILING);
    }

    /** Clears statistics, performs one authenticated GET, returns statement count. */
    private long dashboardStatementCount(Principal learner) throws Exception {
        var statistics = entityManagerFactory.unwrap(SessionFactoryImplementor.class)
                .getStatistics();
        statistics.clear();
        mockMvc.perform(get("/api/v1/dashboard")
                        .header("Authorization", "Bearer " + learner.token()))
                .andExpect(status().isOk());
        return statistics.getPrepareStatementCount();
    }

    /**
     * Seeds mastery rows, ACTIVE recommendations, unlocks and completed
     * attempts; multiplier scales every collection.
     */
    private void seedLearnerData(UUID userId, int multiplier) {
        User user = userRepository.findById(userId).orElseThrow();
        Subject subject = subject("qb-" + multiplier);
        activePath(user, subject);

        int topics = 3 * multiplier;
        for (int i = 1; i <= topics; i++) {
            Topic topic = topic("qbt-" + multiplier + "-" + i, subject);
            masteryRow(userId, topic,
                    Instant.now().minusSeconds((multiplier * 100L + i) * 60));
            recommendation(user, topic, (i % 4) + 1);
        }
        for (int i = 1; i <= 2 * multiplier; i++) {
            Achievement achievement = achievement("qb" + multiplier + "_" + i);
            achievementRepository.save(achievement);
            UserAchievement unlock = new UserAchievement();
            unlock.setUser(user);
            unlock.setAchievement(achievement);
            unlock.setUnlockedAt(Instant.now().minusSeconds(i * 120L));
            userAchievementRepository.save(unlock);
        }
        for (int i = 1; i <= 2 * multiplier; i++) {
            completedAttempt(user, subject, Instant.now().minusSeconds(i * 90L));
        }
    }

    private User user(UUID userId) {
        return userRepository.findById(userId).orElseThrow();
    }

    private Subject subject(String label) {
        Subject subject = new Subject();
        subject.setName(label + "-" + UUID.randomUUID());
        subject.setDescription(label);
        subject.setIconKey("icon_" + label);
        subject.setActive(true);
        subject.setDisplayOrder(5);
        return subjectRepository.saveAndFlush(subject);
    }

    private Topic topic(String label, Subject subject) {
        Topic topic = new Topic();
        topic.setSubject(subject);
        topic.setName(label + "-" + UUID.randomUUID());
        topic.setDescription(label);
        topic.setDifficulty(Difficulty.EASY);
        topic.setDisplayOrder(1);
        topic.setActive(true);
        return topicRepository.saveAndFlush(topic);
    }

    private void masteryRow(UUID userId, Topic topic, Instant lastAssessedAt) {
        TopicMastery mastery = new TopicMastery();
        mastery.setUser(user(userId));
        mastery.setTopic(topic);
        mastery.setMasteryScore(new BigDecimal("55.00"));
        mastery.setMasteryLevel(MasteryLevel.PROFICIENT);
        mastery.setCurrentDifficulty(Difficulty.MEDIUM);
        mastery.setAttemptCount(2);
        mastery.setRecentAccuracy(new BigDecimal("50.00"));
        mastery.setTrend(MasteryTrend.STABLE);
        mastery.setLastAssessedAt(lastAssessedAt);
        topicMasteryRepository.save(mastery);
    }

    private void recommendation(User user, Topic topic, int priority) {
        Recommendation recommendation = new Recommendation();
        recommendation.setUser(user);
        recommendation.setTopic(topic);
        recommendation.setActivityType(RecommendationActivityType.PRACTICE);
        recommendation.setRecommendedDifficulty(Difficulty.EASY);
        recommendation.setReason("QB_REC");
        recommendation.setPriority(priority);
        recommendation.setStatus(RecommendationStatus.ACTIVE);
        recommendation.setGeneratedAt(Instant.now());
        recommendationRepository.save(recommendation);
    }

    private Achievement achievement(String label) {
        Achievement achievement = new Achievement();
        achievement.setCode(label.toUpperCase() + "_" + UUID.randomUUID());
        achievement.setName(label + " Achievement");
        achievement.setDescription(label);
        achievement.setIconKey("achievement_" + label);
        achievement.setRuleType("THRESHOLD");
        achievement.setRuleConfigJson("{\"threshold\":100}");
        achievement.setXpReward(10);
        achievement.setActive(true);
        return achievement;
    }

    private LearningPath activePath(User user, Subject subject) {
        Topic topic = topic("qbpath-" + UUID.randomUUID(), subject);
        LearningPath path = new LearningPath();
        path.setUser(user);
        path.setSubject(subject);
        path.setTitle("QB Path " + UUID.randomUUID());
        path.setStatus(LearningPathStatus.ACTIVE);
        path.setGeneratedBy(GeneratedBy.SYSTEM);
        path = learningPathRepository.saveAndFlush(path);
        var node = new com.gamelearn.entity.LearningPathNode();
        node.setLearningPath(path);
        node.setTopic(topic);
        node.setSequenceNumber(1);
        node.setRequiredMastery(BigDecimal.ZERO);
        node.setStatus(PathNodeStatus.AVAILABLE);
        learningPathNodeRepository.save(node);
        learningPathNodeRepository.flush();
        return path;
    }

    private void completedAttempt(User user, Subject subject, Instant submittedAt) {
        Topic topic = topic("qbatt-" + UUID.randomUUID(), subject);
        Question q = new Question();
        q.setTopic(topic);
        q.setQuestionText("Q " + UUID.randomUUID());
        q.setQuestionType(QuestionType.MCQ);
        q.setDifficulty(Difficulty.EASY);
        q.setOptionsJson("{\"options\":[\"a\",\"b\"]}");
        q.setCorrectAnswer("a");
        q.setExplanation("because");
        q.setSourceType(SourceType.CURATED);
        q.setActive(true);
        q = questionRepository.save(q);
        Quiz quiz = new Quiz();
        quiz.setTopic(topic);
        quiz.setTitle("QB Quiz " + UUID.randomUUID());
        quiz.setDifficulty(Difficulty.EASY);
        quiz.setSourceType(SourceType.CURATED);
        quiz.setActive(true);
        quiz = quizRepository.saveAndFlush(quiz);
        QuizQuestion link = new QuizQuestion();
        link.setQuiz(quiz);
        link.setQuestion(q);
        link.setQuestionOrder(1);
        quizQuestionRepository.save(link);
        var attempt = new com.gamelearn.entity.QuizAttempt();
        attempt.setQuiz(quiz);
        attempt.setUser(user);
        attempt.setScore(new BigDecimal("75.00"));
        attempt.setCorrectCount(3);
        attempt.setTotalQuestions(4);
        attempt.setDifficultyAtAttempt(Difficulty.EASY);
        attempt.setStartedAt(submittedAt.minusSeconds(60));
        attempt.setSubmittedAt(submittedAt);
        attempt.setStatus(com.gamelearn.entity.enums.QuizAttemptStatus.COMPLETED);
        quizAttemptRepository.save(attempt);
    }

    @Autowired
    private com.gamelearn.repository.QuizAttemptRepository quizAttemptRepository;
}
