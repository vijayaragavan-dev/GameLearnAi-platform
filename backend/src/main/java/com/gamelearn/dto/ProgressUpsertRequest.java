package com.gamelearn.dto;

import java.math.BigDecimal;

import com.gamelearn.entity.enums.ProgressStatus;

import jakarta.validation.constraints.NotNull;

/**
 * Topic learning-progress upsert (Phase QA-6B). The client may ONLY state the
 * learner-facing completion state: user identity comes from the authenticated
 * principal and topic existence is verified server-side. Phase 1 supports the
 * explicit completion action only: COMPLETED / 100.
 */
public record ProgressUpsertRequest(
        @NotNull(message = "Status is required")
        ProgressStatus status,

        @NotNull(message = "Completion percentage is required")
        BigDecimal completionPercentage) {
}
