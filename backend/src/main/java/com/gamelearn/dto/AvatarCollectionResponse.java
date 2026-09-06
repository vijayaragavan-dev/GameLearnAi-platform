package com.gamelearn.dto;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record AvatarCollectionResponse(
        int creditsAvailable,
        String equippedAvatarId,
        AvatarCatalogItem equippedAvatar,
        List<AvatarCollectionItem> items
) {}
