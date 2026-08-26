package com.gamelearn.controller;

import java.util.UUID;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.gamelearn.dto.LessonResponse;
import com.gamelearn.service.LessonService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;

/**
 * LESSON-001: canonical lesson of a topic.
 */
@RestController
@RequestMapping("/api/v1/topics")
@Tag(name = "Lessons", description = "Lesson content")
@SecurityRequirement(name = "bearerAuth")
public class LessonController {

    private final LessonService lessonService;

    public LessonController(LessonService lessonService) {
        this.lessonService = lessonService;
    }

    @Operation(summary = "Get the active lesson of a topic")
    @GetMapping("/{topicId}/lesson")
    public LessonResponse getLesson(@PathVariable UUID topicId) {
        return lessonService.getCanonicalLesson(topicId);
    }
}
