package com.gamelearn.auth;

import java.util.List;
import java.util.UUID;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

/**
 * Trusted identity of an authenticated user, resolved from a validated
 * token AND confirmed against the database by the authentication filter.
 * Services must take the caller identity from here (SecurityContext),
 * never from request parameters.
 */
public record AuthenticatedUser(
        UUID id,
        String email,
        String displayName) implements UserDetails {

    @Override
    public java.util.Collection<? extends GrantedAuthority> getAuthorities() {
        // Phase 2 has no approved role model; every authenticated principal is equal.
        return List.of();
    }

    @Override
    public String getPassword() {
        // Never expose the password hash through the security context.
        return null;
    }

    @Override
    public String getUsername() {
        return email;
    }
}
