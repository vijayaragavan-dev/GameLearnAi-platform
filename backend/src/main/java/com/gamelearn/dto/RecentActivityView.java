package com.gamelearn.dto;

import java.util.List;

/**
 * Dashboard section 10 (Dashboard Specification section 8.10, decision D2):
 * single-source recent activity — COMPLETED quiz attempts ONLY. No unified
 * cross-domain feed is built (explicit non-invention ruling, section 10.7).
 */
public record RecentActivityView(
        List<RecentQuizItem> quizzes) {
}
