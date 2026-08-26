package com.gamelearn.ai.validation;

import java.util.List;
import java.util.regex.Pattern;

import org.springframework.stereotype.Component;

/**
 * Input-side policy classifier (AI-TUTOR v1.0.0 section 12.3): detects the
 * narrow class of questions that EXPLICITLY solicit system-prompt or
 * credential material. Matching fires a deterministic pre-Gemini refusal
 * (no quota, no model call).
 *
 * <p>Deliberately narrow: prompt-injection PHRASING inside ordinary
 * questions is NOT refused here (learners may legitimately quote such
 * strings when studying security topics) - those are handled by the
 * delimiting/instruction-hierarchy/output-scan layers instead. This
 * classifier is one best-effort layer, not the security boundary.</p>
 */
@Component
public class TutorRefusalClassifier {

    /** "show/reveal/print ... your system prompt / instructions / rules". */
    private static final Pattern PROMPT_EXTRACTION = Pattern.compile(
            "(?i)\\b(show|reveal|print|repeat|output|display|give|tell|leak|expose|share|paste|copy)\\b"
                    + "[^.?!]{0,60}\\b(system\\s*(prompt|instructions?|rules?|message)"
                    + "|initial\\s+instructions?"
                    + "|hidden\\s+(instructions?|prompt|rules?)"
                    + "|your\\s+(instructions?|rules?|prompt|system))\\b");

    /** "what is your api key" / "reveal the secret" style solicitations. */
    private static final Pattern CREDENTIAL_SOLICITATION = Pattern.compile(
            "(?i)(\\b(api[\\s_-]?key|secret(\\s*key)?|credentials?|password"
                    + "|access[\\s_-]?token|private[\\s_-]?key|env(ironment)? variables?)\\b"
                    + "[^.?!]{0,40}\\b(show|reveal|print|give|tell|share|expose|list|what)\\b)"
                    + "|(\\b(what|which)('s| is| are)\\s+(your|the)\\s+"
                    + "(api[\\s_-]?key|secret|credential|password|access[\\s_-]?token)\\b)");

    private static final List<Pattern> RULES = List.of(PROMPT_EXTRACTION, CREDENTIAL_SOLICITATION);

    /**
     * @return true when the sanitized question explicitly solicits protected
     *         material and must be refused before any AI involvement.
     */
    public boolean isPolicyRefusal(String sanitizedQuestion) {
        if (sanitizedQuestion == null || sanitizedQuestion.isBlank()) {
            return false;
        }
        for (Pattern rule : RULES) {
            if (rule.matcher(sanitizedQuestion).find()) {
                return true;
            }
        }
        return false;
    }
}
