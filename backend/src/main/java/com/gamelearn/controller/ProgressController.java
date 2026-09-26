package com.gamelearn.controller;

import java.util.List;
import java.util.UUID;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.gamelearn.auth.AuthenticatedUser;
import com.gamelearn.dto.ProgressResponse;
import com.gamelearn.dto.ProgressUpsertRequest;
import com.gamelearn.service.ProgressService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * PROG-001/PROG-002: learner progress reads, plus the generic explicit
 * topic-completion upsert (Phase QA-6B). Learning state only: marking
 * progress never awards XP, mastery, streaks, or achievements.
 */
@RestController
@RequestMapping("/api/v1/progress")
@Tag(name = "Progress", description = "Learner progress (read-only)")
@SecurityRequirement(name = "bearerAuth")
public class ProgressController {

    private final ProgressService progressService;

    public ProgressController(ProgressService progressService) {
        this.progressService = progressService;
    }

    @Operation(summary = "List the authenticated learner's progress records")
    @GetMapping
    public List<ProgressResponse> listProgress(@AuthenticationPrincipal AuthenticatedUser principal) {
        return progressService.getOwnProgress(principal.id());
    }

    @Operation(summary = "Get the authenticated learner's progress for a topic",
            description = "Returns 404 when no progress record exists for this learner and topic.")
    @GetMapping("/{topicId}")
    public ProgressResponse getTopicProgress(
            @AuthenticationPrincipal AuthenticatedUser principal,
            @PathVariable UUID topicId) {
        return progressService.getOwnProgressForTopic(principal.id(), topicId);
    }

    @Operation(summary = "Mark a topic complete for the authenticated learner",
            description = "Idempotent explicit completion (COMPLETED / 100 only). "
                    + "User identity comes from authentication; unknown or inactive "
                    + "topics return 404. No XP, mastery, streak, or achievement effects.")
    @PutMapping("/{topicId}")
    public ProgressResponse markTopicComplete(
            @AuthenticationPrincipal AuthenticatedUser principal,
            @PathVariable UUID topicId,
            @Valid @RequestBody ProgressUpsertRequest request) {
        return progressService.markTopicComplete(principal.id(), topicId, request);
    }
}
