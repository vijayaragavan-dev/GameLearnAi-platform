package com.gamelearn.controller;

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
import com.gamelearn.dto.QuizResponse;
import com.gamelearn.dto.QuizResultResponse;
import com.gamelearn.dto.QuizSubmissionRequest;
import com.gamelearn.service.QuizService;
import com.gamelearn.service.QuizSubmissionService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * Quiz endpoints (Backend + AI Specification section 11):
 * QUIZ-001 discovery, QUIZ-002 submission.
 */
@RestController
@RequestMapping("/api/v1/quiz")
@Tag(name = "Quiz", description = "Quiz delivery and authoritative submission")
@SecurityRequirement(name = "bearerAuth")
public class QuizController {

    private final QuizService quizService;
    private final QuizSubmissionService quizSubmissionService;

    public QuizController(QuizService quizService, QuizSubmissionService quizSubmissionService) {
        this.quizService = quizService;
        this.quizSubmissionService = quizSubmissionService;
    }

    @Operation(summary = "Get the active quiz of a topic",
            description = "Returns the quiz with its ordered questions. Correct answers "
                    + "and explanations are never included in this response.")
    @GetMapping("/{topicId}")
    public QuizResponse getQuiz(@PathVariable UUID topicId) {
        return quizService.getQuizForTopic(topicId);
    }

    @Operation(summary = "Submit answers and receive the evaluated result",
            description = "Creates an attempt for the authenticated learner, evaluates all "
                    + "answers server-side and persists the result atomically. Correctness "
                    + "and score are always computed by the backend; correct answers are "
                    + "revealed only in this post-submission result.")
    @PostMapping("/{quizId}/submit")
    public ResponseEntity<QuizResultResponse> submit(
            @AuthenticationPrincipal AuthenticatedUser principal,
            @PathVariable UUID quizId,
            @Valid @RequestBody QuizSubmissionRequest request) {
        QuizResultResponse result = quizSubmissionService.submit(principal.id(), quizId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(result);
    }
}
