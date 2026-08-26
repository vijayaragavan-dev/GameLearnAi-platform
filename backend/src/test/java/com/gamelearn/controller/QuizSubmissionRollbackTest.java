package com.gamelearn.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;

import com.gamelearn.entity.Quiz;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.repository.QuestionAttemptRepository;

/**
 * Proves the Phase 4 atomicity requirement: if finalization fails partway,
 * everything rolls back and no partial attempt state remains.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class QuizSubmissionRollbackTest extends AbstractCoreApiTest {

    @Autowired
    private com.gamelearn.repository.QuestionRepository questionRepository;

    @Autowired
    private com.gamelearn.repository.QuizRepository quizRepository;

    @Autowired
    private com.gamelearn.repository.QuizQuestionRepository quizQuestionRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @MockitoSpyBean
    private QuestionAttemptRepository questionAttemptRepository;

    @Test
    void failureDuringFinalizationLeavesNoPartialAttempt() throws Exception {
        String[] learner = registerLearner("rollback");

        Subject subject = newActiveSubject("rollbacksubj", 1);
        Topic topic = newTopic("rollbacktopic", subject, true);
        Quiz quiz = new Quiz();
        quiz.setTopic(topic);
        quiz.setTitle("Rollback Quiz");
        quiz.setDifficulty(com.gamelearn.entity.enums.Difficulty.EASY);
        quiz.setSourceType(com.gamelearn.entity.enums.SourceType.CURATED);
        quiz.setActive(true);
        quiz = quizRepository.save(quiz);

        var q1 = question("rq1", topic, "a");
        var q2 = question("rq2", topic, "b");
        associate(quiz, q1, 1);
        associate(quiz, q2, 2);

        // Fail on the SECOND question-attempt insert (mid-transaction).
        org.mockito.Mockito.doThrow(new IllegalStateException("simulated persistence failure"))
                .when(questionAttemptRepository).save(org.mockito.ArgumentMatchers.argThat(
                        argument -> argument.getQuestion().getId().equals(q2.getId())));

        mockMvc.perform(post("/api/v1/quiz/{id}/submit", quiz.getId())
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "answers": [
                                    {"questionId": "%s", "selectedAnswer": "a"},
                                    {"questionId": "%s", "selectedAnswer": "b"}
                                  ] }
                                """.formatted(q1.getId(), q2.getId())))
                .andExpect(status().isInternalServerError());

        Integer attempts = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM quiz_attempts WHERE quiz_id = ?", Integer.class, quiz.getId());
        // Scoped to THIS quiz: other tests legitimately own question attempts.
        Integer orphanedQuestionAttempts = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM question_attempts qa "
                        + "JOIN quiz_attempts a ON a.id = qa.quiz_attempt_id WHERE a.quiz_id = ?",
                Integer.class, quiz.getId());
        assertThat(attempts).as("attempt must be rolled back").isZero();
        assertThat(orphanedQuestionAttempts)
                .as("no orphaned question attempts may remain").isZero();
    }

    private com.gamelearn.entity.Question question(String label, Topic topic, String correct) {
        var q = new com.gamelearn.entity.Question();
        q.setTopic(topic);
        q.setQuestionText(label + "?");
        q.setQuestionType(com.gamelearn.entity.enums.QuestionType.MCQ);
        q.setDifficulty(com.gamelearn.entity.enums.Difficulty.EASY);
        q.setOptionsJson("{\"options\":[\"" + correct + "\",\"wrong\"]}");
        q.setCorrectAnswer(correct);
        q.setExplanation(label + " because");
        q.setSourceType(com.gamelearn.entity.enums.SourceType.CURATED);
        q.setActive(true);
        return questionRepository.save(q);
    }

    private void associate(Quiz quiz, com.gamelearn.entity.Question q, int order) {
        var association = new com.gamelearn.entity.QuizQuestion();
        association.setQuiz(quiz);
        association.setQuestion(q);
        association.setQuestionOrder(order);
        quizQuestionRepository.save(association);
    }
}
