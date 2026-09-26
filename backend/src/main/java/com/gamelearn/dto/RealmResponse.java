package com.gamelearn.dto;

import java.util.UUID;

/**
 * Public learning-realm view (REALM-001). Only active realms are listed;
 * inactive or unknown keys resolve to 404 through the service layer.
 */
public record RealmResponse(
        UUID id,
        String realmKey,
        String name,
        String description,
        String iconKey,
        boolean isActive,
        int displayOrder) {
}
