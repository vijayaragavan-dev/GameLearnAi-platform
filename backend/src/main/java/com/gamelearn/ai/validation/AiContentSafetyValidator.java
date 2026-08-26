package com.gamelearn.ai.validation;

import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import org.springframework.stereotype.Component;

import com.gamelearn.ai.parser.GeneratedPathCandidate;
import com.gamelearn.service.context.TopicCatalogEntry;

/**
 * Content safety scans C-1..C-6 (Learning Path AI Specification section 25,
 * as amended by section 25.1 - C-4 relevance, v1.1.0). Practical,
 * deterministic rejection checks - fail safe to the SYSTEM fallback path.
 * Never a moderation platform.
 *
 * <p>C-4 (amended): relevance is established PER NODE against the
 * SERVER-AUTHORITATIVE topic resolved from the generated topicRef. A valid
 * topicRef alone is NOT evidence of relevant content, and the absence of a
 * verbatim topic-name substring is NOT evidence of irrelevance: legitimate
 * educational PARAPHRASES of the referenced topic are accepted through a
 * deterministic lexical-overlap floor against the catalog's authoritative
 * name/description metadata. No embeddings, no ML, no external services.</p>
 */
@Component
public class AiContentSafetyValidator {

    private static final List<String> LEAKAGE_MARKERS = List.of(
            "SYSTEM RULES",
            "SYSTEM INSTRUCTIONS",
            "OUTPUT SCHEMA",
            "LEARNER_DATA_BEGIN",
            "LEARNER_DATA_END",
            "LEARNER_GOAL>>>",
            "PROMPT VERSION:",
            "learning-path-v1.0");

    private static final Pattern SECRET_PATTERNS = Pattern.compile(
            "(?i)("
                    + "sk-[A-Za-z0-9]{8,}"                       // OpenAI-style keys
                    + "|AIza[0-9A-Za-z_\\-]{20,}"                // Google-style keys
                    + "|Bearer\\s+[A-Za-z0-9._\\-]{10,}"         // tokens
                    + "|-----BEGIN[A-Z ]*PRIVATE KEY-----"       // PEM material
                    + "|(api[_-]?key|password|passwd|secret)\\s*[:=]\\s*\\S+" // assignments
                    + ")");

    private static final Pattern INJECTION_ARTIFACTS = Pattern.compile(
            "(?i)("
                    + "ignore (all |the )?(previous|prior|above) (instructions|rules)"
                    + "|disregard (the |all |previous )?(system|instructions|rules)"
                    + "|you are now"
                    + "|new instructions:"
                    + "|override (the )?(system|rules)"
                    + ")");

    private static final Pattern CONTROL_AND_ZERO_WIDTH = Pattern.compile(
            "[\\u0000-\\u001F\\u007F\\u200B-\\u200D\\uFEFF]");

    /**
     * Generic English function words that carry no topical signal. Kept
     * deliberately small and language-scoped; everything else contributes
     * to the C-4 lexical-overlap floor.
     */
    private static final Set<String> STOPWORDS = Set.of(
            "the", "and", "for", "with", "this", "that", "from", "are", "was",
            "were", "has", "have", "had", "its", "his", "her", "you", "your",
            "they", "them", "will", "shall", "can", "could", "should", "would",
            "may", "might", "must", "not", "but", "all", "any", "each", "via",
            "per", "how", "why", "what", "when", "where", "who", "which",
            "there", "here", "then", "than", "also", "too", "very", "more",
            "most", "some", "such", "only", "own", "same", "into", "about",
            "over", "under", "between", "through", "during", "before",
            "after", "again", "further", "once", "against", "out", "off");

    private static final int MIN_TOKEN_LENGTH = 3;

    /**
     * Runs C-1..C-5 over ALL generated strings and the amended C-4 topical
     * relevance floor per node.
     *
     * <p>Unknown topicRefs are intentionally NOT judged here: structural
     * validity (bounds, duplicates, sequence) belongs to the schema/business
     * layers which classify those violations precisely (spec section 26).</p>
     *
     * @return true when the candidate passes every safety gate.
     */
    public boolean isSafe(GeneratedPathCandidate candidate, List<TopicCatalogEntry> catalog) {
        String all = combinedText(candidate);
        if (CONTROL_AND_ZERO_WIDTH.matcher(all).find()) {
            return false; // C-5 control/zero-width payloads
        }
        for (String marker : LEAKAGE_MARKERS) {
            if (all.contains(marker)) {
                return false; // C-1 system-prompt leakage
            }
        }
        if (SECRET_PATTERNS.matcher(all).find()) {
            return false; // C-2 secret patterns
        }
        if (INJECTION_ARTIFACTS.matcher(all).find()) {
            return false; // C-3 injection artifacts
        }
        return everyNodeTopicallyRelevant(candidate, catalog); // C-4 (amended)
    }

