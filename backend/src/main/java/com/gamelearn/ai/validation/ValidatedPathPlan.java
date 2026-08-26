package com.gamelearn.ai.validation;

import java.math.BigDecimal;
import java.util.Comparator;

import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.service.context.TopicCatalogEntry;

/**
 * A fully validated generation plan ready for persistence. Nodes are ordered
 * by sequence; mastery gates are BACKEND-DERIVED from the approved mapping -
 * never taken from Gemini (Learning Path AI Specification sections 10.1 and
 * 24.3). objective/rationale stay non-persisted display metadata.
 */
public record ValidatedPathPlan(
        String title,
        String description,
        java.util.List<PlannedNode> nodes) {

    public record PlannedNode(
            TopicCatalogEntry entry,
            int sequenceNumber,
            BigDecimal requiredMastery,
            String objective,
            String rationale) {

        public java.util.UUID topicId() {
            return entry.topicId();
        }
    }

    public ValidatedPathPlan {
        nodes = nodes.stream()
                .sorted(Comparator.comparingInt(PlannedNode::sequenceNumber))
                .toList();
    }

    /** Approved derivation map (spec section 24.3): EASY 0 / MEDIUM 40 / HARD 70. */
    public static BigDecimal requiredMasteryFor(Difficulty difficulty) {
        return switch (difficulty) {
            case EASY -> new BigDecimal("0.00");
            case MEDIUM -> new BigDecimal("40.00");
            case HARD -> new BigDecimal("70.00");
        };
    }
}
