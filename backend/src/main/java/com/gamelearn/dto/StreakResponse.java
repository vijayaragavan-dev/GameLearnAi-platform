package com.gamelearn.dto;

import java.time.LocalDate;

/**
 * GAM-003 response (API Contract v1.1.0 section 5A.1). Zero-state learners
 * report null lastLearningDate and the v1 fixed "UTC" timezone.
 */
public record StreakResponse(
        int currentStreakDays,
        int longestStreakDays,
        LocalDate lastLearningDate,
        String timezone) {
}
