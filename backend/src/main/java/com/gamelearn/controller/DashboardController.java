package com.gamelearn.controller;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.gamelearn.auth.AuthenticatedUser;
import com.gamelearn.dto.DashboardResponse;
import com.gamelearn.service.DashboardService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;

/**
 * DASH-001 (API Contract v1.3.0 section 5C) — the learner's home-screen
 * read model. Identity always comes from the SecurityContext; the endpoint
 * has NO path/query/body parameters of any kind, so client-controlled
 * ownership is structurally impossible. Strictly read-only.
 */
@RestController
@Tag(name = "Dashboard", description = "Read-only aggregation of the authenticated learner's own state")
@SecurityRequirement(name = "bearerAuth")
@RequestMapping("/api/v1")
public class DashboardController {

    private final DashboardService dashboardService;

    public DashboardController(DashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    @Operation(summary = "Learner dashboard",
            description = "One read-only aggregation of the authenticated "
                    + "learner's own persisted state: profile pointers, mastery, "
                    + "gamification, streak, achievements, active recommendations, "
                    + "active learning path (D1), assessment coverage (R-GUARD "
                    + "lineage) and recent completed quizzes. Absent optional data "
                    + "degrades to null/[] — never an error. Zero mutations and "
                    + "zero AI involvement.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Dashboard snapshot",
                    content = @Content(mediaType = "application/json",
                            schema = @Schema(implementation = DashboardResponse.class))),
            @ApiResponse(responseCode = "401", description = "Missing/invalid/expired token or suspended account")
    })
    @GetMapping("/dashboard")
    public DashboardResponse dashboard(@AuthenticationPrincipal AuthenticatedUser principal) {
        return dashboardService.dashboard(principal);
    }
}
