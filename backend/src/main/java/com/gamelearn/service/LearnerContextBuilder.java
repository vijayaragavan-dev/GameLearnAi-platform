package com.gamelearn.service;

import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.entity.LearningPath;
import com.gamelearn.entity.LearnerProfile;
import com.gamelearn.entity.Recommendation;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.TopicMastery;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.LearningPathStatus;
import com.gamelearn.entity.enums.RecommendationStatus;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.repository.LearnerProfileRepository;
import com.gamelearn.repository.LearningPathRepository;
import com.gamelearn.repository.RecommendationRepository;
import com.gamelearn.repository.TopicMasteryRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.service.context.LearnerPathContext;
import com.gamelearn.service.context.TopicCatalogEntry;

/**
 * Builds the server-side generation context from verified persisted state
 * (Learning Path AI Specification section 6). Reads ONLY; never duplicates
 * Adaptive Engine calculations. The catalog contains the subject's ACTIVE
 * topics only, so Gemini can reference nothing else.
 */
@Service
public class LearnerContextBuilder {

    private final TopicRepository topicRepository;
    private final TopicMasteryRepository topicMasteryRepository;
    private final LearnerProfileRepository learnerProfileRepository;
    private final RecommendationRepository recommendationRepository;
    private final LearningPathRepository learningPathRepository;

    public LearnerContextBuilder(TopicRepository topicRepository,
                                 TopicMasteryRepository topicMasteryRepository,
                                 LearnerProfileRepository learnerProfileRepository,
                                 RecommendationRepository recommendationRepository,
                                 LearningPathRepository learningPathRepository) {
        this.topicRepository = topicRepository;
        this.topicMasteryRepository = topicMasteryRepository;
        this.learnerProfileRepository = learnerProfileRepository;
        this.recommendationRepository = recommendationRepository;
        this.learningPathRepository = learningPathRepository;
    }

    @Transactional(readOnly = true)
    public LearnerPathContext build(User user, Subject subject, String sanitizedGoal) {
        List<TopicCatalogEntry> catalog = topicRepository
                .findBySubjectIdAndActiveTrueOrderByDisplayOrderAscIdAsc(subject.getId())
                .stream()
                .map(topic -> new TopicCatalogEntry(0, topic.getId(), topic.getName(),
                        topic.getDescription(), topic.getDifficulty(), topic.getDisplayOrder()))
                .toList();
        // Refs are assigned AFTER the stable ordering inside the context record.
        List<TopicCatalogEntry> refCatalog = new java.util.ArrayList<>();
        for (int index = 0; index < catalog.size(); index++) {
            var entry = catalog.get(index);
            refCatalog.add(new TopicCatalogEntry(index + 1, entry.topicId(), entry.name(),
                    entry.description(), entry.difficulty(), entry.displayOrder()));
        }
        if (refCatalog.isEmpty()) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                    ErrorCode.RESOURCE_NOT_FOUND.name(), "Subject not found");
        }

        List<TopicMastery> masteries = topicMasteryRepository.findByUserId(user.getId()).stream()
                .filter(m -> m.getTopic().getSubject().getId().equals(subject.getId()))
                .toList();

        List<Recommendation> recommendations =
                recommendationRepository
                        .findByUserIdAndStatusOrderByPriorityAscGeneratedAtDesc(
                                user.getId(), RecommendationStatus.ACTIVE).stream()
                        .filter(r -> refCatalog.stream()
                                .anyMatch(entry -> entry.topicId().equals(r.getTopic().getId())))
                        .toList();

        LearnerProfile profile = learnerProfileRepository.findByUserId(user.getId())
                .orElseThrow(() -> new ApiException(ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                        ErrorCode.INTERNAL_ERROR.name(), "Learner profile missing"));

        LearningPath previousActive = findActivePath(user.getId(), subject.getId());

        return new LearnerPathContext(subject, List.copyOf(refCatalog),
                profile.getOverallMastery(), profile.getCurrentLevel(), masteries,
                recommendations, previousActive, sanitizedGoal);
    }

    /** Finds the caller's ACTIVE path for the subject, if any (idempotency + regeneration). */
    @Transactional(readOnly = true)
    public LearningPath findActivePath(UUID userId, UUID subjectId) {
        return learningPathRepository
                .findByUserIdAndSubjectIdOrderByCreatedAtAsc(userId, subjectId).stream()
                .filter(path -> path.getStatus() == LearningPathStatus.ACTIVE)
                .findFirst()
                .orElse(null);
    }
}
