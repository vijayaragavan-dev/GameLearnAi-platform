package com.gamelearn.service;

import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.dto.UserResponse;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.repository.LearnerProfileRepository;

/**
 * Learner profile retrieval (USER-001). The profile of the authenticated
 * learner only; protected system fields (XP/level/mastery) are readable but
 * can never be modified through this API.
 */
@Service
public class ProfileService {

    private final LearnerProfileRepository learnerProfileRepository;
    private final com.gamelearn.repository.UserRepository userRepository;

    public ProfileService(LearnerProfileRepository learnerProfileRepository,
                          com.gamelearn.repository.UserRepository userRepository) {
        this.learnerProfileRepository = learnerProfileRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public UserResponse getOwnProfile(UUID authenticatedUserId) {
        var user = userRepository.findById(authenticatedUserId)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                        ErrorCode.RESOURCE_NOT_FOUND.name(),
                        "Profile not found"));
        var profile = learnerProfileRepository.findByUserId(authenticatedUserId)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                        ErrorCode.RESOURCE_NOT_FOUND.name(),
                        "Profile not found"));

        return new UserResponse(
                user.getId(),
                user.getEmail(),
                user.getDisplayName(),
                profile.getCurrentLevel(),
                profile.getTotalXp(),
                profile.getOverallMastery(),
                profile.getCurrentSubject() != null ? profile.getCurrentSubject().getId() : null,
                profile.getCurrentTopic() != null ? profile.getCurrentTopic().getId() : null);
    }
}
