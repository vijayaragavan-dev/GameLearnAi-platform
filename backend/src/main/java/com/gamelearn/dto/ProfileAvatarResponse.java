package com.gamelearn.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ProfileAvatarResponse(
        String equippedAvatarId,
        AvatarCatalogItem avatar
) {}
