package com.gamelearn.ai.parser;

import org.springframework.stereotype.Component;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamelearn.ai.validation.AiOutputRejectionException;

/**
 * Converts the raw model text into {@link GeneratedPathCandidate}.
 * Malformed JSON is a deterministic failure (never retried) - LP_MALFORMED_RESPONSE.
 */
@Component
public class LearningPathOutputParser {

    private final ObjectMapper objectMapper;

    public LearningPathOutputParser() {
        this.objectMapper = new ObjectMapper()
                .enable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES);
    }

    public GeneratedPathCandidate parse(String rawModelText) {
        try {
            return objectMapper.readValue(rawModelText, GeneratedPathCandidate.class);
        } catch (Exception ex) {
            throw new AiOutputRejectionException("LP_MALFORMED_RESPONSE",
                    "The AI response could not be processed");
        }
    }
}
