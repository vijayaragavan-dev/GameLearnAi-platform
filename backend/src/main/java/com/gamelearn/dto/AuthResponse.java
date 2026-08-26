package com.gamelearn.dto;

import java.util.UUID;

/**
 * Authentication response for register/login/validate. Contains the access
 * token and a safe view of the user; never the password hash or any
 * internal security field.
 */
public record AuthResponse(
        String token,
        String tokenType,
        long expiresInSeconds,
        UserView user) {

    /**
     * Safe public view of the authenticated user.
     */
    public record UserView(UUID id, String email, String displayName) {
    }
}
