package com.gamelearn.ai.validation;

import java.util.HashSet;
import java.util.Set;

import org.springframework.stereotype.Component;

import com.gamelearn.ai.parser.GeneratedPathCandidate;
import com.gamelearn.service.context.LearnerPathContext;

/**
 * Post-schema business validation against live backend state (Learning Path
 * AI Specification section 24): topic identity, subject membership,
 * duplicates, sequence, size, and gate derivation. The catalog is built from
 * the requested subject's ACTIVE topics only, so resolving a ref guarantees
 * validity; checks below are defense-in-depth. Gemini output can never
 * bypass this layer.
 */
@Component
public class AiBusinessValidator {

    public ValidatedPathPlan validate(GeneratedPathCandidate candidate, LearnerPathContext context) {
        var entriesByRef = context.entriesByRef();
        Set<java.util.UUID> seenTopics = new HashSet<>();
        Set<Integer> sequences = new HashSet<>();
        var planned = new java.util.ArrayList<ValidatedPathPlan.PlannedNode>();

        for (GeneratedPathCandidate.CandidateNode node : candidate.nodes()) {
            var entry = entriesByRef.get(node.topicRef());
            if (entry == null) {
                throw rejection("Generated node references an unknown topic");
            }
            if (!seenTopics.add(entry.topicId())) {
                throw rejection("Generated path contains a duplicate topic");
            }
            if (!sequences.add(node.sequence())) {
                throw rejection("Generated path has duplicate sequence numbers");
            }
            planned.add(new ValidatedPathPlan.PlannedNode(
                    entry,
                    node.sequence(),
                    ValidatedPathPlan.requiredMasteryFor(entry.difficulty()),
                    node.objective(),
                    node.rationale()));
        }

        // Contiguity re-check on the resolved plan.
        for (int expected = 1; expected <= planned.size(); expected++) {
            if (!sequences.contains(expected)) {
                throw rejection("Generated sequence is not contiguous from 1");
            }
        }

        return new ValidatedPathPlan(candidate.title().strip(), candidate.description(),
                java.util.List.copyOf(planned));
    }

    private AiOutputRejectionException rejection(String safeMessage) {
        return new AiOutputRejectionException("LP_BUSINESS_VALIDATION_FAILED", safeMessage);
    }
}
