package com.gamelearn.dto;

import java.util.List;
import java.util.UUID;

/**
 * ASMT-001 response (API Contract v1.2.0 section 5B). Deterministic,
 * read-only delivery of the subject placement set.
 */
public record AssessmentDeliveryResponse(
        UUID subjectId,
        List<AssessmentQuestion> questions) {
}
