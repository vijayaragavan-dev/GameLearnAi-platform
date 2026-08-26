package com.gamelearn.gamification;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.dto.AchievementItem;
import com.gamelearn.dto.GamificationSummaryResponse;
import com.gamelearn.dto.StreakResponse;
import com.gamelearn.entity.Achievement;
import com.gamelearn.entity.LearnerProfile;
import com.gamelearn.entity.QuizAttempt;
import com.gamelearn.entity.Streak;
import com.gamelearn.entity.User;
import com.gamelearn.entity.UserAchievement;
import com.gamelearn.entity.XpTransaction;
import com.gamelearn.entity.enums.MasteryLevel;
import com.gamelearn.entity.enums.XpEventType;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.repository.AchievementRepository;
import com.gamelearn.repository.LearnerProfileRepository;
import com.gamelearn.repository.QuizAttemptRepository;
import com.gamelearn.repository.StreakRepository;
import com.gamelearn.repository.TopicMasteryRepository;
import com.gamelearn.repository.UserAchievementRepository;
import com.gamelearn.repository.XpTransactionRepository;

/**
 * Gamification Engine (Phase 7) — XP · levels · achievements · streaks
 * (Gamification Specification v1.0.0 APPROVED).
 *
 * <p>Transactional model: awardForQuizSubmission runs INSIDE the QUIZ-002
 * transaction AFTER the Adaptive Engine pipeline, in the owner-approved order
 * O-1 quiz XP → O-2 achievements (+reward XP) → O-3 streak (+milestone XP)
 * → O-4 total_xp + single level recalculation. Any failure rolls back the
 * whole host transaction (spec section 14).</p>
 *
 * <p>Everything is server-derived; no client input reaches any amount,
 * unlock, date, or level (spec section 15). STREAK_DAYS predicates observe
 * this pass's projected streak day (section 9 ordering note), so the
 * streak row lock is acquired BEFORE achievement evaluation and held to
 * commit — after the adaptive mastery/profile locks in every transaction,
 * preserving the established deadlock-free order.</p>
 */
@Service
public class GamificationService {

    private static final Logger log = LoggerFactory.getLogger(GamificationService.class);
    private static final String V1_TIMEZONE = "UTC";

    private final XpTransactionRepository xpTransactionRepository;
    private final AchievementRepository achievementRepository;
    private final UserAchievementRepository userAchievementRepository;
    private final StreakRepository streakRepository;
    private final LearnerProfileRepository learnerProfileRepository;
    private final QuizAttemptRepository quizAttemptRepository;
    private final TopicMasteryRepository topicMasteryRepository;

    /** Injectable for deterministic streak-date tests; UTC in production. */
    private Clock clock = Clock.systemUTC();

    public GamificationService(XpTransactionRepository xpTransactionRepository,
                               AchievementRepository achievementRepository,
                               UserAchievementRepository userAchievementRepository,
                               StreakRepository streakRepository,
                               LearnerProfileRepository learnerProfileRepository,
                               QuizAttemptRepository quizAttemptRepository,
                               TopicMasteryRepository topicMasteryRepository) {
        this.xpTransactionRepository = xpTransactionRepository;
        this.achievementRepository = achievementRepository;
        this.userAchievementRepository = userAchievementRepository;
        this.streakRepository = streakRepository;
        this.learnerProfileRepository = learnerProfileRepository;
        this.quizAttemptRepository = quizAttemptRepository;
        this.topicMasteryRepository = topicMasteryRepository;
    }

    void setClock(Clock clock) {
        this.clock = clock;
    }

    // ------------------------------------------------------------------
    // O-1..O-4 — the approved quiz-submission integration
    // ------------------------------------------------------------------

