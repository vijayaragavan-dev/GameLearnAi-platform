package com.gamelearn.service;

import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Limit;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.auth.AuthenticatedUser;
import com.gamelearn.dto.AssessedSubjectItem;
import com.gamelearn.dto.AssessmentView;
import com.gamelearn.dto.AchievementUnlockItem;
import com.gamelearn.dto.AchievementsView;
import com.gamelearn.dto.CurrentSubjectView;
import com.gamelearn.dto.CurrentTopicView;
import com.gamelearn.dto.DashboardResponse;
import com.gamelearn.dto.GamificationView;
import com.gamelearn.dto.LearnerOverview;
import com.gamelearn.dto.LearningNodeResponse;
import com.gamelearn.dto.LearningPathCard;
import com.gamelearn.dto.MasterySummary;
import com.gamelearn.dto.RecentActivityView;
import com.gamelearn.dto.RecentQuizItem;
import com.gamelearn.dto.RecentTopicItem;
import com.gamelearn.dto.RecommendationItem;
import com.gamelearn.dto.StreakResponse;
import com.gamelearn.entity.LearningPath;
import com.gamelearn.entity.LearningPathNode;
import com.gamelearn.entity.LearnerProfile;
import com.gamelearn.entity.QuizAttempt;
import com.gamelearn.entity.Recommendation;
import com.gamelearn.entity.Streak;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.TopicMastery;
import com.gamelearn.entity.UserAchievement;
import com.gamelearn.entity.enums.LearningPathStatus;
import com.gamelearn.entity.enums.MasteryLevel;
import com.gamelearn.entity.enums.QuizAttemptStatus;
import com.gamelearn.entity.enums.RecommendationStatus;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.gamification.GamificationConstants;
import com.gamelearn.gamification.LevelEngine;
import com.gamelearn.repository.LearningPathNodeRepository;
import com.gamelearn.repository.LearningPathRepository;
import com.gamelearn.repository.LearnerProfileRepository;
import com.gamelearn.repository.QuizAttemptRepository;
import com.gamelearn.repository.RecommendationRepository;
import com.gamelearn.repository.StreakRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicMasteryRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.UserAchievementRepository;

/**
 * DASH-001 — learner Dashboard read model (Dashboard Specification v1.0.0
 * APPROVED; API Contract v1.3.0 section 5C).
 *
 * <p>READ-ONLY aggregation: one {@code @Transactional(readOnly = true)}
 * method that assembles the learner's own already-persisted state from the
 * existing domain repositories. The Dashboard owns NOTHING and mutates
 * NOTHING — no mastery/adaptive recalculation, no XP/achievement/streak
 * events, no recommendation lifecycle changes, no path generation, no
 * Gemini/AI involvement, no network I/O of any kind.</p>
 *
 * <p>Every displayed value is traced to an approved source (Dashboard Spec
 * section 8). Ordering rules are total and deterministic (section 14);
 * collection bounds are compiled constants (section 15); queries are flat
 * and principal-scoped with join-fetched names to prevent N+1 (section 20).</p>
 */
@Service
public class DashboardService {

    private static final Logger log = LoggerFactory.getLogger(DashboardService.class);

    /** Compiled collection bounds (Dashboard Spec section 15) — not configurable. */
    static final int RECOMMENDATIONS_LIMIT = 3;
    static final int RECENT_TOPICS_LIMIT = 5;
    static final int RECENT_UNLOCKS_LIMIT = 5;
    static final int RECENT_QUIZZES_LIMIT = 5;

    private static final String V1_TIMEZONE = "UTC";

    /**
     * Total deterministic recommendation ordering (Dashboard Spec section 14):
     * priority ASC, generated_at DESC, id ASC.
     */
    private static final Comparator<Recommendation> RECOMMENDATION_ORDER =
            Comparator.comparingInt(Recommendation::getPriority)
                    .thenComparing(Recommendation::getGeneratedAt, Comparator.reverseOrder())
                    .thenComparing(Recommendation::getId);

