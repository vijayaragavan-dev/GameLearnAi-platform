package com.gamelearn.service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

import org.springframework.stereotype.Component;

import com.gamelearn.ai.validation.ValidatedPathPlan;
import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.service.context.LearnerPathContext;

/**
 * Deterministic SYSTEM fallback (Learning Path AI Specification section 28).
 * Total order with no randomness: difficulty ladder EASY &lt; MEDIUM &lt; HARD,
 * then display_order ASC, then name ASC. Caps at the approved maximum node
 * count (10) with a foundations-first bias; never pads or invents topics.
 */
@Component
public class FallbackPathPlanner {

    private static final int MAX_NODES = 10;

    public ValidatedPathPlan plan(LearnerPathContext context) {
        List<ValidatedPathPlan.PlannedNode> nodes = new ArrayList<>();
        Comparator<com.gamelearn.service.context.TopicCatalogEntry> order = Comparator
                .comparingInt((com.gamelearn.service.context.TopicCatalogEntry entry) -> ladder(entry.difficulty()))
                .thenComparingInt(com.gamelearn.service.context.TopicCatalogEntry::displayOrder)
                .thenComparing(com.gamelearn.service.context.TopicCatalogEntry::name,
                        String.CASE_INSENSITIVE_ORDER);
        context.catalog().stream()
                .sorted(order)
                .limit(MAX_NODES)
                .forEach(entry -> nodes.add(new ValidatedPathPlan.PlannedNode(
                        entry,
                        nodes.size() + 1,
                        ValidatedPathPlan.requiredMasteryFor(entry.difficulty()),
                        null,
                        null)));

        return new ValidatedPathPlan(
                "Your " + context.subject().getName() + " Learning Path",
                "A structured foundation through " + context.subject().getName()
                        + ", ordered from foundational to advanced topics.",
                List.copyOf(nodes));
    }

    /** Fallback failure is impossible while any catalog topic exists (spec section 28). */
    public boolean canPlan(LearnerPathContext context) {
        return !context.catalog().isEmpty();
    }

    private static int ladder(Difficulty difficulty) {
        return switch (difficulty) {
            case EASY -> 0;
            case MEDIUM -> 1;
            case HARD -> 2;
        };
    }
}
