package com.gamelearn.dto;

import java.util.UUID;

/**
 * Canonical active lesson for a topic (LESSON-001).
 */
public record LessonResponse(
        UUID id,
        UUID topicId,
        String title,
        String content,
        String summary,
        String difficulty,
        String sourceType) {
}