    private final LearnerProfileRepository learnerProfileRepository;
    private final SubjectRepository subjectRepository;
    private final TopicRepository topicRepository;
    private final TopicMasteryRepository topicMasteryRepository;
    private final RecommendationRepository recommendationRepository;
    private final UserAchievementRepository userAchievementRepository;
    private final StreakRepository streakRepository;
    private final QuizAttemptRepository quizAttemptRepository;
    private final LearningPathRepository learningPathRepository;
    private final LearningPathNodeRepository learningPathNodeRepository;

    public DashboardService(LearnerProfileRepository learnerProfileRepository,
                            SubjectRepository subjectRepository,
                            TopicRepository topicRepository,
                            TopicMasteryRepository topicMasteryRepository,
                            RecommendationRepository recommendationRepository,
                            UserAchievementRepository userAchievementRepository,
                            StreakRepository streakRepository,
                            QuizAttemptRepository quizAttemptRepository,
                            LearningPathRepository learningPathRepository,
                            LearningPathNodeRepository learningPathNodeRepository) {
        this.learnerProfileRepository = learnerProfileRepository;
        this.subjectRepository = subjectRepository;
        this.topicRepository = topicRepository;
        this.topicMasteryRepository = topicMasteryRepository;
        this.recommendationRepository = recommendationRepository;
        this.userAchievementRepository = userAchievementRepository;
        this.streakRepository = streakRepository;
        this.quizAttemptRepository = quizAttemptRepository;
        this.learningPathRepository = learningPathRepository;
        this.learningPathNodeRepository = learningPathNodeRepository;
    }

