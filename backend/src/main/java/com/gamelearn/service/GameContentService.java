package com.gamelearn.service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamelearn.dto.GameContentItem;
import com.gamelearn.dto.GameContentResponse;
import com.gamelearn.entity.Question;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.gamification.GameContentKind;
import com.gamelearn.repository.LessonRepository;
import com.gamelearn.repository.QuestionRepository;
import com.gamelearn.repository.TopicRepository;

/**
 * Authoritative subject-scoped and global game content (Batch 2, Phases
 * 4-5).
 *
 * <p>Subject mode filters in the database by subject (and optionally topic
 * and difficulty) so unrelated subjects can never leak in; a topic that
 * does not belong to the requested subject is rejected instead of
 * silently serving another subject's content. Global arena mode
 * intentionally mixes subjects with a deterministic round-robin over the
 * supported mappings, and every item still carries its subject identity.
 *
 * <p>No content is fabricated: QUESTION items come from active MCQ rows
 * (options only — correct answers and explanations are never exposed),
 * CONCEPT definitions resolve server-side with lesson-summary first, then
 * lesson content, then topic description (never an arbitrary option
 * field), and STRUCTURE items expose real topic metadata.
 */
@Service
public class GameContentService {

    private static final int DEFAULT_LIMIT = 20;
    private static final int MAX_LIMIT = 50;

    private final GameCompatibilityService compatibilityService;
    private final SubjectService subjectService;
    private final TopicService topicService;
    private final QuestionRepository questionRepository;
    private final TopicRepository topicRepository;
    private final LessonRepository lessonRepository;
    private final ObjectMapper objectMapper;

    public GameContentService(GameCompatibilityService compatibilityService,
                              SubjectService subjectService,
                              TopicService topicService,
                              QuestionRepository questionRepository,
                              TopicRepository topicRepository,
                              LessonRepository lessonRepository,
                              ObjectMapper objectMapper) {
        this.compatibilityService = compatibilityService;
        this.subjectService = subjectService;
        this.topicService = topicService;
        this.questionRepository = questionRepository;
        this.topicRepository = topicRepository;
        this.lessonRepository = lessonRepository;
        this.objectMapper = objectMapper;
    }

