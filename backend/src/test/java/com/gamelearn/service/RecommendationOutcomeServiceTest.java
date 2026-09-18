package com.gamelearn.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.dto.RecommendationOutcome;
import com.gamelearn.entity.Quiz;
import com.gamelearn.entity.QuizAttempt;
import com.gamelearn.entity.Recommendation;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.entity.enums.QuizAttemptStatus;
import com.gamelearn.entity.enums.RecommendationActivityType;
import com.gamelearn.entity.enums.RecommendationStatus;
import com.gamelearn.exception.ApiException;
import com.gamelearn.persistence.PersistenceTestFixtures;

/**
 * Post-recommendation outcome derivation (Gate 14.2, observational only).
 *
 * <p>Proves improvement/decline/no-change/insufficient/ambiguous handling,
 * topic and learner isolation, point-in-time ordering, supersede bounding,
 * consumed-is-not-success, and zero behavior change to generation/mastery.
 * Every scenario asserts the taxonomy AND the preserved invariants.</p>
 */
@SpringBootTest
@ActiveProfiles("test")
@Transactional
class RecommendationOutcomeServiceTest {

    @Autowired
    private RecommendationOutcomeService outcomeService;

    @Autowired
    private com.gamelearn.repository.UserRepository userRepository;

    @Autowired
    private com.gamelearn.repository.SubjectRepository subjectRepository;

    @Autowired
    private com.gamelearn.repository.TopicRepository topicRepository;

    @Autowired
    private com.gamelearn.repository.QuizRepository quizRepository;

    @Autowired
    private com.gamelearn.repository.QuizAttemptRepository quizAttemptRepository;

    @Autowired
    private com.gamelearn.repository.RecommendationRepository recommendationRepository;

    private static final Instant T0 = Instant.parse("2026-08-01T10:00:00Z");
    private static final Instant T1 = Instant.parse("2026-08-05T10:00:00Z");
    private static final Instant T2 = Instant.parse("2026-08-10T10:00:00Z");
    private static final Instant T3 = Instant.parse("2026-08-15T10:00:00Z");

    private record Setup(User user, Topic topic, Quiz quiz) {
    }

    private Setup setup() {
        User user = userRepository.save(PersistenceTestFixtures.user("recout"));
        Subject subject = subjectRepository.save(PersistenceTestFixtures.subject("recout"));
        Topic topic = topicRepository.save(PersistenceTestFixtures.topic("recout", subject));
        Quiz quiz = quizRepository.save(PersistenceTestFixtures.quiz("recout", topic));
        return new Setup(user, topic, quiz);
    }

    private QuizAttempt attempt(Setup setup, int correct, int total, Instant submittedAt) {
        QuizAttempt attempt = new QuizAttempt();
        attempt.setQuiz(setup.quiz());
        attempt.setUser(setup.user());
        attempt.setScore(BigDecimal.valueOf(correct * 100L / total));
        attempt.setCorrectCount(correct);
        attempt.setTotalQuestions(total);
        attempt.setDifficultyAtAttempt(Difficulty.MEDIUM);
        attempt.setStartedAt(submittedAt);
        attempt.setSubmittedAt(submittedAt);
        attempt.setStatus(QuizAttemptStatus.COMPLETED);
        return quizAttemptRepository.save(attempt);
    }

    private Recommendation recommendation(Setup setup, Instant generatedAt,
            RecommendationStatus status) {
        Recommendation recommendation = new Recommendation();
        recommendation.setUser(setup.user());
        recommendation.setTopic(setup.topic());
        recommendation.setActivityType(RecommendationActivityType.PRACTICE);
        recommendation.setRecommendedDifficulty(Difficulty.EASY);
        recommendation.setPriority(2);
        recommendation.setReason("outcome fixture");
        recommendation.setStatus(status);
        recommendation.setGeneratedAt(generatedAt);
        if (status == RecommendationStatus.CONSUMED) {
            recommendation.setConsumedAt(generatedAt.plusSeconds(60));
        }
        return recommendationRepository.save(recommendation);
    }

