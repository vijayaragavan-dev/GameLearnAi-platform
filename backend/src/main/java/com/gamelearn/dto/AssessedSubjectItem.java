package com.gamelearn.dto;

import java.util.UUID;

/**
 * Dashboard section 9 element (Dashboard Specification section 8.9): one
 * subject whose baseline lineage exists for this learner. Ordered by the
 * SUBJ-001 catalog convention (display_order ASC, subject id ASC).
 */
public record AssessedSubjectItem(
        UUID subjectId,
        String subjectName) {
}