    @Transactional
    public void awardForQuizSubmission(User learner, QuizAttempt attempt) {
        // O-1: quiz XP (base always; performance component only when > 0).
        int base = XpCalculator.baseQuizXp();
        int performance = XpCalculator.performanceXp(attempt.getScore());
        writeLedger(learner, XpEventType.QUIZ_COMPLETED, base, "QUIZ_ATTEMPT",
                attempt.getId(), "Quiz completion");
        if (performance > 0) {
            writeLedger(learner, XpEventType.QUIZ_PERFORMANCE, performance, "QUIZ_ATTEMPT",
                    attempt.getId(),
                    "Quiz performance (accuracy " + attempt.getScore().toPlainString() + ")");
        }

        // Streak projection under lock BEFORE achievements so STREAK_DAYS
        // predicates observe this pass's day (section 9 ordering note).
        LocalDate today = LocalDate.now(clock.withZone(ZoneOffset.UTC));
        Streak streak = streakRepository.findWithLock(learner.getId()).orElse(null);
        StreakEngine.Decision decision = streak == null
                ? StreakEngine.decide(null, today, 0, 0)
                : StreakEngine.decide(streak.getLastLearningDate(), today,
                        streak.getCurrentStreakDays(), streak.getLongestStreakDays());

        // O-2: achievements + reward XP.
        int rewardXp = evaluateAchievements(learner, attempt, decision.newCurrent());
        Integer milestoneXp = decision.milestoneXp();

        // O-3: apply the projected streak state + milestone bonus.
        applyStreak(streak, learner, decision, today);

        // O-4: accumulate total_xp once and recalculate the level exactly once.
        applyTotalsAndLevel(learner, base, performance, rewardXp, milestoneXp);
    }

    private int evaluateAchievements(User learner, QuizAttempt attempt, int projectedStreakDays) {
        List<Achievement> catalog =
                achievementRepository.findByActiveTrueOrderByRuleTypeAscCodeAsc();
        if (catalog.isEmpty()) {
            return 0;
        }
        long attemptCount = quizAttemptRepository.countByUserId(learner.getId());
        boolean perfect = attempt.getScore()
                .compareTo(java.math.BigDecimal.valueOf(100)) >= 0;
        long masteredCount = topicMasteryRepository.countByUserIdAndMasteryLevel(
                learner.getId(), MasteryLevel.MASTERED);
        var snapshot = new AchievementRules.Snapshot(
                attemptCount, perfect, masteredCount, projectedStreakDays);

        int rewardXp = 0;
        List<String> unlockedCodes = new ArrayList<>();
        for (Achievement achievement : catalog) {
            if (userAchievementRepository.existsByUserIdAndAchievementId(
                    learner.getId(), achievement.getId())) {
                continue; // one-time unlock (section 7.2)
            }
            var threshold = AchievementRules.parseThreshold(achievement.getRuleConfigJson());
            if (threshold.isEmpty()) {
                log.warn("GAM_ACH_CONFIG_INVALID code={}", achievement.getCode());
                continue; // fail-open for THIS achievement only (section 7.1)
            }
            if (!AchievementRules.satisfied(
                    achievement.getRuleType(), threshold.getAsInt(), snapshot)) {
                continue;
            }
            try {
                UserAchievement unlock = new UserAchievement();
                unlock.setUser(learner);
                unlock.setAchievement(achievement);
                unlock.setUnlockedAt(Instant.now(clock));
                userAchievementRepository.save(unlock);
            } catch (DataIntegrityViolationException raced) {
                continue; // concurrent unlock loser: UNIQUE constraint decides (13.3)
            }
            int reward = XpCalculator.capped(achievement.getXpReward());
            writeLedger(learner, XpEventType.ACHIEVEMENT_UNLOCKED, reward, "ACHIEVEMENT",
                    achievement.getId(), "Achievement unlocked: " + achievement.getCode());
            rewardXp += reward;
            unlockedCodes.add(achievement.getCode());
        }
        if (!unlockedCodes.isEmpty()) {
            log.info("GAM_ACHIEVEMENT_UNLOCKED codes={}", unlockedCodes);
        }
        return rewardXp;
    }

    private void applyStreak(Streak existing, User learner,
                             StreakEngine.Decision decision, LocalDate today) {
        if (decision.sameDayNoOp()) {
            return; // same-day repeat: full no-op (section 8.2)
        }
        Streak streak = existing != null ? existing : new Streak();
        streak.setUser(learner);
        streak.setCurrentStreakDays(decision.newCurrent());
        streak.setLongestStreakDays(decision.newLongest());
        streak.setLastLearningDate(today);
        if (streak.getTimezone() == null || streak.getTimezone().isBlank()) {
            streak.setTimezone(V1_TIMEZONE); // section 10: v1 fixed UTC
        }
        streakRepository.save(streak);
        log.info("GAM_STREAK_UPDATED current={} longest={}",
                decision.newCurrent(), decision.newLongest());

        if (decision.milestoneXp() != null) {
            writeLedger(learner, XpEventType.STREAK_BONUS, decision.milestoneXp(),
                    "STREAK_MILESTONE", null,
                    "Streak milestone: " + decision.newCurrent() + " days");
        }
    }