    /**
     * C-4, amended (spec section 25.1): each node must demonstrate topical
     * relevance to ITS server-authoritative topic through either
     * <ol>
     *   <li>the exact authoritative topic name inside the node's own
     *       objective/rationale,</li>
     *   <li>a deterministic lexical-overlap (>= 1 meaningful token) between
     *       the node's objective/rationale and the authoritative topic's
     *       name/description metadata - this is the paraphrase route, or</li>
     *   <li>the exact authoritative topic name appearing in the generated
     *       path title/description (the original v1.0 global acceptance,
     *       now scoped per topic instead of per candidate).</li>
     * </ol>
     * Nodes with no textual evidence (blank/absent objective AND rationale)
     * can never satisfy 1 or 2; trusting topicRef alone is forbidden.
     */
    private boolean everyNodeTopicallyRelevant(GeneratedPathCandidate candidate,
                                               List<TopicCatalogEntry> catalog) {
        Map<Integer, TopicCatalogEntry> entriesByRef = catalog.stream()
                .collect(Collectors.toMap(TopicCatalogEntry::ref, Function.identity()));
        String globalText = lowerSafe(candidate.title()) + " "
                + lowerSafe(candidate.description());
        for (GeneratedPathCandidate.CandidateNode node : candidate.nodes()) {
            if (node == null) {
                continue; // rejected earlier by the schema layer
            }
            TopicCatalogEntry entry = entriesByRef.get(node.topicRef());
            if (entry == null) {
                continue; // structural concern: schema/business layers own it
            }
            if (nodeIsRelevant(node, entry, globalText)) {
                continue;
            }
            return false;
        }
        return true;
    }

    private boolean nodeIsRelevant(GeneratedPathCandidate.CandidateNode node,
                                   TopicCatalogEntry entry, String globalText) {
        String nodeText = lowerSafe(node.objective()) + " " + lowerSafe(node.rationale());
        String name = lowerSafe(entry.name());

        // (1) Exact authoritative name inside the node's own text.
        if (!name.isBlank() && nodeText.contains(name)) {
            return true;
        }
        // (2) Paraphrase route: deterministic lexical overlap with the
        //     server-authoritative topic metadata.
        Set<String> topicTokens = meaningfulTokens(name + " " + lowerSafe(entry.description()));
        if (!topicTokens.isEmpty()
                && !java.util.Collections.disjoint(topicTokens, meaningfulTokens(nodeText))) {
            return true;
        }
        // (3) Original v1.0 acceptance, scoped per topic: the exact name in
        //     the generated path title/description.
        return !name.isBlank() && globalText.contains(name);
    }

    /** Lowercased text for matching; never null. */
    private String lowerSafe(String value) {
        return value == null ? "" : value.toLowerCase(Locale.ROOT);
    }

    /**
     * Meaningful topical tokens: lowercased alphanumeric words, stopwords
     * and very short fragments removed. Deterministic and dependency-free.
     */
    private Set<String> meaningfulTokens(String text) {
        if (text == null || text.isBlank()) {
            return Set.of();
        }
        return Pattern.compile("[^a-z0-9]+")
                .splitAsStream(text)
                .filter(token -> token.length() >= MIN_TOKEN_LENGTH)
                .filter(token -> !STOPWORDS.contains(token))
                .collect(Collectors.toUnmodifiableSet());
    }

    private String combinedText(GeneratedPathCandidate candidate) {
        StringBuilder text = new StringBuilder();
        append(text, candidate.title());
        append(text, candidate.description());
        if (candidate.nodes() != null) {
            for (GeneratedPathCandidate.CandidateNode node : candidate.nodes()) {
                if (node == null) {
                    continue;
                }
                append(text, node.objective());
                append(text, node.rationale());
            }
        }
        return text.toString();
    }

    private void append(StringBuilder builder, String value) {
        if (value != null) {
            builder.append(value);
            builder.append(' ');
        }
    }
}
