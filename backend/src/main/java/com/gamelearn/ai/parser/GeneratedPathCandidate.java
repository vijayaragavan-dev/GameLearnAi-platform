package com.gamelearn.ai.parser;

import java.math.BigDecimal;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

/**
 * Strict typed view of Gemini's structured output (Learning Path AI
 * Specification section 10). Parsing is strict: unknown fields fail via the
 * parser configuration; nulls and type mismatches are caught by the schema
 * validator.
 */
@JsonIgnoreProperties(ignoreUnknown = false)
public record GeneratedPathCandidate(
        String title,
        String description,
        List<CandidateNode> nodes) {

    @JsonIgnoreProperties(ignoreUnknown = false)
    public record CandidateNode(
            Integer topicRef,
            Integer sequence,
            BigDecimal requiredMastery,
            String objective,
            String rationale) {
    }
}
