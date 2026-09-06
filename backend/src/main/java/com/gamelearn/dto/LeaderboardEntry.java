package com.gamelearn.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record LeaderboardEntry(
        int rank,
        String displayName,
        AvatarInfo avatar,
        int level,
        int totalXp,
        Integer subjectXp,
        Integer streakDays,
        Double mastery,
        Boolean isMe,
        Integer rankDelta
) {
    public record AvatarInfo(String assetKey, String rarity) {}
}
