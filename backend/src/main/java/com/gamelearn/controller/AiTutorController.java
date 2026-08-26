package com.gamelearn.controller;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.gamelearn.auth.AuthenticatedUser;
import com.gamelearn.dto.AiTutorRequest;
import com.gamelearn.dto.AiTutorResponse;
import com.gamelearn.service.AiTutorService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * AI-001 (API Contract v1.4.0 section 5D) — conversational AI Tutor.
 * Identity always comes from the SecurityContext; the endpoint accepts NO
 * client-controlled userId, and the service performs zero mutations outside
 * sanitized audit metadata. Thin by convention — all logic lives in the
 * service layer.
 */
@RestController
@Tag(name = "AI Tutor", description = "Conversational learning tutor (stateless v1)")
@SecurityRequirement(name = "bearerAuth")
@RequestMapping("/api/v1")
public class AiTutorController {

    private final AiTutorService aiTutorService;

    public AiTutorController(AiTutorService aiTutorService) {
        this.aiTutorService = aiTutorService;
    }

    @Operation(summary = "Ask the AI tutor",
            description = "One stateless educational Q&A turn for the "
                    + "authenticated learner: an allowlisted context slice is "
                    + "combined with the sanitized question and bounded "
                    + "conversation window, answered by Gemini under strict "
                    + "output validation. Zero learner-state mutations; "
                    + "conversation content is never persisted. Provider-side "
                    + "failures surface as 503; quota exhaustion as 429.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Answer (or deterministic refusal/degraded template)",
                    content = @io.swagger.v3.oas.annotations.media.Content(
                            mediaType = "application/json",
                            schema = @io.swagger.v3.oas.annotations.media.Schema(
                                    implementation = AiTutorResponse.class))),
            @ApiResponse(responseCode = "400", description = "Structural/referential validation failure"),
            @ApiResponse(responseCode = "401", description = "Missing/invalid/expired token or suspended account"),
            @ApiResponse(responseCode = "429", description = "Tutor rate limit exhausted"),
            @ApiResponse(responseCode = "503", description = "Tutor disabled or Gemini unavailable after approved retry")
    })
    @PostMapping("/ai/tutor")
    public AiTutorResponse ask(@AuthenticationPrincipal AuthenticatedUser principal,
                               @Valid @RequestBody AiTutorRequest request) {
        return aiTutorService.ask(principal.id(), request);
    }
}
