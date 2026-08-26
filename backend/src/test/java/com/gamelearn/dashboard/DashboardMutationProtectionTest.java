package com.gamelearn.dashboard;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

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
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.entity.enums.GeneratedBy;
import com.gamelearn.entity.enums.LearningPathStatus;
import com.gamelearn.entity.enums.PathNodeStatus;
import com.gamelearn.entity.enums.QuestionType;
import com.gamelearn.entity.enums.RecommendationActivityType;
import com.gamelearn.entity.enums.RecommendationStatus;
import com.gamelearn.entity.enums.SourceType;
import com.gamelearn.repository.AchievementRepository;
import com.gamelearn.repository.AiInteractionRepository;
import com.gamelearn.repository.LearningPathNodeRepository;
import com.gamelearn.repository.LearningPathRepository;
import com.gamelearn.repository.ProgressRepository;
import com.gamelearn.repository.QuestionRepository;
import com.gamelearn.repository.QuizQuestionRepository;
import com.gamelearn.repository.QuizRepository;
import com.gamelearn.repository.RecommendationRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.UserRepository;
import com.gamelearn.service.AuthService;
import com.gamelearn.service.QuizSubmissionService;

/**
 * Phase 9B — DASH-TEST-023..027: opening the dashboard is a PURE READ.
 * Every domain-owned table must be byte-identical across the call, and
 * zero AI activity may occur (Dashboard Specification sections 6/10, X1-X10).
 *
 * <p>The extra property gives this class its OWN cached application context
 * (and therefore its own throwaway H2 database): its fixtures create
 * catalog/subject rows, and sharing a context with classes that assert
 * global catalog counts would make those assertions order-dependent.</p>
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestPropertySource(properties = "gamelearn.test.isolation=dashboard-mutation-protection")
class DashboardMutationProtectionTest {

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
    private RecommendationRepository recommendationRepository;
    @Autowired
    private AchievementRepository achievementRepository;
    @Autowired
    private LearningPathRepository learningPathRepository;
    @Autowired
    private LearningPathNodeRepository learningPathNodeRepository;
    @Autowired
    private AiInteractionRepository aiInteractionRepository;
    @Autowired
    private ProgressRepository progressRepository;
    @Autowired
    private QuizSubmissionService quizSubmissionService;
    @Autowired
    private JdbcTemplate jdbcTemplate;

    private record Principal(String token, UUID userId) {
    }

    private Principal principal(String label) {
        AuthResponse auth = authService.register(new RegisterRequest(
                label + "-" + UUID.randomUUID() + "@example.test",
                "Str0ng-Passw0rd!", "Learner " + label));
        return new Principal(auth.token(), auth.user().id());
    }

    @Test
    @DisplayName("DASH-TEST-023..026: adaptive/gamification/recommendation/path state byte-identical")
    void dashboardReadMutatesNoDomainState() throws Exception {
        Principal learner = principal("frozen");
        Subject subject = subject("frozen-subj");
        Topic topic = topic("frozen-topic", subject);

        // Rich state via the REAL pipeline: mastery rows + recommendations
        // (ACTIVE lifecycle) + XP ledger + unlocks + streak.
        Question q1 = questionFor(topic);
        Question q2 = questionFor(topic);
        Quiz quiz = quizWithQuestions(topic, q1, q2);
        quizSubmissionService.submit(learner.userId(), quiz.getId(),
                new QuizSubmissionRequest(List.of(
                        new QuizSubmissionRequest.SubmittedAnswer(q1.getId(), "a"),
                        new QuizSubmissionRequest.SubmittedAnswer(q2.getId(), "a"))));
        LearningPath path = pathWithNodes(learner.userId(), subject,
                List.of(topic), LearningPathStatus.ACTIVE);
        Achievement achievement = achievement("frz");
        achievementRepository.save(achievement);
        unlock(user(learner.userId()), achievement);

        List<Map<String, Object>> beforeProfile = snapshot(
                "SELECT * FROM learner_profiles WHERE user_id=?", learner.userId());
        List<Map<String, Object>> beforeMastery = snapshot(
                "SELECT * FROM topic_mastery WHERE user_id=? ORDER BY id", learner.userId());
        List<Map<String, Object>> beforeRecommendations = snapshot(
                "SELECT * FROM recommendations WHERE user_id=? ORDER BY id", learner.userId());
        List<Map<String, Object>> beforePaths = snapshot(
                "SELECT * FROM learning_paths WHERE user_id=? ORDER BY id", learner.userId());
        List<Map<String, Object>> beforeNodes = snapshot(
                "SELECT n.* FROM learning_path_nodes n JOIN learning_paths p "
                        + "ON p.id=n.learning_path_id WHERE p.user_id=? ORDER BY n.id",
                learner.userId());
        List<Map<String, Object>> beforeXp = snapshot(
                "SELECT * FROM xp_transactions WHERE user_id=? ORDER BY id", learner.userId());
        List<Map<String, Object>> beforeUnlocks = snapshot(
                "SELECT * FROM user_achievements WHERE user_id=? ORDER BY id", learner.userId());
        List<Map<String, Object>> beforeStreaks = snapshot(
                "SELECT * FROM streaks WHERE user_id=?", learner.userId());
        long progressRowsBefore = progressRepository.count();
        long aiRowsBefore = aiInteractionRepository.count();

        mockMvc.perform(get("/api/v1/dashboard")
                        .header("Authorization", "Bearer " + learner.token()))
                .andExpect(status().isOk());

        // DASH-TEST-023 — adaptive state untouched.
        assertThat(snapshot(
                "SELECT * FROM topic_mastery WHERE user_id=? ORDER BY id",
                learner.userId())).isEqualTo(beforeMastery);
        assertThat(snapshot(
                "SELECT * FROM learner_profiles WHERE user_id=?", learner.userId()))
                .isEqualTo(beforeProfile);

        // DASH-TEST-024 — gamification state untouched.
        assertThat(snapshot(
                "SELECT * FROM xp_transactions WHERE user_id=? ORDER BY id",
                learner.userId())).isEqualTo(beforeXp);
        assertThat(snapshot(
                "SELECT * FROM user_achievements WHERE user_id=? ORDER BY id",
                learner.userId())).isEqualTo(beforeUnlocks);
        assertThat(snapshot(
                "SELECT * FROM streaks WHERE user_id=?", learner.userId()))
                .isEqualTo(beforeStreaks);

        // DASH-TEST-025 — recommendation lifecycle untouched (no consumption).
        assertThat(snapshot(
                "SELECT * FROM recommendations WHERE user_id=? ORDER BY id",
                learner.userId())).isEqualTo(beforeRecommendations);
        Integer activeCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM recommendations WHERE user_id=? AND status='ACTIVE'",
                Integer.class, learner.userId());
        Integer consumedCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM recommendations WHERE user_id=? AND status='CONSUMED'",
                Integer.class, learner.userId());
        assertThat(activeCount).isEqualTo(beforeRecommendations.size());
        assertThat(consumedCount).isZero();

        // DASH-TEST-026 — learning-path tables untouched (no generation/archival).
        assertThat(snapshot(
                "SELECT * FROM learning_paths WHERE user_id=? ORDER BY id",
                learner.userId())).isEqualTo(beforePaths);
        assertThat(snapshot(
                "SELECT n.* FROM learning_path_nodes n JOIN learning_paths p "
                        + "ON p.id=n.learning_path_id WHERE p.user_id=? ORDER BY n.id",
                learner.userId())).isEqualTo(beforeNodes);
        assertThat(learningPathRepository.findById(path.getId())
                .orElseThrow().getStatus()).isEqualTo(LearningPathStatus.ACTIVE);

        // X9/X10 — no progress rows and no AI audit rows may appear.
        assertThat(progressRepository.count()).isEqualTo(progressRowsBefore);
        assertThat(aiInteractionRepository.count()).isEqualTo(aiRowsBefore);
    }

    @Test
    @DisplayName("DASH-TEST-027: zero AI activity — ai_interactions count stays flat")
    void zeroAiActivity() throws Exception {
        Principal learner = principal("noai");
        Subject subject = subject("noai-subj");
        Topic topic = topic("noai-topic", subject);
        Question q1 = questionFor(topic);
        Question q2 = questionFor(topic);
        Quiz quiz = quizWithQuestions(topic, q1, q2);
        quizSubmissionService.submit(learner.userId(), quiz.getId(),
                new QuizSubmissionRequest(List.of(
                        new QuizSubmissionRequest.SubmittedAnswer(q1.getId(), "a"),
                        new QuizSubmissionRequest.SubmittedAnswer(q2.getId(), "a"))));

        long before = aiInteractionRepository.count();
        mockMvc.perform(get("/api/v1/dashboard")
                        .header("Authorization", "Bearer " + learner.token()))
                .andExpect(status().isOk());
        assertThat(aiInteractionRepository.count()).isEqualTo(before);
    }

    @Test
    @DisplayName("DASH-TEST-025b: CONSUMED recommendations survive a dashboard read unchanged")
    void consumedRecommendationsUntouched() throws Exception {
        Principal learner = principal("consumed");
        Subject subject = subject("cons-subj");
        Topic topic = topic("cons-topic", subject);
        User user = user(learner.userId());

        Recommendation consumed = recommendation(user, topic, 2);
        consumed.setStatus(RecommendationStatus.CONSUMED);
        consumed.setConsumedAt(Instant.parse("2026-08-20T10:00:00Z"));
        recommendationRepository.saveAndFlush(consumed);
        Recommendation active = recommendation(user, topic, 1);
        recommendationRepository.saveAndFlush(active);

        List<Map<String, Object>> before = snapshot(
                "SELECT * FROM recommendations WHERE user_id=? ORDER BY id", learner.userId());
        mockMvc.perform(get("/api/v1/dashboard")
                        .header("Authorization", "Bearer " + learner.token()))
                .andExpect(status().isOk());

        assertThat(snapshot(
                "SELECT * FROM recommendations WHERE user_id=? ORDER BY id",
                learner.userId())).isEqualTo(before);
        assertThat(recommendationRepository.findById(active.getId())
                .orElseThrow().getStatus()).isEqualTo(RecommendationStatus.ACTIVE);
        assertThat(recommendationRepository.findById(consumed.getId())
                .orElseThrow().getStatus()).isEqualTo(RecommendationStatus.CONSUMED);
    }

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------

    private User user(UUID userId) {
        return userRepository.findById(userId).orElseThrow();
    }

    private List<Map<String, Object>> snapshot(String sql, Object... args) {
        return jdbcTemplate.queryForList(sql, args);
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

    private Quiz quizWithQuestions(Topic topic, Question q1, Question q2) {
        Quiz quiz = new Quiz();
        quiz.setTopic(topic);
        quiz.setTitle("Frozen Quiz " + UUID.randomUUID());
        quiz.setDifficulty(Difficulty.MEDIUM);
        quiz.setSourceType(SourceType.CURATED);
        quiz.setTimeLimitSeconds(600);
        quiz.setActive(true);
        quiz = quizRepository.saveAndFlush(quiz);
        associate(quiz, q1, 1);
        associate(quiz, q2, 2);
        return quiz;
    }

    private Question questionFor(Topic topic) {
        Question question = new Question();
        question.setTopic(topic);
        question.setQuestionText("Answer a? " + UUID.randomUUID());
        question.setQuestionType(QuestionType.MCQ);
        question.setDifficulty(Difficulty.EASY);
        question.setOptionsJson("{\"options\":[\"a\",\"wrong\"]}");
        question.setCorrectAnswer("a");
        question.setExplanation("because");
        question.setSourceType(SourceType.CURATED);
        question.setActive(true);
        return questionRepository.save(question);
    }

    private void associate(Quiz quiz, Question question, int order) {
        QuizQuestion link = new QuizQuestion();
        link.setQuiz(quiz);
        link.setQuestion(question);
        link.setQuestionOrder(order);
        quizQuestionRepository.save(link);
    }

    private Achievement achievement(String label) {
        Achievement achievement = new Achievement();
        achievement.setCode(label.toUpperCase() + "_" + UUID.randomUUID());
        achievement.setName(label + " Achievement");
        achievement.setDescription(label);
        achievement.setIconKey("achievement_" + label);
        achievement.setRuleType("THRESHOLD");
        achievement.setRuleConfigJson("{\"threshold\":100}");
        achievement.setXpReward(50);
        achievement.setActive(true);
        return achievement;
    }

    private void unlock(User user, Achievement achievement) {
        var unlock = new com.gamelearn.entity.UserAchievement();
        unlock.setUser(user);
        unlock.setAchievement(achievement);
        unlock.setUnlockedAt(Instant.now());
        userAchievementRepository.save(unlock);
    }

    @Autowired
    private com.gamelearn.repository.UserAchievementRepository userAchievementRepository;

    private Recommendation recommendation(User user, Topic topic, int priority) {
        Recommendation recommendation = new Recommendation();
        recommendation.setUser(user);
        recommendation.setTopic(topic);
        recommendation.setActivityType(RecommendationActivityType.PRACTICE);
        recommendation.setRecommendedDifficulty(Difficulty.EASY);
        recommendation.setReason("FROZEN_REC");
        recommendation.setPriority(priority);
        recommendation.setStatus(RecommendationStatus.ACTIVE);
        recommendation.setGeneratedAt(Instant.now());
        return recommendation;
    }

    private LearningPath pathWithNodes(UUID userId, Subject subject, List<Topic> topics,
                                       LearningPathStatus status) {
        LearningPath path = new LearningPath();
        path.setUser(user(userId));
        path.setSubject(subject);
        path.setTitle("Frozen Path " + UUID.randomUUID());
        path.setStatus(status);
        path.setGeneratedBy(GeneratedBy.AI);
        path = learningPathRepository.saveAndFlush(path);
        int sequence = 1;
        for (Topic topic : topics) {
            var node = new com.gamelearn.entity.LearningPathNode();
            node.setLearningPath(path);
            node.setTopic(topic);
            node.setSequenceNumber(sequence++);
            node.setRequiredMastery(BigDecimal.ZERO);
            node.setStatus(PathNodeStatus.AVAILABLE);
            learningPathNodeRepository.save(node);
        }
        learningPathNodeRepository.flush();
        return path;
    }
}
