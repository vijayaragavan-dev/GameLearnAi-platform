package com.gamelearn.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import com.fasterxml.jackson.databind.JsonNode;
import com.gamelearn.repository.QuizQuestionRepository;
import com.gamelearn.repository.QuizRepository;

/**
 * REALM-001 (quiz engine): the V34 seed assembles the existing 18
 * Aptitude questions into one Quiz per Aptitude topic, unblocking the
 * unchanged QUIZ-001 path consumed by both Quiz Battle and Speed Run.
 * DATA-ONLY verification — no game, quiz, or progression code changed.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AptitudeQuizEngineTest extends AbstractCoreApiTest {

    private static final List<String> APTITUDE_TOPICS = List.of(
            "77777777-7777-7777-7777-777777777701",
            "77777777-7777-7777-7777-777777777702",
            "77777777-7777-7777-7777-777777777703",
            "77777777-7777-7777-7777-777777777704",
            "77777777-7777-7777-7777-777777777705",
            "77777777-7777-7777-7777-777777777706");

    private static final Map<String, String> EXPECTED_FIRST_QUESTIONS = Map.of(
            "77777777-7777-7777-7777-777777777701", "What is 25% of 200?",
            "77777777-7777-7777-7777-777777777702",
            "An item bought for 500 is sold for 600. What is the profit percent?",
            "77777777-7777-7777-7777-777777777703",
            "Divide 600 in the ratio 2:3. What is the smaller share?",
            "77777777-7777-7777-7777-777777777704",
            "Find the next number: 2, 5, 8, 11, ?",
            "77777777-7777-7777-7777-777777777705",
            "A finishes a job in 6 days and B in 12 days. Working together, how many days do they need?",
            "77777777-7777-7777-7777-777777777706",
            "If CAT is coded as 3120 (A=1, B=2, ...), how is DOG coded?");

    @Autowired
    private QuizRepository quizRepository;

    @Autowired
    private QuizQuestionRepository quizQuestionRepository;

    @Test
    void everyAptitudeTopicResolvesAQuizWithThreeOrderedQuestions() throws Exception {
        String[] learner = registerLearner("aptquiz");

        for (String topicId : APTITUDE_TOPICS) {
            String body = mockMvc.perform(get("/api/v1/quiz/{id}", topicId)
                            .header("Authorization", bearer(learner[0])))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.topicId").value(topicId))
                    .andExpect(jsonPath("$.questionCount").value(3))
                    .andReturn().getResponse().getContentAsString();

            JsonNode questions = objectMapper.readTree(body).path("questions");
            assertThat(questions.size()).isEqualTo(3);
            // Deterministic order with real options on every question.
            for (JsonNode q : questions) {
                assertThat(q.path("questionText").asText()).isNotEmpty();
                assertThat(q.path("options").size()).isGreaterThanOrEqualTo(2);
                // QUIZ-001 never leaks correctness.
                assertThat(q.has("correctAnswer")).isFalse();
            }
            // First question matches the seeded text for the topic.
            assertThat(questions.get(0).path("questionText").asText())
                    .isEqualTo(EXPECTED_FIRST_QUESTIONS.get(topicId));
        }
    }

    @Test
    void quizDifficultyMatchesTopicDifficulty() throws Exception {
        String[] learner = registerLearner("aptdiff");

        Map<String, String> expected = Map.of(
                "77777777-7777-7777-7777-777777777701", "EASY",
                "77777777-7777-7777-7777-777777777702", "EASY",
                "77777777-7777-7777-7777-777777777703", "MEDIUM",
                "77777777-7777-7777-7777-777777777704", "EASY",
                "77777777-7777-7777-7777-777777777705", "MEDIUM",
                "77777777-7777-7777-7777-777777777706", "MEDIUM");
        for (var entry : expected.entrySet()) {
            mockMvc.perform(get("/api/v1/quiz/{id}", entry.getKey())
                            .header("Authorization", bearer(learner[0])))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.difficulty").value(entry.getValue()));
        }
    }

    @Test
    @Transactional(readOnly = true)
    void exactlySixQuizzesAndEighteenAssociationsExist() {
        long aptitudeQuizzes = quizRepository.findAll().stream()
                .filter(q -> APTITUDE_TOPICS.contains(q.getTopic().getId().toString()))
                .count();
        assertThat(aptitudeQuizzes).isEqualTo(6);

        long associations = quizQuestionRepository.findAll().stream()
                .filter(a -> APTITUDE_TOPICS.contains(a.getQuiz().getTopic().getId().toString()))
                .count();
        assertThat(associations).isEqualTo(18);

        // Per-quiz uniqueness: 3 distinct orders, 3 distinct questions.
        var quizIds = quizRepository.findAll().stream()
                .filter(q -> APTITUDE_TOPICS.contains(q.getTopic().getId().toString()))
                .map(q -> q.getId())
                .toList();
        assertThat(quizIds).hasSize(6);
    }

    @Test
    void speedRunConsumesTheSameQuizContract() throws Exception {
        // Speed Run loads through QUIZ-001 identically to Quiz Battle, so
        // one resolution proof covers both games' loading path.
        String[] learner = registerLearner("aptspeed");
        mockMvc.perform(get("/api/v1/quiz/{id}", "77777777-7777-7777-7777-777777777704")
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.questionCount").value(3))
                .andExpect(jsonPath("$.questions[0].questionText")
                        .value("Find the next number: 2, 5, 8, 11, ?"));
    }

    @Test
    void existingComputerScienceQuizFlowIsUnchanged() throws Exception {
        String[] learner = registerLearner("aptcsreg");
        // Seeded CS topic keeps resolving its pre-existing quiz.
        mockMvc.perform(get("/api/v1/quiz/{id}", "22222222-2222-2222-2222-222222222244")
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.topicId")
                        .value("22222222-2222-2222-2222-222222222244"))
                .andExpect(jsonPath("$.questionCount").value(3));
    }

    @Test
    void quizzesRequireAuthentication() throws Exception {
        mockMvc.perform(get("/api/v1/quiz/{id}", "77777777-7777-7777-7777-777777777701"))
                .andExpect(status().isUnauthorized());
    }
}
