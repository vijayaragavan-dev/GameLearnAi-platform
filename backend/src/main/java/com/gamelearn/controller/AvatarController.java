package com.gamelearn.controller;

import java.util.List;
import java.util.UUID;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.gamelearn.auth.AuthenticatedUser;
import com.gamelearn.dto.AvatarCatalogItem;
import com.gamelearn.dto.AvatarCollectionResponse;
import com.gamelearn.entity.UserAvatar;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.gamification.LeaderboardRateLimiter;
import com.gamelearn.service.AvatarService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@Tag(name = "Avatars", description = "Avatar catalog and ownership")
@SecurityRequirement(name = "bearerAuth")
@RequestMapping("/api/v1")
public class AvatarController {

    private final AvatarService avatarService;
    private final LeaderboardRateLimiter rateLimiter;

    public AvatarController(AvatarService avatarService, LeaderboardRateLimiter rateLimiter) {
        this.avatarService = avatarService;
        this.rateLimiter = rateLimiter;
    }

    @Operation(summary = "Avatar catalog")
    @GetMapping("/avatars")
    public List<AvatarCatalogItem> catalog(@AuthenticationPrincipal AuthenticatedUser principal) {
        checkRate(principal);
        return avatarService.catalogItems();
    }

    @Operation(summary = "My avatar collection")
    @GetMapping("/avatars/me")
    public AvatarCollectionResponse me(@AuthenticationPrincipal AuthenticatedUser principal) {
        checkRate(principal);
        return avatarService.collection(principal.id());
    }

    @Operation(summary = "Purchase avatar")
    @PostMapping("/avatars/{avatarId}/purchase")
    public AvatarCollectionResponse purchase(
            @AuthenticationPrincipal AuthenticatedUser principal,
            @PathVariable UUID avatarId) {
        checkRate(principal);
        UserAvatar ua = avatarService.purchase(principal.id(), avatarId);
        return avatarService.collection(principal.id());
    }

    @Operation(summary = "Claim threshold avatar")
    @PostMapping("/avatars/{avatarId}/claim")
    public AvatarCollectionResponse claim(
            @AuthenticationPrincipal AuthenticatedUser principal,
            @PathVariable UUID avatarId) {
        checkRate(principal);
        UserAvatar ua = avatarService.claim(principal.id(), avatarId);
        return avatarService.collection(principal.id());
    }

    private void checkRate(AuthenticatedUser principal) {
        if (!rateLimiter.tryAcquire(principal.id())) {
            throw new ApiException(ErrorCode.AI_RATE_LIMITED.getHttpStatus(), ErrorCode.AI_RATE_LIMITED.name(), "Too many requests");
        }
    }
}