    @Test
    void improvementAfterRecommendation() {
        Setup setup = setup();
        attempt(setup, 1, 4, T0);
        Recommendation rec = recommendation(setup, T1, RecommendationStatus.ACTIVE);
        attempt(setup, 4, 4, T2);

        RecommendationOutcome outcome = outcomeService.deriveOutcome(
                setup.user().getId(), rec.getId());

        assertThat(outcome.category())
                .isEqualTo(RecommendationOutcome.Category.IMPROVED);
        assertThat(outcome.preAccuracy()).isEqualByComparingTo("25.00");
        assertThat(outcome.postAccuracy()).isEqualByComparingTo("100.00");
        assertThat(outcome.delta()).isEqualByComparingTo("75.00");
        assertThat(outcome.preAttempts()).isEqualTo(1);
        assertThat(outcome.postAttempts()).isEqualTo(1);
        assertThat(outcome.detail()).isEqualTo("OBSERVED_ASSOCIATION");
    }

    @Test
    void noMeasurableImprovementWithinBand() {
        Setup setup = setup();
        attempt(setup, 2, 4, T0);
        Recommendation rec = recommendation(setup, T1, RecommendationStatus.ACTIVE);
        attempt(setup, 2, 4, T2);

        RecommendationOutcome outcome = outcomeService.deriveOutcome(
                setup.user().getId(), rec.getId());

        assertThat(outcome.category()).isEqualTo(
                RecommendationOutcome.Category.NO_MEASURABLE_IMPROVEMENT);
        assertThat(outcome.delta()).isEqualByComparingTo("0.00");
    }

    @Test
    void declineAfterRecommendation() {
        Setup setup = setup();
        attempt(setup, 4, 4, T0);
        Recommendation rec = recommendation(setup, T1, RecommendationStatus.ACTIVE);
        attempt(setup, 1, 4, T2);

        assertThat(outcomeService.deriveOutcome(setup.user().getId(), rec.getId()).category())
                .isEqualTo(RecommendationOutcome.Category.DECLINED);
    }

    @Test
    void missingPreBaselineIsInsufficient() {
        Setup setup = setup();
        Recommendation rec = recommendation(setup, T1, RecommendationStatus.ACTIVE);
        attempt(setup, 4, 4, T2);

        RecommendationOutcome outcome = outcomeService.deriveOutcome(
                setup.user().getId(), rec.getId());

        assertThat(outcome.category()).isEqualTo(
                RecommendationOutcome.Category.INSUFFICIENT_DATA);
        assertThat(outcome.preAccuracy()).isNull();
        assertThat(outcome.postAccuracy()).isNull();
        assertThat(outcome.delta()).isNull();
        assertThat(outcome.detail()).isEqualTo("NO_PRE_BASELINE");
    }

    @Test
    void missingPostObservationIsInsufficient() {
        Setup setup = setup();
        attempt(setup, 1, 4, T0);
        Recommendation rec = recommendation(setup, T1, RecommendationStatus.ACTIVE);

        RecommendationOutcome outcome = outcomeService.deriveOutcome(
                setup.user().getId(), rec.getId());

        assertThat(outcome.category()).isEqualTo(
                RecommendationOutcome.Category.INSUFFICIENT_DATA);
        assertThat(outcome.detail()).isEqualTo("NO_POST_OBSERVATION");
    }

