package com.gamelearn.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.adaptive.AdaptiveConstants;
import com.gamelearn.adaptive.AdaptiveEngine;
import com.gamelearn.dto.AdaptiveInsight;
import com.gamelearn.entity.LearnerProfile;
import com.gamelearn.entity.Quiz;
import com.gamelearn.entity.Recommendation;
import com.gamelearn.entity.TopicMastery;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.entity.enums.RecommendationStatus;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.repository.LearnerProfileRepository;
import com.gamelearn.repository.RecommendationRepository;
import com.gamelearn.repository.TopicMasteryRepository;
import com.gamelearn.repository.UserRepository;

/**
 * Adaptive Engine orchestration (Adaptive Engine Specification v1.0.0,
 * sections 15 and 19). Runs INSIDE the quiz-submission transaction —
 * an attempt exists only if its adaptive processing committed
 * (structural exactly-once processing, spec section 18).
 *
 * <p>Lock ordering is fixed to prevent deadlocks: the user row (creation
 * anchor only, outermost) first, topic_mastery row second,
 * learner_profiles row third.</p>
 */
@Service
public class AdaptiveLearningService {

    private final TopicMasteryRepository topicMasteryRepository;
    private final LearnerProfileRepository learnerProfileRepository;
    private final RecommendationRepository recommendationRepository;
    private final UserRepository userRepository;

    public AdaptiveLearningService(TopicMasteryRepository topicMasteryRepository,
                                   LearnerProfileRepository learnerProfileRepository,
                                   RecommendationRepository recommendationRepository,
                                   UserRepository userRepository) {
        this.topicMasteryRepository = topicMasteryRepository;
        this.learnerProfileRepository = learnerProfileRepository;
        this.recommendationRepository = recommendationRepository;
        this.userRepository = userRepository;
    }

    /**
     * Processes one verified quiz attempt adaptively. Must be called within
     * the submission transaction (Propagation.REQUIRED joins it).
     */
    @Transactional(propagation = Propagation.REQUIRED)
    public AdaptiveInsight processSubmission(User learner, Quiz quiz, Instant submittedAt,
                                             int correctCount, int totalQuestions) {
        BigDecimal accuracy = AdaptiveEngine.accuracy(correctCount, totalQuestions);

        // Fixed lock ordering (spec section 19): mastery row FIRST.
        TopicMastery mastery = topicMasteryRepository
                .findWithLock(learner.getId(), quiz.getTopic().getId())
                .orElseGet(() -> createSerialized(learner, quiz));

        int attemptCountNew = mastery.getAttemptCount() + 1;
        AdaptiveEngine.PreviousState previousState = new AdaptiveEngine.PreviousState(
                mastery.getMasteryScore(), mastery.getRecentAccuracy(),
                mastery.getCurrentDifficulty());

        AdaptiveEngine.Decision decision = AdaptiveEngine.decide(
                previousState, accuracy, attemptCountNew, quiz.getDifficulty());

        persistMastery(mastery, decision, accuracy, attemptCountNew, submittedAt);
        supersedeAndInsertRecommendation(learner, quiz, decision, submittedAt);
        refreshProfile(learner, quiz);

        return new AdaptiveInsight(
                quiz.getTopic().getId(),
                decision.masteryScore(),
                decision.previousMasteryScore(),
                decision.masteryLevel().name(),
                decision.trend().name(),
                decision.nextDifficulty().name(),
                decision.activityType().name(),
                decision.reasonCode());
    }

    /**
     * First submission for (user, topic): the mastery row does not exist yet,
     * so findWithLock had nothing to lock. Two simultaneous creators would
     * otherwise both pass the empty read and race to INSERT, violating
     * uq_topic_mastery_user_topic. Serialize them on the always-existing user
     * row instead; after acquiring that anchor lock, re-check — the first
     * creator has committed by then, so its row becomes visible here.
     */
    private TopicMastery createSerialized(User learner, Quiz quiz) {
        userRepository.findWithLock(learner.getId());
        return topicMasteryRepository
                .findWithLock(learner.getId(), quiz.getTopic().getId())
                .orElseGet(() -> initialize(learner, quiz));
    }

    /** Spec section 7.2 defaults; fields overwritten by persistMastery below. */
    private TopicMastery initialize(User learner, Quiz quiz) {
        TopicMastery mastery = new TopicMastery();
        mastery.setUser(learner);
        mastery.setTopic(quiz.getTopic());
        mastery.setAttemptCount(0);
        mastery.setCurrentDifficulty(quiz.getDifficulty());
        mastery.setTrend(com.gamelearn.entity.enums.MasteryTrend.INSUFFICIENT_DATA);
        return mastery;
    }

