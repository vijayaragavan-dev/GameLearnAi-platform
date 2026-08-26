package com.gamelearn.controller;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.gamelearn.auth.AuthenticatedUser;
import com.gamelearn.dto.UserResponse;
import com.gamelearn.service.ProfileService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;

/**
 * USER-001: the authenticated learner's own profile. Read-only in Phase 3.
 */
@RestController
@RequestMapping("/api/v1/profile")
@Tag(name = "Profile", description = "Learner profile")
@SecurityRequirement(name = "bearerAuth")
public class ProfileController {

    private final ProfileService profileService;

    public ProfileController(ProfileService profileService) {
        this.profileService = profileService;
    }

    @Operation(summary = "Get the authenticated learner's profile",
            description = "Identity is taken from the access token; client-supplied "
                    + "user identifiers are never accepted.")
    @GetMapping
    public UserResponse getProfile(@AuthenticationPrincipal AuthenticatedUser principal) {
        return profileService.getOwnProfile(principal.id());
    }
}
