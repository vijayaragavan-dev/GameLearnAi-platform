package com.gamelearn.dto;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record LeaderboardPositionResponse(
        String segment,
        String subjectId,
        int rank,
        int totalXp,
        Integer subjectXp,
        int level,
        Integer xpToNextRank,
        Integer nextRank,
        Integer nextRankXp,
        int totalPlayers,
        LeaderboardEntry.AvatarInfo avatar,
        List<LeaderboardEntry> top
) {}
