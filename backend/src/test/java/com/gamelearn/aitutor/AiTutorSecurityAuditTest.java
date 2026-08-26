package com.gamelearn.aitutor;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamelearn.ai.gemini.GenerationOptions;
import com.gamelearn.ai.gemini.GeminiClient;
import com.gamelearn.ai.gemini.GeminiPrompt;
import com.gamelearn.dto.AuthResponse;
import com.gamelearn.dto.QuizSubmissionRequest;
import com.gamelearn.dto.RegisterRequest;
import com.gamelearn.entity.Achievement;
import com.gamelearn.entity.LearningPath;
import com.gamelearn.entity.LearningPathNode;
import com.gamelearn.entity.Question;
import com.gamelearn.entity.Quiz;
import com.gamelearn.entity.QuizQuestion;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.entity.enums.GeneratedBy;
import com.gamelearn.entity.enums.LearningPathStatus;
import com.gamelearn.entity.enums.PathNodeStatus;
import com.gamelearn.entity.enums.QuestionType;
import com.gamelearn.entity.enums.SourceType;
import com.gamelearn.repository.AchievementRepository;
import com.gamelearn.repository.LearningPathNodeRepository;
import com.gamelearn.repository.LearningPathRepository;
import com.gamelearn.repository.ProgressRepository;
import com.gamelearn.repository.QuestionRepository;
import com.gamelearn.repository.QuizQuestionRepository;
import com.gamelearn.repository.QuizRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.UserAchievementRepository;
import com.gamelearn.repository.UserRepository;
import com.gamelearn.service.AuthService;
import com.gamelearn.service.QuizSubmissionService;

