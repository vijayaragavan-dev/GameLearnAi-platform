package com.gamelearn.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;

import com.gamelearn.dto.AuthResponse;
import com.gamelearn.dto.QuizSubmissionRequest;
import com.gamelearn.entity.Question;
import com.gamelearn.entity.Quiz;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.repository.QuestionRepository;
import com.gamelearn.repository.QuizQuestionRepository;
import com.gamelearn.repository.QuizRepository;
import com.gamelearn.repository.RecommendationRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicMasteryRepository;
import com.gamelearn.repository.TopicRepository;

/**
 * Spec section 19 transaction model: adaptive failure rolls back EVERYTHING,
 * and concurrent submissions serialize on the locked mastery row without
 * lost updates.
 */
@SpringBootTest
@ActiveProfiles("test")
class AdaptiveTransactionAndConcurrencyTest {

    @Autowired
    private QuizSubmissionService quizSubmissionService;

    @Autowired
    private AuthService authService;

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
    private TopicMasteryRepository topicMasteryRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @MockitoSpyBean
    private RecommendationRepository recommendationRepository;

    // --- helpers -------------------------------------------------------------

    private record Fixture(UUID userId, String email, Quiz quiz, Question q1, Question q2) {
    }

    private Fixture fixture(String label) {
        AuthResponse auth = authService.register(new com.gamelearn.dto.RegisterRequest(
                label + "-" + UUID.randomUUID() + "@example.test",
                "Str0ng-Passw0rd!", "Learner " + label));

        Subject subject = subjectRepository.save(subject(label));
        Topic topic = topicRepository.save(topic(label, subject));
        Quiz quiz = quizRepository.save(quiz(label, topic));
        // Flush so the generated UUIDs exist before linking rows.
        Question q1 = questionRepository.saveAndFlush(question("a", topic));
        Question q2 = questionRepository.saveAndFlush(question("b", topic));
        associate(quizRepository.saveAndFlush(quiz), q1, 1);
        associate(quiz, q2, 2);
        return new Fixture(auth.user().id(), auth.user().email(), quiz, q1, q2);
    }

    private Subject subject(String label) {
        Subject s = new Subject();
        s.setName(label + " " + UUID.randomUUID());
        s.setDescription("d");
        s.setIconKey("i");
        s.setActive(true);
        s.setDisplayOrder(1);
        return s;
    }

    private Topic topic(String label, Subject subject) {
        Topic t = new Topic();
        t.setSubject(subject);
        t.setName(label + " " + UUID.randomUUID());
        t.setDescription("d");
        t.setDifficulty(com.gamelearn.entity.enums.Difficulty.EASY);
        t.setDisplayOrder(1);
        t.setActive(true);
        return t;
    }

    private Quiz quiz(String label, Topic topic) {
        Quiz q = new Quiz();
        q.setTopic(topic);
        q.setTitle(label + " Quiz");
        q.setDifficulty(com.gamelearn.entity.enums.Difficulty.MEDIUM);
        q.setSourceType(com.gamelearn.entity.enums.SourceType.CURATED);
        q.setActive(true);
        return q;
    }

    private Question question(String correct, Topic topic) {
        Question q = new Question();
        q.setTopic(topic);
        q.setQuestionText(correct + "?");
        q.setQuestionType(com.gamelearn.entity.enums.QuestionType.MCQ);
        q.setDifficulty(com.gamelearn.entity.enums.Difficulty.EASY);
        q.setOptionsJson("{\"options\":[\"" + correct + "\",\"wrong\"]}");
        q.setCorrectAnswer(correct);
        q.setExplanation("because");
        q.setSourceType(com.gamelearn.entity.enums.SourceType.CURATED);
        q.setActive(true);
        return q;
    }

    private void associate(Quiz quiz, Question q, int order) {
        var link = new com.gamelearn.entity.QuizQuestion();
        link.setQuiz(quiz);
        link.setQuestion(q);
        link.setQuestionOrder(order);
        quizQuestionRepository.save(link);
    }

    private QuizSubmissionRequest request(Question q, String answer) {
        return new QuizSubmissionRequest(List.of(
                new QuizSubmissionRequest.SubmittedAnswer(q.getId(), answer)));
    }

