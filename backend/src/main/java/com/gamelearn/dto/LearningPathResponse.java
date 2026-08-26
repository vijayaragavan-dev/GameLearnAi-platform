package com.gamelearn.dto;

import java.util.List;
import java.util.UUID;

/**
 * The authenticated learner's learning path for a subject (PATH-001).
 */
public record LearningPathResponse(
        UUID id,
        UUID subjectId,
        String title,
        String description,
        String status,
        String generatedBy,
        List<LearningNodeResponse> nodes) {
}
