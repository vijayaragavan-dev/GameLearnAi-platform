package com.gamelearn.gamification;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.LocalDate;
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
import com.gamelearn.dto.QuizSubmissionRequest;
import com.gamelearn.entity.Quiz;
import com.gamelearn.entity.Achievement;
import com.gamelearn.entity.QuizAttempt;
import com.gamelearn.entity.Question;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.entity.enums.SourceType;
import com.gamelearn.repository.AchievementRepository;
import com.gamelearn.repository.LearnerProfileRepository;
import com.gamelearn.repository.QuestionRepository;
import com.gamelearn.repository.QuizAttemptRepository;
import com.gamelearn.repository.QuizQuestionRepository;
import com.gamelearn.repository.QuizRepository;
import com.gamelearn.repository.StreakRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.UserAchievementRepository;
import com.gamelearn.repository.UserRepository;
import com.gamelearn.repository.XpTransactionRepository;
import com.gamelearn.service.QuizSubmissionService;

/**
 * Stage 5/8 integration layer: QUIZ-002 + Adaptive + Gamification in ONE
 * transaction (Gamification Specification sections 9/13/14), including
 * rollback, retry, duplicate, boundary and concurrency cases against H2.
 */
@SpringBootTest
@ActiveProfiles("test")
class GamificationIntegrationTest {

    @Autowired
    private AuthService authService;
    @Autowired
    private UserRepository userRepository;
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
    private QuizAttemptRepository quizAttemptRepository;
    @Autowired
    private XpTransactionRepository xpTransactionRepository;
    @Autowired
    private UserAchievementRepository userAchievementRepository;
    @Autowired
    private StreakRepository streakRepository;
    @Autowired
    private LearnerProfileRepository learnerProfileRepository;
    @Autowired
    private QuizSubmissionService quizSubmissionService;
    @Autowired
    private JdbcTemplate jdbcTemplate;

    @MockitoSpyBean
    private XpTransactionRepository xpTransactionSpyRepository;

    @MockitoSpyBean
    private AchievementRepository achievementRepositorySpy;

    // ------------------------------------------------------------------
    // fixtures
    // ------------------------------------------------------------------

    private User newUser(String label) {
        AuthResponse auth = authService.register(new com.gamelearn.dto.RegisterRequest(
                label + "-" + UUID.randomUUID() + "@example.test",
                "Str0ng-Passw0rd!", "Learner " + label));
        return userRepository.findById(auth.user().id()).orElseThrow();
    }

    private record Fixture(Quiz quiz, Question q1, Question q2) {
    }

    private Fixture twoQuestionQuiz(String label) {
        Subject subject = new Subject();
        subject.setName(label + " " + UUID.randomUUID());
        subject.setDescription(label);
        subject.setIconKey("icon");
        subject.setActive(true);
        subject.setDisplayOrder(1);
        subjectRepository.save(subject);

        Topic topic = new Topic();
        topic.setSubject(subject);
        topic.setName(label + " topic");
        topic.setDescription(label + " description");
        topic.setDifficulty(Difficulty.MEDIUM);
        topic.setDisplayOrder(1);
        topic.setActive(true);
        topicRepository.save(topic);

        Quiz quiz = new Quiz();
        quiz.setTopic(topic);
        quiz.setTitle(label + " Quiz");
        quiz.setDifficulty(Difficulty.MEDIUM);
        quiz.setSourceType(SourceType.CURATED);
        quiz.setActive(true);
        quiz = quizRepository.save(quiz);

        Question q1 = question("a", topic);
        Question q2 = question("b", topic);
        associate(quiz, q1, 1);
        associate(quiz, q2, 2);
        return new Fixture(quiz, q1, q2);
    }

    private Question question(String correct, Topic topic) {
        Question q = new Question();
        q.setTopic(topic);
        q.setQuestionText("Answer " + correct + "?");
        q.setQuestionType(com.gamelearn.entity.enums.QuestionType.MCQ);
        q.setDifficulty(Difficulty.EASY);
        q.setOptionsJson("{\"options\":[\"" + correct + "\",\"wrong\"]}");
        q.setCorrectAnswer(correct);
        q.setExplanation("because");
        q.setSourceType(SourceType.CURATED);
        q.setActive(true);
        return questionRepository.save(q);
    }

