package com.gamelearn.controller;

import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.gamelearn.auth.AuthenticatedUser;
import com.gamelearn.dto.GeneratedLearningPathResponse;
import com.gamelearn.dto.LearningPathResponse;
import com.gamelearn.dto.PathGenerationRequest;
import com.gamelearn.ai.prompts.LearningPathPromptBuilder;
import com.gamelearn.entity.LearningPath;
import com.gamelearn.logging.RequestCorrelationFilter;
import com.gamelearn.service.GeneratedPathResponseMapper;
import com.gamelearn.service.LearnerContextBuilder;
import com.gamelearn.service.LearningPathGenerationService;
import com.gamelearn.service.LearningPathService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;

/**
 * PATH-001 read model plus PATH-002 learner-initiated AI learning-path
 * generation (central API Contract section 5). Controllers stay thin; all
 * behavior lives in services; the caller identity always comes from the
 * security context.
 */
@RestController
@RequestMapping("/api/v1/learning-path")
@Tag(name = "Learning Path", description = "Personal learning paths")
@SecurityRequirement(name = "bearerAuth")
public class LearningPathController {

    private final LearningPathService learningPathService;
    private final LearningPathGenerationService generationService;
    private final LearnerContextBuilder contextBuilder;
    private final GeneratedPathResponseMapper responseMapper;

    public LearningPathController(LearningPathService learningPathService,
                                  LearningPathGenerationService generationService,
                                  LearnerContextBuilder contextBuilder,
                                  GeneratedPathResponseMapper responseMapper) {
        this.learningPathService = learningPathService;
        this.generationService = generationService;
        this.contextBuilder = contextBuilder;
        this.responseMapper = responseMapper;
    }

    @Operation(summary = "List the caller's learning paths for a subject",
            description = "Returns only paths owned by the authenticated learner; "
                    + "an empty list means none exist yet.")
    @GetMapping("/{subjectId}")
    public List<LearningPathResponse> getLearningPaths(
            @AuthenticationPrincipal AuthenticatedUser principal,
            @PathVariable UUID subjectId) {
        return learningPathService.getOwnPathsForSubject(principal.id(), subjectId);
    }

    /**
     * PATH-002. 200 = idempotent return of an existing ACTIVE path (no AI
     * work); 201 = new ACTIVE path created (AI-generated or deterministic
     * SYSTEM fallback).
     */
    @Operation(summary = "Generate (or return the existing) personalized learning path",
            description = "Learner-initiated AI generation for one subject. Idempotent: "
                    + "an existing ACTIVE path is returned unchanged without any AI call.")
    @PostMapping("/{subjectId}/generate")
    public ResponseEntity<GeneratedLearningPathResponse> generateLearningPath(
            @AuthenticationPrincipal AuthenticatedUser principal,
            @PathVariable UUID subjectId,
            @jakarta.validation.Valid
            @RequestBody(required = false) PathGenerationRequest request) {
        PathGenerationRequest body = request == null
                ? new PathGenerationRequest(null, null)
                : request;
        String sanitizedGoal = LearningPathPromptBuilder.sanitizeLearningGoal(body.learningGoal());

        var outcome = generationService.generate(principal.id(), subjectId,
                body.regenerateOrDefault(), sanitizedGoal,
                RequestCorrelationFilter.currentRequestId());

        // Reload through caller-scoped state - never trust ids from the client.
        LearningPath delivered = contextBuilder.findActivePath(principal.id(), subjectId);
        GeneratedLearningPathResponse response =
                responseMapper.toResponse(delivered, outcome.plan());
        HttpStatus status = outcome.created() ? HttpStatus.CREATED : HttpStatus.OK;
        return ResponseEntity.status(status).body(response);
    }
}
