package com.gamelearn.dto;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Authenticated learner's own profile view (USER-001). Contains only
 * learner-safe data; system/security fields such as account status and
 * password hash are never exposed.
 */
public record UserResponse(
        UUID id,
        String email,
        String displayName,
        int currentLevel,
        int totalXp,
        BigDecimal overallMastery,
        UUID currentSubjectId,
        UUID currentTopicId) {
}
