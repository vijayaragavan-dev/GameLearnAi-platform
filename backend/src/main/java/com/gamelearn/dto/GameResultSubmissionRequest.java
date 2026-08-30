package com.gamelearn.dto;

import java.util.UUID;

import com.gamelearn.entity.enums.Difficulty;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * PROG-101: client submission for a single educational game completion.
 *
 * <p>The {@code clientRequestId} is a caller-generated UUID used for
 * idempotency: replaying the same value never grants XP twice (server-side
 * UNIQUE(user_id, client_request_id) plus a defensive read).</p>
 *
 * <p>All numeric fields are bounded by the server; out-of-range values are
 * rejected with 400 before any ledger write. The server computes the XP
 * award — the client never sends a desired XP value.</p>
 */
public record GameResultSubmissionRequest(
        @NotNull UUID clientRequestId,
        @NotBlank @Size(max = 60) String gameType,
        @NotNull Difficulty difficulty,
        boolean completed,
        @Min(0) @Max(1_000_000) int score,
        @Min(0) @Max(86_400) int durationSeconds,
        @Min(0) @Max(10_000) int bestCombo) {
}
