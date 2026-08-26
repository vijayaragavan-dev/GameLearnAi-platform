package com.gamelearn.service;

import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.dto.LearningNodeResponse;
import com.gamelearn.dto.LearningPathResponse;
import com.gamelearn.entity.LearningPath;
import com.gamelearn.repository.LearningPathNodeRepository;
import com.gamelearn.repository.LearningPathRepository;

/**
 * Learning path retrieval (PATH-001). Returns ONLY the authenticated
 * learner's own paths for a subject; the caller identity always comes from
 * the security context. Path generation itself belongs to the later
 * Adaptive/AI phases.
 */
@Service
public class LearningPathService {

    private final LearningPathRepository learningPathRepository;
    private final LearningPathNodeRepository learningPathNodeRepository;
    private final SubjectService subjectService;

    public LearningPathService(LearningPathRepository learningPathRepository,
                               LearningPathNodeRepository learningPathNodeRepository,
                               SubjectService subjectService) {
        this.learningPathRepository = learningPathRepository;
        this.learningPathNodeRepository = learningPathNodeRepository;
        this.subjectService = subjectService;
    }

    @Transactional(readOnly = true)
    public List<LearningPathResponse> getOwnPathsForSubject(UUID authenticatedUserId, UUID subjectId) {
        subjectService.requireActiveSubject(subjectId);
        List<LearningPath> paths = learningPathRepository
                .findByUserIdAndSubjectIdOrderByCreatedAtAsc(authenticatedUserId, subjectId);
        return paths.stream()
                .map(this::toResponse)
                .toList();
    }

    private LearningPathResponse toResponse(LearningPath path) {
        List<LearningNodeResponse> nodes = learningPathNodeRepository
                .findByLearningPathIdOrderBySequenceNumberAsc(path.getId()).stream()
                .map(node -> new LearningNodeResponse(
                        node.getId(),
                        node.getTopic().getId(),
                        node.getTopic().getName(),
                        node.getSequenceNumber(),
                        node.getRequiredMastery(),
                        node.getStatus().name()))
                .toList();
        return new LearningPathResponse(
                path.getId(),
                path.getSubject().getId(),
                path.getTitle(),
                path.getDescription(),
                path.getStatus().name(),
                path.getGeneratedBy().name(),
                nodes);
    }
}
