package com.gamelearn.service;

import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.ai.validation.ValidatedPathPlan;
import com.gamelearn.dto.GeneratedLearningPathResponse;
import com.gamelearn.entity.LearningPath;
import com.gamelearn.entity.LearningPathNode;
import com.gamelearn.repository.LearningPathNodeRepository;

/**
 * Maps persisted path state (+ optional in-memory validated plan) into the
 * approved PATH-002 response DTO. aiMetadata appears ONLY when a validated
 * plan exists - never for idempotent returns or fallback paths.
 */
@Component
public class GeneratedPathResponseMapper {

    private final LearningPathNodeRepository learningPathNodeRepository;

    public GeneratedPathResponseMapper(LearningPathNodeRepository learningPathNodeRepository) {
        this.learningPathNodeRepository = learningPathNodeRepository;
    }

    /**
     * Read-only transaction keeps lazy topic proxies loadable
     * (open-in-view is disabled project-wide).
     */
    @Transactional(readOnly = true)
    public GeneratedLearningPathResponse toResponse(LearningPath path,
                                                    ValidatedPathPlan validatedPlan) {
        List<GeneratedLearningPathResponse.Node> nodes = new ArrayList<>();
        for (LearningPathNode node : learningPathNodeRepository
                .findByLearningPathIdOrderBySequenceNumberAsc(path.getId())) {
            nodes.add(new GeneratedLearningPathResponse.Node(
                    node.getId(),
                    node.getTopic().getId(),
                    node.getTopic().getName(),
                    node.getSequenceNumber(),
                    node.getRequiredMastery(),
                    node.getStatus().name()));
        }
        return new GeneratedLearningPathResponse(
                path.getId(),
                path.getSubject().getId(),
                path.getTitle(),
                path.getDescription(),
                path.getStatus().name(),
                path.getGeneratedBy().name(),
                path.getCreatedAt(),
                path.getUpdatedAt(),
                List.copyOf(nodes),
                aiMetadata(validatedPlan));
    }

    private GeneratedLearningPathResponse.AiMetadata aiMetadata(ValidatedPathPlan plan) {
        if (plan == null || plan.nodes().stream().allMatch(node ->
                node.objective() == null && node.rationale() == null)) {
            return null;
        }
        List<GeneratedLearningPathResponse.AiNode> aiNodes = new ArrayList<>();
        for (ValidatedPathPlan.PlannedNode node : plan.nodes()) {
            if (node.objective() != null || node.rationale() != null) {
                aiNodes.add(new GeneratedLearningPathResponse.AiNode(
                        node.sequenceNumber(), node.objective(), node.rationale()));
            }
        }
        return aiNodes.isEmpty() ? null : new GeneratedLearningPathResponse.AiMetadata(aiNodes);
    }
}
