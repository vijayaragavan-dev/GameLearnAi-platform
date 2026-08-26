package com.gamelearn.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;

import com.gamelearn.entity.Quiz;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;

import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class QuizRetrievalApiTest extends AbstractCoreApiTest {

    @Autowired
    private com.gamelearn.repository.QuestionRepository questionRepository;

    @Autowired
    private com.gamelearn.repository.QuizRepository quizRepository;

    @Autowired
    private com.gamelearn.repository.QuizQuestionRepository quizQuestionRepository;

    private Quiz newQuiz(String label, Topic topic, boolean active) {
        Quiz quiz = new Quiz();
        quiz.setTopic(topic);
        quiz.setTitle(label + " Quiz");
        quiz.setDescription(label + " quiz description");
        quiz.setDifficulty(com.gamelearn.entity.enums.Difficulty.MEDIUM);
        quiz.setSourceType(com.gamelearn.entity.enums.SourceType.CURATED);
        quiz.setTimeLimitSeconds(600);
        quiz.setActive(active);
        return quizRepository.save(quiz);
    }

    private com.gamelearn.entity.Question newQuestion(String label, Topic topic,
                                                      String correctAnswer) {
        com.gamelearn.entity.Question question = new com.gamelearn.entity.Question();
        question.setTopic(topic);
        question.setQuestionText(label + " question text?");
        question.setQuestionType(com.gamelearn.entity.enums.QuestionType.MCQ);
        question.setDifficulty(com.gamelearn.entity.enums.Difficulty.EASY);
        question.setOptionsJson("{\"options\":[\"" + correctAnswer + "\",\"other\"]}");
        question.setCorrectAnswer(correctAnswer);
        question.setExplanation(label + " explanation");
        question.setSourceType(com.gamelearn.entity.enums.SourceType.CURATED);
        question.setActive(true);
        return questionRepository.save(question);
    }

    private void associate(Quiz quiz, com.gamelearn.entity.Question question, int order) {
        com.gamelearn.entity.QuizQuestion association = new com.gamelearn.entity.QuizQuestion();
        association.setQuiz(quiz);
        association.setQuestion(question);
        association.setQuestionOrder(order);
        quizQuestionRepository.save(association);
    }

    @Test
    void returnsActiveQuizWithQuestionsButNeverCorrectAnswers() throws Exception {
        String[] learner = registerLearner("quizget");
        Subject subject = newActiveSubject("quizsubj", 1);
        Topic topic = newTopic("quiztopic", subject, true);
        Quiz quiz = newQuiz("network", topic, true);

        var q1 = newQuestion("q1", topic, "192.168.1.1");
        var q2 = newQuestion("q2", topic, "TCP");
        associate(quiz, q2, 2);
        associate(quiz, q1, 1);

        String body = mockMvc.perform(get("/api/v1/quiz/{id}", topic.getId())
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(quiz.getId().toString()))
                .andExpect(jsonPath("$.topicId").value(topic.getId().toString()))
                .andExpect(jsonPath("$.title").value("network Quiz"))
                .andExpect(jsonPath("$.difficulty").value("MEDIUM"))
                .andExpect(jsonPath("$.timeLimitSeconds").value(600))
                .andExpect(jsonPath("$.questionCount").value(2))
                .andExpect(jsonPath("$.questions.length()").value(2))
                // Ordered by question_order: q1 then q2.
                .andExpect(jsonPath("$.questions[0].id").value(q1.getId().toString()))
                .andExpect(jsonPath("$.questions[0].questionText").value("q1 question text?"))
                .andExpect(jsonPath("$.questions[0].options.length()").value(2))
                .andExpect(jsonPath("$.questions[0].options[0]").value("192.168.1.1"))
                .andExpect(jsonPath("$.questions[0].difficulty").value("EASY"))
                .andReturn().getResponse().getContentAsString();

        // Correct answers and explanations must never leak in delivery.
        org.assertj.core.api.Assertions.assertThat(body)
                .doesNotContain("correctAnswer")
                .doesNotContain("explanation")
                .doesNotContain("\"correct\"")
                .doesNotContain("isCorrect");
    }

    @Test
    void inactiveOrUnknownTopicOrMissingQuizReturns404() throws Exception {
        String[] learner = registerLearner("quiz404");

        mockMvc.perform(get("/api/v1/quiz/{id}", UUID.randomUUID())
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode").value("RESOURCE_NOT_FOUND"));

        // Active topic without any quiz -> 404 as well.
        Subject subject = newActiveSubject("noquiz", 1);
        Topic topicWithoutQuiz = newTopic("noquiztopic", subject, true);
        mockMvc.perform(get("/api/v1/quiz/{id}", topicWithoutQuiz.getId())
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isNotFound());

        // Inactive topic is hidden like any other content.
        Topic hiddenTopic = newTopic("hiddenquiztopic", subject, false);
        mockMvc.perform(get("/api/v1/quiz/{id}", hiddenTopic.getId())
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isNotFound());
    }

    @Test
    void malformedTopicIdRejectedAndAuthRequired() throws Exception {
        String[] learner = registerLearner("quizbad");

        mockMvc.perform(get("/api/v1/quiz/{id}", "' OR '1'='1")
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("MALFORMED_REQUEST"));

        mockMvc.perform(get("/api/v1/quiz/{id}", UUID.randomUUID()))
                .andExpect(status().isUnauthorized());
    }
}