    private void applyTotalsAndLevel(User learner, int base, int performance,
                                     int rewardXp, Integer milestoneXp) {
        LearnerProfile profile = learnerProfileRepository.findWithLock(learner.getId())
                .orElseThrow(() -> new ApiException(
                        ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                        ErrorCode.INTERNAL_ERROR.name(),
                        "Learner profile missing"));
        int previousLevel = profile.getCurrentLevel();
        long delta = (long) base + performance + rewardXp
                + (milestoneXp == null ? 0 : milestoneXp);
        long clampedTotal = Math.min(Integer.MAX_VALUE,
                Math.max(0L, profile.getTotalXp() + (long) delta));
        profile.setTotalXp((int) clampedTotal);
        int recalculated = LevelEngine.levelFor(clampedTotal);
        profile.setCurrentLevel(Math.max(previousLevel, recalculated)); // never decreases
        learnerProfileRepository.save(profile);
        if (recalculated > previousLevel) {
            log.info("GAM_LEVEL_UP from={} to={}", previousLevel, recalculated);
        }
        log.debug("GAM_XP_AWARDED delta={} total={}", delta, clampedTotal);
    }

    private void writeLedger(User learner, XpEventType eventType, int amount,
                             String referenceType, java.util.UUID referenceId,
                             String description) {
        if (amount <= 0) {
            return; // section 4.2: every ledger row MUST carry a positive amount
        }
        XpTransaction row = new XpTransaction();
        row.setUser(learner);
        row.setEventType(eventType);
        row.setAmount(XpCalculator.capped(amount));
        row.setReferenceType(referenceType);
        row.setReferenceId(referenceId);
        row.setDescription(description.length() > 255 ? description.substring(0, 255) : description);
        xpTransactionRepository.save(row);
    }

    // ------------------------------------------------------------------
    // GAM-001 / GAM-002 / GAM-003 reads (API Contract v1.1.0 section 5A)
    // ------------------------------------------------------------------

    @Transactional(readOnly = true)
    public GamificationSummaryResponse summary(UUID userId) {
        LearnerProfile profile = learnerProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                        ErrorCode.INTERNAL_ERROR.name(),
                        "Learner profile missing"));
        Long nextThreshold = LevelEngine.nextThreshold(profile.getCurrentLevel());
        Integer xpToNext = nextThreshold == null
                ? null
                : Math.toIntExact(Math.max(0, nextThreshold - profile.getTotalXp()));
        Streak streak = streakRepository.findByUserId(userId).orElse(null);
        return new GamificationSummaryResponse(
                profile.getTotalXp(),
                profile.getCurrentLevel(),
                GamificationConstants.MAX_LEVEL,
                nextThreshold,
                xpToNext,
                streak == null ? 0 : streak.getCurrentStreakDays(),
                streak == null ? 0 : streak.getLongestStreakDays(),
                userAchievementRepository.countByUserId(userId));
    }

    @Transactional(readOnly = true)
    public List<AchievementItem> achievements(UUID userId) {
        List<Achievement> catalog = achievementRepository
                .findByActiveTrueOrderByRuleTypeAscCodeAsc();
        Map<java.util.UUID, Instant> unlockedByAchievementId = new java.util.HashMap<>();
        for (UserAchievement unlock : userAchievementRepository.findByUserId(userId)) {
            unlockedByAchievementId.put(unlock.getAchievement().getId(), unlock.getUnlockedAt());
        }
        List<AchievementItem> items = new ArrayList<>(catalog.size());
        for (Achievement achievement : catalog) {
            items.add(new AchievementItem(achievement.getCode(), achievement.getName(),
                    achievement.getDescription(), achievement.getIconKey(),
                    achievement.getXpReward(),
                    unlockedByAchievementId.get(achievement.getId())));
        }
        return items;
    }

    @Transactional(readOnly = true)
    public StreakResponse streak(UUID userId) {
        return streakRepository.findByUserId(userId)
                .map(streak -> new StreakResponse(streak.getCurrentStreakDays(),
                        streak.getLongestStreakDays(), streak.getLastLearningDate(),
                        streak.getTimezone()))
                .orElse(new StreakResponse(0, 0, null, V1_TIMEZONE));
    }
}