    @Transactional(readOnly = true)
    public GameContentResponse subjectContent(UUID subjectId, UUID topicId, String gameType,
                                              String difficultyParam, Integer limitParam) {
        compatibilityService.requireValidGameType(gameType);
        var subject = subjectService.requireActiveSubject(subjectId);
        compatibilityService.requireSupported(subject.getId(), gameType);
        Topic topic = resolveTopicInSubject(topicId, subject.getId());
        Difficulty difficulty = parseDifficulty(difficultyParam);
        int limit = resolveLimit(limitParam);

        List<GameContentItem> items = switch (GameContentKind.forGameType(gameType)) {
            case QUESTION -> questionRepository
                    .findActiveMcqForGame(subject.getId(), topicId, difficulty).stream()
                    .limit(limit)
                    .map(q -> toQuestionItem(q, gameType))
                    .toList();
            case CONCEPT -> topicRepository
                    .findActiveForGame(subject.getId(), topicId, difficulty).stream()
                    .limit(limit)
                    .map(t -> toConceptItem(t, gameType))
                    .toList();
            case STRUCTURE -> topicRepository
                    .findActiveForGame(subject.getId(), topicId, difficulty).stream()
                    .limit(limit)
                    .map(t -> toStructureItem(t, gameType))
                    .toList();
        };
        if (items.isEmpty()) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                    ErrorCode.RESOURCE_NOT_FOUND.name(), "No game content found");
        }
        if (topic != null) {
            // Touch inside the transaction so a stale proxy cannot surface later.
            topic.getName();
        }
        return new GameContentResponse("SUBJECT", subject.getId(), items);
    }

    @Transactional(readOnly = true)
    public GameContentResponse globalContent(String gameType, String difficultyParam, Integer limitParam) {
        compatibilityService.requireValidGameType(gameType);
        Difficulty difficulty = parseDifficulty(difficultyParam);
        int limit = resolveLimit(limitParam);

        List<GameContentItem> items = switch (GameContentKind.forGameType(gameType)) {
            case QUESTION -> roundRobin(
                    questionRepository.findActiveMcqForGlobalArena(difficulty).stream()
                            .limit(1000)
                            .map(q -> toQuestionItem(q, gameType))
                            .toList(),
                    limit);
            case CONCEPT -> roundRobin(
                    topicRepository.findAllActiveOrderedForArena().stream()
                            .filter(t -> difficulty == null || t.getDifficulty() == difficulty)
                            .limit(1000)
                            .map(t -> toConceptItem(t, gameType))
                            .toList(),
                    limit);
            case STRUCTURE -> roundRobin(
                    topicRepository.findAllActiveOrderedForArena().stream()
                            .filter(t -> difficulty == null || t.getDifficulty() == difficulty)
                            .limit(1000)
                            .map(t -> toStructureItem(t, gameType))
                            .toList(),
                    limit);
        };
        if (items.isEmpty()) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                    ErrorCode.RESOURCE_NOT_FOUND.name(), "No game content found");
        }
        return new GameContentResponse("GLOBAL", null, items);
    }

    private Topic resolveTopicInSubject(UUID topicId, UUID subjectId) {
        if (topicId == null) {
            return null;
        }
        Topic topic = topicService.requireActiveTopic(topicId);
        if (!topic.getSubject().getId().equals(subjectId)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                    ErrorCode.VALIDATION_FAILED.name(), "Request validation failed",
                    Map.of("subjectId", "does not match topic's subject"));
        }
        return topic;
    }

    private Difficulty parseDifficulty(String difficultyParam) {
        if (difficultyParam == null || difficultyParam.isBlank()) {
            return null;
        }
        try {
            return Difficulty.valueOf(difficultyParam.trim().toUpperCase());
        } catch (IllegalArgumentException unknown) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                    ErrorCode.VALIDATION_FAILED.name(), "Request validation failed",
                    Map.of("difficulty", "must be one of EASY, MEDIUM, HARD"));
        }
    }

    private int resolveLimit(Integer limitParam) {
        if (limitParam == null) {
            return DEFAULT_LIMIT;
        }
        if (limitParam < 1 || limitParam > MAX_LIMIT) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                    ErrorCode.VALIDATION_FAILED.name(), "Request validation failed",
                    Map.of("limit", "must be between 1 and 50"));
        }
        return limitParam;
    }

    /**
     * Deterministic cross-subject mix: groups preserve the database order
     * (subject display order first) and rounds take one item per subject,
     * so a limit of two or more spans multiple subjects whenever more than
     * one subject has content. No randomness involved.
     */
    private List<GameContentItem> roundRobin(List<GameContentItem> ordered, int limit) {
        Map<UUID, List<GameContentItem>> bySubject = new LinkedHashMap<>();
        for (GameContentItem item : ordered) {
            bySubject.computeIfAbsent(item.subjectId(), key -> new ArrayList<>()).add(item);
        }
        List<GameContentItem> mixed = new ArrayList<>(Math.min(limit, ordered.size()));
        boolean progress = true;
        while (mixed.size() < limit && progress) {
            progress = false;
            for (List<GameContentItem> group : bySubject.values()) {
                if (!group.isEmpty() && mixed.size() < limit) {
                    mixed.add(group.remove(0));
                    progress = true;
                }
            }
        }
        return mixed;
    }

    private GameContentItem toQuestionItem(Question question, String gameType) {
        Topic topic = question.getTopic();
        return new GameContentItem(GameContentKind.QUESTION.name(), question.getId(),
                topic.getSubject().getId(), topic.getSubject().getName(), topic.getId(),
                topic.getName(), topic.getUnit() == null ? null : topic.getUnit().getId(), gameType,
                question.getDifficulty().name(), question.getQuestionText(),
                parseOptions(question.getOptionsJson()), null);
    }

    private GameContentItem toConceptItem(Topic topic, String gameType) {
        return new GameContentItem(GameContentKind.CONCEPT.name(), topic.getId(),
                topic.getSubject().getId(), topic.getSubject().getName(), topic.getId(),
                topic.getName(), topic.getUnit() == null ? null : topic.getUnit().getId(), gameType,
                topic.getDifficulty().name(), null, null, resolveDefinition(topic));
    }

    private GameContentItem toStructureItem(Topic topic, String gameType) {
        return new GameContentItem(GameContentKind.STRUCTURE.name(), topic.getId(),
                topic.getSubject().getId(), topic.getSubject().getName(), topic.getId(),
                topic.getName(), topic.getUnit() == null ? null : topic.getUnit().getId(), gameType,
                topic.getDifficulty().name(), null, null, null);
    }

    /**
     * Authoritative definition priority: canonical lesson summary, then the
     * opening of the canonical lesson content, then the topic description.
     * Never an arbitrary question option (Gate 8 integrity lesson).
     */
    private String resolveDefinition(Topic topic) {
        var lesson = lessonRepository
                .findFirstByTopicIdAndActiveTrueOrderByCreatedAtAscIdAsc(topic.getId());
        if (lesson.isPresent()) {
            String summary = lesson.get().getSummary();
            if (summary != null && !summary.isBlank()) {
                return truncate(summary.trim(), 1000);
            }
            String content = lesson.get().getContent();
            if (content != null && !content.isBlank()) {
                return truncate(firstSentences(content.trim(), 2), 1000);
            }
        }
        if (topic.getDescription() != null && !topic.getDescription().isBlank()) {
            return truncate(firstSentences(topic.getDescription().trim(), 2), 1000);
        }
        return topic.getName();
    }

    private String firstSentences(String text, int maxSentences) {
        String[] parts = text.split("(?<=\\.)\\s+");
        StringBuilder joined = new StringBuilder();
        for (int i = 0; i < Math.min(maxSentences, parts.length); i++) {
            if (i > 0) {
                joined.append(' ');
            }
            joined.append(parts[i].trim());
        }
        return joined.toString();
    }

    private String truncate(String text, int maxLength) {
        return text.length() <= maxLength ? text : text.substring(0, maxLength);
    }

    private List<String> parseOptions(String optionsJson) {
        if (optionsJson == null || optionsJson.isBlank()) {
            return List.of();
        }
        try {
            JsonNode root = objectMapper.readTree(optionsJson);
            // Some databases return a seeded JSON document double-encoded as a
            // JSON string literal; unwrap once so seeded rows parse identically
            // to rows written through JPA on every database.
            if (root.isTextual()) {
                root = objectMapper.readTree(root.asText());
            }
            JsonNode node = root.path("options");
            List<String> options = objectMapper.convertValue(node,
                    objectMapper.getTypeFactory().constructCollectionType(List.class, String.class));
            return options == null ? List.of() : options;
        } catch (Exception malformedContent) {
            return List.of();
        }
    }
}