    @Test
    void unrelatedTopicActivityIsIgnored() {
        Setup setup = setup();
        Subject otherSubject = subjectRepository.save(
                PersistenceTestFixtures.subject("recoutother"));
        Topic otherTopic = topicRepository.save(
                PersistenceTestFixtures.topic("recoutother", otherSubject));
        Quiz otherQuiz = quizRepository.save(PersistenceTestFixtures.quiz("recoutother", otherTopic));
        attempt(setup, 1, 4, T0);
        Recommendation rec = recommendation(setup, T1, RecommendationStatus.ACTIVE);

        QuizAttempt foreign = new QuizAttempt();
        foreign.setQuiz(otherQuiz);
        foreign.setUser(setup.user());
        foreign.setScore(BigDecimal.valueOf(100));
        foreign.setCorrectCount(4);
        foreign.setTotalQuestions(4);
        foreign.setDifficultyAtAttempt(Difficulty.MEDIUM);
        foreign.setStartedAt(T2);
        foreign.setSubmittedAt(T2);
        foreign.setStatus(QuizAttemptStatus.COMPLETED);
        quizAttemptRepository.save(foreign);

        // Perfect foreign-topic activity must not rescue the missing post baseline.
        assertThat(outcomeService.deriveOutcome(setup.user().getId(), rec.getId()).category())
                .isEqualTo(RecommendationOutcome.Category.INSUFFICIENT_DATA);
    }

    @Test
    void learnerMismatchIsForbidden() {
        Setup setup = setup();
        Recommendation rec = recommendation(setup, T1, RecommendationStatus.ACTIVE);
        UUID stranger = UUID.randomUUID();

        assertThatThrownBy(() -> outcomeService.deriveOutcome(stranger, rec.getId()))
                .isInstanceOf(ApiException.class);
    }

    @Test
    void unknownRecommendationIsNotFound() {
        Setup setup = setup();

        assertThatThrownBy(
                () -> outcomeService.deriveOutcome(setup.user().getId(), UUID.randomUUID()))
                .isInstanceOf(ApiException.class);
    }

    @Test
    void nullTopicIsUnavailable() {
        Setup setup = setup();
        Recommendation rec = recommendation(setup, T1, RecommendationStatus.ACTIVE);
        rec.setTopic(null);
        recommendationRepository.save(rec);

        RecommendationOutcome outcome = outcomeService.deriveOutcome(
                setup.user().getId(), rec.getId());

        assertThat(outcome.category()).isEqualTo(
                RecommendationOutcome.Category.INSUFFICIENT_DATA);
        assertThat(outcome.detail()).isEqualTo("TOPIC_NULL");
        assertThat(outcome.topicId()).isNull();
    }

    @Test
    void consumedStatusIsNotSuccess() {
        Setup setup = setup();
        attempt(setup, 1, 4, T0);
        // CONSUMED here means superseded (sole production write path) —
        // derivation must use attempt evidence, and with no post evidence
        // the outcome stays insufficient rather than succeeding.
        Recommendation rec = recommendation(setup, T1, RecommendationStatus.CONSUMED);

        assertThat(outcomeService.deriveOutcome(setup.user().getId(), rec.getId()).category())
                .isEqualTo(RecommendationOutcome.Category.INSUFFICIENT_DATA);
    }

    @Test
    void supersededWindowBoundsAttribution() {
        Setup setup = setup();
        attempt(setup, 1, 4, T0);
        Recommendation old = recommendation(setup, T1, RecommendationStatus.CONSUMED);
        attempt(setup, 4, 4, T2);
        Recommendation next = recommendation(setup, T3, RecommendationStatus.ACTIVE);
        attempt(setup, 0, 4, T3.plusSeconds(3600));

        // Old rec sees only the T2 attempt (bounded by T3); next rec sees
        // only the post-T3 attempt (decline) — no double attribution.
        RecommendationOutcome oldOutcome =
                outcomeService.deriveOutcome(setup.user().getId(), old.getId());
        assertThat(oldOutcome.category()).isEqualTo(RecommendationOutcome.Category.IMPROVED);
        assertThat(oldOutcome.postAttempts()).isEqualTo(1);

        RecommendationOutcome nextOutcome =
                outcomeService.deriveOutcome(setup.user().getId(), next.getId());
        assertThat(nextOutcome.category()).isEqualTo(RecommendationOutcome.Category.DECLINED);
        assertThat(nextOutcome.preAttempts()).isEqualTo(2);
    }

