package com.gamelearn.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

import com.fasterxml.jackson.databind.JsonNode;
import com.gamelearn.entity.Quiz;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;

/**
 * End-to-end verification of the quiz -> Adaptive Engine integration
 * (specification sections 15, 19, 26) against real persistence.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AdaptiveFlowIntegrationTest extends AbstractCoreApiTest {

    @Autowired
    private com.gamelearn.repository.QuestionRepository questionRepository;

    @Autowired
    private com.gamelearn.repository.QuizRepository quizRepository;

    @Autowired
    private com.gamelearn.repository.QuizQuestionRepository quizQuestionRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private record Fixture(Quiz quiz, com.gamelearn.entity.Question q1,
                           com.gamelearn.entity.Question q2) {
    }

    private Fixture twoQuestionQuiz(String label) {
        Subject subject = newActiveSubject(label + "subj", 1);
        Topic topic = newTopic(label + "topic", subject, true);
        Quiz quiz = new Quiz();
        quiz.setTopic(topic);
        quiz.setTitle(label + " Quiz");
        quiz.setDifficulty(com.gamelearn.entity.enums.Difficulty.MEDIUM);
        quiz.setSourceType(com.gamelearn.entity.enums.SourceType.CURATED);
        quiz.setActive(true);
        quiz = quizRepository.save(quiz);

        var q1 = question("a", topic);
        var q2 = question("b", topic);
        associate(quiz, q1, 1);
        associate(quiz, q2, 2);
        return new Fixture(quiz, q1, q2);
    }

    private com.gamelearn.entity.Question question(String correct, Topic topic) {
        var q = new com.gamelearn.entity.Question();
        q.setTopic(topic);
        q.setQuestionText("Answer " + correct + "?");
        q.setQuestionType(com.gamelearn.entity.enums.QuestionType.MCQ);
        q.setDifficulty(com.gamelearn.entity.enums.Difficulty.EASY);
        q.setOptionsJson("{\"options\":[\"" + correct + "\",\"wrong\"]}");
        q.setCorrectAnswer(correct);
        q.setExplanation("because");
        q.setSourceType(com.gamelearn.entity.enums.SourceType.CURATED);
        q.setActive(true);
        return questionRepository.save(q);
    }

    private void associate(Quiz quiz, com.gamelearn.entity.Question q, int order) {
        var link = new com.gamelearn.entity.QuizQuestion();
        link.setQuiz(quiz);
        link.setQuestion(q);
        link.setQuestionOrder(order);
        quizQuestionRepository.save(link);
    }

    private String body(UUID qId, String answer) {
        return """
                { "answers": [ { "questionId": "%s", "selectedAnswer": "%s" } ] }
                """.formatted(qId, answer);
    }

    private JsonNode submit(String token, UUID quizId, UUID qId, String answer) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/v1/quiz/{id}/submit", quizId)
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body(qId, answer)))
                .andExpect(status().isCreated())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    @Test
    void submissionProducesAdaptiveStateRecommendationAndProfileRefresh() throws Exception {
        String[] learner = registerLearner("adapt");
        Fixture fixture = twoQuestionQuiz("first");

        // First attempt: 1/2 correct -> accuracy 50.00.
        JsonNode root = submit(learner[0], fixture.quiz().getId(), fixture.q1().getId(), "a");
        JsonNode adaptive = root.get("adaptive");
        assertThat(adaptive.get("topicId").asText())
                .isEqualTo(fixture.quiz().getTopic().getId().toString());
        assertThat(adaptive.get("masteryScore").doubleValue()).isEqualTo(50.0);
        assertThat(adaptive.get("previousMasteryScore").isNull()).isTrue();
        assertThat(adaptive.get("masteryLevel").asText()).isEqualTo("DEVELOPING");
        assertThat(adaptive.get("trend").asText()).isEqualTo("INSUFFICIENT_DATA");
        assertThat(adaptive.get("nextDifficulty").asText()).isEqualTo("MEDIUM");
        assertThat(adaptive.get("recommendedActivity").asText()).isEqualTo("PRACTICE");
        assertThat(adaptive.get("reasonCode").asText())
                .isEqualTo("FIRST_ATTEMPT_BASELINE_SET");

        // topic_mastery persisted exactly per spec section 7.2.
        var mastery = jdbcTemplate.queryForMap(
                "SELECT tm.mastery_score, tm.mastery_level, tm.current_difficulty, "
                        + "tm.attempt_count, tm.recent_accuracy, tm.trend "
                        + "FROM topic_mastery tm JOIN users u ON u.id = tm.user_id "
                        + "WHERE u.email = ?",
                learner[1]);
        assertThat(new BigDecimal(mastery.get("mastery_score").toString()))
                .isEqualByComparingTo("50.00");
        assertThat(mastery.get("mastery_level")).isEqualTo("DEVELOPING");
        assertThat(((Number) mastery.get("attempt_count")).intValue()).isEqualTo(1);
        assertThat(mastery.get("trend")).isEqualTo("INSUFFICIENT_DATA");

        // Exactly one ACTIVE recommendation with priority and deterministic reason.
        Integer activeRecs = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM recommendations r JOIN users u ON u.id = r.user_id "
                        + "WHERE u.email = ? AND r.status = 'ACTIVE'",
                Integer.class, learner[1]);
        assertThat(activeRecs).isEqualTo(1);
        String reason = jdbcTemplate.queryForObject(
                "SELECT r.reason FROM recommendations r JOIN users u ON u.id = r.user_id "
                        + "WHERE u.email = ? AND r.status = 'ACTIVE'",
                String.class, learner[1]);
        assertThat(reason).startsWith("FIRST_ATTEMPT_BASELINE_SET:");
        Integer priority = jdbcTemplate.queryForObject(
                "SELECT r.priority FROM recommendations r JOIN users u ON u.id = r.user_id "
                        + "WHERE u.email = ? AND r.status = 'ACTIVE'",
                Integer.class, learner[1]);
        assertThat(priority).isEqualTo(2);

        // Profile refreshed: overall_mastery mirrors the single topic; current topic set.
        var profile = jdbcTemplate.queryForMap(
                "SELECT p.overall_mastery, p.current_topic_id, t.id IS NOT NULL AS has_topic "
                        + "FROM learner_profiles p "
                        + "LEFT JOIN topics t ON t.id = p.current_topic_id "
                        + "JOIN users u ON u.id = p.user_id WHERE u.email = ?",
                learner[1]);
        assertThat(new BigDecimal(profile.get("overall_mastery").toString()))
                .isEqualByComparingTo("50.00");
        assertThat(profile.get("current_topic_id")).isNotNull();

        // Gamification Engine (Phase 7, spec v1.0.0 section 9) awards in the
        // SAME transaction AFTER adaptive: score 50.00 -> base 10 + performance
        // round_half_up_2(50*0.15)=7 -> 7, plus FIRST_QUIZ reward 20 => 37.
        var gamification = jdbcTemplate.queryForMap(
                "SELECT p.total_xp, p.current_level FROM learner_profiles p "
                        + "JOIN users u ON u.id = p.user_id WHERE u.email = ?",
                learner[1]);
        assertThat(((Number) gamification.get("total_xp")).intValue()).isEqualTo(37);
        assertThat(((Number) gamification.get("current_level")).intValue()).isEqualTo(1);
    }

    private UUID userIdOf(String email) {
        return jdbcTemplate.queryForObject(
                "SELECT id FROM users WHERE email = ?", UUID.class, email);
    }

    @Test
    void secondSubmissionUpdatesMasterySupersedesRecommendationAndKeepsOneActive() throws Exception {
        String[] learner = registerLearner("second");

        Subject subject = newActiveSubject("secsujb2", 2);
        Topic topic = newTopic("sectopic2", subject, true);
        Quiz quiz = new Quiz();
        quiz.setTopic(topic);
        quiz.setTitle("Second Quiz");
        quiz.setDifficulty(com.gamelearn.entity.enums.Difficulty.MEDIUM);
        quiz.setSourceType(com.gamelearn.entity.enums.SourceType.CURATED);
        quiz.setActive(true);
        quiz = quizRepository.save(quiz);
        var q1 = question("x", topic);
        associate(quiz, q1, 1);

        // Attempt 1: correct -> 100.00 baseline.
        submit(learner[0], quiz.getId(), q1.getId(), "x");
        // Attempt 2: wrong -> accuracy 0.00, n=2: 100 + (-100)/2 = 50.00 DECLINING.
        JsonNode second = submit(learner[0], quiz.getId(), q1.getId(), "wrong");
        assertThat(second.get("adaptive").get("masteryScore").doubleValue()).isEqualTo(50.0);
        assertThat(second.get("adaptive").get("previousMasteryScore").doubleValue()).isEqualTo(100.0);
        assertThat(second.get("adaptive").get("masteryLevel").asText()).isEqualTo("DEVELOPING");
        assertThat(second.get("adaptive").get("trend").asText()).isEqualTo("DECLINING");
        assertThat(second.get("adaptive").get("nextDifficulty").asText()).isEqualTo("EASY");
        assertThat(second.get("adaptive").get("recommendedActivity").asText())
                .isEqualTo("REMEDIATION");
        assertThat(second.get("adaptive").get("reasonCode").asText())
                .isEqualTo("RECENT_DECLINE_REMEDIATION");

        // Supersede policy: old ACTIVE -> CONSUMED, exactly one new ACTIVE remains.
        Integer consumed = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM recommendations r JOIN users u ON u.id = r.user_id "
                        + "WHERE u.email = ? AND r.status = 'CONSUMED' "
                        + "AND r.activity_type = 'PRACTICE'",
                Integer.class, learner[1]);
        assertThat(consumed).isEqualTo(1);

        Integer active = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM recommendations r JOIN users u ON u.id = r.user_id "
                        + "WHERE u.email = ? AND r.status = 'ACTIVE'",
                Integer.class, learner[1]);
        assertThat(active).isEqualTo(1);

        String activeType = jdbcTemplate.queryForObject(
                "SELECT r.activity_type FROM recommendations r JOIN users u ON u.id = r.user_id "
                        + "WHERE u.email = ? AND r.status = 'ACTIVE'",
                String.class, learner[1]);
        assertThat(activeType).isEqualTo("REMEDIATION");

        // attempt_count grew to exactly 2 (no double-processing).
        Integer attempts = jdbcTemplate.queryForObject(
                "SELECT attempt_count FROM topic_mastery tm JOIN users u ON u.id = tm.user_id "
                        + "WHERE u.email = ?",
                Integer.class, learner[1]);
        assertThat(attempts).isEqualTo(2);

        // overall_mastery = mean of the single topic's masteries = 50.00.
        BigDecimal overall = jdbcTemplate.queryForObject(
                "SELECT p.overall_mastery FROM learner_profiles p "
                        + "JOIN users u ON u.id = p.user_id WHERE u.email = ?",
                BigDecimal.class, learner[1]);
        assertThat(overall).isEqualByComparingTo("50.00");
    }
}
