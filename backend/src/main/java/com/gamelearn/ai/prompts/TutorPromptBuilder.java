package com.gamelearn.ai.prompts;

import java.util.List;

import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

/**
 * Renders the versioned tutor prompt (AI-TUTOR v1.0.0 section 9; LP-AI
 * section 18 conventions). System instructions live in the versioned
 * resource; ALL learner-derived text is sanitized and placed exclusively
 * inside delimited untrusted blocks with delimiter-collision
 * neutralization. The full prompt is NEVER logged, persisted or returned.
 */
@Component
public class TutorPromptBuilder {

    public static final String PROMPT_VERSION = "ai-tutor-v1.0";
    public static final int QUESTION_MAX_CHARS = 2000;
    public static final int MESSAGE_MAX_CHARS = 1000;
    public static final int MAX_HISTORY_MESSAGES = 8;
    public static final int ANSWER_MAX_CHARS = 4000;

    private static final String TEMPLATE_LOCATION = "prompts/tutor/ai-tutor-v1.0.txt";
    private static final String REFUSAL_LOCATION = "prompts/tutor/tutor-refusal-v1.0.txt";
    private static final String DEGRADED_LOCATION = "prompts/tutor/tutor-degraded-v1.0.txt";

    /** Rendered-prompt hard budget (spec section 10) - defense in depth. */
    public static final int RENDERED_PROMPT_BUDGET_CHARS = 12000;

    private volatile String cachedTemplate;
    private volatile String cachedRefusal;
    private volatile String cachedDegraded;

    public String promptVersion() {
        return PROMPT_VERSION;
    }

    /**
     * @param contextJson serialized allowlist context (already JSON-safe)
     * @param history     sanitized "ROLE: text" turns, in order, never null
     * @param question    sanitized question, never null
     */
    public String build(String contextJson, List<String> history, String question) {
        String template = template();
        StringBuilder conversation = new StringBuilder();
        if (history.isEmpty()) {
            conversation.append("(no prior messages)");
        } else {
            for (String turn : history) {
                conversation.append(turn).append('\n');
            }
        }
        return template
                .replace("{{LEARNER_CONTEXT}}", sanitizeUntrusted(contextJson))
                .replace("{{CONVERSATION}}", conversation.toString().trim())
                .replace("{{QUESTION}}", sanitizeUntrusted(question));
    }

    /**
     * Untrusted free text is neutralized before entering the prompt
     * (AI-TUTOR v1.0.0 section 8.1; LP-AI section 18.3 mechanism):
     * control/zero-width characters removed, delimiter-collision sequences
     * destroyed (runs of '>' collapsed so forged block closers are
     * impossible), trimmed.
     */
    public static String sanitizeUntrusted(String raw) {
        if (raw == null) {
            return "";
        }
        return raw.replaceAll("[\\u0000-\\u001F\\u007F\\u200B-\\u200D\\uFEFF]", "")
                .replaceAll(">+", ">")
                .strip();
    }

    /** Deterministic policy-refusal template (versioned resource). */
    public String refusalTemplate() {
        return load(REFUSAL_LOCATION, this.cachedRefusal).trim();
    }

    /** Deterministic degraded-answer template (versioned resource). */
    public String degradedTemplate() {
        return load(DEGRADED_LOCATION, this.cachedDegraded).trim();
    }

    /** Convenience for audit payloads: counts only, never content. */
    public static int countChars(String sanitizedText) {
        return sanitizedText == null ? 0 : sanitizedText.length();
    }

    /** Role line for the CONVERSATION block; role pre-validated upstream. */
    public static String turnLine(String role, String sanitizedContent) {
        return role + ": " + sanitizedContent;
    }

    public static boolean isAllowedRole(String role) {
        return "LEARNER".equals(role) || "TUTOR".equals(role);
    }

    private String template() {
        return load(TEMPLATE_LOCATION, this.cachedTemplate);
    }

    private synchronized String load(String location, String current) {
        if (current != null) {
            return current;
        }
        try {
            String value = new String(new ClassPathResource(location)
                    .getInputStream().readAllBytes(), java.nio.charset.StandardCharsets.UTF_8);
            switch (location) {
                case TEMPLATE_LOCATION -> this.cachedTemplate = value;
                case REFUSAL_LOCATION -> this.cachedRefusal = value;
                default -> this.cachedDegraded = value;
            }
            return value;
        } catch (java.io.IOException ex) {
            throw new IllegalStateException("Tutor prompt resource missing: " + location, ex);
        }
    }
}
