package com.gamelearn.dto;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record AvatarCollectionItem(
        String id,
        String code,
        String displayName,
        String description,
        String assetKey,
        String rarity,
        Integer creditCost,
        boolean isActive,
        int displayOrder,
        boolean owned,
        boolean equipped,
        String state,
        boolean eligible,
        Integer creditsRequired,
        Integer creditsAvailable,
        Integer creditsShort,
        List<RequirementCheck> requirements
) {
    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record RequirementCheck(
            String type,
            Object required,
            Object current,
            boolean satisfied
    ) {}
}
