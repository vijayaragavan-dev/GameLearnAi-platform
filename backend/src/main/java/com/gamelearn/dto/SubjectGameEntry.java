package com.gamelearn.dto;

/**
 * One supported game for a subject, with truthful content availability:
 * {@code hasContent} is true only when the backend can actually serve
 * playable items for the combination; {@code contentCount} is the exact
 * number of servable items backing that claim.
 */
public record SubjectGameEntry(String gameType, String rationale, boolean hasContent, long contentCount) {
}
