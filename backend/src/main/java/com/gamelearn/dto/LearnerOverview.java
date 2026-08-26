package com.gamelearn.dto;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Dashboard section 1 (Dashboard Specification section 8.1): identity
 * greeting + headline mastery + resume pointers. Email, password hash and
 * account status are deliberately NOT exposed.
 *
 * @param displayName      users.display_name verbatim
 * @param overallMastery   learner_profiles.overall_mastery verbatim (Adaptive/Assessment-owned)
 * @param currentSubjectId learner_profiles.current_subject_id; null until first quiz or assessment
 * @param currentTopicId   learner_profiles.current_topic_id; null until first processed quiz
 */
public record LearnerOverview(
        String displayName,
        BigDecimal overallMastery,
        UUID currentSubjectId,
        UUID currentTopicId) {
}
