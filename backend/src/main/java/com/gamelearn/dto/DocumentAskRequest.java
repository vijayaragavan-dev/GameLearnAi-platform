package com.gamelearn.dto;

import java.util.UUID;

import jakarta.validation.constraints.NotBlank;

/**
 * USER-DOC RAG Phase I: document question request (API Contract additive).
 * The request carries NO owner identity — ownership is the authenticated
 * principal, server-derived. No raw filters, chunk IDs, citations, paths,
 * vectors or model parameters are accepted; unknown JSON properties are
 * rejected by the default strict binding.
 */
public record DocumentAskRequest(
        @NotBlank(message = "question is required")
        String question,
        UUID documentId,
        Integer docVersion,
        Integer topK) {
}
