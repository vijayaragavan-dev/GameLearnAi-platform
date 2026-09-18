package com.gamelearn.ai.rag;

import java.util.List;

/**
 * Gate 23: validated RAG evidence for one tutor question. Citations
 * originate exclusively from the sidecar bundle (authoritative Gate 21
 * lineage) - never from user input, never from LLM output.
 */
public record RagEvidence(
        boolean served,
        String emptyReason,
        List<Chunk> chunks,
        String corpusFingerprint,
        String retrieverVersion,
        long latencyMs) {

    /** One scoped, citable evidence chunk (educational DATA, not instructions). */
    public record Chunk(
            String chunkId,
            String citation,
            String sourceTable,
            String sourceId,
            String subjectId,
            String topicId,
            String unitId,
            String contentVersion,
            String difficulty,
            double score,
            String text) {
    }
}
