package com.gamelearn.dto;

import java.time.Instant;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record LeaderboardResponse(
        String segment,
        String season,
        String subjectId,
        String subjectName,
        int page,
        int size,
        int totalPlayers,
        int totalPages,
        List<LeaderboardEntry> top,
        List<LeaderboardEntry> entries,
        LeaderboardEntry me,
        List<LeaderboardEntry> nearby,
        Instant generatedAt,
        Integer cacheTtlSeconds
) {}
