package com.gamelearn.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record AvatarCatalogItem(
        String id,
        String code,
        String displayName,
        String description,
        String assetKey,
        String rarity,
        Integer creditCost,
        boolean isActive,
        int displayOrder,
        RequirementInfo requirement
) {
    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record RequirementInfo(
            Integer levelMin,
            Double syllabusCompletionMin,
            String syllabusSubjectId,
            Integer streakCurrentMin,
            Integer streakLongestMin,
            Integer bossBattlesMin,
            Integer masteredCountMin
    ) {}
}
