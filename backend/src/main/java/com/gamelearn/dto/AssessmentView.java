package com.gamelearn.dto;

import java.util.List;

/**
 * Dashboard section 9 (Dashboard Specification section 8.9, decision D3):
 * placement-state visibility. A subject appears once ANY baseline lineage
 * exists for it (exact R-GUARD criterion, Assessment Specification section
 * 11.4(a)); no scores, answers or assessment internals are exposed.
 */
public record AssessmentView(
        List<AssessedSubjectItem> assessedSubjects) {
}
