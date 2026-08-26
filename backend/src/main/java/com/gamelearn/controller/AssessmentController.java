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
import com.gamelearn.assessment.AssessmentService;
import com.gamelearn.dto.AssessmentDeliveryResponse;
import com.gamelearn.dto.AssessmentResultResponse;
import com.gamelearn.dto.AssessmentSubmissionRequest;
import com.gamelearn.dto.AssessmentSubmissionResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * ASMT-001..003 (API Contract v1.2.0 section 5B) — subject placement
 * assessment. Identity always comes from the SecurityContext; no
 * client-supplied user identifier exists on these paths.
 */
@RestController
@Tag(name = "Assessment", description = "Subject placement assessment")
@SecurityRequirement(name = "bearerAuth")
@RequestMapping("/api/v1/assessment")
public class AssessmentController {

    private final AssessmentService assessmentService;

    public AssessmentController(AssessmentService assessmentService) {
        this.assessmentService = assessmentService;
    }

    @Operation(summary = "Fetch the subject placement assessment",
            description = "Deterministic selection of up to 3 active MCQ "
                    + "questions per active topic. Correct answers and "
                    + "explanations are never exposed.")
    @GetMapping("/{subjectId}")
    public AssessmentDeliveryResponse delivery(
            @AuthenticationPrincipal AuthenticatedUser principal,
            @PathVariable UUID subjectId) {
        return assessmentService.delivery(subjectId);
    }

    @Operation(summary = "Submit the subject placement assessment",
            description = "Grades the delivered question set server-side, "
                    + "seeds per-topic mastery baselines and refreshes the "
                    + "profile subset in ONE atomic transaction. Rejected with "
                    + "409 when a placement baseline already exists.")
    @PostMapping("/{subjectId}/submit")
    public ResponseEntity<AssessmentSubmissionResponse> submit(
            @AuthenticationPrincipal AuthenticatedUser principal,
            @PathVariable UUID subjectId,
            @Valid @RequestBody AssessmentSubmissionRequest request) {
        AssessmentSubmissionResponse response =
                assessmentService.submit(principal.id(), subjectId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @Operation(summary = "Placement result",
            description = "Derived read of the persisted per-topic baselines; "
                    + "assessed=false before the first successful submission.")
    @GetMapping("/{subjectId}/result")
    public AssessmentResultResponse result(
            @AuthenticationPrincipal AuthenticatedUser principal,
            @PathVariable UUID subjectId) {
        return assessmentService.result(principal.id(), subjectId);
    }
}
