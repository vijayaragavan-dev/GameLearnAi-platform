package com.gamelearn.controller;

import java.util.UUID;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.gamelearn.auth.AuthenticatedUser;
import com.gamelearn.dto.LeaderboardPositionResponse;
import com.gamelearn.dto.LeaderboardResponse;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.gamification.LeaderboardRateLimiter;
import com.gamelearn.service.LeaderboardService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@Tag(name = "Leaderboard", description = "Overall and subject leaderboards")
@SecurityRequirement(name = "bearerAuth")
@RequestMapping("/api/v1")
public class LeaderboardController {

    private final LeaderboardService leaderboardService;
    private final LeaderboardRateLimiter rateLimiter;

    public LeaderboardController(LeaderboardService leaderboardService, LeaderboardRateLimiter rateLimiter) {
        this.leaderboardService = leaderboardService;
        this.rateLimiter = rateLimiter;
    }

    @Operation(summary = "Overall leaderboard")
    @GetMapping("/leaderboard/overall")
    public LeaderboardResponse overall(
            @AuthenticationPrincipal AuthenticatedUser principal,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "true") boolean includeTop,
            @RequestParam(required = false) String season,
            @RequestParam(required = false) String aliasMode) {
        checkRate(principal);
        validatePageSize(page, size);
        return leaderboardService.overall(principal.id(), page, size, includeTop, season);
    }

    @Operation(summary = "Subject leaderboard")
    @GetMapping("/leaderboard/subject/{subjectId}")
    public LeaderboardResponse subject(
            @AuthenticationPrincipal AuthenticatedUser principal,
            @PathVariable UUID subjectId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "true") boolean includeTop,
            @RequestParam(required = false) String season,
            @RequestParam(required = false) String aliasMode) {
        checkRate(principal);
        validatePageSize(page, size);
        return leaderboardService.subject(principal.id(), subjectId, page, size, includeTop, season);
    }

    @Operation(summary = "My leaderboard position")
    @GetMapping("/me/leaderboard-position")
    public LeaderboardPositionResponse position(
            @AuthenticationPrincipal AuthenticatedUser principal,
            @RequestParam(defaultValue = "OVERALL") String segment,
            @RequestParam(required = false) UUID subjectId) {
        checkRate(principal);
        return leaderboardService.position(principal.id(), segment, subjectId);
    }

    private void validatePageSize(int page, int size) {
        if (page < 1) throw new ApiException(ErrorCode.VALIDATION_FAILED.getHttpStatus(), ErrorCode.VALIDATION_FAILED.name(), "page must be >=1");
        if (size < 1 || size > 50) throw new ApiException(ErrorCode.VALIDATION_FAILED.getHttpStatus(), ErrorCode.VALIDATION_FAILED.name(), "size must be between 1 and 50");
    }

    private void checkRate(AuthenticatedUser principal) {
        if (!rateLimiter.tryAcquire(principal.id())) {
            throw new ApiException(ErrorCode.AI_RATE_LIMITED.getHttpStatus(), ErrorCode.AI_RATE_LIMITED.name(), "Too many leaderboard requests");
        }
    }
}