    private void associate(Quiz quiz, Question q, int order) {
        var link = new com.gamelearn.entity.QuizQuestion();
        link.setQuiz(quiz);
        link.setQuestion(q);
        link.setQuestionOrder(order);
        quizQuestionRepository.save(link);
    }


    /** Spec G21 fixture: identical catalog except FIRST_QUIZ carries an unparseable config. */
    @SuppressWarnings("unchecked")
    private List<Achievement> modifiedCatalogWithBrokenFirstQuiz(List<Achievement> real) {
        List<Achievement> modified = new java.util.ArrayList<>();
        for (Achievement achievement : real) {
            if ("FIRST_QUIZ".equals(achievement.getCode())) {
                Achievement broken = new Achievement();
                org.springframework.test.util.ReflectionTestUtils.setField(
                        broken, "id", achievement.getId());
                broken.setCode(achievement.getCode());
                broken.setName(achievement.getName());
                broken.setDescription(achievement.getDescription());
                broken.setRuleType(achievement.getRuleType());
                broken.setRuleConfigJson("{\"threshold\": \"ten\"}");
                broken.setXpReward(achievement.getXpReward());
                broken.setActive(true);
                modified.add(broken);
            } else {
                modified.add(achievement);
            }
        }
        return modified;
    }

    /** @param firstCorrect answer for q1 ("a"=correct, anything else wrong) */
    private java.math.BigDecimal submit(User learner, Fixture fixture,
                                        boolean allCorrect, boolean secondCorrect) {
        var answers = List.of(
                new QuizSubmissionRequest.SubmittedAnswer(fixture.q1().getId(),
                        allCorrect || secondCorrect ? "a" : "wrong"),
                new QuizSubmissionRequest.SubmittedAnswer(fixture.q2().getId(),
                        allCorrect ? "b" : "wrong"));
        var result = quizSubmissionService.submit(learner.getId(), fixture.quiz().getId(),
                new QuizSubmissionRequest(answers));
        return result.score();
    }

    private int xpTotal(UUID userId) {
        Integer total = jdbcTemplate.queryForObject(
                "SELECT COALESCE(SUM(amount),0) FROM xp_transactions x "
                        + "JOIN users u ON u.id=x.user_id WHERE u.id=?",
                Integer.class, userId);
        return total == null ? 0 : total;
    }

    private long unlockedCount(UUID userId) {
        return userAchievementRepository.countByUserId(userId);
    }

