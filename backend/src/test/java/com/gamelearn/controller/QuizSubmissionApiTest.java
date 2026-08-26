package com.gamelearn.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

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

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class QuizSubmissionApiTest extends AbstractCoreApiTest {

    @Autowired
    private com.gamelearn.repository.QuestionRepository questionRepository;

    @Autowired
    private com.gamelearn.repository.QuizRepository quizRepository;

    @Autowired
    private com.gamelearn.repository.QuizQuestionRepository quizQuestionRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private record Fixture(Quiz quiz, com.gamelearn.entity.Question q1,
                           com.gamelearn.entity.Question q2, com.gamelearn.entity.Question q3) {
    }

    private Fixture threeQuestionQuiz() {
        Subject subject = newActiveSubject("submitsubj", 1);
        Topic topic = newTopic("submittopic", subject, true);
        Quiz quiz = new Quiz();
        quiz.setTopic(topic);
        quiz.setTitle("Submit Quiz");
        quiz.setDifficulty(com.gamelearn.entity.enums.Difficulty.MEDIUM);
        quiz.setSourceType(com.gamelearn.entity.enums.SourceType.CURATED);
        quiz.setActive(true);
        quiz = quizRepository.save(quiz);

        var q1 = question("q1", topic, "Paris");
        var q2 = question("q2", topic, "8");
        var q3 = question("q3", topic, "HTTP");
        associate(quiz, q1, 1);
        associate(quiz, q2, 2);
        associate(quiz, q3, 3);
        return new Fixture(quiz, q1, q2, q3);
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

    private void associate(Quiz quiz, com.gamelearn.entity.Question q, int order) {
        var association = new com.gamelearn.entity.QuizQuestion();
        association.setQuiz(quiz);
        association.setQuestion(q);
        association.setQuestionOrder(order);
        quizQuestionRepository.save(association);
    }

    private String submissionBody(String id, String answer) {
        return """
                { "answers": [ { "questionId": "%s", "selectedAnswer": "%s" } ] }
                """.formatted(id, answer);
    }

    @Test
    void mixedSubmissionIsEvaluatedServerSideAndPersistedAtomically() throws Exception {
        String[] learner = registerLearner("submit");
        Fixture fixture = threeQuestionQuiz();

        // q1 correct, q2 wrong, q3 unanswered (counts incorrect).
        String body = """
                {
                  "answers": [
                    {"questionId": "%s", "selectedAnswer": "Paris"},
                    {"questionId": "%s", "selectedAnswer": "wrong"}
                  ]
                }
                """.formatted(fixture.q1().getId(), fixture.q2().getId());

        MvcResult result = mockMvc.perform(post("/api/v1/quiz/{id}/submit", fixture.quiz().getId())
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.attemptId").isNotEmpty())
                .andExpect(jsonPath("$.quizId").value(fixture.quiz().getId().toString()))
                .andExpect(jsonPath("$.status").value("COMPLETED"))
                .andExpect(jsonPath("$.score").value(33.33))
                .andExpect(jsonPath("$.correctCount").value(1))
                .andExpect(jsonPath("$.totalQuestions").value(3))
                .andReturn();

        JsonNode json = objectMapper.readTree(result.getResponse().getContentAsString());
        UUID attemptId = UUID.fromString(json.get("attemptId").asText());

        // Authoritative rows in the database.
        var attempt = jdbcTemplate.queryForMap(
                "SELECT score, correct_count, total_questions, status FROM quiz_attempts WHERE id = ?",
                attemptId);
        assertThat(new java.math.BigDecimal(attempt.get("score").toString()))
                .isEqualByComparingTo(new java.math.BigDecimal("33.33"));
        assertThat(((Number) attempt.get("correct_count")).intValue()).isEqualTo(1);
        assertThat(((Number) attempt.get("total_questions")).intValue()).isEqualTo(3);
        assertThat(attempt.get("status")).isEqualTo("COMPLETED");

        Integer persistedAnswers = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM question_attempts WHERE quiz_attempt_id = ?",
                Integer.class, attemptId);
        assertThat(persistedAnswers).isEqualTo(3); // unanswered q3 also persisted

        // Correct answers revealed only AFTER submission.
        String response = result.getResponse().getContentAsString();
        assertThat(response).contains("\"correctAnswer\":\"Paris\"");
        assertThat(response).contains("\"isCorrect\":true");
        assertThat(response).contains("\"isCorrect\":false");
        // Unanswered question: selected null, not correct.
        assertThat(response).contains("\"selectedAnswer\":null");

        // Attempt belongs to the authenticated learner.
        Integer ownedRows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM quiz_attempts qa JOIN users u ON u.id = qa.user_id "
                        + "WHERE qa.id = ? AND u.email = ?",
                Integer.class, attemptId, learner[1]);
        assertThat(ownedRows).isEqualTo(1);
    }

    @Test
    void perfectAndZeroScoresAreExact() throws Exception {
        String[] learner = registerLearner("score");
        Fixture fixture = threeQuestionQuiz();

        mockMvc.perform(post("/api/v1/quiz/{id}/submit", fixture.quiz().getId())
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "answers": [
                                    {"questionId": "%s", "selectedAnswer": " Paris "},
                                    {"questionId": "%s", "selectedAnswer": "8"},
                                    {"questionId": "%s", "selectedAnswer": "HTTP"}
                                  ] }
                                """.formatted(fixture.q1().getId(), fixture.q2().getId(),
                                fixture.q3().getId())))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.score").value(100.00))
                .andExpect(jsonPath("$.correctCount").value(3));

        // All wrong: every option deliberately incorrect.
        mockMvc.perform(post("/api/v1/quiz/{id}/submit", fixture.quiz().getId())
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "answers": [
                                    {"questionId": "%s", "selectedAnswer": "wrong"},
                                    {"questionId": "%s", "selectedAnswer": "wrong"},
                                    {"questionId": "%s", "selectedAnswer": "wrong"}
                                  ] }
                                """.formatted(fixture.q1().getId(), fixture.q2().getId(),
                                fixture.q3().getId())))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.score").value(0.00))
                .andExpect(jsonPath("$.correctCount").value(0));

        // Two identical requests produced two independent attempts (history).
        Integer attempts = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM quiz_attempts WHERE quiz_id = ?", Integer.class,
                fixture.quiz().getId());
        assertThat(attempts).isEqualTo(2);
    }

    @Test
    void invalidSubmissionsAreRejectedSafely() throws Exception {
        String[] learner = registerLearner("badsubmit");
        Fixture fixture = threeQuestionQuiz();

        String submitUrl = "/api/v1/quiz/{id}/submit";

        // Empty answers.
        mockMvc.perform(post(submitUrl, fixture.quiz().getId())
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{ \"answers\": [] }"))
                .andExpect(status().isBadRequest());

        // Duplicate question in one payload.
        mockMvc.perform(post(submitUrl, fixture.quiz().getId())
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "answers": [
                                    {"questionId": "%s", "selectedAnswer": "Paris"},
                                    {"questionId": "%s", "selectedAnswer": "Paris"}
                                  ] }
                                """.formatted(fixture.q1().getId(), fixture.q1().getId())))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("MALFORMED_REQUEST"));

        // Question from another quiz.
        var stranger = threeQuestionQuiz();
        mockMvc.perform(post(submitUrl, fixture.quiz().getId())
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(submissionBody(stranger.q1().getId().toString(), "Paris")))
                .andExpect(status().isBadRequest());

        // Unknown quiz.
        mockMvc.perform(post(submitUrl, UUID.randomUUID())
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(submissionBody(UUID.randomUUID().toString(), "x")))
                .andExpect(status().isNotFound());

        // Unauthenticated.
        mockMvc.perform(post(submitUrl, fixture.quiz().getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(submissionBody(fixture.q1().getId().toString(), "Paris")))
                .andExpect(status().isUnauthorized());

        // No partial attempts must exist from the rejected calls above.
        Integer attemptsForQuiz = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM quiz_attempts WHERE quiz_id = ?",
                Integer.class, fixture.quiz().getId());
        assertThat(attemptsForQuiz).isZero();
    }

    @Test
    void clientCannotOverrideAuthoritativeFields() throws Exception {
        String[] learner = registerLearner("fake");
        Fixture fixture = threeQuestionQuiz();

        // Client claims everything is correct with a fake 100% score; backend
        // ignores unknown properties entirely (one wrong answer included).
        mockMvc.perform(post("/api/v1/quiz/{id}/submit", fixture.quiz().getId())
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "score": 100, "correctCount": 3, "status": "COMPLETED",
                                  "answers": [
                                    {"questionId": "%s", "selectedAnswer": "Paris", "isCorrect": true},
                                    {"questionId": "%s", "selectedAnswer": "wrong", "isCorrect": true},
                                    {"questionId": "%s", "selectedAnswer": "wrong", "isCorrect": true}
                                  ] }
                                """.formatted(fixture.q1().getId(), fixture.q2().getId(),
                                fixture.q3().getId())))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.score").value(33.33))
                .andExpect(jsonPath("$.correctCount").value(1))
                .andExpect(jsonPath("$.totalQuestions").value(3))
                .andExpect(jsonPath("$.results[?(@.questionId == '%s')].isCorrect"
                        .formatted(fixture.q2().getId())).value(false));
    }

    @Test
    void inactiveQuizCannotBeSubmitted() throws Exception {
        String[] learner = registerLearner("inactiveq");
        Subject subject = newActiveSubject("inactivesubj2", 2);
        Topic topic = newTopic("inactivetopic2", subject, true);
        Quiz quiz = new Quiz();
        quiz.setTopic(topic);
        quiz.setTitle("Closed Quiz");
        quiz.setDifficulty(com.gamelearn.entity.enums.Difficulty.EASY);
        quiz.setSourceType(com.gamelearn.entity.enums.SourceType.CURATED);
        quiz.setActive(true);
        quiz = quizRepository.save(quiz);
        var q = question("iq", topic, "a");
        associate(quiz, q, 1);
        quiz.setActive(false);
        quizRepository.saveAndFlush(quiz);

        mockMvc.perform(post("/api/v1/quiz/{id}/submit", quiz.getId())
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(submissionBody(q.getId().toString(), "a")))
                .andExpect(status().isNotFound());
    }

    @Test
    void getEndpointRemainsAvailableAfterSubmissions() throws Exception {
        String[] learner = registerLearner("stillget");
        Fixture fixture = threeQuestionQuiz();

        mockMvc.perform(post("/api/v1/quiz/{id}/submit", fixture.quiz().getId())
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(submissionBody(fixture.q1().getId().toString(), "Paris")))
                .andExpect(status().isCreated());

        mockMvc.perform(get("/api/v1/quiz/{id}", fixture.quiz().getTopic().getId())
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(fixture.quiz().getId().toString()));
    }
}