    // --- tests ---------------------------------------------------------------

    @Test
    void failureInsideAdaptivePhaseRollsBackEverything() {
        Fixture f = fixture("rollback");

        Integer beforeAttempts = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM quiz_attempts WHERE user_id = ?", Integer.class, f.userId());
        assertThat(beforeAttempts).isZero();

        // Force a failure AFTER quiz rows are persisted but BEFORE commit:
        // recommendation insert is the last write of the pipeline.
        doThrow(new IllegalStateException("simulated recommendation failure"))
                .when(recommendationRepository).save(any(com.gamelearn.entity.Recommendation.class));

        org.junit.jupiter.api.Assertions.assertThrows(IllegalStateException.class,
                () -> quizSubmissionService.submit(f.userId(), f.quiz().getId(),
                        request(f.q1(), "a")));

        // Full rollback per spec section 19.
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM quiz_attempts WHERE user_id = ?",
                Integer.class, f.userId())).isZero();
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM question_attempts", Integer.class)).isZero();
        assertThat(topicMasteryRepository.findByUserId(f.userId())).isEmpty();
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM recommendations WHERE user_id = ?",
                Integer.class, f.userId())).isZero();
        BigDecimal overall = jdbcTemplate.queryForObject(
                "SELECT overall_mastery FROM learner_profiles WHERE user_id = ?",
                BigDecimal.class, f.userId());
        assertThat(overall).isEqualByComparingTo("0");
    }

    @Test
    void concurrentSubmissionsSerializeWithoutLostUpdates() throws Exception {
        Fixture f = fixture("concurrent");

        // Order-independent by construction: perfect-then-zero or zero-then-perfect
        // both converge to 100 -> 50 under weight 1/min(n,5).
        // Each thread submits a COMPLETE answer sheet: accuracy is graded over
        // every quiz question with unanswered scored incorrect (spec section 6),
        // so partial sheets would yield 50/0 instead of the intended 100/0.
        QuizSubmissionRequest perfectSheet = new QuizSubmissionRequest(List.of(
                new QuizSubmissionRequest.SubmittedAnswer(f.q1().getId(), "a"),
                new QuizSubmissionRequest.SubmittedAnswer(f.q2().getId(), "b")));
        QuizSubmissionRequest zeroSheet = new QuizSubmissionRequest(List.of(
                new QuizSubmissionRequest.SubmittedAnswer(f.q1().getId(), "wrong"),
                new QuizSubmissionRequest.SubmittedAnswer(f.q2().getId(), "wrong")));
        try (ExecutorService pool = Executors.newFixedThreadPool(2)) {
            Future<?> a = pool.submit((Callable<Void>) () -> {
                quizSubmissionService.submit(f.userId(), f.quiz().getId(), perfectSheet);
                return null;
            });
            Future<?> b = pool.submit((Callable<Void>) () -> {
                quizSubmissionService.submit(f.userId(), f.quiz().getId(), zeroSheet);
                return null;
            });
            a.get();
            b.get();
        }

        Integer attemptCount = jdbcTemplate.queryForObject(
                "SELECT attempt_count FROM topic_mastery tm JOIN users u ON u.id = tm.user_id "
                        + "WHERE u.email = ?",
                Integer.class, f.email());
        assertThat(attemptCount)
                .as("both attempts must be counted exactly once").isEqualTo(2);

        var state = jdbcTemplate.queryForMap(
                "SELECT mastery_score, recent_accuracy FROM topic_mastery tm "
                        + "JOIN users u ON u.id = tm.user_id WHERE u.email = ?",
                f.email());
        assertThat(new java.math.BigDecimal(state.get("mastery_score").toString()))
                .isEqualByComparingTo("50.00");
        // recent_accuracy equals the accuracy of whichever attempt serialized
        // LAST: [perfect->zero] ends at 0.00, [zero->perfect] at 100.00. Both
        // orders are approved serializations (mastery converges to 50.00 either
        // way); pinning one value here was a latent race in the assertion.
        assertThat(new java.math.BigDecimal(state.get("recent_accuracy").toString()))
                .isIn(java.math.BigDecimal.valueOf(0, 2),
                        new java.math.BigDecimal("100.00"));
    }
}
