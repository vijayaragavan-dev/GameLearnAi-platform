package com.gamelearn.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.dto.AdaptiveInsight;
import com.gamelearn.dto.QuizResultResponse;
import com.gamelearn.dto.QuizSubmissionRequest;
import com.gamelearn.entity.Question;
import com.gamelearn.entity.QuestionAttempt;
import com.gamelearn.entity.Quiz;
import com.gamelearn.entity.QuizAttempt;
import com.gamelearn.entity.QuizQuestion;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.QuizAttemptStatus;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.gamification.GamificationService;
import com.gamelearn.repository.QuestionAttemptRepository;
import com.gamelearn.repository.QuestionRepository;
import com.gamelearn.repository.QuizAttemptRepository;
import com.gamelearn.repository.QuizQuestionRepository;
import com.gamelearn.repository.QuizRepository;
import com.gamelearn.repository.UserRepository;

/**
 * Quiz submission (QUIZ-002) — the authoritative evaluation boundary.
 *
 * <p>One atomic transaction: create the attempt for the authenticated
 * learner, evaluate every question server-side, persist the per-question
 * attempts, finalize the attempt as COMPLETED, then let the Adaptive Engine
 * (Phase 5) and the Gamification Engine (Phase 7) join this same
 * transaction — adaptive FIRST, gamification strictly after (approved order
 * O-1..O-4). Any failure rolls back all of it (Backend + AI Specification
 * section 36; Gamification Specification sections 9/14).</p>
 *
 * <p>Scoring rule (simplest deterministic rule; no approved formula exists):
 * score = correctCount / totalQuestions * 100 at two decimal places.
 * Unanswered questions count as incorrect.</p>
 */
@Service
public class QuizSubmissionService {

    private final QuizRepository quizRepository;
    private final QuizQuestionRepository quizQuestionRepository;
    private final QuestionRepository questionRepository;
    private final QuizAttemptRepository quizAttemptRepository;
    private final QuestionAttemptRepository questionAttemptRepository;
    private final UserRepository userRepository;
    private final AdaptiveLearningService adaptiveLearningService;
    private final GamificationService gamificationService;

    public QuizSubmissionService(QuizRepository quizRepository,
                                 QuizQuestionRepository quizQuestionRepository,
                                 QuestionRepository questionRepository,
                                 QuizAttemptRepository quizAttemptRepository,
                                 QuestionAttemptRepository questionAttemptRepository,
                                 UserRepository userRepository,
                                 AdaptiveLearningService adaptiveLearningService,
                                 GamificationService gamificationService) {
        this.quizRepository = quizRepository;
        this.quizQuestionRepository = quizQuestionRepository;
        this.questionRepository = questionRepository;
        this.quizAttemptRepository = quizAttemptRepository;
        this.questionAttemptRepository = questionAttemptRepository;
        this.userRepository = userRepository;
        this.adaptiveLearningService = adaptiveLearningService;
        this.gamificationService = gamificationService;
    }

