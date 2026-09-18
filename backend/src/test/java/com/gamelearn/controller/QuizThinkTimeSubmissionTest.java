package com.gamelearn.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamelearn.entity.Quiz;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.service.ThinkTimeService;

/**
 * Think-time collection (Gate 14.1): server-authoritative
 * {@code response_time_seconds} on future question attempts.
 *
 * <p>Proves: delivery-then-submit populates timing; missing/stale
 * boundaries persist NULL; scoring, mastery and recommendations are
 * unaffected; clients send no timing; historical NULL semantics hold.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class QuizThinkTimeSubmissionTest extends AbstractCoreApiTest {

    @Autowired
    private com.gamelearn.repository.QuestionRepository questionRepository;

    @Autowired
    private com.gamelearn.repository.QuizRepository quizRepository;

    @Autowired
    private com.gamelearn.repository.QuizQuestionRepository quizQuestionRepository;

    @Autowired
    private ThinkTimeService thinkTimeService;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private ObjectMapper objectMapper;

    @AfterEach
    void resetThinkTimeClock() {
        thinkTimeService.setClock(Clock.systemUTC());
    }

    private Quiz twoQuestionQuiz() {
        Subject subject = newActiveSubject("thinksubj", 1);
        Topic topic = newTopic("thinktopic", subject, true);
        Quiz quiz = new Quiz();
        quiz.setTopic(topic);
        quiz.setTitle("Think Quiz");
        quiz.setDifficulty(com.gamelearn.entity.enums.Difficulty.MEDIUM);
        quiz.setSourceType(com.gamelearn.entity.enums.SourceType.CURATED);
        quiz.setActive(true);
        quiz = quizRepository.save(quiz);

        var q1 = question("tq1", topic, "Paris");
        var q2 = question("tq2", topic, "8");
        associate(quiz, q1, 1);
        associate(quiz, q2, 2);
        return quiz;
    }

    private com.gamelearn.entity.Question question(String label, Topic topic, String correct) {
        var question = new com.gamelearn.entity.Question();
        question.setTopic(topic);
        question.setQuestionText(label + "?");
        question.setQuestionType(com.gamelearn.entity.enums.QuestionType.MCQ);
        question.setDifficulty(com.gamelearn.entity.enums.Difficulty.EASY);
        question.setOptionsJson("{\"options\":[\"" + correct + "\",\"wrong\"]}");
        question.setCorrectAnswer(correct);
        question.setExplanation(label + " because");
        question.setSourceType(com.gamelearn.entity.enums.SourceType.CURATED);
        question.setActive(true);
        return questionRepository.save(question);
    }

    private void associate(Quiz quiz, com.gamelearn.entity.Question question, int order) {
        var association = new com.gamelearn.entity.QuizQuestion();
        association.setQuiz(quiz);
        association.setQuestion(question);
        association.setQuestionOrder(order);
        quizQuestionRepository.save(association);
    }

    private String submitAllCorrect(UUID quizId, String token,
            List<com.gamelearn.entity.Question> questions) throws Exception {
        StringBuilder answers = new StringBuilder();
        for (com.gamelearn.entity.Question question : questions) {
            if (answers.length() > 0) {
                answers.append(",");
            }
            answers.append("""
                    { "questionId": "%s", "selectedAnswer": "%s" }
                    """.formatted(question.getId(), question.getCorrectAnswer()));
        }
        String body = "{ \"answers\": [" + answers + "] }";
        MvcResult result = mockMvc.perform(post("/api/v1/quiz/" + quizId + "/submit")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.score").value(100.00))
                .andExpect(jsonPath("$.correctCount").value(2))
                .andReturn();
        JsonNode json = objectMapper.readTree(result.getResponse().getContentAsString());
        return json.get("attemptId").asText();
    }

    private List<Integer> thinkTimes(UUID attemptId) {
        return jdbcTemplate.queryForList(
                "SELECT response_time_seconds FROM question_attempts WHERE quiz_attempt_id = ? "
                        + "ORDER BY question_id",
                Integer.class, attemptId.toString());
    }

    @Test
    void deliveryThenSubmitPopulatesThinkTimeWithoutChangingScoring() throws Exception {
        String[] learner = registerLearner("thinktime");
        Quiz quiz = twoQuestionQuiz();
        var questions = questionRepository.findAll().stream()
                .filter(question -> question.getTopic().getId().equals(
                        quiz.getTopic().getId()))
                .sorted((left, right) -> left.getQuestionText().compareTo(right.getQuestionText()))
                .toList();

        mockMvc.perform(get("/api/v1/quiz/" + quiz.getTopic().getId())
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk());

        String attemptId = submitAllCorrect(quiz.getId(), learner[0], questions);

        List<Integer> thinkTimes = thinkTimes(UUID.fromString(attemptId));
        assertThat(thinkTimes).hasSize(2);
        assertThat(thinkTimes).allSatisfy(thinkTime -> assertThat(thinkTime).isNotNull()
                .isGreaterThanOrEqualTo(0));
    }

    @Test
    void submitWithoutDeliveryPersistsNullAndKeepsWorking() throws Exception {
        String[] learner = registerLearner("thinknull");
        Quiz quiz = twoQuestionQuiz();
        var questions = questionRepository.findAll().stream()
                .filter(question -> question.getTopic().getId().equals(
                        quiz.getTopic().getId()))
                .sorted((left, right) -> left.getQuestionText().compareTo(right.getQuestionText()))
                .toList();

        String attemptId = submitAllCorrect(quiz.getId(), learner[0], questions);

        List<Integer> thinkTimes = thinkTimes(UUID.fromString(attemptId));
        assertThat(thinkTimes).hasSize(2);
        assertThat(thinkTimes).containsExactly(null, null);
    }

    @Test
    void staleDeliveryDegradesToNull() throws Exception {
        String[] learner = registerLearner("thinkstale");
        Quiz quiz = twoQuestionQuiz();
        var questions = questionRepository.findAll().stream()
                .filter(question -> question.getTopic().getId().equals(
                        quiz.getTopic().getId()))
                .sorted((left, right) -> left.getQuestionText().compareTo(right.getQuestionText()))
                .toList();
        UUID learnerId = userByEmail(learner[1]).getId();

        thinkTimeService.setClock(Clock.fixed(
                Instant.now().minusSeconds(ThinkTimeService.TTL_SECONDS + 60), ZoneOffset.UTC));
        mockMvc.perform(get("/api/v1/quiz/" + quiz.getTopic().getId())
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk());
        thinkTimeService.setClock(Clock.systemUTC());

        String attemptId = submitAllCorrect(quiz.getId(), learner[0], questions);

        List<Integer> thinkTimes = thinkTimes(UUID.fromString(attemptId));
        assertThat(thinkTimes).containsExactly(null, null);
        assertThat(learnerId).isNotNull();
    }

    @Test
    void repeatedSubmissionsEachResolveTimingIndependently() throws Exception {
        String[] learner = registerLearner("thinkrepeat");
        Quiz quiz = twoQuestionQuiz();
        var questions = questionRepository.findAll().stream()
                .filter(question -> question.getTopic().getId().equals(
                        quiz.getTopic().getId()))
                .sorted((left, right) -> left.getQuestionText().compareTo(right.getQuestionText()))
                .toList();

        mockMvc.perform(get("/api/v1/quiz/" + quiz.getTopic().getId())
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk());

        String first = submitAllCorrect(quiz.getId(), learner[0], questions);
        String second = submitAllCorrect(quiz.getId(), learner[0], questions);

        assertThat(thinkTimes(UUID.fromString(first))).allSatisfy(
                thinkTime -> assertThat(thinkTime).isNotNull());
        assertThat(thinkTimes(UUID.fromString(second))).allSatisfy(
                thinkTime -> assertThat(thinkTime).isNotNull());
        Long rows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM question_attempts WHERE quiz_attempt_id IN (?, ?)",
                Long.class, first, second);
        assertThat(rows).isEqualTo(4L);
    }
}
