package com.gamelearn.service;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.dto.ProgressResponse;
import com.gamelearn.dto.ProgressUpsertRequest;
import com.gamelearn.entity.Progress;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.ProgressStatus;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.repository.ProgressRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.UserRepository;

/**
 * Learner progress retrieval (PROG-001/PROG-002) plus the generic explicit
 * topic-completion upsert (Phase QA-6B). Ownership is enforced by resolving
 * everything from the authenticated user id; the client never supplies a
 * user identity. Learning state only: this service never touches XP,
 * mastery, streaks, achievements, quizzes, or game results.
 */
@Service
public class ProgressService {

    private static final BigDecimal COMPLETE_PERCENTAGE = new BigDecimal("100");

    private final ProgressRepository progressRepository;
    private final TopicRepository topicRepository;
    private final UserRepository userRepository;

    public ProgressService(ProgressRepository progressRepository,
                           TopicRepository topicRepository,
                           UserRepository userRepository) {
        this.progressRepository = progressRepository;
        this.topicRepository = topicRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<ProgressResponse> getOwnProgress(UUID authenticatedUserId) {
        return progressRepository.findByUserIdOrderByLastActivityAtDescIdAsc(authenticatedUserId).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public ProgressResponse getOwnProgressForTopic(UUID authenticatedUserId, UUID topicId) {
        return progressRepository.findByUserIdAndTopicId(authenticatedUserId, topicId)
                .map(this::toResponse)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                        ErrorCode.RESOURCE_NOT_FOUND.name(),
                        "Progress not found"));
    }

    private ProgressResponse toResponse(com.gamelearn.entity.Progress progress) {
        return new ProgressResponse(
                progress.getId(),
                progress.getTopic().getId(),
                progress.getLearningPathNode() != null ? progress.getLearningPathNode().getId() : null,
                progress.getCompletionPercentage(),
                progress.getStatus().name(),
                progress.getLastActivityAt(),
                progress.getCompletedAt());
    }

    /**
     * Generic explicit topic-completion upsert (Phase QA-6B). Idempotent: the
     * first completion creates exactly one row per learner + topic; repeated
     * completions update that row. The uq_progress_user_topic constraint is
     * the final guard; a concurrent double-insert is recovered by re-reading
     * the winning row. completed_at is set on first completion and kept
     * stable afterwards; last_activity_at refreshes on every completion.
     * Topic-only progress: learning_path_node_id stays null on create and is
     * preserved untouched on update. No XP, mastery, streak, achievement,
     * quiz, or game side effects occur here.
     */
    @Transactional
    public ProgressResponse markTopicComplete(UUID authenticatedUserId, UUID topicId,
                                              ProgressUpsertRequest request) {
        if (request == null || request.status() != ProgressStatus.COMPLETED
                || request.completionPercentage() == null
                || request.completionPercentage().compareTo(COMPLETE_PERCENTAGE) != 0) {
            throw new ApiException(
                    ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                    ErrorCode.VALIDATION_FAILED.name(),
                    "Request validation failed",
                    java.util.Map.of("progress", "only COMPLETED with completionPercentage 100 is supported"));
        }
        Topic topic = topicRepository.findById(topicId)
                .filter(Topic::isActive)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                        ErrorCode.RESOURCE_NOT_FOUND.name(),
                        "Topic not found"));
        User learner = userRepository.findById(authenticatedUserId)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.UNAUTHORIZED.getHttpStatus(),
                        ErrorCode.UNAUTHORIZED.name(),
                        "Invalid email or password"));
        Instant now = Instant.now();
        try {
            Progress progress = progressRepository
                    .findByUserIdAndTopicId(learner.getId(), topic.getId())
                    .orElseGet(() -> {
                        Progress created = new Progress();
                        created.setUser(learner);
                        created.setTopic(topic);
                        created.setCompletedAt(now);
                        return created;
                    });
            progress.setStatus(ProgressStatus.COMPLETED);
            progress.setCompletionPercentage(COMPLETE_PERCENTAGE);
            progress.setLastActivityAt(now);
            return toResponse(progressRepository.save(progress));
        } catch (DataIntegrityViolationException concurrentInsert) {
            return toResponse(progressRepository
                    .findByUserIdAndTopicId(learner.getId(), topic.getId())
                    .orElseThrow(() -> new ApiException(
                            ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                            ErrorCode.INTERNAL_ERROR.name(),
                            "An unexpected internal error occurred")));
        }
    }
}
