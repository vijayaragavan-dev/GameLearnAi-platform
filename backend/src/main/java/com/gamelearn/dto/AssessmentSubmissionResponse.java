package com.gamelearn.dto;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * ASMT-002 response (API Contract v1.2.0 section 5B). Returned on 201 after
 * the atomic baseline creation commits.
 */
public record AssessmentSubmissionResponse(
        UUID subjectId,
        BigDecimal score,
        BigDecimal overallMastery,
        List<AssessmentTopicBaseline> topics) {
}
