package com.gamelearn.dto;

import java.util.UUID;

/**
 * Public learning-content view of a subject (SUBJ-001).
 */
public record SubjectResponse(
        UUID id,
        String name,
        String description,
        String iconKey,
        boolean isActive,
        int displayOrder) {
}
