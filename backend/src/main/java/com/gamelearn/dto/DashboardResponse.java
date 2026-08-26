package com.gamelearn.dto;

import java.util.List;

/**
 * DASH-001 response (API Contract v1.3.0 section 5C; Dashboard Specification
 * v1.0.0 section 8). Plain-DTO read model over the authenticated learner's
 * own persisted state. All ten top-level sections are ALWAYS serialized;
 * absent optional data is expressed as null/[] — never a missing key and
 * never an error. Read-only: composing this response performs zero writes,
 * zero AI calls and zero domain mutations.
 */
public record DashboardResponse(
        LearnerOverview learner,
        CurrentSubjectView currentSubject,
        MasterySummary mastery,
        GamificationView gamification,
        StreakResponse streak,
        AchievementsView achievements,
        List<RecommendationItem> recommendations,
        LearningPathCard learningPath,
        AssessmentView assessment,
        RecentActivityView recentActivity) {
}
