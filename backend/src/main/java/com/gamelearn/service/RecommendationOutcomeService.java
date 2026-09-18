package com.gamelearn.service;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.adaptive.AdaptiveConstants;
import com.gamelearn.adaptive.AdaptiveEngine;
import com.gamelearn.dto.RecommendationOutcome;
import com.gamelearn.entity.QuizAttempt;
import com.gamelearn.entity.Recommendation;
import com.gamelearn.entity.enums.QuizAttemptStatus;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.repository.QuizAttemptRepository;
import com.gamelearn.repository.RecommendationRepository;

/**
 * Post-recommendation outcome derivation (Gate 14.2, observational only).
 *
 * <p>Answers "did measurable learner improvement follow this
 * recommendation?" using authoritative attempts strictly ordered around
 * the recommendation instant — never "the recommendation caused
 * improvement". Pure derivation: no writes, no mastery/rec/XP changes,
 * no AdaptiveEngine involvement, no API surface.</p>
 *
 * <p>Semantics preserved from existing code (not reinterpreted):
 * CONSUMED means superseded by a newer recommendation
 * ({@code AdaptiveLearningService}, the sole write site) — never
 * learner action, never success. EXPIRED has no write site and is
 * treated like any other non-ACTIVE status: derivable, never
 * meaningful. Topic NULL means unattributable. Post window
 * {@code (generatedAt, nextGeneratedAt]} bounds attribution so one
 * mastery change is never double-counted; same-instant duplicates are
 * AMBIGUOUS, never split.</p>
 *
 * <p>Category bands reuse the engine's own meaningful-change delta
 * ({@code TREND_DELTA}, 5 percentage points) — borrowed semantics,
 * not invented thresholds.</p>
 */
@Service
public class RecommendationOutcomeService {

    private final RecommendationRepository recommendationRepository;
    private final QuizAttemptRepository quizAttemptRepository;

    public RecommendationOutcomeService(RecommendationRepository recommendationRepository,
            QuizAttemptRepository quizAttemptRepository) {
        this.recommendationRepository = recommendationRepository;
        this.quizAttemptRepository = quizAttemptRepository;
    }

    /**
     * Derives the v1 outcome for one recommendation owned by the given
     * learner. Read-only transaction; throws FORBIDDEN on ownership
     * mismatch, RESOURCE_NOT_FOUND on unknown id.
     */
    @Transactional(readOnly = true)
    public RecommendationOutcome deriveOutcome(UUID userId, UUID recommendationId) {
        Recommendation recommendation = recommendationRepository.findById(recommendationId)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                        ErrorCode.RESOURCE_NOT_FOUND.name(),
                        "Recommendation not found"));
        if (!recommendation.getUser().getId().equals(userId)) {
            throw new ApiException(
                    ErrorCode.FORBIDDEN.getHttpStatus(),
                    ErrorCode.FORBIDDEN.name(),
                    "Recommendation does not belong to the learner");
        }
        Instant evaluatedAt = Instant.now();
        if (recommendation.getTopic() == null) {
            return unavailable(recommendation, userId,
                    RecommendationOutcome.Category.INSUFFICIENT_DATA,
                    "TOPIC_NULL", evaluatedAt);
        }
        UUID topicId = recommendation.getTopic().getId();
        Instant generatedAt = recommendation.getGeneratedAt();

        List<Recommendation> siblings = recommendationRepository
                .findByUserIdAndTopicIdOrderByGeneratedAtAscIdAsc(userId, topicId);
        long sameInstant = siblings.stream()
                .filter(sibling -> sibling.getGeneratedAt().equals(generatedAt))
                .count();
        if (sameInstant > 1) {
            return unavailable(recommendation, userId,
                    RecommendationOutcome.Category.AMBIGUOUS,
                    "SAME_INSTANT_DUPLICATES", evaluatedAt);
        }
        Instant nextBoundary = siblings.stream()
                .map(Recommendation::getGeneratedAt)
                .filter(candidate -> candidate.isAfter(generatedAt))
                .min(Instant::compareTo)
                .orElse(null);

        List<QuizAttempt> attempts = quizAttemptRepository.findCompletedForOutcome(
                userId, topicId, QuizAttemptStatus.COMPLETED);
        List<QuizAttempt> pre = new ArrayList<>();
        List<QuizAttempt> post = new ArrayList<>();
        for (QuizAttempt attempt : attempts) {
            // Timestamps are the only nullable aggregate input; counts are
            // primitives and always present on persisted rows.
            if (attempt.getSubmittedAt() == null
                    || attempt.getTotalQuestions() == 0) {
                continue;
            }
            if (attempt.getSubmittedAt().isBefore(generatedAt)) {
                pre.add(attempt);
            } else if (attempt.getSubmittedAt().isAfter(generatedAt)
                    && (nextBoundary == null || !attempt.getSubmittedAt().isAfter(nextBoundary))) {
                post.add(attempt);
            }
        }
        if (pre.isEmpty() || post.isEmpty()) {
            return unavailable(recommendation, userId,
                    RecommendationOutcome.Category.INSUFFICIENT_DATA,
                    pre.isEmpty() ? "NO_PRE_BASELINE" : "NO_POST_OBSERVATION", evaluatedAt);
        }
        BigDecimal preAccuracy = accuracyOf(pre);
        BigDecimal postAccuracy = accuracyOf(post);
        BigDecimal delta = postAccuracy.subtract(preAccuracy);
        RecommendationOutcome.Category category;
        if (delta.compareTo(AdaptiveConstants.TREND_DELTA) >= 0) {
            category = RecommendationOutcome.Category.IMPROVED;
        } else if (delta.compareTo(AdaptiveConstants.TREND_DELTA.negate()) <= 0) {
            category = RecommendationOutcome.Category.DECLINED;
        } else {
            category = RecommendationOutcome.Category.NO_MEASURABLE_IMPROVEMENT;
        }
        return new RecommendationOutcome(
                recommendation.getId(), userId, topicId,
                recommendation.getStatus().name(), generatedAt,
                preAccuracy, postAccuracy, delta, category,
                pre.size(), post.size(), "OBSERVED_ASSOCIATION", evaluatedAt);
    }

    private BigDecimal accuracyOf(List<QuizAttempt> attempts) {
        int correct = 0;
        int total = 0;
        for (QuizAttempt attempt : attempts) {
            correct += attempt.getCorrectCount();
            total += attempt.getTotalQuestions();
        }
        return AdaptiveEngine.accuracy(correct, total);
    }

    private RecommendationOutcome unavailable(Recommendation recommendation, UUID userId,
            RecommendationOutcome.Category category, String detail, Instant evaluatedAt) {
        return new RecommendationOutcome(
                recommendation.getId(), userId,
                recommendation.getTopic() == null ? null : recommendation.getTopic().getId(),
                recommendation.getStatus().name(), recommendation.getGeneratedAt(),
                null, null, null, category, 0, 0, detail, evaluatedAt);
    }
}
