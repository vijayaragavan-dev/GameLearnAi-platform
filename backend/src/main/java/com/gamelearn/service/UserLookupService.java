package com.gamelearn.service;

import java.util.UUID;

import org.springframework.stereotype.Service;

import com.gamelearn.auth.AuthenticatedUser;
import com.gamelearn.entity.User;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.repository.UserRepository;

/**
 * Resolves the authenticated principal to a managed {@link User} entity.
 * Centralised so every controller follows the same approved principal
 * resolution and the same safe-error mapping (never exposes the row id to
 * the client). Trust boundary: the caller MUST come from the SecurityContext
 * — no controller-supplied user identifier is ever honoured here.
 */
@Service
public class UserLookupService {

    private final UserRepository userRepository;

    public UserLookupService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    /**
     * Returns the user row for the authenticated principal. Throws
     * 401 if the principal is missing and 500 if the database invariant is
     * violated (a user row that the authentication filter accepted must
     * still exist).
     */
    public User requireUser(AuthenticatedUser principal) {
        if (principal == null) {
            throw new ApiException(
                    ErrorCode.UNAUTHORIZED.getHttpStatus(),
                    ErrorCode.UNAUTHORIZED.name(),
                    "Authentication required");
        }
        UUID id = principal.id();
        return userRepository.findById(id).orElseThrow(() -> new ApiException(
                ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                ErrorCode.INTERNAL_ERROR.name(),
                "Authenticated user not found"));
    }
}
