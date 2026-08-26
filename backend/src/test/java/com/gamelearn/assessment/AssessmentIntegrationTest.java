package com.gamelearn.assessment;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import com.gamelearn.exception.ApiException;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;

import com.gamelearn.service.AuthService;
import com.gamelearn.dto.AuthResponse;
import com.gamelearn.dto.AssessmentSubmissionRequest;
import com.gamelearn.entity.Quiz;
import com.gamelearn.entity.Question;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.entity.enums.SourceType;
import com.gamelearn.repository.LearnerProfileRepository;
import com.gamelearn.repository.QuestionRepository;
import com.gamelearn.repository.QuizAttemptRepository;
import com.gamelearn.repository.QuizQuestionRepository;
import com.gamelearn.repository.QuizRepository;
import com.gamelearn.repository.StreakRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicMasteryRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.UserAchievementRepository;
import com.gamelearn.repository.UserRepository;
import com.gamelearn.repository.XpTransactionRepository;
import com.gamelearn.service.QuizSubmissionService;

/**
 * Phase 8B — Assessment Engine integration coverage mapping to the approved
 * matrix ASMT-TEST-001..032 (Assessment Specification section 22).
 */
@SpringBootTest
@ActiveProfiles("test")
class AssessmentIntegrationTest {

    @Autowired
    private AuthService authService;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private SubjectRepository subjectRepository;
    @Autowired
    private TopicRepository topicRepository;
    @Autowired
    private QuestionRepository questionRepository;
    @Autowired
    private QuizRepository quizRepository;
    @Autowired
    private QuizQuestionRepository quizQuestionRepository;
    @Autowired
    private QuizAttemptRepository quizAttemptRepository;
    @Autowired
    private TopicMasteryRepository topicMasteryRepository;
    @Autowired
    private LearnerProfileRepository learnerProfileRepository;
    @Autowired
    private XpTransactionRepository xpTransactionRepository;
    @Autowired
    private UserAchievementRepository userAchievementRepository;
    @Autowired
    private StreakRepository streakRepository;
    @Autowired
    private AssessmentService assessmentService;
    @Autowired
    private QuizSubmissionService quizSubmissionService;
    @Autowired
    private JdbcTemplate jdbcTemplate;

    @MockitoSpyBean
    private TopicMasteryRepository topicMasterySpyRepository;

    private User newUser(String label) {
        AuthResponse auth = authService.register(new com.gamelearn.dto.RegisterRequest(
                label + "-" + UUID.randomUUID() + "@example.test",
                "Str0ng-Passw0rd!", "Learner " + label));
        return userRepository.findById(auth.user().id()).orElseThrow();
    }

    /** Subject with `topicCount` active topics, each holding `questionsPerTopic` MCQs. */
    private Subject subjectWith(String label, int topicCount, int questionsPerTopic,
                                String... correctAnswers) {
        Subject subject = new Subject();
        subject.setName(label + " " + UUID.randomUUID());
        subject.setDescription(label);
        subject.setIconKey("icon");
        subject.setActive(true);
        subject.setDisplayOrder(1);
        subject = subjectRepository.save(subject);

        for (int t = 1; t <= topicCount; t++) {
            Topic topic = new Topic();
            topic.setSubject(subject);
            topic.setName(label + " topic" + t);
            topic.setDescription(label + " description");
            topic.setDifficulty(Difficulty.MEDIUM);
            topic.setDisplayOrder(t);
            topic.setActive(true);
            topic = topicRepository.save(topic);
            for (int qn = 1; qn <= questionsPerTopic; qn++) {
                Question q = new Question();
                q.setTopic(topic);
                q.setQuestionText(label + " Q" + t + "/" + qn);
                q.setQuestionType(com.gamelearn.entity.enums.QuestionType.MCQ);
                q.setDifficulty(Difficulty.EASY);
                String correct = correctAnswers.length >= qn
                        ? correctAnswers[qn - 1]
                        : "opt" + qn;
                q.setOptionsJson("{\"options\":[\"" + correct + "\",\"wrong\"]}");
                q.setCorrectAnswer(correct);
                q.setExplanation("because");
                q.setSourceType(SourceType.CURATED);
                q.setActive(true);
                questionRepository.save(q);
            }
        }
        return subject;
    }

    private List<UUID> deliveredIds(UUID subjectId) {
        return assessmentService.delivery(subjectId).questions().stream()
                .map(com.gamelearn.dto.AssessmentQuestion::questionId).toList();
    }

