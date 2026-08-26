package com.gamelearn.controller;

import java.util.List;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.gamelearn.auth.AuthenticatedUser;
import com.gamelearn.dto.AchievementItem;
import com.gamelearn.dto.GamificationSummaryResponse;
import com.gamelearn.dto.StreakResponse;
import com.gamelearn.gamification.GamificationService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;

/**
 * GAM-001..003 (API Contract v1.1.0 section 5A) — read-only gamification
 * state of the AUTHENTICATED learner. Identity always comes from the
 * SecurityContext; no client-supplied user identifier exists on these paths,
 * and there is deliberately no mutation endpoint.
 */
@RestController
@Tag(name = "Gamification", description = "XP, level, achievements and streak state")
@SecurityRequirement(name = "bearerAuth")
@RequestMapping("/api/v1")
public class GamificationController {

    private final GamificationService gamificationService;

    public GamificationController(GamificationService gamificationService) {
        this.gamificationService = gamificationService;
    }

    @Operation(summary = "Gamification summary",
            description = "Total XP, current level, streak and achievement count "
                    + "for the authenticated learner. Level fields are null at max level.")
    @GetMapping("/gamification/summary")
    public GamificationSummaryResponse summary(
            @AuthenticationPrincipal AuthenticatedUser principal) {
        return gamificationService.summary(principal.id());
    }

    @Operation(summary = "Achievement catalog",
            description = "The complete active achievement catalog with this "
                    + "learner's unlock timestamps; unlockedAt is null while locked.")
    @GetMapping("/achievements")
    public List<AchievementItem> achievements(
            @AuthenticationPrincipal AuthenticatedUser principal) {
        return gamificationService.achievements(principal.id());
    }

    @Operation(summary = "Learning streak",
            description = "Current and longest daily learning streak of the "
                    + "authenticated learner; zero-state before the first activity.")
    @GetMapping("/streak")
    public StreakResponse streak(@AuthenticationPrincipal AuthenticatedUser principal) {
        return gamificationService.streak(principal.id());
    }
}