    private void persistMastery(TopicMastery mastery, AdaptiveEngine.Decision decision,
                                BigDecimal accuracy, int attemptCountNew, Instant submittedAt) {
        mastery.setMasteryScore(decision.masteryScore());
        mastery.setMasteryLevel(decision.masteryLevel());
        mastery.setCurrentDifficulty(decision.nextDifficulty());
        mastery.setRecentAccuracy(accuracy);
        mastery.setTrend(decision.trend());
        mastery.setAttemptCount(attemptCountNew);
        mastery.setLastAssessedAt(submittedAt);
        topicMasteryRepository.save(mastery);
    }

    private void supersedeAndInsertRecommendation(User learner, Quiz quiz,
                                                  AdaptiveEngine.Decision decision,
                                                  Instant generatedAt) {
        List<Recommendation> active = recommendationRepository
                .findByUserIdAndTopicIdAndStatus(learner.getId(), quiz.getTopic().getId(),
                        RecommendationStatus.ACTIVE);
        for (Recommendation stale : active) {
            stale.setStatus(RecommendationStatus.CONSUMED);
            stale.setConsumedAt(generatedAt);
        }
        recommendationRepository.saveAll(active);

        Recommendation recommendation = new Recommendation();
        recommendation.setUser(learner);
        recommendation.setTopic(quiz.getTopic());
        recommendation.setActivityType(decision.activityType());
        recommendation.setRecommendedDifficulty(decision.nextDifficulty());
        recommendation.setPriority(decision.priority());
        recommendation.setStatus(RecommendationStatus.ACTIVE);
        recommendation.setGeneratedAt(generatedAt);
        recommendation.setReason(reasonText(decision.reasonCode(), decision.nextDifficulty(),
                quiz.getTopic().getName()));
        recommendationRepository.save(recommendation);
    }

    /** Deterministic templates from specification section 21. */
    private String reasonText(String code, Difficulty difficulty, String topicName) {
        return switch (code) {
            case AdaptiveEngine.FIRST_ATTEMPT_BASELINE_SET ->
                    code + ": Baseline set from your first quiz — keep practicing.";
            case AdaptiveEngine.BEGINNER_NEEDS_FOUNDATIONS ->
                    code + ": Let's revisit the fundamentals of " + topicName + ".";
            case AdaptiveEngine.RECENT_DECLINE_REMEDIATION ->
                    code + ": Recent results dropped — targeted remediation for " + topicName + ".";
            case AdaptiveEngine.STRONG_PERFORMANCE_INCREASES_DIFFICULTY ->
                    code + ": Strong result — difficulty increased to " + difficulty.name() + ".";
            case AdaptiveEngine.DEVELOPING_KEEP_PRACTICING ->
                    code + ": Keep practicing " + topicName + " to build consistency.";
            case AdaptiveEngine.PROFICIENT_CONFIRM_WITH_QUIZ ->
                    code + ": Solid grasp — confirm it with the next quiz.";
            case AdaptiveEngine.MASTERED_ADVANCE_CHALLENGE ->
                    code + ": Topic mastered — ready for a bigger challenge.";
            default -> code;
        };
    }

    private void refreshProfile(User learner, Quiz quiz) {
        // Lock ordering (spec section 19): profile row AFTER the mastery row.
        LearnerProfile profile = learnerProfileRepository.findWithLock(learner.getId())
                .orElseThrow(() -> new ApiException(
                        ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                        ErrorCode.INTERNAL_ERROR.name(),
                        "An unexpected internal error occurred"));

        List<TopicMastery> allMasteries = topicMasteryRepository.findByUserId(learner.getId());
        BigDecimal sum = allMasteries.stream()
                .map(TopicMastery::getMasteryScore)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal overall = allMasteries.isEmpty()
                ? BigDecimal.ZERO
                : sum.divide(BigDecimal.valueOf(allMasteries.size()), AdaptiveConstants.SCALE,
                        RoundingMode.HALF_UP);

        profile.setOverallMastery(overall);
        profile.setCurrentTopic(quiz.getTopic());
        profile.setCurrentSubject(quiz.getTopic().getSubject());
        learnerProfileRepository.save(profile);
    }
}