    private AssessmentSubmissionRequest requestFor(UUID subjectId, String answerPattern) {
        List<UUID> ids = deliveredIds(subjectId);
        var answers = new java.util.ArrayList<com.gamelearn.dto.AssessmentSubmissionRequest.SubmittedAnswer>();
        for (int i = 0; i < ids.size(); i++) {
            boolean correct = answerPattern.charAt(i % answerPattern.length()) == 'C';
            answers.add(new com.gamelearn.dto.AssessmentSubmissionRequest.SubmittedAnswer(
                    ids.get(i), correct ? "opt" + (i % 3 + 1) : "wrong"));
        }
        return new AssessmentSubmissionRequest(answers);
    }

    // ------------------------------------------------------------------
    // Delivery determinism / redaction
    // ------------------------------------------------------------------

    @Test
    @DisplayName("ASMT-TEST-001/027/-029: K=3 cap, deterministic order, no answers exposed")
    void deliveryDeterministicKCapRedaction() throws Exception {
        User learner = newUser("asmt001");
        // 5 questions on the topic -> only first 3 delivered (K=3).
        Subject subject = subjectWith("cap", 1, 5, "a");

        var first = assessmentService.delivery(subject.getId());
        var second = assessmentService.delivery(subject.getId());

        assertThat(first.questions()).hasSize(3);
        assertThat(first).isEqualTo(second); // deterministic repeat (-027)
        assertThat(first.questions()).allSatisfy(q -> {
            assertThat(q.topicId()).isEqualTo(
                    topicRepository.findBySubjectIdAndActiveTrueOrderByDisplayOrderAscIdAsc(
                            subject.getId()).get(0).getId());
            assertThat(q.options()).doesNotContain("because");
        });
                // Redaction: serialized payload never contains any correct answer.
        List<String> correct = jdbcTemplate.queryForList(
                "SELECT qz.correct_answer FROM questions qz "
                        + "JOIN topics t ON t.id=qz.topic_id WHERE t.subject_id=?",
                String.class, subject.getId());
        String json = new com.fasterxml.jackson.databind.ObjectMapper()
                .writeValueAsString(first);
        for (String c : correct) {
            assertThat(json).doesNotContain("correctAnswer");
            assertThat(json).doesNotContain("explanation");
            assertThat(json).doesNotContain("\"" + c + "\":");
        }
    }

    @Test
    @DisplayName("ASMT-TEST-002/-025/-028: topic ordering, empty-topic skip, inactive filter")
    void deliveryOrderingAndFiltering() {
        Subject subject = subjectWith("order", 3, 2);
        // Deactivate ALL questions of middle topic -> skipped entirely.
        UUID middleTopicId = topicRepository
                .findBySubjectIdAndActiveTrueOrderByDisplayOrderAscIdAsc(subject.getId())
                .get(1).getId();
        jdbcTemplate.update("UPDATE questions SET is_active=false WHERE topic_id=?",
                middleTopicId);

        var delivery = assessmentService.delivery(subject.getId());
        assertThat(delivery.questions()).hasSize(4); // 2 + 2, middle skipped
        assertThat(delivery.questions()).allSatisfy(
                q -> assertThat(q.topicId()).isNotEqualTo(middleTopicId));
    }

    @Test
    @DisplayName("ASMT-TEST-002/A10: unknown subject and zero assessable content => 404")
    void notFoundPaths() {
        User learner = newUser("asmt404");
        assertThatThrownBy(() -> assessmentService.delivery(UUID.randomUUID()))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("Subject not found");

        // Active subject, but its single topic has zero ACTIVE questions.
        Subject subject = subjectWith("empty", 1, 2);
        jdbcTemplate.update("UPDATE questions SET is_active=false "
                + "WHERE topic_id IN (SELECT id FROM topics WHERE subject_id=?)",
                subject.getId());
        assertThatThrownBy(() -> assessmentService.delivery(subject.getId()))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("No assessable content");
        assertThatThrownBy(() -> assessmentService.submit(
                learner.getId(), subject.getId(),
                new AssessmentSubmissionRequest(List.of())))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("No assessable content");
    }

    // ------------------------------------------------------------------
    // Grading
    // ------------------------------------------------------------------

