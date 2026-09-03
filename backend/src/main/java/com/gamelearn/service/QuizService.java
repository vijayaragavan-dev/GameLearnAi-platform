package com.gamelearn.service;

import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamelearn.dto.QuizQuestionResponse;
import com.gamelearn.dto.QuizResponse;
import com.gamelearn.entity.Quiz;
import com.gamelearn.entity.QuizQuestion;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.repository.QuizQuestionRepository;
import com.gamelearn.repository.QuizRepository;

/**
 * Quiz discovery (QUIZ-001): the canonical active quiz of a topic with its
 * ordered questions. Correct answers and explanations are never included —
 * the backend is authoritative for correctness.
 */
@Service
public class QuizService {

    private final QuizRepository quizRepository;
    private final QuizQuestionRepository quizQuestionRepository;
    private final TopicService topicService;
    private final SubjectService subjectService;
    private final ObjectMapper objectMapper;

    public QuizService(QuizRepository quizRepository,
                       QuizQuestionRepository quizQuestionRepository,
                       TopicService topicService,
                       SubjectService subjectService,
                       ObjectMapper objectMapper) {
        this.quizRepository = quizRepository;
        this.quizQuestionRepository = quizQuestionRepository;
        this.topicService = topicService;
        this.subjectService = subjectService;
        this.objectMapper = objectMapper;
    }

    @Transactional(readOnly = true)
    public QuizResponse getQuizForTopic(UUID topicId) {
        return getQuizForTopic(topicId, null);
    }

    @Transactional(readOnly = true)
    public QuizResponse getQuizForTopic(UUID topicId, UUID subjectId) {
        var topic = topicService.requireActiveTopic(topicId);
        if (subjectId != null) {
            var subject = subjectService.requireActiveSubject(subjectId);
            if (!topic.getSubject().getId().equals(subject.getId())) {
                throw new ApiException(
                        ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                        ErrorCode.VALIDATION_FAILED.name(),
                        "Request validation failed",
                        java.util.Map.of("subjectId", "does not match topic's subject"));
            }
        }
        Quiz quiz = quizRepository.findFirstByTopicIdAndActiveTrueOrderByCreatedAtAscIdAsc(topic.getId())
                .orElseThrow(() -> new ApiException(
                        ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                        ErrorCode.RESOURCE_NOT_FOUND.name(),
                        "Quiz not found"));
        return toResponse(quiz);
    }

    private QuizResponse toResponse(Quiz quiz) {
        List<QuizQuestionResponse> questions = quizQuestionRepository
                .findByQuizIdOrderByQuestionOrderAsc(quiz.getId()).stream()
                .map(this::toQuestionResponse)
                .toList();
        return new QuizResponse(
                quiz.getId(),
                quiz.getTopic().getId(),
                quiz.getTitle(),
                quiz.getDescription(),
                quiz.getDifficulty().name(),
                quiz.getTimeLimitSeconds(),
                questions.size(),
                questions);
    }

    private QuizQuestionResponse toQuestionResponse(QuizQuestion association) {
        var question = association.getQuestion();
        return new QuizQuestionResponse(
                question.getId(),
                question.getQuestionText(),
                parseOptions(question.getOptionsJson()),
                question.getDifficulty().name());
    }

    /**
     * options_json stores {"options":[...]} (content validated before
     * persistence). A malformed document degrades to an empty option list.
     */
    private List<String> parseOptions(String optionsJson) {
        if (optionsJson == null || optionsJson.isBlank()) {
            return List.of();
        }
        try {
            JsonNode node = objectMapper.readTree(optionsJson).path("options");
            return objectMapper.convertValue(node,
                    objectMapper.getTypeFactory().constructCollectionType(List.class, String.class));
        } catch (Exception malformedContent) {
            return List.of();
        }
    }
}