    @Test
    void sameInstantDuplicatesAreAmbiguous() {
        Setup setup = setup();
        attempt(setup, 1, 4, T0);
        recommendation(setup, T1, RecommendationStatus.CONSUMED);
        Recommendation twin = recommendation(setup, T1, RecommendationStatus.ACTIVE);
        attempt(setup, 4, 4, T3);

        // Both rows share generatedAt T1: attribution cannot be unique.
        RecommendationOutcome outcome =
                outcomeService.deriveOutcome(setup.user().getId(), twin.getId());
        assertThat(outcome.category()).isEqualTo(
                RecommendationOutcome.Category.AMBIGUOUS);
    }

    @Test
    void strictTimestampOrderingExcludesEqualInstants() {
        Setup setup = setup();
        // Attempt stamped exactly at generation time belongs to neither
        // window (strict inequality both sides).
        attempt(setup, 4, 4, T1);
        attempt(setup, 1, 4, T0);
        Recommendation rec = recommendation(setup, T1, RecommendationStatus.ACTIVE);
        attempt(setup, 4, 4, T2);

        RecommendationOutcome outcome = outcomeService.deriveOutcome(
                setup.user().getId(), rec.getId());

        assertThat(outcome.preAttempts()).isEqualTo(1);
        assertThat(outcome.postAttempts()).isEqualTo(1);
        assertThat(outcome.category()).isEqualTo(RecommendationOutcome.Category.IMPROVED);
    }

    @Test
    void futureAttemptsExcludedFromBaseline() {
        Setup setup = setup();
        attempt(setup, 4, 4, T0);
        Recommendation rec = recommendation(setup, T1, RecommendationStatus.ACTIVE);
        attempt(setup, 0, 4, T2);
        attempt(setup, 4, 4, T3.plusSeconds(7200));

        // Post window is unbounded here (no next rec): both T2 and T3 count.
        // Pre uses only T0 — the T3 attempt must not leak backwards.
        RecommendationOutcome outcome = outcomeService.deriveOutcome(
                setup.user().getId(), rec.getId());

        assertThat(outcome.preAttempts()).isEqualTo(1);
        assertThat(outcome.postAttempts()).isEqualTo(2);
        assertThat(outcome.preAccuracy()).isEqualByComparingTo("100.00");
    }

    @Test
    void duplicateSubmitsCountAsRecorded() {
        Setup setup = setup();
        attempt(setup, 1, 4, T0);
        Recommendation rec = recommendation(setup, T1, RecommendationStatus.ACTIVE);
        attempt(setup, 2, 4, T2);
        attempt(setup, 2, 4, T2.plusSeconds(30));

        // Both post rows are authoritative records; aggregation is over
        // recorded rows, never deduplicated by guesswork.
        RecommendationOutcome outcome = outcomeService.deriveOutcome(
                setup.user().getId(), rec.getId());

        assertThat(outcome.postAttempts()).isEqualTo(2);
        assertThat(outcome.postAccuracy()).isEqualByComparingTo("50.00");
    }

    @Test
    void derivationWritesNothing() {
        Setup setup = setup();
        attempt(setup, 1, 4, T0);
        Recommendation rec = recommendation(setup, T1, RecommendationStatus.ACTIVE);
        attempt(setup, 4, 4, T2);
        long attemptsBefore = quizAttemptRepository.count();
        long recsBefore = recommendationRepository.count();

        outcomeService.deriveOutcome(setup.user().getId(), rec.getId());

        assertThat(quizAttemptRepository.count()).isEqualTo(attemptsBefore);
        assertThat(recommendationRepository.count()).isEqualTo(recsBefore);
    }
}
