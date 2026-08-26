package com.gamelearn.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.gamelearn.dto.SubjectResponse;
import com.gamelearn.service.SubjectService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;

/**
 * SUBJ-001: subject catalogue.
 */
@RestController
@RequestMapping("/api/v1/subjects")
@Tag(name = "Subjects", description = "Learning subject catalogue")
@SecurityRequirement(name = "bearerAuth")
public class SubjectController {

    private final SubjectService subjectService;

    public SubjectController(SubjectService subjectService) {
        this.subjectService = subjectService;
    }

    @Operation(summary = "List active subjects",
            description = "Returns all active subjects ordered by display order.")
    @GetMapping
    public List<SubjectResponse> listSubjects() {
        return subjectService.listActiveSubjects();
    }
}
