package com.gamelearn.gamification;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.UUID;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import com.gamelearn.service.AuthService;
import com.gamelearn.dto.AuthResponse;
import com.gamelearn.dto.QuizSubmissionRequest;
import com.gamelearn.dto.RegisterRequest;
import com.gamelearn.entity.Quiz;
import com.gamelearn.entity.Question;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.entity.enums.SourceType;
import com.gamelearn.repository.QuestionRepository;
import com.gamelearn.repository.QuizQuestionRepository;
import com.gamelearn.repository.QuizRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.UserRepository;
import com.gamelearn.service.QuizSubmissionService;

/**
 * Stage 6/7 — GAM-001..003 HTTP contract verification: authentication,
 * principal scoping, exact response shapes/nullability, zero-state and
 * populated state, max-level nullability.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class GamificationControllerTest {

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

    // ------------------------------------------------------------------
    // SEC-01 / authentication boundary
    // ------------------------------------------------------------------

    @Test
    @DisplayName("Anonymous access to every GAM endpoint is 401 UNAUTHORIZED")
    void anonymousAccessRejected() throws Exception {
        mockMvc.perform(get("/api/v1/gamification/summary")).andExpect(status().isUnauthorized());
        mockMvc.perform(get("/api/v1/achievements")).andExpect(status().isUnauthorized());
        mockMvc.perform(get("/api/v1/streak")).andExpect(status().isUnauthorized());
    }

    // ------------------------------------------------------------------
    // GAM-001 zero-state and populated state
    // ------------------------------------------------------------------

    @Test
    void summaryZeroStateAndPopulatedState() throws Exception {
        Principal fresh = principal("gamsum");
        mockMvc.perform(get("/api/v1/gamification/summary")
                        .header("Authorization", "Bearer " + fresh.token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalXp").value(0))
                .andExpect(jsonPath("$.currentLevel").value(1))
                .andExpect(jsonPath("$.maxLevel").value(50))
                .andExpect(jsonPath("$.nextLevelThresholdXp").value(100))
                .andExpect(jsonPath("$.xpToNextLevel").value(100))
                .andExpect(jsonPath("$.currentStreakDays").value(0))
                .andExpect(jsonPath("$.longestStreakDays").value(0))
                .andExpect(jsonPath("$.achievementCount").value(0));

        Principal earner = principal("gamearn");
        perfectSubmission(earner.userId());
        mockMvc.perform(get("/api/v1/gamification/summary")
                        .header("Authorization", "Bearer " + earner.token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalXp").value(115))
                .andExpect(jsonPath("$.currentLevel").value(2))
                .andExpect(jsonPath("$.nextLevelThresholdXp").value(300))
                .andExpect(jsonPath("$.xpToNextLevel").value(185))
                .andExpect(jsonPath("$.achievementCount").value(3));
    }

    @Test
    @DisplayName("LVL-06/G13: at MAX_LEVEL the next-level fields are null while XP shows")
    void maxLevelNullability() throws Exception {
        Principal capped = principal("gammax");
        jdbcTemplate.update(
                "UPDATE learner_profiles SET total_xp=130000, current_level=50 "
                        + "WHERE user_id=?", capped.userId());
        mockMvc.perform(get("/api/v1/gamification/summary")
                        .header("Authorization", "Bearer " + capped.token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalXp").value(130000))
                .andExpect(jsonPath("$.currentLevel").value(50))
                .andExpect(jsonPath("$.nextLevelThresholdXp").doesNotExist())
                .andExpect(jsonPath("$.xpToNextLevel").doesNotExist());
    }

    // ------------------------------------------------------------------
    // GAM-002 catalog with locked/unlocked mix
    // ------------------------------------------------------------------

    @Test
    void achievementCatalogMixesLockedAndUnlocked() throws Exception {
        Principal learner = principal("gamach");
        perfectSubmission(learner.userId());

        String body = mockMvc.perform(get("/api/v1/achievements")
                        .header("Authorization", "Bearer " + learner.token()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        var root = new com.fasterxml.jackson.databind.ObjectMapper().readTree(body);

        org.assertj.core.api.Assertions.assertThat(root).hasSize(6);
        var byCode = new java.util.HashMap<String, com.fasterxml.jackson.databind.JsonNode>();
        root.forEach(item -> byCode.put(item.get("code").asText(), item));

        assertThat(byCode.get("FIRST_QUIZ").get("unlockedAt").isNull()).isFalse();
        assertThat(byCode.get("PERFECT_SCORE").get("unlockedAt").isNull()).isFalse();
        assertThat(byCode.get("FIRST_MASTERED").get("unlockedAt").isNull()).isFalse();
        assertThat(byCode.get("TEN_QUIZZES").get("unlockedAt").isNull()).isTrue();
        assertThat(byCode.get("STREAK_3").get("xpReward").asInt()).isEqualTo(20);
        assertThat(byCode.get("WEEK_WARRIOR").get("name").asText()).isEqualTo("Week Warrior");
    }

    // ------------------------------------------------------------------
    // GAM-003 zero-state and populated streak
    // ------------------------------------------------------------------

    @Test
    void streakZeroStateThenPopulated() throws Exception {
        Principal learner = principal("gamstreakread");
        mockMvc.perform(get("/api/v1/streak")
                        .header("Authorization", "Bearer " + learner.token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.currentStreakDays").value(0))
                .andExpect(jsonPath("$.longestStreakDays").value(0))
                .andExpect(jsonPath("$.lastLearningDate").doesNotExist())
                .andExpect(jsonPath("$.timezone").value("UTC"));

        perfectSubmission(learner.userId());
        String today = java.time.LocalDate.now(java.time.ZoneOffset.UTC).toString();
        mockMvc.perform(get("/api/v1/streak")
                        .header("Authorization", "Bearer " + learner.token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.currentStreakDays").value(1))
                .andExpect(jsonPath("$.lastLearningDate").value(today))
                .andExpect(jsonPath("$.timezone").value("UTC"));
    }

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------

    private void perfectSubmission(UUID userId) {
        User learner = userRepository.findById(userId).orElseThrow();
        Subject subject = new Subject();
        subject.setName("gammc " + UUID.randomUUID());
        subject.setDescription("x");
        subject.setIconKey("icon");
        subject.setActive(true);
        subject.setDisplayOrder(1);
        subjectRepository.save(subject);
        Topic topic = new Topic();
        topic.setSubject(subject);
        topic.setName("gammc topic " + UUID.randomUUID());
        topic.setDescription("d");
        topic.setDifficulty(Difficulty.EASY);
        topic.setDisplayOrder(1);
        topic.setActive(true);
        topicRepository.save(topic);

        Quiz quiz = new Quiz();
        quiz.setTopic(topic);
        quiz.setTitle("MC Quiz");
        quiz.setDifficulty(Difficulty.MEDIUM);
        quiz.setSourceType(SourceType.CURATED);
        quiz.setActive(true);
        quiz = quizRepository.save(quiz);

        Question q1 = question("a", topic);
        Question q2 = question("b", topic);
        associate(quiz, q1, 1);
        associate(quiz, q2, 2);

        quizSubmissionService.submit(userId, quiz.getId(),
                new QuizSubmissionRequest(java.util.List.of(
                        new QuizSubmissionRequest.SubmittedAnswer(q1.getId(), "a"),
                        new QuizSubmissionRequest.SubmittedAnswer(q2.getId(), "b"))));
    }

    private Question question(String correct, Topic topic) {
        Question q = new Question();
        q.setTopic(topic);
        q.setQuestionText("Answer " + correct + "?");
        q.setQuestionType(com.gamelearn.entity.enums.QuestionType.MCQ);
        q.setDifficulty(Difficulty.EASY);
        q.setOptionsJson("{\"options\":[\"" + correct + "\",\"wrong\"]}");
        q.setCorrectAnswer(correct);
        q.setExplanation("because");
        q.setSourceType(SourceType.CURATED);
        q.setActive(true);
        return questionRepository.save(q);
    }

    private void associate(Quiz quiz, Question q, int order) {
        var link = new com.gamelearn.entity.QuizQuestion();
        link.setQuiz(quiz);
        link.setQuestion(q);
        link.setQuestionOrder(order);
        quizQuestionRepository.save(link);
    }
}
