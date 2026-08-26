package com.gamelearn.dto;

import java.util.UUID;

/**
 * Topic view (TOPIC-001). Exposes the owning subject as identifiers and a
 * display name, never internal entity relationships.
 */
public record TopicResponse(
        UUID id,
        UUID subjectId,
        String subjectName,
        String name,
        String description,
        String difficulty,
        int displayOrder) {
}
