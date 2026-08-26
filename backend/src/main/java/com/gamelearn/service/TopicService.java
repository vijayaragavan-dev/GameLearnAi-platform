package com.gamelearn.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.dto.TopicResponse;
import com.gamelearn.entity.Topic;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.repository.TopicRepository;

/**
 * Topic retrieval (TOPIC-001). Inactive topics are hidden from learners.
 */
@Service
public class TopicService {

    private final TopicRepository topicRepository;

    public TopicService(TopicRepository topicRepository) {
        this.topicRepository = topicRepository;
    }

    @Transactional(readOnly = true)
    public TopicResponse getActiveTopic(java.util.UUID topicId) {
        return toResponse(requireActiveTopic(topicId));
    }

    @Transactional(readOnly = true)
    public com.gamelearn.entity.Topic requireActiveTopic(java.util.UUID topicId) {
        return topicRepository.findById(topicId)
                .filter(Topic::isActive)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                        ErrorCode.RESOURCE_NOT_FOUND.name(),
                        "Topic not found"));
    }

    private TopicResponse toResponse(Topic topic) {
        return new TopicResponse(
                topic.getId(),
                topic.getSubject().getId(),
                topic.getSubject().getName(),
                topic.getName(),
                topic.getDescription(),
                topic.getDifficulty().name(),
                topic.getDisplayOrder());
    }
}
