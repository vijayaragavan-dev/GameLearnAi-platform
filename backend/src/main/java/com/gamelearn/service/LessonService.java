package com.gamelearn.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.dto.LessonResponse;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.repository.LessonRepository;
import com.gamelearn.repository.TopicRepository;

/**
 * Lesson retrieval (LESSON-001). Returns the canonical active lesson of a
 * topic: the oldest active lesson, with the id as a deterministic tie-break.
 */
@Service
public class LessonService {

    private final TopicRepository topicRepository;
    private final LessonRepository lessonRepository;

    public LessonService(TopicRepository topicRepository, LessonRepository lessonRepository) {
        this.topicRepository = topicRepository;
        this.lessonRepository = lessonRepository;
    }

    @Transactional(readOnly = true)
    public LessonResponse getCanonicalLesson(java.util.UUID topicId) {
        var topic = topicRepository.findById(topicId)
                .filter(t -> t.isActive())
                .orElseThrow(() -> new ApiException(
                        ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                        ErrorCode.RESOURCE_NOT_FOUND.name(),
                        "Topic not found"));

        return lessonRepository
                .findFirstByTopicIdAndActiveTrueOrderByCreatedAtAscIdAsc(topic.getId())
                .map(lesson -> new LessonResponse(
                        lesson.getId(),
                        topicId,
                        lesson.getTitle(),
                        lesson.getContent(),
                        lesson.getSummary(),
                        lesson.getDifficulty().name(),
                        lesson.getSourceType().name()))
                .orElseThrow(() -> new ApiException(
                        ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                        ErrorCode.RESOURCE_NOT_FOUND.name(),
                        "Lesson not found"));
    }
}
