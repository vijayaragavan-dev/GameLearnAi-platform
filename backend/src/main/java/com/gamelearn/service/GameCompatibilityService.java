package com.gamelearn.service;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.dto.SubjectGameEntry;
import com.gamelearn.dto.SubjectGamesResponse;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.gamification.GameContentKind;
import com.gamelearn.gamification.GameType;
import com.gamelearn.repository.QuestionRepository;
import com.gamelearn.repository.SubjectGameCompatRepository;
import com.gamelearn.repository.TopicRepository;

/**
 * Subject/game compatibility authority (Batch 2, Phase 3).
 *
 * <p>Supported combinations come exclusively from
 * {@code subject_game_compat}; absence means unsupported. Availability is
 * truthful: it is computed from the rows that can actually back gameplay
 * (MCQ questions for QUESTION games, active topics for CONCEPT/STRUCTURE
 * games), never assumed.
 */
@Service
public class GameCompatibilityService {

    private final SubjectService subjectService;
    private final SubjectGameCompatRepository compatRepository;
    private final QuestionRepository questionRepository;
    private final TopicRepository topicRepository;

    public GameCompatibilityService(SubjectService subjectService,
                                    SubjectGameCompatRepository compatRepository,
                                    QuestionRepository questionRepository,
                                    TopicRepository topicRepository) {
        this.subjectService = subjectService;
        this.compatRepository = compatRepository;
        this.questionRepository = questionRepository;
        this.topicRepository = topicRepository;
    }

    @Transactional(readOnly = true)
    public SubjectGamesResponse gamesForSubject(UUID subjectId) {
        var subject = subjectService.requireActiveSubject(subjectId);
        List<SubjectGameEntry> games = compatRepository
                .findBySubjectIdAndActiveTrueOrderByDisplayOrderAscIdAsc(subject.getId()).stream()
                .map(row -> {
                    long count = contentCount(subject.getId(), row.getGameType());
                    return new SubjectGameEntry(row.getGameType(), row.getRationale(), count > 0, count);
                })
                .toList();
        return new SubjectGamesResponse(subject.getId(), subject.getName(), games);
    }

    @Transactional(readOnly = true)
    public void requireSupported(UUID subjectId, String gameType) {
        requireValidGameType(gameType);
        var subject = subjectService.requireActiveSubject(subjectId);
        if (!compatRepository.existsBySubjectIdAndGameTypeAndActiveTrue(subject.getId(), gameType)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                    ErrorCode.VALIDATION_FAILED.name(), "Request validation failed",
                    Map.of("gameType", "not supported for this subject"));
        }
    }

    @Transactional(readOnly = true)
    public void requireValidGameType(String gameType) {
        if (!GameType.isValid(gameType)) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                    ErrorCode.VALIDATION_FAILED.name(), "Request validation failed",
                    Map.of("gameType", "must be one of " + String.join(", ", GameType.allIds())));
        }
    }

    private long contentCount(UUID subjectId, String gameType) {
        return switch (GameContentKind.forGameType(gameType)) {
            case QUESTION -> questionRepository.countActiveMcqBySubjectId(subjectId);
            case CONCEPT, STRUCTURE -> topicRepository.countBySubjectIdAndActiveTrue(subjectId);
        };
    }
}
