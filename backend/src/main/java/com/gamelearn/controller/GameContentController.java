package com.gamelearn.controller;

import java.util.UUID;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.gamelearn.dto.GameContentResponse;
import com.gamelearn.dto.SubjectGamesResponse;
import com.gamelearn.service.GameCompatibilityService;
import com.gamelearn.service.GameContentService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;

/**
 * Backend-authoritative game catalog and content (Batch 2).
 *
 * <p>Subject mode serves only the requested subject's content — a topic
 * that belongs to another subject is rejected, never silently swapped.
 * Global arena mode intentionally mixes subjects with deterministic
 * round-robin ordering, and every item still carries its subject identity.
 */
@RestController
@RequestMapping("/api/v1")
@Tag(name = "Game Content", description = "Subject/game compatibility and authoritative game content")
@SecurityRequirement(name = "bearerAuth")
public class GameContentController {

    private final GameCompatibilityService compatibilityService;
    private final GameContentService contentService;

    public GameContentController(GameCompatibilityService compatibilityService,
                                 GameContentService contentService) {
        this.compatibilityService = compatibilityService;
        this.contentService = contentService;
    }

    @Operation(summary = "Supported games for a subject",
            description = "Lists the backend-supported games for the subject with truthful "
                    + "content availability. Unsupported combinations are never exposed.")
    @GetMapping("/subjects/{subjectId}/games")
    public SubjectGamesResponse subjectGames(@PathVariable UUID subjectId) {
        return compatibilityService.gamesForSubject(subjectId);
    }

    @Operation(summary = "Subject-scoped game content",
            description = "Authoritative playable items for one subject/game combination, "
                    + "optionally narrowed by topic and difficulty. Every item preserves "
                    + "subject identity; cross-subject topics are rejected.")
    @GetMapping("/game-content")
    public GameContentResponse subjectContent(
            @RequestParam(required = false) UUID subjectId,
            @RequestParam(required = false) UUID topicId,
            @RequestParam(required = false) String gameType,
            @RequestParam(required = false) String difficulty,
            @RequestParam(required = false) Integer limit) {
        if (subjectId == null) {
            throw new com.gamelearn.exception.ApiException(
                    com.gamelearn.exception.ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                    com.gamelearn.exception.ErrorCode.VALIDATION_FAILED.name(),
                    "Request validation failed",
                    java.util.Map.of("subjectId", "is required"));
        }
        if (gameType == null || gameType.isBlank()) {
            throw new com.gamelearn.exception.ApiException(
                    com.gamelearn.exception.ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                    com.gamelearn.exception.ErrorCode.VALIDATION_FAILED.name(),
                    "Request validation failed",
                    java.util.Map.of("gameType", "is required"));
        }
        return contentService.subjectContent(subjectId, topicId, gameType, difficulty, limit);
    }

    @Operation(summary = "Global mixed-arena game content",
            description = "Intentionally mixed items from all subjects with authoritative "
                    + "per-item subject metadata, in deterministic round-robin order.")
    @GetMapping("/game-content/global")
    public GameContentResponse globalContent(
            @RequestParam(required = false) String gameType,
            @RequestParam(required = false) String difficulty,
            @RequestParam(required = false) Integer limit) {
        if (gameType == null || gameType.isBlank()) {
            throw new com.gamelearn.exception.ApiException(
                    com.gamelearn.exception.ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                    com.gamelearn.exception.ErrorCode.VALIDATION_FAILED.name(),
                    "Request validation failed",
                    java.util.Map.of("gameType", "is required"));
        }
        return contentService.globalContent(gameType, difficulty, limit);
    }
}
