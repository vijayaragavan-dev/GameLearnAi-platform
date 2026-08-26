package com.gamelearn.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.dto.SubjectResponse;
import com.gamelearn.entity.Subject;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.repository.SubjectRepository;

/**
 * Subject catalogue (SUBJ-001). Only active subjects are visible to
 * learners, ordered by display order.
 */
@Service
public class SubjectService {

    private final SubjectRepository subjectRepository;

    public SubjectService(SubjectRepository subjectRepository) {
        this.subjectRepository = subjectRepository;
    }

    @Transactional(readOnly = true)
    public List<SubjectResponse> listActiveSubjects() {
        return subjectRepository.findByActiveTrueOrderByDisplayOrderAscIdAsc().stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public Subject requireActiveSubject(java.util.UUID subjectId) {
        Subject subject = subjectRepository.findById(subjectId)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                        ErrorCode.RESOURCE_NOT_FOUND.name(),
                        "Subject not found"));
        if (!subject.isActive()) {
            throw new ApiException(
                    ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                    ErrorCode.RESOURCE_NOT_FOUND.name(),
                    "Subject not found");
        }
        return subject;
    }

    private SubjectResponse toResponse(Subject subject) {
        return new SubjectResponse(subject.getId(), subject.getName(), subject.getDescription(),
                subject.getIconKey(), subject.isActive(), subject.getDisplayOrder());
    }
}