    @Transactional(readOnly = true)
    public DashboardResponse dashboard(AuthenticatedUser principal) {
        UUID userId = principal.id();

        // Registration guarantees the profile row; absence is a data
        // invariant violation answered with the approved 500 (mirrors GAM-001).
        LearnerProfile profile = learnerProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                        ErrorCode.INTERNAL_ERROR.name(),
                        "Learner profile missing"));

        UUID currentSubjectId = profile.getCurrentSubject() == null
                ? null : profile.getCurrentSubject().getId();
        UUID currentTopicId = profile.getCurrentTopic() == null
                ? null : profile.getCurrentTopic().getId();

        LearnerOverview learner = new LearnerOverview(
                principal.displayName(),
                profile.getOverallMastery(),
                currentSubjectId,
                currentTopicId);

        CurrentSubjectView currentSubject = buildCurrentSubject(currentSubjectId, currentTopicId);
        MasterySummary mastery = buildMastery(userId);
        GamificationView gamification = buildGamification(profile);
        StreakResponse streak = buildStreak(userId);
        AchievementsView achievements = buildAchievements(userId);
        List<RecommendationItem> recommendations = buildRecommendations(userId);
        LearningPathCard learningPath = buildLearningPath(userId, currentSubjectId);
        AssessmentView assessment = buildAssessment(userId);
        RecentActivityView recentActivity = buildRecentActivity(userId);

        log.info("DASH_COMPOSED recommendations={} recentTopics={} recentUnlocks={} recentQuizzes={}",
                recommendations.size(), mastery.recentTopics().size(),
                achievements.recentUnlocks().size(), recentActivity.quizzes().size());

        return new DashboardResponse(learner, currentSubject, mastery, gamification,
                streak, achievements, recommendations, learningPath, assessment, recentActivity);
    }

    // ------------------------------------------------------------------
    // Section builders (Dashboard Specification section 8)
    // ------------------------------------------------------------------

    /**
     * section 8.2 — non-null iff the pointer resolves to an ACTIVE subject;
     * the topic block additionally requires an ACTIVE topic of THAT subject
     * (Case 8 guard). Inactive fallthrough yields null, never an error.
     */
    private CurrentSubjectView buildCurrentSubject(UUID subjectId, UUID topicId) {
        if (subjectId == null) {
            return null;
        }
        Subject subject = subjectRepository.findById(subjectId).orElse(null);
        if (subject == null || !subject.isActive()) {
            return null;
        }
        CurrentTopicView currentTopic = null;
        if (topicId != null) {
            Topic topic = topicRepository.findById(topicId).orElse(null);
            if (topic != null && topic.isActive()
                    && subjectId.equals(topic.getSubject().getId())) {
                currentTopic = new CurrentTopicView(topic.getId(), topic.getName(),
                        topic.getDifficulty().name());
            }
        }
        return new CurrentSubjectView(subject.getId(), subject.getName(),
                subject.getIconKey(), currentTopic);
    }

    /** section 8.3 — stored values verbatim; counts over rows only. */
    private MasterySummary buildMastery(UUID userId) {
        int topicsAssessed = (int) topicMasteryRepository.countByUserId(userId);
        int topicsMastered = (int) topicMasteryRepository.countByUserIdAndMasteryLevel(
                userId, MasteryLevel.MASTERED);
        List<RecentTopicItem> recentTopics = topicMasteryRepository
                .findRecentTopicsForDashboard(userId, Limit.of(RECENT_TOPICS_LIMIT))
                .stream()
                .map(this::toRecentTopicItem)
                .toList();
        return new MasterySummary(topicsAssessed, topicsMastered, recentTopics);
    }

    private RecentTopicItem toRecentTopicItem(TopicMastery mastery) {
        Topic topic = mastery.getTopic();
        return new RecentTopicItem(
                topic.getId(),
                topic.getName(),
                mastery.getMasteryScore(),
                mastery.getMasteryLevel().name(),
                mastery.getCurrentDifficulty().name(),
                mastery.getTrend().name(),
                mastery.getLastAssessedAt());
    }

    /** section 8.4 — GAM-001 parity via the same LevelEngine rules. */
    private GamificationView buildGamification(LearnerProfile profile) {
        Long nextThreshold = LevelEngine.nextThreshold(profile.getCurrentLevel());
        Integer xpToNext = nextThreshold == null
                ? null
                : Math.toIntExact(Math.max(0, nextThreshold - profile.getTotalXp()));
        return new GamificationView(profile.getTotalXp(), profile.getCurrentLevel(),
                GamificationConstants.MAX_LEVEL, nextThreshold, xpToNext);
    }

    /** section 8.5 — GAM-003 shape and zero-state parity. */
    private StreakResponse buildStreak(UUID userId) {
        Streak streak = streakRepository.findByUserId(userId).orElse(null);
        return streak == null
                ? new StreakResponse(0, 0, null, V1_TIMEZONE)
                : new StreakResponse(streak.getCurrentStreakDays(),
                        streak.getLongestStreakDays(), streak.getLastLearningDate(),
                        streak.getTimezone());
    }

    /** section 8.6 — unlock count plus newest unlocks; locked entries excluded. */
    private AchievementsView buildAchievements(UUID userId) {
        long unlockedCount = userAchievementRepository.countByUserId(userId);
        List<AchievementUnlockItem> recentUnlocks = userAchievementRepository
                .findRecentUnlocksForDashboard(userId, Limit.of(RECENT_UNLOCKS_LIMIT))
                .stream()
                .map(unlock -> {
                    var achievement = unlock.getAchievement();
                    return new AchievementUnlockItem(achievement.getCode(),
                            achievement.getName(), achievement.getIconKey(),
                            unlock.getUnlockedAt());
                })
                .toList();
        return new AchievementsView(unlockedCount, recentUnlocks);
    }

    /**
     * section 8.7 — ACTIVE recommendations only, displayed without mutation:
     * reading the dashboard never consumes/expires/modifies a recommendation.
     */
    private List<RecommendationItem> buildRecommendations(UUID userId) {
        List<Recommendation> active = recommendationRepository
                .findByUserIdAndStatusOrderByPriorityAscGeneratedAtDesc(
                        userId, RecommendationStatus.ACTIVE);
        Set<UUID> topicIds = new HashSet<>();
        for (Recommendation recommendation : active) {
            if (recommendation.getTopic() != null) {
                topicIds.add(recommendation.getTopic().getId());
            }
        }
        Map<UUID, String> topicNames = loadTopicNames(topicIds);
        return active.stream()
                .sorted(RECOMMENDATION_ORDER)
                .limit(RECOMMENDATIONS_LIMIT)
                .map(recommendation -> toRecommendationItem(recommendation, topicNames))
                .toList();
    }

    private RecommendationItem toRecommendationItem(Recommendation recommendation,
                                                    Map<UUID, String> topicNames) {
        Topic topic = recommendation.getTopic();
        UUID topicId = topic == null ? null : topic.getId();
        return new RecommendationItem(
                topicId,
                topicId == null ? null : topicNames.get(topicId),
                recommendation.getActivityType().name(),
                recommendation.getRecommendedDifficulty() == null
                        ? null : recommendation.getRecommendedDifficulty().name(),
                recommendation.getPriority(),
                recommendation.getReason(),
                recommendation.getGeneratedAt());
    }

    /** Batched name lookup for the selected slice — prevents N+1 lazy loads. */
    private Map<UUID, String> loadTopicNames(Set<UUID> topicIds) {
        if (topicIds.isEmpty()) {
            return Map.of();
        }
        Map<UUID, String> names = new HashMap<>(topicIds.size());
        for (Topic topic : topicRepository.findAllById(topicIds)) {
            names.put(topic.getId(), topic.getName());
        }
        return names;
    }

    /**
     * section 8.8, decision D1 — active-path card selection, read-only:
     * (1) ACTIVE path of the current subject first; (2) else most recent
     * ACTIVE path in any subject; (3) else null. Nothing is generated,
     * archived or regenerated here; PATH-002/Gemini never run.
     */
    private LearningPathCard buildLearningPath(UUID userId, UUID currentSubjectId) {
        List<LearningPath> activePaths = learningPathRepository.findByStatusForDashboard(
                userId, LearningPathStatus.ACTIVE);
        LearningPath selected = null;
        if (currentSubjectId != null) {
            selected = activePaths.stream()
                    .filter(path -> path.getSubject().getId().equals(currentSubjectId))
                    .findFirst()
                    .orElse(null);
        }
        if (selected == null && !activePaths.isEmpty()) {
            selected = activePaths.get(0);
        }
        if (selected == null) {
            return null;
        }
        List<LearningNodeResponse> nodes = learningPathNodeRepository
                .findNodesForDashboard(selected.getId())
                .stream()
                .map(this::toLearningNodeResponse)
                .toList();
        return new LearningPathCard(selected.getId(), selected.getSubject().getId(),
                selected.getSubject().getName(), selected.getTitle(),
                selected.getStatus().name(), selected.getGeneratedBy().name(),
                selected.getCreatedAt(), nodes);
    }

    private LearningNodeResponse toLearningNodeResponse(LearningPathNode node) {
        Topic topic = node.getTopic();
        return new LearningNodeResponse(node.getId(), topic.getId(), topic.getName(),
                node.getSequenceNumber(), node.getRequiredMastery(),
                node.getStatus().name());
    }

    /** section 8.9, decision D3 — R-GUARD lineage criterion, aggregated. */
    private AssessmentView buildAssessment(UUID userId) {
        List<AssessedSubjectItem> assessedSubjects = topicMasteryRepository
                .findDistinctAssessedSubjects(userId)
                .stream()
                .map(subject -> new AssessedSubjectItem(subject.getId(), subject.getName()))
                .toList();
        return new AssessmentView(assessedSubjects);
    }

    /** section 8.10, decision D2 — COMPLETED attempts only, bounded at 5. */
    private RecentActivityView buildRecentActivity(UUID userId) {
        List<RecentQuizItem> quizzes = quizAttemptRepository.findRecentForDashboard(
                        userId, QuizAttemptStatus.COMPLETED, Limit.of(RECENT_QUIZZES_LIMIT))
                .stream()
                .map(this::toRecentQuizItem)
                .toList();
        return new RecentActivityView(quizzes);
    }

    private RecentQuizItem toRecentQuizItem(QuizAttempt attempt) {
        Topic topic = attempt.getQuiz().getTopic();
        return new RecentQuizItem(attempt.getId(), topic.getId(), topic.getName(),
                attempt.getScore(), attempt.getCorrectCount(),
                attempt.getTotalQuestions(), attempt.getSubmittedAt());
    }
}
