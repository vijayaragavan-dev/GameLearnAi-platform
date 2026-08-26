package com.gamelearn.service;

import java.math.BigDecimal;
import java.util.Map;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.entity.LearnerProfile;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.TopicMastery;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.repository.LearnerProfileRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicMasteryRepository;
import com.gamelearn.repository.TopicRepository;

/**
 * Builds the AI-TUTOR context slice from verified persisted state
 * (AI-TUTOR v1.0.0 section 7): the closed TC1-TC6 allowlist, focus-resolved
 * per section 6.2. READ-ONLY; never duplicates Adaptive Engine math; never
 * touches recommendations, paths, gamification or progress.
 *
 * <p>The result is a flat VALUE object - entities never escape this
 * read-only transaction ({@code open-in-view} is disabled project-wide).
 * The client may NEVER reach another learner's data: every query is
 * principal-scoped and subject/topic rows are global catalog content.</p>
 */
@Service
public class TutorContextBuilder {

    /**
     * Fully materialized allowlist slice for one request. Null members =
     * absent (GENERIC mode / no focused topic / no mastery row yet).
     */
    public record TutorContext(
            UUID subjectId,
            String subjectName,
            UUID topicId,
            String topicName,
            String topicDifficulty,
            BigDecimal overallMastery,
            int currentLevel,
            TopicMasteryView mastery) {

        /** TC4 - absent when the learner has no stored row for the topic. */
        public record TopicMasteryView(
                BigDecimal score,
                String level,
                String trend,
                int attemptCount) {
        }

        public UUID subjectIdOrNull() {
            return subjectId;
        }

        public UUID topicIdOrNull() {
            return topicId;
        }
    }

    private final LearnerProfileRepository learnerProfileRepository;
    private final SubjectRepository subjectRepository;
    private final TopicRepository topicRepository;
    private final TopicMasteryRepository topicMasteryRepository;

    public TutorContextBuilder(LearnerProfileRepository learnerProfileRepository,
                               SubjectRepository subjectRepository,
                               TopicRepository topicRepository,
                               TopicMasteryRepository topicMasteryRepository) {
        this.learnerProfileRepository = learnerProfileRepository;
        this.subjectRepository = subjectRepository;
        this.topicRepository = topicRepository;
        this.topicMasteryRepository = topicMasteryRepository;
    }

    /**
     * Deterministic focus resolution (spec section 6.2): explicit topicId >
     * explicit subjectId > current-topic pointer > current-subject pointer >
     * GENERIC. Unknown/inactive/cross-subject explicit references are
     * rejected with 400 VALIDATION_FAILED + fieldErrors BEFORE any quota or
     * Gemini contact; inactive POINTERS fall through silently instead.
     */
    @Transactional(readOnly = true)
    public TutorContext resolve(UUID userId, UUID subjectId, UUID topicId) {
        LearnerProfile profile = learnerProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                        ErrorCode.INTERNAL_ERROR.name(),
                        "Learner profile missing"));
        BigDecimal overallMastery = profile.getOverallMastery();
        int currentLevel = profile.getCurrentLevel();

        if (topicId != null) {
            Topic topic = topicRepository.findById(topicId)
                    .filter(Topic::isActive)
                    .orElseThrow(() -> referentialError("topicId",
                            "Unknown or inactive topicId"));
            Subject subject = topic.getSubject();
            if (subjectId != null && !subject.getId().equals(subjectId)) {
                throw referentialError("topicId", "topicId does not belong to subjectId");
            }
            return new TutorContext(subject.getId(), subject.getName(),
                    topic.getId(), topic.getName(), topic.getDifficulty().name(),
                    overallMastery, currentLevel, masteryView(userId, topic.getId()));
        }
        if (subjectId != null) {
            Subject subject = subjectRepository.findById(subjectId)
                    .filter(Subject::isActive)
                    .orElseThrow(() -> referentialError("subjectId",
                            "Unknown or inactive subjectId"));
            return new TutorContext(subject.getId(), subject.getName(),
                    null, null, null, overallMastery, currentLevel, null);
        }
        // Pointer fallthrough - deactivated referenced rows are skipped, not errors.
        Topic pointedTopic = activeTopic(profile);
        if (pointedTopic != null) {
            Subject subject = pointedTopic.getSubject();
            return new TutorContext(subject.getId(), subject.getName(),
                    pointedTopic.getId(), pointedTopic.getName(),
                    pointedTopic.getDifficulty().name(), overallMastery, currentLevel,
                    masteryView(userId, pointedTopic.getId()));
        }
        Subject pointedSubject = activeSubject(profile);
        if (pointedSubject != null) {
            return new TutorContext(pointedSubject.getId(), pointedSubject.getName(),
                    null, null, null, overallMastery, currentLevel, null);
        }
        return new TutorContext(null, null, null, null, null, overallMastery, currentLevel, null);
    }

    /** Plain read - NO lock; the tutor never mutates adaptive state. */
    private TutorContext.TopicMasteryView masteryView(UUID userId, UUID topicId) {
        return topicMasteryRepository.findByUserIdAndTopicId(userId, topicId)
                .map(m -> new TutorContext.TopicMasteryView(m.getMasteryScore(),
                        m.getMasteryLevel().name(), m.getTrend().name(),
                        m.getAttemptCount()))
                .orElse(null);
    }

    private Topic activeTopic(LearnerProfile profile) {
        try {
            Topic topic = profile.getCurrentTopic();
            return topic != null && topic.isActive() ? topic : null;
        } catch (RuntimeException danglingReference) {
            return null; // deactivated/deleted pointer target: skip, never fail
        }
    }

    private Subject activeSubject(LearnerProfile profile) {
        try {
            Subject subject = profile.getCurrentSubject();
            return subject != null && subject.isActive() ? subject : null;
        } catch (RuntimeException danglingReference) {
            return null;
        }
    }

    private ApiException referentialError(String field, String message) {
        return new ApiException(
                ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                ErrorCode.VALIDATION_FAILED.name(),
                "Request validation failed",
                Map.of(field, message));
    }
}
