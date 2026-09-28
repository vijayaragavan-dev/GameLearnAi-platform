package com.gamelearn.ai.validation;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

import org.springframework.stereotype.Component;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamelearn.ai.validation.TutorOutputValidator.TutorOutputRejection;

/**
 * USER-DOC RAG Phase I: strict validation for structured document answers.
 *
 * <p>Schema: exactly {@code {"answer": text, "citations": [text...]}} —
 * no unexpected fields (mirrors the tutor's strict-shape policy).
 * Safety reuses {@link TutorOutputValidator#scanSafety} (S-1..S-4,
 * deterministic, fail-closed). Citation SHAPE is checked here
 * (document-citation form); citation MEMBERSHIP against the Phase H
 * allowlist happens in the orchestrating service, never here.</p>
 *
 * <p>Rejections reuse {@link TutorOutputRejection} categories so audit
 * semantics stay uniform across AI surfaces.</p>
 */
@Component
public class DocAnswerValidator {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    /** Document-citation shape: doc:{uuid}:v{version}#p{page}c{chunk}. */
    private static final Pattern CITATION_SHAPE = Pattern.compile(
            "^doc:[^#\\s]+:v\\d+#p\\d+c\\d+$");

    /** Validated model answer with structurally valid citations. */
    public record DocAnswer(String answer, List<String> citations) {
    }

    /**
     * Validates one raw Gemini response.
     *
     * @throws TutorOutputRejection on any validation failure (category set)
     */
    public DocAnswer validate(String rawResponse) {
        JsonNode root = parseStrict(rawResponse);
        String answer = extractAnswer(root);
        List<String> citations = extractCitations(root);
        TutorOutputValidator.scanSafety(answer);
        for (String citation : citations) {
            if (!CITATION_SHAPE.matcher(citation).matches()) {
                throw new TutorOutputRejection(TutorOutputValidator.SCHEMA_INVALID);
            }
        }
        return new DocAnswer(answer, List.copyOf(citations));
    }

    private JsonNode parseStrict(String raw) {
        if (raw == null || raw.isBlank()) {
            throw new TutorOutputRejection(TutorOutputValidator.MALFORMED);
        }
        try {
            return MAPPER.readTree(raw);
        } catch (Exception ex) {
            throw new TutorOutputRejection(TutorOutputValidator.MALFORMED);
        }
    }

    private String extractAnswer(JsonNode root) {
        if (root == null || !root.isObject() || root.size() != 2
                || !root.has("answer") || !root.has("citations")) {
            throw new TutorOutputRejection(TutorOutputValidator.SCHEMA_INVALID);
        }
        JsonNode answerNode = root.get("answer");
        if (!answerNode.isTextual()) {
            throw new TutorOutputRejection(TutorOutputValidator.SCHEMA_INVALID);
        }
        String answer = answerNode.asText().strip();
        if (answer.isEmpty()) {
            throw new TutorOutputRejection(TutorOutputValidator.SCHEMA_INVALID);
        }
        return answer;
    }

    private List<String> extractCitations(JsonNode root) {
        JsonNode citationsNode = root.get("citations");
        if (citationsNode == null || !citationsNode.isArray()) {
            throw new TutorOutputRejection(TutorOutputValidator.SCHEMA_INVALID);
        }
        List<String> citations = new ArrayList<>(citationsNode.size());
        for (JsonNode citation : citationsNode) {
            if (!citation.isTextual() || citation.asText().isBlank()) {
                throw new TutorOutputRejection(TutorOutputValidator.SCHEMA_INVALID);
            }
            citations.add(citation.asText().strip());
        }
        return citations;
    }
}
