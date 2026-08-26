package com.gamelearn.ai.validation;

import java.util.List;
import java.util.regex.Pattern;

import org.springframework.stereotype.Component;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Output validation chain for AI-001 (AI-TUTOR v1.0.0 section 11.3):
 * strict JSON parse -> schema -> safety scans (S-1 leakage, S-2 secrets,
 * S-3 injection artifacts, S-4 control payloads) -> length gate with
 * deterministic sentence-boundary truncation. Deterministic regex/set
 * checks only - no moderation platform, no ML.
 *
 * <p>Rejections carry an internal audit category; the raw reason NEVER
 * reaches the learner (spec section 21).</p>
 */
@Component
public class TutorOutputValidator {

    /** Rejection with internal-only category string. */
    public static class TutorOutputRejection extends RuntimeException {
        public final String category;

        public TutorOutputRejection(String category) {
            super(category);
            this.category = category;
        }
    }

    /** Validated, deliverable answer. */
    public record TutorAnswer(String answer, boolean truncated) {
    }

    private static final ObjectMapper MAPPER = new ObjectMapper();

    public static final String MALFORMED = "TUTOR_MALFORMED_RESPONSE";
    public static final String SCHEMA_INVALID = "TUTOR_OUTPUT_INVALID";
    public static final String UNSAFE = "TUTOR_UNSAFE_CONTENT";
    public static final String PROMPT_LEAK = "TUTOR_PROMPT_LEAK";
    public static final String SECRET_LEAK = "TUTOR_SECRET_LEAK";
    public static final String INJECTION_ARTIFACT = "TUTOR_INJECTION_ARTIFACT";

    /** S-1: system-material markers that must never appear in answers. */
    private static final List<String> LEAKAGE_MARKERS = List.of(
            "SYSTEM RULES",
            "SYSTEM INSTRUCTIONS",
            "OUTPUT SCHEMA",
            "PROMPT VERSION:",
            "ai-tutor-v",
            "LEARNER_CONTEXT",
            "LEARNER_QUESTION");

    /** S-2: credential-shaped material (class reused from Phase 6 C-2). */
    private static final Pattern SECRET_PATTERNS = Pattern.compile(
            "(?i)("
                    + "sk-[A-Za-z0-9]{8,}"
                    + "|AIza[0-9A-Za-z_\\-]{20,}"
                    + "|Bearer\\s+[A-Za-z0-9._\\-]{10,}"
                    + "|-----BEGIN[A-Z ]*PRIVATE KEY-----"
                    + "|(api[_-]?key|password|passwd|secret)\\s*[:=]\\s*\\S+"
                    + ")");

    /** S-3: classic injection phrasing surfacing INSIDE the answer. */
    private static final Pattern INJECTION_ARTIFACTS = Pattern.compile(
            "(?i)("
                    + "ignore (all |the )?(previous|prior|above) (instructions|rules)"
                    + "|disregard (the |all |previous )?(system|instructions|rules)"
                    + "|you are now"
                    + "|new instructions:"
                    + "|override (the )?(system|rules)"
                    + ")");

    /**
     * S-4: control and zero-width payloads. Ordinary whitespace controls
     * (\t \n \r) are allowed so multiline Gemini answers pass; every other
     * C0 control, DEL and zero-width code point stays rejected.
     */
    private static final Pattern CONTROL_AND_ZERO_WIDTH =
            Pattern.compile("[\\u0000-\\u0008\\u000B\\u000C\\u000E-\\u001F\\u007F\\u200B-\\u200D\\uFEFF]");

    private static final int ANSWER_MAX_CHARS = 4000;

    /**
     * Validates one raw Gemini response.
     *
     * @throws TutorOutputRejection on any validation failure (category set)
     */
    public TutorAnswer validate(String rawResponse) {
        JsonNode root = parseStrict(rawResponse);
        String answer = extractAnswer(root);
        scanSafety(answer);
        return truncateIfNeeded(answer);
    }

    private JsonNode parseStrict(String raw) {
        if (raw == null || raw.isBlank()) {
            throw new TutorOutputRejection(MALFORMED);
        }
        try {
            return MAPPER.readTree(raw);
        } catch (Exception ex) {
            throw new TutorOutputRejection(MALFORMED);
        }
    }

    private String extractAnswer(JsonNode root) {
        if (root == null || !root.isObject() || root.size() != 1 || !root.has("answer")) {
            throw new TutorOutputRejection(SCHEMA_INVALID);
        }
        JsonNode answerNode = root.get("answer");
        if (!answerNode.isTextual()) {
            throw new TutorOutputRejection(SCHEMA_INVALID);
        }
        String answer = answerNode.asText().strip();
        if (answer.isEmpty()) {
            throw new TutorOutputRejection(SCHEMA_INVALID);
        }
        return answer;
    }

    private void scanSafety(String answer) {
        if (CONTROL_AND_ZERO_WIDTH.matcher(answer).find()) {
            throw new TutorOutputRejection(UNSAFE);
        }
        for (String marker : LEAKAGE_MARKERS) {
            if (answer.contains(marker)) {
                throw new TutorOutputRejection(PROMPT_LEAK);
            }
        }
        if (SECRET_PATTERNS.matcher(answer).find()) {
            throw new TutorOutputRejection(SECRET_LEAK);
        }
        if (INJECTION_ARTIFACTS.matcher(answer).find()) {
            throw new TutorOutputRejection(INJECTION_ARTIFACT);
        }
    }

    /**
     * Length gate: over-limit answers are cut at the last sentence boundary
     * within the cap (never mid-word when avoidable); spec section 11.3.
     */
    private TutorAnswer truncateIfNeeded(String answer) {
        if (answer.length() <= ANSWER_MAX_CHARS) {
            return new TutorAnswer(answer, false);
        }
        String window = answer.substring(0, ANSWER_MAX_CHARS);
        int cut = lastSentenceEnd(window);
        if (cut < 500) {
            cut = ANSWER_MAX_CHARS; // no usable sentence boundary - hard cut
        } else {
            window = window.substring(0, cut);
        }
        String trimmed = window.strip();
        if (trimmed.isEmpty()) {
            throw new TutorOutputRejection(SCHEMA_INVALID);
        }
        return new TutorAnswer(trimmed, true);
    }

    private int lastSentenceEnd(String text) {
        for (int i = text.length() - 1; i >= 0; i--) {
            char c = text.charAt(i);
            if (c == '.' || c == '!' || c == '?' || c == '\n') {
                return i + 1;
            }
        }
        return -1;
    }
}