    private boolean unlocked(UUID userId, String code) {
        Boolean hit = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM user_achievements ua "
                        + "JOIN achievements a ON a.id=ua.achievement_id "
                        + "WHERE ua.user_id=? AND a.code=?",
                Long.class, userId, code) > 0;
        return Boolean.TRUE.equals(hit);
    }

    // ------------------------------------------------------------------
    // XP + level + achievements happy paths
    // ------------------------------------------------------------------

    @Test
    @DisplayName("INT-01: partial score awards base+performance+FIRST_QUIZ; streak created")
    void happyPathAwardsConsistently() {
        User learner = newUser("gamhappy");
        Fixture fixture = twoQuestionQuiz("gamhappy");

        java.math.BigDecimal score = submit(learner, fixture, false, true);
        assertThat(score).isEqualByComparingTo("50.00");

        // base 10 + performance 7 (50*0.15=7.50 -> 7) + FIRST_QUIZ reward 20 = 37.
        assertThat(xpTotal(learner.getId())).isEqualTo(37);
        var profile = learnerProfileRepository.findByUserId(learner.getId()).orElseThrow();
        assertThat(profile.getTotalXp()).isEqualTo(37);
        assertThat(profile.getCurrentLevel()).isEqualTo(1); // 37 < T(2)=100

        var streak = streakRepository.findByUserId(learner.getId()).orElseThrow();
        assertThat(streak.getCurrentStreakDays()).isEqualTo(1);
        assertThat(streak.getLongestStreakDays()).isEqualTo(1);
        assertThat(streak.getTimezone()).isEqualTo("UTC");
        assertThat(streak.getLastLearningDate()).isEqualTo(LocalDate.now(java.time.ZoneOffset.UTC));

        assertThat(unlocked(learner.getId(), "FIRST_QUIZ")).isTrue();
        assertThat(unlockedCount(learner.getId())).isEqualTo(1);

        Long perfRows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM xp_transactions x JOIN users u ON u.id=x.user_id "
                        + "WHERE u.id=? AND x.event_type='QUIZ_PERFORMANCE'",
                Long.class, learner.getId());
        assertThat(perfRows).isEqualTo(1); // accuracy 50 -> 7 > 0, row written
    }

    @Test
    @DisplayName("Perfect first attempt: three unlocks, multi-component XP, level jump to 2")
    void perfectFirstAttemptJumpsLevel() {
        User learner = newUser("gammaster");
        Fixture fixture = twoQuestionQuiz("gammaster");

        java.math.BigDecimal score = submit(learner, fixture, true, false);
        assertThat(score).isEqualByComparingTo("100.00");

        // base 10 + perf 15 + FIRST_QUIZ 20 + PERFECT_SCORE 30 + FIRST_MASTERED 40 = 115 >= 100.
        assertThat(xpTotal(learner.getId())).isEqualTo(115);
        var profile = learnerProfileRepository.findByUserId(learner.getId()).orElseThrow();
        assertThat(profile.getTotalXp()).isEqualTo(115);
        assertThat(profile.getCurrentLevel()).isEqualTo(2); // crossed T(2)=100

        assertThat(unlocked(learner.getId(), "FIRST_QUIZ")).isTrue();
        assertThat(unlocked(learner.getId(), "PERFECT_SCORE")).isTrue();
        assertThat(unlocked(learner.getId(), "FIRST_MASTERED")).isTrue();

        Long ledgerRows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM xp_transactions x JOIN users u ON u.id=x.user_id WHERE u.id=?",
                Long.class, learner.getId());
        assertThat(ledgerRows).isEqualTo(5); // completed, perf, 3x rewards
    }

    @Test
    @DisplayName("Zero score: base-only award, NO zero-amount performance row")
    void zeroScoreOmitsZeroAmountRow() {
        User learner = newUser("gamzero");
        Fixture fixture = twoQuestionQuiz("gamzero");

        java.math.BigDecimal score = submit(learner, fixture, false, false);
        assertThat(score).isEqualByComparingTo("0.00");

        // base 10 + FIRST_QUIZ 20; performance 0 writes NO ledger row (spec 4.2).
        assertThat(xpTotal(learner.getId())).isEqualTo(30);
        Long perfRows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM xp_transactions x JOIN users u ON u.id=x.user_id "
                        + "WHERE u.id=? AND x.event_type='QUIZ_PERFORMANCE'",
                Long.class, learner.getId());
        assertThat(perfRows).isZero();
        assertThat(streakRepository.findByUserId(learner.getId())).isPresent();
    }

    @Test
    @DisplayName("C4-boundary: TEN_QUIZZES unlocks exactly on the tenth processed attempt")
    void tenthAttemptUnlocksTenQuizzes() {
        User learner = newUser("gamten");
        Fixture fixture = twoQuestionQuiz("gamten");

        for (int attempt = 1; attempt <= 10; attempt++) {
            submit(learner, fixture, attempt % 2 == 0, true);
            if (attempt == 9) {
                assertThat(unlocked(learner.getId(), "TEN_QUIZZES")).isFalse();
            }
            if (attempt == 10) {
                assertThat(unlocked(learner.getId(), "TEN_QUIZZES")).isTrue();
            }
        }
        assertThat(quizAttemptRepository.countByUserId(learner.getId())).isEqualTo(10);
    }

    // ------------------------------------------------------------------
    // Streaks
    // ------------------------------------------------------------------

    @Test
    @DisplayName("STR-05/07: consecutive third day fires STREAK_BONUS once")
    void thirdDayMilestone() {
        User learner = newUser("gamstreak");
        Fixture fixture = twoQuestionQuiz("gamstreak");

        submit(learner, fixture, true, false); // real today -> day 1
        jdbcTemplate.update(
                "UPDATE streaks SET last_learning_date=?, current_streak_days=2, "
                        + "longest_streak_days=2 WHERE user_id=?",
                LocalDate.now(java.time.ZoneOffset.UTC).minusDays(1), learner.getId());

        int before = xpTotal(learner.getId());
        submit(learner, fixture, false, true); // consecutive -> reaches day 3

        // Reaching day 3 also unlocks STREAK_3 (+20) alongside the +5 bonus.
        assertThat(unlocked(learner.getId(), "STREAK_3")).isTrue();

        Integer bonus = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM xp_transactions x JOIN users u ON u.id=x.user_id "
                        + "WHERE u.id=? AND x.event_type='STREAK_BONUS' AND x.amount=5",
                Integer.class, learner.getId());
        assertThat(bonus).isEqualTo(1);
        assertThat(streakRepository.findByUserId(learner.getId()).orElseThrow()
                .getCurrentStreakDays()).isEqualTo(3);
        // before(35: 25 perfect + 10? recompute-free invariant) + 17 quiz + 5 bonus
        var profile = learnerProfileRepository.findByUserId(learner.getId()).orElseThrow();
        assertThat(profile.getTotalXp()).isEqualTo(before + 17 + 20 + 5);
    }

    @Test
    @DisplayName("G7 duplicate same-day submission: XP repeats, streak day does NOT double")
    void duplicateSameDaySubmission() {
        User learner = newUser("gamsameday");
        Fixture fixture = twoQuestionQuiz("gamsameday");

        submit(learner, fixture, true, false);
        submit(learner, fixture, true, false);

        assertThat(quizAttemptRepository.countByUserId(learner.getId())).isEqualTo(2);
        var streak = streakRepository.findByUserId(learner.getId()).orElseThrow();
        assertThat(streak.getCurrentStreakDays()).isEqualTo(1); // same-day no-op
        // pass1: 10+15+90 one-time rewards = 115; pass2 (no new unlocks): 10+15 = 25.
        assertThat(xpTotal(learner.getId())).isEqualTo(115 + 25);
        assertThat(unlockedCount(learner.getId())).isEqualTo(3); // never duplicated
        assertThat(unlocked(learner.getId(), "FIRST_QUIZ")).isTrue();
    }

    @Test
    @DisplayName("G21: malformed achievement config fails open for that entry only")
    void invalidConfigSkipsOnlyThatAchievement() {
        User learner = newUser("gambadcfg");
        Fixture fixture = twoQuestionQuiz("gambadcfg");

        // Corrupt ONLY the in-memory catalog view handed to the evaluator;
        // the persisted catalog is never touched (order-independent tests).
        List<Achievement> realCatalog = new java.util.ArrayList<>(
                achievementRepositorySpy.findByActiveTrueOrderByRuleTypeAscCodeAsc());
        Mockito.doReturn(modifiedCatalogWithBrokenFirstQuiz(realCatalog))
                .when(achievementRepositorySpy).findByActiveTrueOrderByRuleTypeAscCodeAsc();
        try {
            java.math.BigDecimal score = submit(learner, fixture, true, false);
            assertThat(score).isEqualByComparingTo("100.00");

            assertThat(unlocked(learner.getId(), "FIRST_QUIZ")).isFalse(); // skipped
            assertThat(unlocked(learner.getId(), "PERFECT_SCORE")).isTrue(); // siblings work
            // base 10 + perf 15 + PERFECT_SCORE 30 + FIRST_MASTERED 40 (no FIRST_QUIZ 20)
            assertThat(xpTotal(learner.getId())).isEqualTo(95);
        } finally {
            Mockito.reset(achievementRepositorySpy);
        }
    }

    // ------------------------------------------------------------------
    // Rollback / retry (section 14)
    // ------------------------------------------------------------------

    @Test
    @DisplayName("G14/G15: gamification failure rolls back EVERYTHING; retry succeeds cleanly")
    void rollbackThenCleanRetry() {
        User learner = newUser("gamrollback");
        Fixture fixture = twoQuestionQuiz("gamrollback");

        Mockito.doThrow(new IllegalStateException("boom"))
                .when(xpTransactionSpyRepository).save(Mockito.any());

        assertThatThrownBy(() -> submit(learner, fixture, true, false))
                .hasMessageContaining("boom");

        assertThat(quizAttemptRepository.countByUserId(learner.getId())).isZero();
        assertThat(xpTotal(learner.getId())).isZero();
        assertThat(learnerProfileRepository.findByUserId(learner.getId())
                .orElseThrow().getTotalXp()).isZero();
        assertThat(streakRepository.findByUserId(learner.getId())).isEmpty();
        assertThat(userAchievementRepository.countByUserId(learner.getId())).isZero();

        Mockito.reset(xpTransactionSpyRepository); // retry path
        java.math.BigDecimal score = submit(learner, fixture, true, false);
        assertThat(score).isEqualByComparingTo("100.00");
        assertThat(quizAttemptRepository.countByUserId(learner.getId())).isEqualTo(1);
        assertThat(xpTotal(learner.getId())).isEqualTo(115);
        assertThat(learnerProfileRepository.findByUserId(learner.getId())
                .orElseThrow().getCurrentLevel()).isEqualTo(2);
    }

    // ------------------------------------------------------------------
    // Concurrency (section 13)
    // ------------------------------------------------------------------

    @Test
    @DisplayName("G6/G18: simultaneous submissions stay consistent (XP, unlocks, streak)")
    void simultaneousSubmissionsRemainConsistent() throws Exception {
        User learner = newUser("gamconcurrent");
        Fixture fixture = twoQuestionQuiz("gamconcurrent");

        ExecutorService pool = Executors.newFixedThreadPool(2);
        CountDownLatch ready = new CountDownLatch(2);
        CountDownLatch go = new CountDownLatch(1);
        Future<java.math.BigDecimal> first = pool.submit(() -> {
            ready.countDown();
            go.await();
            return submit(learner, fixture, true, false);
        });
        Future<java.math.BigDecimal> second = pool.submit(() -> {
            ready.countDown();
            go.await();
            return submit(learner, fixture, false, true);
        });
        assertThat(ready.await(5, java.util.concurrent.TimeUnit.SECONDS)).isTrue();
        go.countDown();
        assertThat(first.get(30, java.util.concurrent.TimeUnit.SECONDS))
                .isEqualByComparingTo("100.00");
        assertThat(second.get(30, java.util.concurrent.TimeUnit.SECONDS))
                .isEqualByComparingTo("50.00");
        pool.shutdownNow();

        assertThat(quizAttemptRepository.countByUserId(learner.getId())).isEqualTo(2);
        // FIRST_QUIZ and PERFECT_SCORE always unlock. FIRST_MASTERED depends on
        // which submission INITIALISES mastery (Adaptive T01): if the 50-score
        // lands first, the topic ends at 75 (PROFICIENT) -> no MASTERED unlock;
        // if the 100-score lands first, it does. Both outcomes are approved.
        long unlockedCount = unlockedCount(learner.getId());
        assertThat(unlockedCount).isBetween(2L, 3L);
        assertThat(unlocked(learner.getId(), "FIRST_QUIZ")).isTrue();
        assertThat(unlocked(learner.getId(), "PERFECT_SCORE")).isTrue();
        assertThat(unlockedCount(learner.getId())).isEqualTo(unlockedCount);
        assertThat(streakRepository.findByUserId(learner.getId()).orElseThrow()
                .getCurrentStreakDays()).isEqualTo(1); // single calendar day credited

        // Ledger sum MUST equal the stored total (stage 11 consistency check).
        Integer ledgerSum = jdbcTemplate.queryForObject(
                "SELECT COALESCE(SUM(amount),0) FROM xp_transactions x "
                        + "JOIN users u ON u.id=x.user_id WHERE u.id=?",
                Integer.class, learner.getId());
        var profile = learnerProfileRepository.findByUserId(learner.getId()).orElseThrow();
        assertThat(ledgerSum).isEqualTo(profile.getTotalXp());
        // 100-score pass contributes 10+15 (+rewards present in unlockedCount);
        // 50-score pass contributes 10+7. Derive expectation from the ACTUAL
        // race outcome instead of assuming which submission initialised mastery.
        int expectedTotal = 17 + 25 + 20 + 30 + (unlockedCount == 3 ? 40 : 0);
        assertThat(profile.getTotalXp()).isEqualTo(expectedTotal);
        assertThat(profile.getCurrentLevel()).isEqualTo(LevelEngine.levelFor(expectedTotal));
    }
}
