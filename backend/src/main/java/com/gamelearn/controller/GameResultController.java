package com.gamelearn.controller;

import java.util.List;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.gamelearn.auth.AuthenticatedUser;
import com.gamelearn.dto.GameResultProgressResponse;
import com.gamelearn.dto.GameResultSubmissionRequest;
import com.gamelearn.dto.GameResultSubmissionResponse;
import com.gamelearn.gamification.GameResultService;
import com.gamelearn.service.UserLookupService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * PROG-101/PROG-102: persistent educational-game result submission and
 * per-game progress read (Persistent Gamification + Player Progression phase).
 *
 * <p>Identity comes exclusively from the SecurityContext; there is no
 * client-supplied user identifier. The submission payload must carry a
 * caller-generated UUID {@code clientRequestId} that the backend uses as an
 * idempotency key (UNIQUE on (user_id, client_request_id)) — replaying the
 * same UUID never re-grants XP.</p>
 */
@RestController
@RequestMapping("/api/v1/me/game-results")
@Tag(name = "Game Results", description = "Submit completed game results and read per-game progress")
@SecurityRequirement(name = "bearerAuth")
public class GameResultController {

    private final GameResultService gameResultService;
    private final UserLookupService userLookupService;

    public GameResultController(GameResultService gameResultService,
                                UserLookupService userLookupService) {
        this.gameResultService = gameResultService;
        this.userLookupService = userLookupService;
    }

    @Operation(summary = "Submit a completed game result",
            description = "Award XP and persist per-game progress for the authenticated "
                    + "learner. Idempotent on the caller UUID; replay never re-grants XP."
                    + " New submissions are rate-limited per user (default 30/hour);"
                    + " replays are quota-free.")
    @io.swagger.v3.oas.annotations.responses.ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "201", description = "Game result persisted and XP awarded (or idempotent replay)"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "429", description = "Game submission rate limit exceeded")
    })
    @PostMapping
    public GameResultSubmissionResponse submit(
            @AuthenticationPrincipal AuthenticatedUser principal,
            @Valid @RequestBody GameResultSubmissionRequest request) {
        return gameResultService.submit(userLookupService.requireUser(principal), request);
    }

    @Operation(summary = "List per-game progress",
            description = "Aggregated plays/completions/best score/best combo/total XP/last "
                    + "played per game type for the authenticated learner. Empty list if the "
                    + "learner has never played any game.")
    @GetMapping
    public List<GameResultProgressResponse> listProgress(
            @AuthenticationPrincipal AuthenticatedUser principal) {
        return gameResultService.progressForUser(principal.id());
    }

    @Operation(summary = "Per-game progress",
            description = "Returns the persisted aggregate for one game type; zero-state "
                    + "values when the learner has never played that game.")
    @GetMapping("/{gameType}")
    public GameResultProgressResponse perGameProgress(
            @AuthenticationPrincipal AuthenticatedUser principal,
            @PathVariable String gameType) {
        return gameResultService.progressForGame(principal.id(), gameType);
    }
}
