package com.gamelearn.service;

import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.dto.ProgressResponse;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.repository.ProgressRepository;

/**
 * Learner progress retrieval (PROG-001/PROG-002). Read-only in Phase 3:
 * progress rows are created by future assessment/quiz phases. Ownership is
 * enforced by resolving everything from the authenticated user id.
 */
@Service
public class ProgressService {

    private final ProgressRepository progressRepository;

    public ProgressService(ProgressRepository progressRepository) {
        this.progressRepository = progressRepository;
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
}
