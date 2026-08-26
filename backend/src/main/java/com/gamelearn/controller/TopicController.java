package com.gamelearn.controller;

import java.util.UUID;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.gamelearn.dto.TopicResponse;
import com.gamelearn.service.TopicService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;

/**
 * TOPIC-001: topic details. (The approved matrix groups topics with the
 * learning-path domain; the external contract is unchanged.)
 */
@RestController
@RequestMapping("/api/v1/topics")
@Tag(name = "Topics", description = "Topic details")
@SecurityRequirement(name = "bearerAuth")
public class TopicController {

    private final TopicService topicService;

    public TopicController(TopicService topicService) {
        this.topicService = topicService;
    }

    @Operation(summary = "Get a single active topic")
    @GetMapping("/{topicId}")
    public TopicResponse getTopic(@PathVariable UUID topicId) {
        return topicService.getActiveTopic(topicId);
    }
}
