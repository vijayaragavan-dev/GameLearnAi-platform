package com.gamelearn.service.context;

import java.util.UUID;

import com.gamelearn.entity.enums.Difficulty;

/**
 * One entry of the controlled topic catalog handed to Gemini
 * (Learning Path AI Specification sections 6.2 and 11). {@code ref} is the
 * 1-based pseudonymized reference Gemini must use; the mapping back to the
 * real topic id happens ONLY inside backend validation.
 */
public record TopicCatalogEntry(
        int ref,
        UUID topicId,
        String name,
        String description,
        Difficulty difficulty,
        int displayOrder) {
}
