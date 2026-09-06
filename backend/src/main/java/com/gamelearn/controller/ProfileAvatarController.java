package com.gamelearn.controller;

import java.util.UUID;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.gamelearn.auth.AuthenticatedUser;
import com.gamelearn.dto.EquipAvatarRequest;
import com.gamelearn.dto.ProfileAvatarResponse;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.gamification.LeaderboardRateLimiter;
import com.gamelearn.service.AvatarService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@Tag(name = "Profile Avatar", description = "Equipped avatar")
@SecurityRequirement(name = "bearerAuth")
@RequestMapping("/api/v1/profile")
public class ProfileAvatarController {

    private final AvatarService avatarService;
    private final LeaderboardRateLimiter rateLimiter;

    public ProfileAvatarController(AvatarService avatarService, LeaderboardRateLimiter rateLimiter) {
        this.avatarService = avatarService;
        this.rateLimiter = rateLimiter;
    }

    @Operation(summary = "Get equipped avatar")
    @GetMapping("/avatar")
    public ProfileAvatarResponse get(@AuthenticationPrincipal AuthenticatedUser principal) {
        checkRate(principal);
        return avatarService.profileAvatar(principal.id());
    }

    @Operation(summary = "Equip avatar")
    @PostMapping("/avatar")
    public ProfileAvatarResponse equip(
            @AuthenticationPrincipal AuthenticatedUser principal,
            @RequestBody(required = false) EquipAvatarRequest request) {
        checkRate(principal);
        UUID avatarId = request == null ? null : request.avatarId();
        avatarService.equip(principal.id(), avatarId);
        return avatarService.profileAvatar(principal.id());
    }

    private void checkRate(AuthenticatedUser principal) {
        if (!rateLimiter.tryAcquire(principal.id())) {
            throw new ApiException(ErrorCode.AI_RATE_LIMITED.getHttpStatus(), ErrorCode.AI_RATE_LIMITED.name(), "Too many requests");
        }
    }
}
