package com.gamelearn.dto;

import java.util.List;

/**
 * USER-DOC RAG Phase I: grounded document answer. {@code grounded} is true
 * only when the answer passed the citation allowlist against Phase H
 * evidence; {@code insufficientEvidence} marks the explicit safe refusal
 * (same message shape whether evidence was empty, unusable, or the model
 * output failed grounding). Never carries paths, point IDs, vectors,
 * secrets or transport metadata.
 */
public record DocumentAskResponse(
        String answer,
        List<String> citations,
        boolean grounded,
        boolean insufficientEvidence) {
}
