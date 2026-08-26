package com.gamelearn.controller;

import java.util.List;
import java.util.UUID;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.gamelearn.auth.AuthenticatedUser;
import com.gamelearn.dto.ProgressResponse;
import com.gamelearn.service.ProgressService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;

/**
 * PROG-001/PROG-002: read-only learner progress.
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
}
