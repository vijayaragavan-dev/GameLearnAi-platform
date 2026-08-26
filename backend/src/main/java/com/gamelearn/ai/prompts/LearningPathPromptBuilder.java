package com.gamelearn.ai.prompts;

import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.gamelearn.entity.enums.RecommendationStatus;
import com.gamelearn.service.context.LearnerPathContext;

/**
 * Renders the versioned learning-path prompt (Learning Path AI Specification
 * sections 18 and 45). System instructions live in the versioned resource;
 * learner-derived data is serialized into the delimited UNTRUSTED block with
 * delimiter-collision neutralization. The full prompt is NEVER logged.
 */
@Component
public class LearningPathPromptBuilder {

    public static final String PROMPT_VERSION = "learning-path-v1.0";

    private static final String TEMPLATE_LOCATION = "prompts/learning-path/learning-path-v1.0.txt";

    private final ObjectMapper objectMapper = new ObjectMapper();
    private volatile String cachedTemplate;

    public String promptVersion() {
        return PROMPT_VERSION;
    }

    public String build(LearnerPathContext context) {
        String template = template();
        int catalogSize = context.catalog().size();
        // Defense-in-depth: the builder itself neutralizes untrusted text -
        // it never relies on callers having sanitized the goal first.
        return template
                .replace("{{LEARNER_DATA}}", learnerDataJson(context))
                .replace("{{LEARNER_GOAL_BLOCK}}",
                        goalBlock(sanitizeLearningGoal(context.learningGoal())))
                .replace("{{MIN_NODES}}", String.valueOf(Math.min(3, catalogSize)))
                .replace("{{MAX_NODES}}", String.valueOf(catalogSize));
    }

    /** Serialized, sanitized LEARNER_DATA payload - also reused for audit rows. */
    public String learnerDataJson(LearnerPathContext context) {
        ObjectNode root = objectMapper.createObjectNode();
        root.put("subjectName", context.subject().getName());
        ArrayNode catalogNode = root.putArray("topicCatalog");
        context.catalog().forEach(entry -> {
            ObjectNode node = catalogNode.addObject();
            node.put("ref", entry.ref());
            node.put("name", entry.name());
            node.put("difficulty", entry.difficulty().name());
        });
        root.put("overallMastery", context.overallMastery());
        root.put("currentLevel", context.currentLevel());

        ArrayNode masteryNode = root.putArray("perTopicMastery");
        context.masteries().forEach(m -> {
            Integer ref = refOrNull(context, m.getTopic().getId());
            if (ref == null) {
                return; // other subjects' masteries are never sent
            }
            ObjectNode node = masteryNode.addObject();
            node.put("ref", ref);
            node.put("masteryScore", m.getMasteryScore());
            node.put("masteryLevel", m.getMasteryLevel().name());
            node.put("trend", m.getTrend().name());
            node.put("attemptCount", m.getAttemptCount());
        });

        addRefArray(root, "weakTopicRefs", context.weakTopicRefs());
        addRefArray(root, "strongTopicRefs", context.strongTopicRefs());

        ArrayNode recsNode = root.putArray("activeRecommendations");
        context.activeRecommendations().forEach(r -> {
            Integer ref = refOrNull(context, r.getTopic().getId());
            if (ref == null) {
                return;
            }
            ObjectNode node = recsNode.addObject();
            node.put("ref", ref);
            node.put("activityType", r.getActivityType().name());
            node.put("recommendedDifficulty", r.getRecommendedDifficulty().name());
            node.put("priority", r.getPriority());
        });

        if (context.previousActivePath() != null) {
            ObjectNode previous = root.putObject("previousPathSummary");
            previous.put("title", context.previousActivePath().getTitle());
        }
        return sanitizeDelimiters(root.toString());
    }

    /**
     * Untrusted free text is neutralized before entering the prompt:
     * control characters removed, delimiter runs collapsed, length capped.
     * Returns null when no usable goal was supplied.
     */
    public static String sanitizeLearningGoal(String rawGoal) {
        if (rawGoal == null || rawGoal.isBlank()) {
            return null;
        }
        String cleaned = rawGoal.replaceAll("\\p{Cntrl}", "")
                .replaceAll(">+", ">")
                .strip();
        if (cleaned.isEmpty()) {
            return null;
        }
        return cleaned.substring(0, Math.min(cleaned.length(), 300));
    }

    private String goalBlock(String sanitizedGoal) {
        if (sanitizedGoal == null) {
            return "";
        }
        return "\n<<<LEARNER_GOAL>>>\n" + sanitizeDelimiters(sanitizedGoal)
                + "\n<<<END_LEARNER_GOAL>>>";
    }

    /**
     * Collapses delimiter-collision sequences an attacker could embed in free
     * text. Replacements deliberately do NOT contain the original markers as
     * substrings, so the rendered prompt can be scanned reliably.
     */
    static String sanitizeDelimiters(String value) {
        return value.replace("LEARNER_DATA_END", "«data-end»")
                .replace("LEARNER_DATA_BEGIN", "«data-begin»")
                .replace("END_LEARNER_GOAL", "«goal-end»")
                .replaceAll(">+", ">");
    }

    private void addRefArray(ObjectNode root, String field, Iterable<Integer> refs) {
        ArrayNode array = root.putArray(field);
        refs.forEach(array::add);
    }

    private Integer refOrNull(LearnerPathContext context, java.util.UUID topicId) {
        var entry = context.entriesByTopicId().get(topicId);
        return entry == null ? null : Integer.valueOf(entry.ref());
    }

    private String template() {
        String cached = this.cachedTemplate;
        if (cached != null) {
            return cached;
        }
        synchronized (this) {
            if (this.cachedTemplate == null) {
                try {
                    this.cachedTemplate = new String(new ClassPathResource(TEMPLATE_LOCATION)
                            .getInputStream().readAllBytes(), java.nio.charset.StandardCharsets.UTF_8);
                } catch (java.io.IOException ex) {
                    throw new IllegalStateException("Learning-path prompt resource missing", ex);
                }
            }
            return this.cachedTemplate;
        }
    }
}