    @Transactional
    public QuizResultResponse submit(UUID authenticatedUserId, UUID quizId, QuizSubmissionRequest request) {
        Quiz quiz = quizRepository.findById(quizId)
                .filter(Quiz::isActive)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                        ErrorCode.RESOURCE_NOT_FOUND.name(),
                        "Quiz not found"));
        User learner = userRepository.findById(authenticatedUserId)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.UNAUTHORIZED.getHttpStatus(),
                        ErrorCode.UNAUTHORIZED.name(),
                        "Invalid email or password"));

        List<QuizQuestion> associations = quizQuestionRepository.findByQuizIdOrderByQuestionOrderAsc(quizId);
        if (associations.isEmpty()) {
            throw new ApiException(
                    ErrorCode.MALFORMED_REQUEST.getHttpStatus(),
                    ErrorCode.MALFORMED_REQUEST.name(),
                    "Quiz has no questions");
        }
        Set<UUID> quizQuestionIds = collectQuestionIds(associations);
        validateAnswers(request, quizQuestionIds);
        Map<UUID, String> answersByQuestionId = indexAnswers(request);

        // One batched load for all questions (no per-question queries).
        Map<UUID, Question> questionsById = new HashMap<>();
        questionRepository.findAllById(quizQuestionIds)
                .forEach(question -> questionsById.put(question.getId(), question));

        // Server-side evaluation over ALL quiz questions, in quiz order.
        Instant startedAt = Instant.now();
        int correctCount = 0;
        List<EvaluatedAnswer> evaluations = new ArrayList<>(associations.size());
        for (QuizQuestion association : associations) {
            Question question = questionsById.get(association.getQuestion().getId());
            String selected = answersByQuestionId.get(question.getId()); // null when unanswered
            boolean isCorrect = selected != null
                    && selected.trim().equals(question.getCorrectAnswer().trim());
            if (isCorrect) {
                correctCount++;
            }
            evaluations.add(new EvaluatedAnswer(question, selected, isCorrect));
        }
        Instant submittedAt = Instant.now();

        BigDecimal score = BigDecimal.valueOf(correctCount * 100L)
                .divide(BigDecimal.valueOf(evaluations.size()), 2, RoundingMode.HALF_UP);

        QuizAttempt attemptRow = new QuizAttempt();
        attemptRow.setQuiz(quiz);
        attemptRow.setUser(learner);
        attemptRow.setScore(score);
        attemptRow.setCorrectCount(correctCount);
        attemptRow.setTotalQuestions(evaluations.size());
        attemptRow.setDifficultyAtAttempt(quiz.getDifficulty());
        attemptRow.setStartedAt(startedAt);
        attemptRow.setSubmittedAt(submittedAt);
        attemptRow.setDurationSeconds((int) Duration.between(startedAt, submittedAt).getSeconds());
        attemptRow.setStatus(QuizAttemptStatus.COMPLETED);
        attemptRow = quizAttemptRepository.save(attemptRow);

        List<QuizResultResponse.AnswerReview> reviews = new ArrayList<>(evaluations.size());
        for (EvaluatedAnswer evaluated : evaluations) {
            QuestionAttempt row = new QuestionAttempt();
            row.setQuizAttempt(attemptRow);
            row.setQuestion(evaluated.question());
            row.setSelectedAnswer(evaluated.selected());
            row.setCorrect(evaluated.isCorrect());
            questionAttemptRepository.save(row);

            reviews.add(new QuizResultResponse.AnswerReview(
                    evaluated.question().getId(),
                    evaluated.selected(),
                    evaluated.isCorrect(),
                    evaluated.question().getCorrectAnswer(),
                    evaluated.question().getExplanation()));
        }

        // Phase 5: Adaptive Engine joins THIS transaction (spec sections 15/19).
        AdaptiveInsight adaptive = adaptiveLearningService.processSubmission(
                learner, quiz, attemptRow.getSubmittedAt(), correctCount, evaluations.size());

        // Phase 7: Gamification Engine joins the SAME transaction AFTER the
        // adaptive pipeline — approved order O-1..O-4 (Gamification Spec
        // sections 9/14). Any failure rolls back everything above.
        gamificationService.awardForQuizSubmission(learner, attemptRow);

        return new QuizResultResponse(
                attemptRow.getId(), quiz.getId(), attemptRow.getStatus().name(), score,
                correctCount, evaluations.size(), attemptRow.getDurationSeconds(), reviews,
                adaptive);
    }

    private record EvaluatedAnswer(Question question, String selected, boolean isCorrect) {
    }

    private Set<UUID> collectQuestionIds(List<QuizQuestion> associations) {
        Set<UUID> ids = new HashSet<>();
        for (QuizQuestion association : associations) {
            if (!ids.add(association.getQuestion().getId())) {
                throw new ApiException(
                        ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                        ErrorCode.INTERNAL_ERROR.name(),
                        "Inconsistent quiz configuration");
            }
        }
        return ids;
    }

    private void validateAnswers(QuizSubmissionRequest request, Set<UUID> quizQuestionIds) {
        Set<UUID> seen = new HashSet<>();
        for (var answer : request.answers()) {
            if (!seen.add(answer.questionId())) {
                throw new ApiException(
                        ErrorCode.MALFORMED_REQUEST.getHttpStatus(),
                        ErrorCode.MALFORMED_REQUEST.name(),
                        "Duplicate answer for the same question");
            }
            if (!quizQuestionIds.contains(answer.questionId())) {
                throw new ApiException(
                        ErrorCode.MALFORMED_REQUEST.getHttpStatus(),
                        ErrorCode.MALFORMED_REQUEST.name(),
                        "Answer references a question outside this quiz");
            }
        }
    }

    private Map<UUID, String> indexAnswers(QuizSubmissionRequest request) {
        Map<UUID, String> map = new HashMap<>();
        for (var answer : request.answers()) {
            map.put(answer.questionId(), answer.selectedAnswer());
        }
        return map;
    }
}