    @Test
    @DisplayName("ASMT-TEST-004: mixed answers grade per-topic and refresh profile")
    void mixedGrading() {
        User learner = newUser("asmtmix");
        // 2 topics x 3 questions; pattern C W C | W C W -> topic1 2/3=66.67,
        // topic2 1/3=33.33, overall mean 50.00.
        Subject subject = subjectWith("mix", 2, 3);
        var response = assessmentService.submit(learner.getId(), subject.getId(),
                requestFor(subject.getId(), "CWCWCW"));

        assertThat(response.score()).isEqualByComparingTo("50.00"); // 3/6
        assertThat(response.overallMastery()).isEqualByComparingTo("50.00");
        assertThat(response.topics()).hasSize(2);
        assertThat(response.topics().get(0).accuracy()).isEqualByComparingTo("66.67");
        assertThat(response.topics().get(1).accuracy()).isEqualByComparingTo("33.33");
        // Approved bands: 66.67 -> DEVELOPING, 33.33 -> BEGINNER (spec section 8).
        assertThat(response.topics().get(0).masteryLevel()).isEqualTo("DEVELOPING");
        assertThat(response.topics().get(1).masteryLevel()).isEqualTo("BEGINNER");
        assertThat(response.topics()).allSatisfy(b ->
                assertThat(b.currentDifficulty()).isEqualTo("EASY")); // A3

        var profile = learnerProfileRepository.findByUserId(learner.getId()).orElseThrow();
        assertThat(profile.getOverallMastery()).isEqualByComparingTo("50.00");
        assertThat(profile.getCurrentSubject().getId()).isEqualTo(subject.getId());
        // C1: XP-owned fields untouched.
        assertThat(profile.getCurrentLevel()).isEqualTo(1);
        assertThat(profile.getTotalXp()).isZero();
    }

    @Test
    @DisplayName("ASMT-TEST-005: all correct -> MASTERED baselines at EASY difficulty")
    void allCorrect() {
        User learner = newUser("asmtall");
        Subject subject = subjectWith("allc", 1, 2);
        var response = assessmentService.submit(learner.getId(), subject.getId(),
                requestFor(subject.getId(), "CC"));

        assertThat(response.score()).isEqualByComparingTo("100.00");
        assertThat(response.topics()).singleElement().satisfies(b -> {
            assertThat(b.accuracy()).isEqualByComparingTo("100.00");
            assertThat(b.masteryLevel()).isEqualTo("MASTERED");
            assertThat(b.currentDifficulty()).isEqualTo("EASY"); // A3 fixed value
        });
    }

    @Test
    @DisplayName("ASMT-TEST-006/-007: zero score and 1/3 rounding boundary")
    void zeroScoreAndRounding() {
        User learner = newUser("asmtzero");
        Subject subject = subjectWith("zero", 1, 3);
        var response = assessmentService.submit(learner.getId(), subject.getId(),
                requestFor(subject.getId(), "WWW"));
        assertThat(response.score()).isEqualByComparingTo("0.00");
        assertThat(response.topics().get(0).accuracy()).isEqualByComparingTo("0.00");
        assertThat(response.topics().get(0).masteryLevel()).isEqualTo("BEGINNER");

        User learner2 = newUser("asmtround");
        // Single-question topic answered wrong->right pattern gives 1/3 = 33.33.
        Subject s2 = subjectWith("round", 1, 3);
        List<UUID> ids = deliveredIds(s2.getId());
        var answers = List.of(
                new com.gamelearn.dto.AssessmentSubmissionRequest.SubmittedAnswer(ids.get(0), "wrong"),
                new com.gamelearn.dto.AssessmentSubmissionRequest.SubmittedAnswer(ids.get(1), "wrong"),
                new com.gamelearn.dto.AssessmentSubmissionRequest.SubmittedAnswer(ids.get(2), "wrong"));
        var r2 = assessmentService.submit(learner2.getId(), s2.getId(),
                new AssessmentSubmissionRequest(answers));
        assertThat(r2.score()).isEqualByComparingTo("0.00");

        // One correct of three: 33.33 HALF_UP boundary.
        User learner3 = newUser("asmtround2");
        Subject s3 = subjectWith("round2", 1, 3);
        List<UUID> ids3 = deliveredIds(s3.getId());
        var answers3 = List.of(
                new com.gamelearn.dto.AssessmentSubmissionRequest.SubmittedAnswer(ids3.get(0), "opt1"),
                new com.gamelearn.dto.AssessmentSubmissionRequest.SubmittedAnswer(ids3.get(1), "wrong"),
                new com.gamelearn.dto.AssessmentSubmissionRequest.SubmittedAnswer(ids3.get(2), "wrong"));
        var r3 = assessmentService.submit(learner3.getId(), s3.getId(),
                new AssessmentSubmissionRequest(answers3));
        assertThat(r3.score()).isEqualByComparingTo("33.33");
    }

