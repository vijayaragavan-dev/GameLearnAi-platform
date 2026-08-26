package com.gamelearn.ai.validation;

import java.math.BigDecimal;
import java.util.HashSet;
import java.util.Set;

import org.springframework.stereotype.Component;

import com.gamelearn.ai.parser.GeneratedPathCandidate;

/**
 * Schema validation S1-S14 (Learning Path AI Specification section 23).
 * Deterministic: violations are never retried against Gemini.
 */
@Component
public class AiSchemaValidator {

    private static final int TITLE_MIN = 3;
    private static final int TITLE_MAX = 200;
    private static final int DESCRIPTION_MAX = 1000;
    private static final int OBJECTIVE_MAX = 300;
    private static final int RATIONALE_MAX = 500;
    private static final int MIN_NODES_WHEN_CATALOG_ALLOWS = 3;
    private static final int MAX_NODES = 10;

    public void validate(GeneratedPathCandidate candidate, int catalogSize) {
        if (candidate == null) {
            throw rejection("No structured output was produced");
        }
        validateTitle(candidate.title());
        validateDescription(candidate.description());
        validateNodes(candidate.nodes(), catalogSize);
    }

    private void validateTitle(String title) {
        if (title == null || title.strip().length() < TITLE_MIN || title.length() > TITLE_MAX) {
            throw rejection("Generated title is missing or out of bounds");
        }
    }

    private void validateDescription(String description) {
        if (description == null || description.isBlank() || description.length() > DESCRIPTION_MAX) {
            throw rejection("Generated description is missing or too long");
        }
    }

    private void validateNodes(java.util.List<GeneratedPathCandidate.CandidateNode> nodes,
                               int catalogSize) {
        if (nodes == null || nodes.isEmpty()) {
            throw rejection("Generated path has no nodes");
        }
        int minCount = catalogSize >= MIN_NODES_WHEN_CATALOG_ALLOWS
                ? MIN_NODES_WHEN_CATALOG_ALLOWS
                : catalogSize;
        int maxCount = Math.min(MAX_NODES, catalogSize);
        if (nodes.size() < minCount || nodes.size() > maxCount) {
            throw rejection("Generated path size is outside approved bounds");
        }
        Set<Integer> sequences = new HashSet<>();
        Set<Integer> refs = new HashSet<>();
        for (GeneratedPathCandidate.CandidateNode node : nodes) {
            if (node == null) {
                throw rejection("Generated node is missing");
            }
            if (node.topicRef() == null || node.topicRef() < 1 || node.topicRef() > catalogSize) {
                throw rejection("Generated node references an unknown topic");
            }
            if (!refs.add(node.topicRef())) {
                throw rejection("Generated path contains a duplicate topic");
            }
            if (node.sequence() == null) {
                throw rejection("Generated node sequence is missing");
            }
            if (!sequences.add(node.sequence())) {
                throw rejection("Generated path has duplicate sequence numbers");
            }
            validateRequiredMastery(node.requiredMastery());
            validateOptionalText(node.objective(), OBJECTIVE_MAX, "objective");
            validateOptionalText(node.rationale(), RATIONALE_MAX, "rationale");
        }
        // Contiguity: exactly 1..N.
        for (int expected = 1; expected <= nodes.size(); expected++) {
            if (!sequences.contains(expected)) {
                throw rejection("Generated sequence is not contiguous from 1");
            }
        }
    }

    private void validateRequiredMastery(BigDecimal requiredMastery) {
        if (requiredMastery == null) {
            return; // proposal field; backend derives authoritative gates
        }
        if (requiredMastery.signum() < 0
                || requiredMastery.compareTo(BigDecimal.valueOf(100)) > 0
                || requiredMastery.scale() > 2) {
            throw rejection("Generated required mastery is invalid");
        }
    }

    private void validateOptionalText(String value, int max, String field) {
        if (value != null && value.length() > max) {
            throw rejection("Generated " + field + " exceeds the allowed length");
        }
    }

    private AiOutputRejectionException rejection(String safeMessage) {
        return new AiOutputRejectionException("LP_SCHEMA_VALIDATION_FAILED", safeMessage);
    }
}
