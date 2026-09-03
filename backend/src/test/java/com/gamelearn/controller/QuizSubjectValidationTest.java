package com.gamelearn.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import com.gamelearn.entity.Quiz;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.repository.QuestionRepository;
import com.gamelearn.repository.QuizQuestionRepository;
import com.gamelearn.repository.QuizRepository;

/**
 * Gate 6 P1-2: optional subjectId validation for QUIZ-001.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class QuizSubjectValidationTest extends AbstractCoreApiTest {

    @Autowired private QuizRepository quizRepository;
    @Autowired private QuestionRepository questionRepository;
    @Autowired private QuizQuestionRepository quizQuestionRepository;
    @Autowired private com.gamelearn.repository.SubjectRepository subjectRepository;

    private Quiz newQuiz(String label, Topic topic, boolean active) {
        Quiz quiz = new Quiz();
        quiz.setTopic(topic);
        quiz.setTitle(label + " Quiz");
        quiz.setDescription(label + " desc");
        quiz.setDifficulty(com.gamelearn.entity.enums.Difficulty.MEDIUM);
        quiz.setSourceType(com.gamelearn.entity.enums.SourceType.CURATED);
        quiz.setTimeLimitSeconds(600);
        quiz.setActive(active);
        return quizRepository.save(quiz);
    }

    private com.gamelearn.entity.Question newQuestion(String label, Topic topic, String correct) {
        com.gamelearn.entity.Question q = new com.gamelearn.entity.Question();
        q.setTopic(topic);
        q.setQuestionText(label + " text?");
        q.setQuestionType(com.gamelearn.entity.enums.QuestionType.MCQ);
        q.setDifficulty(com.gamelearn.entity.enums.Difficulty.EASY);
        q.setOptionsJson("{\"options\":[\"" + correct + "\",\"other\"]}");
        q.setCorrectAnswer(correct);
        q.setExplanation(label + " exp");
        q.setSourceType(com.gamelearn.entity.enums.SourceType.CURATED);
        q.setActive(true);
        return questionRepository.save(q);
    }

    private void associate(Quiz quiz, com.gamelearn.entity.Question q, int order) {
        com.gamelearn.entity.QuizQuestion a = new com.gamelearn.entity.QuizQuestion();
        a.setQuiz(quiz);
        a.setQuestion(q);
        a.setQuestionOrder(order);
        quizQuestionRepository.save(a);
    }

    @Test
    void omittedSubjectIdPreservesExistingBehavior() throws Exception {
        String[] learner = registerLearner("qsubjOm");
        Subject s = newActiveSubject("qsubjOmSub", 1);
        Topic t = newTopic("qsubjOmTopic", s, true);
        Quiz quiz = newQuiz("om", t, true);
        var q = newQuestion("q1", t, "A");
        associate(quiz, q, 1);

        mockMvc.perform(get("/api/v1/quiz/{id}", t.getId())
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(quiz.getId().toString()));
    }

    @Test
    void validSubjectIdSucceeds() throws Exception {
        String[] learner = registerLearner("qsubjValid");
        Subject s = newActiveSubject("qsubjValidSub", 1);
        Topic t = newTopic("qsubjValidTopic", s, true);
        Quiz quiz = newQuiz("valid", t, true);
        var q = newQuestion("q1", t, "A");
        associate(quiz, q, 1);

        mockMvc.perform(get("/api/v1/quiz/{id}", t.getId())
                        .param("subjectId", s.getId().toString())
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(quiz.getId().toString()));
    }

    @Test
    void nonexistentSubjectIdReturns404() throws Exception {
        String[] learner = registerLearner("qsubj404");
        Subject s = newActiveSubject("qsubj404Sub", 1);
        Topic t = newTopic("qsubj404Topic", s, true);
        Quiz quiz = newQuiz("404", t, true);
        var q = newQuestion("q1", t, "A");
        associate(quiz, q, 1);

        mockMvc.perform(get("/api/v1/quiz/{id}", t.getId())
                        .param("subjectId", UUID.randomUUID().toString())
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode").value("RESOURCE_NOT_FOUND"));
    }

    @Test
    void invalidSubjectIdReturns400Malformed() throws Exception {
        String[] learner = registerLearner("qsubjBad");
        Subject s = newActiveSubject("qsubjBadSub", 1);
        Topic t = newTopic("qsubjBadTopic", s, true);
        newQuiz("bad", t, true);

        mockMvc.perform(get("/api/v1/quiz/{id}", t.getId())
                        .param("subjectId", "not-a-uuid")
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("MALFORMED_REQUEST"));
    }

    @Test
    void mismatchedSubjectIdReturns400ValidationFailed() throws Exception {
        String[] learner = registerLearner("qsubjMis");
        Subject s1 = newActiveSubject("qsubjMisSub1", 1);
        Subject s2 = newActiveSubject("qsubjMisSub2", 2);
        Topic t = newTopic("qsubjMisTopic", s1, true);
        Quiz quiz = newQuiz("mis", t, true);
        var q = newQuestion("q1", t, "A");
        associate(quiz, q, 1);

        mockMvc.perform(get("/api/v1/quiz/{id}", t.getId())
                        .param("subjectId", s2.getId().toString())
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.fieldErrors.subjectId").value("does not match topic's subject"));
    }

    @Test
    void inactiveSubjectTreatedAsNotFound() throws Exception {
        String[] learner = registerLearner("qsubjInact");
        Subject s = newActiveSubject("qsubjInactSub2", 1);
        Topic t = newTopic("qsubjInactTopic2", s, true);
        newQuiz("inact2", t, true);
        Subject inactive = new Subject();
        inactive.setName("inactive" + UUID.randomUUID());
        inactive.setDescription("d");
        inactive.setIconKey("k");
        inactive.setActive(false);
        inactive.setDisplayOrder(99);
        inactive = subjectRepository.save(inactive);
        mockMvc.perform(get("/api/v1/quiz/{id}", t.getId())
                        .param("subjectId", inactive.getId().toString())
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode").value("RESOURCE_NOT_FOUND"));
    }
}