/**
 * Phase 10B - TUT-TEST-026..031 (domain immutability), 037 (audit
 * sanitization) and 038 (log security). Opening the tutor must leave every
 * domain-owned table byte-identical; audit rows carry counts/categories
 * only, never question/history/answer text; logs never contain learner or
 * answer content.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestPropertySource(properties = {
        "gamelearn.ai.tutor.enabled=true",
        "gamelearn.ai.gemini.api-key=test-dummy-key-not-real",
        "gamelearn.ai.gemini.model=test-model",
        "gamelearn.ai.tutor.retry.backoff-base=10ms"
})
@ExtendWith(OutputCaptureExtension.class)
class AiTutorSecurityAuditTest {

    private static final ObjectMapper MAPPER = new ObjectMapper();
    private static final String URL = "/api/v1/ai/tutor";

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
    private LearningPathRepository learningPathRepository;
    @Autowired
    private LearningPathNodeRepository learningPathNodeRepository;
    @Autowired
    private AchievementRepository achievementRepository;
    @Autowired
    private UserAchievementRepository userAchievementRepository;
    @Autowired
    private ProgressRepository progressRepository;
    @Autowired
    private QuizSubmissionService quizSubmissionService;
    @Autowired
    private JdbcTemplate jdbcTemplate;
    @MockitoBean
    private GeminiClient geminiClient;

    private record Principal(String token, UUID userId) {
    }

    private Principal principal(String label) {
        AuthResponse auth = authService.register(new RegisterRequest(
                label + "-" + UUID.randomUUID() + "@example.test",
                "Str0ng-Passw0rd!", "Learner " + label));
        return new Principal(auth.token(), auth.user().id());
    }

    @Test
    @DisplayName("TUT-TEST-026..031: tutor call mutates NO domain state; only audit grows")
    void domainTablesByteIdentical() throws Exception {
        Principal learner = principal("frozen");
        Subject subject = subject("frz-subj");
        Topic topic = topic("frz-topic", subject);

        // Real pipeline: mastery + recommendations + xp + streak + unlock.
        Question q1 = questionFor(topic);
        Question q2 = questionFor(topic);
        Quiz quiz = quizWithQuestions(topic, q1, q2);
        quizSubmissionService.submit(learner.userId(), quiz.getId(),
                new QuizSubmissionRequest(List.of(
                        new QuizSubmissionRequest.SubmittedAnswer(q1.getId(), "a"),
                        new QuizSubmissionRequest.SubmittedAnswer(q2.getId(), "a"))));
        activePath(user(learner.userId()), subject, List.of(topic));
        Achievement achievement = achievement("tutfrozen");
        achievementRepository.save(achievement);
        var unlock = new com.gamelearn.entity.UserAchievement();
        unlock.setUser(user(learner.userId()));
        unlock.setAchievement(achievement);
        unlock.setUnlockedAt(Instant.now());
        userAchievementRepository.save(unlock);

        long beforeAuditRows = aiInteractionCount();
        long beforeProgress = progressRepository.count();

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

        when(geminiClient.generate(any(GeminiPrompt.class), any(GenerationOptions.class)))
                .thenReturn("{\"answer\":\"study tip\"}");
        mockMvc.perform(post(URL)
                        .header("Authorization", "Bearer " + learner.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body("explain my weakest topic")))
                .andReturn().getResponse().getStatus();

        assertThat(snapshot("SELECT * FROM learner_profiles WHERE user_id=?",
                learner.userId())).isEqualTo(beforeProfile);
        assertThat(snapshot("SELECT * FROM topic_mastery WHERE user_id=? ORDER BY id",
                learner.userId())).isEqualTo(beforeMastery);
        assertThat(snapshot("SELECT * FROM recommendations WHERE user_id=? ORDER BY id",
                learner.userId())).isEqualTo(beforeRecommendations);
        assertThat(snapshot("SELECT * FROM learning_paths WHERE user_id=? ORDER BY id",
                learner.userId())).isEqualTo(beforePaths);
        assertThat(snapshot("SELECT n.* FROM learning_path_nodes n JOIN learning_paths p "
                        + "ON p.id=n.learning_path_id WHERE p.user_id=? ORDER BY n.id",
                learner.userId())).isEqualTo(beforeNodes);
        assertThat(snapshot("SELECT * FROM xp_transactions WHERE user_id=? ORDER BY id",
                learner.userId())).isEqualTo(beforeXp);
        assertThat(snapshot("SELECT * FROM user_achievements WHERE user_id=? ORDER BY id",
                learner.userId())).isEqualTo(beforeUnlocks);
        assertThat(snapshot("SELECT * FROM streaks WHERE user_id=?",
                learner.userId())).isEqualTo(beforeStreaks);
        assertThat(progressRepository.count()).isEqualTo(beforeProgress);

        // The ONLY growth: exactly one sanitized TUTOR audit row.
        Long tutorRows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM ai_interactions WHERE user_id=? AND interaction_type='TUTOR'",
                Long.class, learner.userId());
        assertThat(tutorRows).isEqualTo(beforeAuditRows + 1);
    }

    @Test
    @DisplayName("TUT-TEST-037/038: audit rows are counts-only; logs carry no content")
    void auditAndLogsStaySanitized(CapturedOutput output) throws Exception {
        Principal learner = principal("audit");
        String questionSentinel = "WHERE-IS-THE-" + UUID.randomUUID() + "-treasure";
        String answerSentinel = "ANSWER-CONTENTS-" + UUID.randomUUID();

        when(geminiClient.generate(any(GeminiPrompt.class), any(GenerationOptions.class)))
                .thenReturn("{\"answer\":\"" + answerSentinel + "\"}");

        mockMvc.perform(post(URL)
                        .header("Authorization", "Bearer " + learner.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(questionSentinel)))
                .andReturn().getResponse().getStatus();

        Map<String, Object> row = jdbcTemplate.queryForMap(
                "SELECT * FROM ai_interactions WHERE user_id=? AND interaction_type='TUTOR' "
                        + "ORDER BY created_at DESC, id DESC LIMIT 1",
                learner.userId());
        // H2 hands JSON columns back as byte[] - normalize for assertions.
        row.replaceAll((key, value) -> value instanceof byte[] bytes
                ? new String(bytes, java.nio.charset.StandardCharsets.UTF_8) : value);
        assertThat(row.get("interaction_type")).isEqualTo("TUTOR");
        assertThat(row.get("status")).isEqualTo("SUCCESS");
        assertThat((String) row.get("prompt_version")).isEqualTo("ai-tutor-v1.0");
        assertThat(row.get("model_name")).isEqualTo("test-model");
        assertThat(row.get("latency_ms")).isNotNull();

        JsonNode requestContext = MAPPER.readTree((String) row.get("request_context_json"));
        assertThat(requestContext.has("questionChars")).isTrue();
        assertThat(requestContext.has("historyMessages")).isTrue();
        JsonNode responseJson = MAPPER.readTree((String) row.get("response_json"));
        assertThat(responseJson.has("answerChars")).isTrue();
        assertThat(responseJson.has("truncated")).isTrue();

        String entireRow = String.valueOf(row);
        assertThat(entireRow).doesNotContain(questionSentinel);
        assertThat(entireRow).doesNotContain(answerSentinel);

        // Logs: summary lines only - never the question or the answer.
        mockMvc.perform(get("/actuator/health")).andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isOk());
        assertThat(output.getAll()).contains("TUT_ANSWERED");
        assertThat(output.getAll()).doesNotContain(questionSentinel);
        assertThat(output.getAll()).doesNotContain(answerSentinel);
        assertThat(output.getAll()).doesNotContain("test-dummy-key-not-real");
    }

    private String body(String question) {
        return MAPPER.createObjectNode().put("question", question).toString();
    }

    private User user(UUID userId) {
        return userRepository.findById(userId).orElseThrow();
    }

    private List<Map<String, Object>> snapshot(String sql, Object... args) {
        return jdbcTemplate.queryForList(sql, args);
    }

    private long aiInteractionCount() {
        return jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM ai_interactions", Long.class);
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
        quiz.setTitle("Tutor Audit Quiz " + UUID.randomUUID());
        quiz.setDifficulty(Difficulty.EASY);
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
        question.setQuestionText("Q " + UUID.randomUUID());
        question.setQuestionType(QuestionType.MCQ);
        question.setDifficulty(Difficulty.EASY);
        question.setOptionsJson("{\"options\":[\"a\",\"b\"]}");
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

    private LearningPath activePath(User user, Subject subject, List<Topic> topics) {
        LearningPath path = new LearningPath();
        path.setUser(user);
        path.setSubject(subject);
        path.setTitle("Frozen Path " + UUID.randomUUID());
        path.setStatus(LearningPathStatus.ACTIVE);
        path.setGeneratedBy(GeneratedBy.SYSTEM);
        path = learningPathRepository.saveAndFlush(path);
        int sequence = 1;
        for (Topic topic : topics) {
            LearningPathNode node = new LearningPathNode();
            node.setLearningPath(path);
            node.setTopic(topic);
            node.setSequenceNumber(sequence++);
            node.setRequiredMastery(BigDecimal.ZERO);
            node.setStatus(PathNodeStatus.AVAILABLE);
            learningPathNodeRepository.save(node);
        }
        return path;
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
}