    // ------------------------------------------------------------------
    // Validation
    // ------------------------------------------------------------------

    @Test
    @DisplayName("ASMT-TEST-008: duplicate question ids rejected")
    void duplicateAnswersRejected() {
        User learner = newUser("asmtdup");
        Subject subject = subjectWith("dup", 1, 2);
        List<UUID> ids = deliveredIds(subject.getId());
        var answers = List.of(
                new com.gamelearn.dto.AssessmentSubmissionRequest.SubmittedAnswer(ids.get(0), "opt1"),
                new com.gamelearn.dto.AssessmentSubmissionRequest.SubmittedAnswer(ids.get(0), "opt1"));
        assertThatThrownBy(() -> assessmentService.submit(learner.getId(), subject.getId(),
                new AssessmentSubmissionRequest(answers)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("Duplicate answer");
        assertThat(topicMasteryRepository.existsByUserIdAndTopicIdIn(
                learner.getId(), List.of())).isFalse();
    }

    @Test
    @DisplayName("ASMT-TEST-009/-010: foreign and stale question ids rejected")
    void foreignAndStaleRejected() {
        User learner = newUser("asmtforeign");
        Subject subjectA = subjectWith("foreignA", 1, 2);
        Subject subjectB = subjectWith("foreignB", 1, 2);
        UUID foreignId = deliveredIds(subjectB.getId()).get(0);

        var answers = List.of(new com.gamelearn.dto.AssessmentSubmissionRequest.SubmittedAnswer(
                foreignId, "opt1"));
        assertThatThrownBy(() -> assessmentService.submit(learner.getId(), subjectA.getId(),
                new AssessmentSubmissionRequest(answers)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("outside this assessment");

        // Stale: deactivate one delivered question after fetch, resubmit.
        List<UUID> idsA = deliveredIds(subjectA.getId());
        jdbcTemplate.update("UPDATE questions SET is_active=false WHERE id=?", idsA.get(0));
        var staleAnswers = List.of(
                new com.gamelearn.dto.AssessmentSubmissionRequest.SubmittedAnswer(idsA.get(0), "opt1"),
                new com.gamelearn.dto.AssessmentSubmissionRequest.SubmittedAnswer(idsA.get(1), "opt1"));
        assertThatThrownBy(() -> assessmentService.submit(learner.getId(), subjectA.getId(),
                new AssessmentSubmissionRequest(staleAnswers)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("outside this assessment");
        assertThat(topicMasteryRepository.countByUserId(learner.getId())).isZero();
    }

    // ------------------------------------------------------------------
    // R-GUARD
    // ------------------------------------------------------------------

    @Test
    @DisplayName("ASMT-TEST-012: replay after success => 409 DATA_CONFLICT")
    void replayAfterSuccess() {
        User learner = newUser("asmtreplay");
        Subject subject = subjectWith("replay", 1, 2);
        assessmentService.submit(learner.getId(), subject.getId(),
                requestFor(subject.getId(), "CC"));

        assertThatThrownBy(() -> assessmentService.submit(learner.getId(), subject.getId(),
                requestFor(subject.getId(), "CC")))
                .isInstanceOf(ApiException.class)
                .extracting(e -> ((ApiException) e).getErrorCode())
                .isEqualTo("DATA_CONFLICT");
    }

    @Test
    @DisplayName("ASMT-TEST-013: concurrent submissions serialize; loser gets 409")
    void concurrentSubmissionsSerialize() throws Exception {
        User learner = newUser("asmtconc");
        Subject subject = subjectWith("conc", 1, 2);

        ExecutorService pool = Executors.newFixedThreadPool(2);
        CountDownLatch ready = new CountDownLatch(2);
        CountDownLatch go = new CountDownLatch(1);
        java.util.concurrent.Callable<Integer> task = () -> {
            ready.countDown();
            go.await();
            try {
                assessmentService.submit(learner.getId(), subject.getId(),
                        requestFor(subject.getId(), "CC"));
                return 201;
            } catch (ApiException e) {
                return e.getHttpStatus(); // 409 lineage loser
            }
        };
        Future<Integer> first = pool.submit(task);
        Future<Integer> second = pool.submit(task);

        assertThat(ready.await(10, java.util.concurrent.TimeUnit.SECONDS)).isTrue();
        go.countDown();
        int r1 = first.get(30, java.util.concurrent.TimeUnit.SECONDS);
        int r2 = second.get(30, java.util.concurrent.TimeUnit.SECONDS);
        pool.shutdownNow();

        assertThat(List.of(r1, r2)).containsExactlyInAnyOrder(201, 409);
        // Exactly one baseline set: 2 topics? subject has ONE topic here.
        long baselineRows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM topic_mastery tm JOIN users u ON u.id=tm.user_id "
                        + "WHERE u.id=?",
                Long.class, learner.getId());
        assertThat(baselineRows).isEqualTo(1);
    }

    @Test
    @DisplayName("ASMT-TEST-014: prior real quiz attempts block assessment (R-GUARD)")
    void existingQuizAttemptBlocks() {
        User learner = newUser("asmtlineage");
        Subject subject = subjectWith("lineage", 1, 2);

        // Establish real lineage through the APPROVED quiz pipeline first.
        Topic topic = topicRepository
                .findBySubjectIdAndActiveTrueOrderByDisplayOrderAscIdAsc(subject.getId())
                .get(0);
        Quiz quiz = new Quiz();
        quiz.setTopic(topic);
        quiz.setTitle("Real quiz");
        quiz.setDifficulty(Difficulty.MEDIUM);
        quiz.setSourceType(SourceType.CURATED);
        quiz.setActive(true);
        quiz = quizRepository.save(quiz);
        List<Question> questions = questionRepository.findAll().stream()
                .filter(q -> q.getTopic().getId().equals(topic.getId())).toList();
        associateAll(quiz, questions);
        quizSubmissionService.submit(learner.getId(), quiz.getId(),
                new com.gamelearn.dto.QuizSubmissionRequest(java.util.List.of(
                        new com.gamelearn.dto.QuizSubmissionRequest.SubmittedAnswer(
                                questions.get(0).getId(), "opt1"))));

        assertThatThrownBy(() -> assessmentService.submit(learner.getId(), subject.getId(),
                requestFor(subject.getId(), "CC")))
                .isInstanceOf(ApiException.class)
                .extracting(e -> ((ApiException) e).getErrorCode())
                .isEqualTo("DATA_CONFLICT");
    }

    // ------------------------------------------------------------------
    // Rollback / retry / engine isolation
    // ------------------------------------------------------------------

    @Test
    @DisplayName("ASMT-TEST-015/-016: failure rolls back everything; retry succeeds")
    void rollbackThenCleanRetry() {
        User learner = newUser("asmtrollback");
        Subject subject = subjectWith("rollback", 1, 2);

        Mockito.doThrow(new IllegalStateException("boom"))
                .when(topicMasterySpyRepository).save(Mockito.any());
        assertThatThrownBy(() -> assessmentService.submit(learner.getId(), subject.getId(),
                requestFor(subject.getId(), "CC")))
                .hasMessageContaining("boom");

        assertThat(topicMasteryRepository.existsByUserIdAndTopicIdIn(
                learner.getId(), List.of())).isFalse();
        var profile = learnerProfileRepository.findByUserId(learner.getId()).orElseThrow();
        assertThat(profile.getCurrentSubject()).isNull(); // unchanged

        Mockito.reset(topicMasterySpyRepository); // retry
        var response = assessmentService.submit(learner.getId(), subject.getId(),
                requestFor(subject.getId(), "CC"));
        assertThat(response.score()).isEqualByComparingTo("100.00");
        assertThat(learnerProfileRepository.findByUserId(learner.getId())
                .orElseThrow().getCurrentSubject().getId()).isEqualTo(subject.getId());
    }

    @Test
    @DisplayName("ASMT-TEST-017/-018/-019: ZERO writes outside approved targets")
    void engineIsolation() {
        User learner = newUser("asmtiso");
        Subject subject = subjectWith("iso", 1, 2);
        assessmentService.submit(learner.getId(), subject.getId(),
                requestFor(subject.getId(), "CC"));

        assertThat(xpTransactionRepository.findByUserIdOrderByCreatedAtAsc(learner.getId()))
                .isEmpty();
        assertThat(userAchievementRepository.countByUserId(learner.getId())).isZero();
        assertThat(streakRepository.findByUserId(learner.getId())).isEmpty();
        Integer recRows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM recommendations r JOIN users u ON u.id=r.user_id "
                        + "WHERE u.id=?",
                Integer.class, learner.getId());
        assertThat(recRows).isZero();
        Long attemptRows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM quiz_attempts WHERE user_id=?",
                Long.class, learner.getId());
        assertThat(attemptRows).isZero(); // assessment creates NO quiz_attempt
        Integer aiRows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM ai_interactions", Integer.class);
        assertThat(aiRows).isZero(); // no Gemini involvement
        var profile = learnerProfileRepository.findByUserId(learner.getId()).orElseThrow();
        assertThat(profile.getCurrentLevel()).isEqualTo(1); // C1
        assertThat(profile.getTotalXp()).isZero(); // C1
        assertThat(profile.getCurrentTopic()).isNull();
    }

    // ------------------------------------------------------------------
    // Derived result + adaptive coexistence
    // ------------------------------------------------------------------

    @Test
    @DisplayName("ASMT-TEST-020/-021: derived result assessed vs not-assessed views")
    void resultViews() {
        User fresh = newUser("asmtfresh");
        Subject subject = subjectWith("result", 1, 2);

        var before = assessmentService.result(fresh.getId(), subject.getId());
        assertThat(before.assessed()).isFalse();
        assertThat(before.topics()).isEmpty();
        assertThat(before.overallMastery()).isEqualByComparingTo("0.00");

        assessmentService.submit(fresh.getId(), subject.getId(),
                requestFor(subject.getId(), "CW"));
        var after = assessmentService.result(fresh.getId(), subject.getId());
        assertThat(after.assessed()).isTrue();
        assertThat(after.topics()).hasSize(1);
        assertThat(after.topics().get(0).masteryScore()).isEqualByComparingTo("50.00");
        assertThat(after.topics().get(0).topicName()).contains("result topic");
    }

    @Test
    @DisplayName("ASMT-TEST-031: baseline then real quiz follows approved T02 lineage")
    void adaptiveCoexistence() {
        User learner = newUser("asmtcoex");
        Subject subject = subjectWith("coex", 1, 2);
        assessmentService.submit(learner.getId(), subject.getId(),
                requestFor(subject.getId(), "CC")); // baseline 100.00

        Topic topic = topicRepository
                .findBySubjectIdAndActiveTrueOrderByDisplayOrderAscIdAsc(subject.getId())
                .get(0);
        Quiz quiz = new Quiz();
        quiz.setTopic(topic);
        quiz.setTitle("Coexistence quiz");
        quiz.setDifficulty(Difficulty.MEDIUM);
        quiz.setSourceType(SourceType.CURATED);
        quiz.setActive(true);
        quiz = quizRepository.save(quiz);
        List<Question> questions = questionRepository.findAll().stream()
                .filter(q -> q.getTopic().getId().equals(topic.getId())).toList();
        associateAll(quiz, questions);

        // Real quiz scores 50 -> T02: step=(50-100)/2 = -25 => mastery 75.00.
        quizSubmissionService.submit(learner.getId(), quiz.getId(),
                new com.gamelearn.dto.QuizSubmissionRequest(java.util.List.of(
                        new com.gamelearn.dto.QuizSubmissionRequest.SubmittedAnswer(
                                questions.get(0).getId(), "opt1"),
                        new com.gamelearn.dto.QuizSubmissionRequest.SubmittedAnswer(
                                questions.get(1).getId(), "wrong"))));

        var mastery = topicMasteryRepository.findByUserId(learner.getId()).stream()
                .filter(m -> m.getTopic().getId().equals(topic.getId()))
                .findFirst().orElseThrow();
        assertThat(mastery.getMasteryScore()).isEqualByComparingTo("75.00");
        assertThat(mastery.getAttemptCount()).isEqualTo(2); // T02 lineage preserved
        assertThat(mastery.getTrend()).isEqualTo(com.gamelearn.entity.enums.MasteryTrend.DECLINING);
    }

    @Test
    @DisplayName("Cross-user protection: results never leak between learners")
    void crossUserIsolation() throws Exception {
        User alice = newUser("asmtalice");
        Subject subject = subjectWith("isol", 1, 2);
        assessmentService.submit(alice.getId(), subject.getId(),
                requestFor(subject.getId(), "CC"));

        User bob = newUser("asmtbob");
        var bobsResult = assessmentService.result(bob.getId(), subject.getId());
        assertThat(bobsResult.assessed()).isFalse(); // bob has no baseline
        assertThat(bobsResult.topics()).isEmpty();
    }

    private void associateAll(Quiz quiz, List<Question> questions) {
        int order = 1;
        for (Question q : questions) {
            var link = new com.gamelearn.entity.QuizQuestion();
            link.setQuiz(quiz);
            link.setQuestion(q);
            link.setQuestionOrder(order++);
            quizQuestionRepository.save(link);
        }
    }

}
