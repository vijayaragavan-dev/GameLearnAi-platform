package com.gamelearn.dto;

import java.util.UUID;

/**
 * Public learning-content view of a subject (SUBJ-001).
 *
 * <p>{@code realmKey} is additive realm metadata (REALM-001): the stable
 * key of the owning realm, or null for legacy rows predating the realm
 * foundation. Existing fields and semantics are unchanged.
 */
public record SubjectResponse(
        UUID id,
        String name,
        String description,
        String iconKey,
        boolean isActive,
        int displayOrder,
        String realmKey) {
}
