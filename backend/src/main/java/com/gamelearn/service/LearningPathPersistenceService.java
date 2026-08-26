package com.gamelearn.service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.entity.LearningPath;
import com.gamelearn.entity.LearningPathNode;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.GeneratedBy;
import com.gamelearn.entity.enums.LearningPathStatus;
import com.gamelearn.entity.enums.PathNodeStatus;
import com.gamelearn.ai.validation.ValidatedPathPlan;
import com.gamelearn.entity.AiInteraction;
import com.gamelearn.repository.LearningPathNodeRepository;
import com.gamelearn.repository.LearningPathRepository;
import com.gamelearn.repository.TopicRepository;

/**
 * Atomic persistence of generated paths (Learning Path AI Specification
 * section 30). Path + nodes + audit commit together or not at all; the
 * regeneration swap archives the old path and inserts the new one in ONE
 * transaction so a crash can never leave the learner without their usable
 * path.
 */
@Service
public class LearningPathPersistenceService {

    private final LearningPathRepository learningPathRepository;
    private final LearningPathNodeRepository learningPathNodeRepository;
    private final TopicRepository topicRepository;

    public LearningPathPersistenceService(LearningPathRepository learningPathRepository,
                                          LearningPathNodeRepository learningPathNodeRepository,
                                          TopicRepository topicRepository) {
        this.learningPathRepository = learningPathRepository;
        this.learningPathNodeRepository = learningPathNodeRepository;
        this.topicRepository = topicRepository;
    }

    /** First-generation insert: new ACTIVE path + nodes + SUCCESS/FALLBACK audit row. */
    @Transactional
    public Delivery insertPath(User user, Subject subject, ValidatedPathPlan plan,
                               GeneratedBy generatedBy, AiInteractionAuditService auditService,
                               String modelName, String promptVersion,
                               String sanitizedContext, String sanitizedResponse,
                               Integer latencyMs, String errorCode) {
        LearningPath path = newPath(user, subject, plan, generatedBy);
        List<LearningPathNode> nodes = persistNodes(path, plan);
        AiInteraction auditRow = auditService.record(user, modelName, promptVersion,
                sanitizedContext, sanitizedResponse, statusFor(generatedBy), latencyMs, errorCode);
        return new Delivery(path.getId(), path.getTitle(), nodes.size(), auditRow.getStatus());
    }

    /**
     * Regeneration swap in ONE transaction: archive old ACTIVE path, insert
     * the new ACTIVE path, write the audit row. Any failure rolls everything
     * back - the old path stays ACTIVE and serving.
     */
    @Transactional
    public Delivery archiveAndInsert(UUID oldPathId, User user, Subject subject,
                                     ValidatedPathPlan plan, GeneratedBy generatedBy,
                                     AiInteractionAuditService auditService,
                                     String modelName, String promptVersion,
                                     String sanitizedContext, String sanitizedResponse,
                                     Integer latencyMs, String errorCode) {
        LearningPath oldPath = learningPathRepository.findById(oldPathId)
                .orElseThrow(() -> new IllegalStateException("Regeneration target vanished"));
        if (!oldPath.getUser().getId().equals(user.getId())) {
            throw new IllegalStateException("Regeneration target belongs to another user");
        }
        oldPath.setStatus(LearningPathStatus.ARCHIVED);

        LearningPath newPath = newPath(user, subject, plan, generatedBy);
        List<LearningPathNode> nodes = persistNodes(newPath, plan);
        AiInteraction auditRow = auditService.record(user, modelName, promptVersion,
                sanitizedContext, sanitizedResponse, statusFor(generatedBy), latencyMs, errorCode);
        return new Delivery(newPath.getId(), newPath.getTitle(), nodes.size(), auditRow.getStatus());
    }

    private LearningPath newPath(User user, Subject subject, ValidatedPathPlan plan,
                                 GeneratedBy generatedBy) {
        LearningPath path = new LearningPath();
        path.setUser(user);
        path.setSubject(subject);
        path.setTitle(plan.title());
        path.setDescription(plan.description());
        path.setStatus(LearningPathStatus.ACTIVE);
        path.setGeneratedBy(generatedBy);
        return learningPathRepository.save(path);
    }

    private List<LearningPathNode> persistNodes(LearningPath path, ValidatedPathPlan plan) {
        List<LearningPathNode> nodes = new ArrayList<>();
        for (int index = 0; index < plan.nodes().size(); index++) {
            ValidatedPathPlan.PlannedNode planned = plan.nodes().get(index);
            Topic topic = topicRepository.getReferenceById(planned.topicId());
            LearningPathNode node = new LearningPathNode();
            node.setLearningPath(path);
            node.setTopic(topic);
            node.setSequenceNumber(planned.sequenceNumber());
            node.setRequiredMastery(planned.requiredMastery());
            node.setStatus(index == 0 ? PathNodeStatus.AVAILABLE : PathNodeStatus.LOCKED);
            nodes.add(node);
        }
        return learningPathNodeRepository.saveAll(nodes);
    }

    private static com.gamelearn.entity.enums.AiInteractionStatus statusFor(GeneratedBy generatedBy) {
        return generatedBy == GeneratedBy.AI
                ? com.gamelearn.entity.enums.AiInteractionStatus.SUCCESS
                : com.gamelearn.entity.enums.AiInteractionStatus.FALLBACK;
    }

    /** What was delivered by a persistence operation. */
    public record Delivery(UUID pathId, String title, int nodeCount,
                           com.gamelearn.entity.enums.AiInteractionStatus auditStatus) {
    }
}
