package com.gamelearn.entity.enums;

/**
 * Lifecycle states for learner-uploaded document metadata (USER-DOC RAG
 * Phase B). Persisted as {@code VARCHAR(30)} via {@code EnumType.STRING},
 * following the existing status-enum convention (e.g. {@code UserStatus},
 * {@code RecommendationStatus}).
 *
 * <p>State representation choice: a plain Java enum with an explicit
 * transition guard ({@link #canTransitionTo}) — no async processing, no
 * workflow engine. This phase establishes the model only; later phases
 * (upload, extraction, indexing) advance rows through these states.</p>
 *
 * <p>Allowed transitions:</p>
 * <ul>
 *   <li>UPLOADED -&gt; EXTRACTING, FAILED</li>
 *   <li>EXTRACTING -&gt; CHUNKED, FAILED</li>
 *   <li>CHUNKED -&gt; INDEXED, EXTRACTING (re-extract), FAILED</li>
 *   <li>INDEXED -&gt; EXTRACTING (re-index), FAILED (index invalidated)</li>
 *   <li>FAILED -&gt; EXTRACTING (retry)</li>
 * </ul>
 *
 * <p>Everything else (e.g. UPLOADED -&gt; INDEXED, any state -&gt; UPLOADED)
 * is rejected by {@link #canTransitionTo} so nonsensical jumps fail loudly
 * instead of silently corrupting the pipeline.</p>
 */
public enum DocumentStatus {
    UPLOADED,
    EXTRACTING,
    CHUNKED,
    INDEXED,
    FAILED;

    /**
     * Whether a direct transition from this state to {@code target} is
     * legal. Self-transitions are never allowed; callers needing a no-op
     * must skip the update instead.
     */
    public boolean canTransitionTo(DocumentStatus target) {
        if (target == null || target == this) {
            return false;
        }
        return switch (this) {
            case UPLOADED -> target == EXTRACTING || target == FAILED;
            case EXTRACTING -> target == CHUNKED || target == FAILED;
            case CHUNKED -> target == INDEXED || target == EXTRACTING || target == FAILED;
            case INDEXED -> target == EXTRACTING || target == FAILED;
            case FAILED -> target == EXTRACTING;
        };
    }
}
