package com.gamelearn.service;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.entity.Avatar;
import com.gamelearn.entity.LearnerProfile;
import com.gamelearn.entity.User;
import com.gamelearn.entity.UserAvatar;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.repository.AvatarRepository;
import com.gamelearn.repository.LearnerProfileRepository;
import com.gamelearn.repository.UserAvatarRepository;
import com.gamelearn.repository.UserRepository;

/**
 * Avatar domain (Phase L1) — catalog + ownership + equipped + requirement gates.
 * Server-authoritative; no REST yet (L2). Purchase/claim logic is transactional
 * and guards against TOCTOU via pessimistic lock on user_credits and unique
 * constraint on user_avatars.
 */
@Service
public class AvatarService {

    private final AvatarRepository avatarRepository;
    private final UserAvatarRepository userAvatarRepository;
    private final UserRepository userRepository;
    private final LearnerProfileRepository learnerProfileRepository;
    private final CreditService creditService;
    private final AvatarRequirementEvaluator requirementEvaluator;

    public AvatarService(AvatarRepository avatarRepository,
                         UserAvatarRepository userAvatarRepository,
                         UserRepository userRepository,
                         LearnerProfileRepository learnerProfileRepository,
                         CreditService creditService,
                         AvatarRequirementEvaluator requirementEvaluator) {
        this.avatarRepository = avatarRepository;
        this.userAvatarRepository = userAvatarRepository;
        this.userRepository = userRepository;
        this.learnerProfileRepository = learnerProfileRepository;
        this.creditService = creditService;
        this.requirementEvaluator = requirementEvaluator;
    }

    @Transactional(readOnly = true)
    public List<Avatar> catalog(boolean includeInactive) {
        if (includeInactive) {
            return avatarRepository.findAllByOrderByDisplayOrderAscIdAsc();
        }
        return avatarRepository.findByActiveTrueOrderByDisplayOrderAscIdAsc();
    }

    @Transactional(readOnly = true)
    public Avatar getOrThrow(UUID avatarId) {
        return avatarRepository.findById(avatarId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                        ErrorCode.RESOURCE_NOT_FOUND.name(), "Avatar not found"));
    }

    @Transactional(readOnly = true)
    public List<UserAvatar> owned(UUID userId) {
        return userAvatarRepository.findByUserId(userId);
    }

    @Transactional(readOnly = true)
    public boolean isOwned(UUID userId, UUID avatarId) {
        return userAvatarRepository.existsByUserIdAndAvatarId(userId, avatarId);
    }

    /**
     * Purchase a credit-cost avatar. Validates active, owned, requirement, and balance
     * under lock, inserts ownership, deducts credits — all atomically.
     */
    @Transactional
    public UserAvatar purchase(UUID userId, UUID avatarId) {
        Avatar avatar = getOrThrow(avatarId);
        if (!avatar.isActive()) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                    ErrorCode.RESOURCE_NOT_FOUND.name(), "Avatar not available");
        }
        if (avatar.getCreditCost() == null) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                    ErrorCode.VALIDATION_FAILED.name(), "Avatar is not purchasable");
        }
        if (userAvatarRepository.existsByUserIdAndAvatarId(userId, avatarId)) {
            throw new ApiException(ErrorCode.AVATAR_ALREADY_OWNED.getHttpStatus(),
                    ErrorCode.AVATAR_ALREADY_OWNED.name(), "Avatar already owned");
        }
        var eval = requirementEvaluator.evaluate(userId, avatar);
        if (!eval.eligible()) {
            throw new ApiException(ErrorCode.AVATAR_REQUIREMENTS_NOT_MET.getHttpStatus(),
                    ErrorCode.AVATAR_REQUIREMENTS_NOT_MET.name(), "Avatar requirements not met");
        }
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.UNAUTHORIZED.getHttpStatus(),
                        ErrorCode.UNAUTHORIZED.name(), "User not found"));

        // deduct credits under lock
        creditService.spend(user, avatar.getCreditCost(), avatarId);

        UserAvatar ua = new UserAvatar();
        ua.setUser(user);
        ua.setAvatar(avatar);
        ua.setAcquiredAt(Instant.now());
        ua.setAcquisitionType("PURCHASED");
        try {
            return userAvatarRepository.save(ua);
        } catch (DataIntegrityViolationException e) {
            // concurrent purchase winner already inserted
            throw new ApiException(ErrorCode.AVATAR_ALREADY_OWNED.getHttpStatus(),
                    ErrorCode.AVATAR_ALREADY_OWNED.name(), "Avatar already owned");
        }
    }

    /**
     * Claim a threshold avatar (no credits). Same ownership guards, no spend.
     */
    @Transactional
    public UserAvatar claim(UUID userId, UUID avatarId) {
        Avatar avatar = getOrThrow(avatarId);
        if (!avatar.isActive()) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                    ErrorCode.RESOURCE_NOT_FOUND.name(), "Avatar not available");
        }
        if (avatar.getCreditCost() != null) {
            throw new ApiException(ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                    ErrorCode.VALIDATION_FAILED.name(), "Avatar must be purchased, not claimed");
        }
        if (userAvatarRepository.existsByUserIdAndAvatarId(userId, avatarId)) {
            throw new ApiException(ErrorCode.AVATAR_ALREADY_OWNED.getHttpStatus(),
                    ErrorCode.AVATAR_ALREADY_OWNED.name(), "Avatar already owned");
        }
        var eval = requirementEvaluator.evaluate(userId, avatar);
        if (!eval.eligible()) {
            throw new ApiException(ErrorCode.AVATAR_REQUIREMENTS_NOT_MET.getHttpStatus(),
                    ErrorCode.AVATAR_REQUIREMENTS_NOT_MET.name(), "Avatar requirements not met");
        }
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.UNAUTHORIZED.getHttpStatus(),
                        ErrorCode.UNAUTHORIZED.name(), "User not found"));
        UserAvatar ua = new UserAvatar();
        ua.setUser(user);
        ua.setAvatar(avatar);
        ua.setAcquiredAt(Instant.now());
        ua.setAcquisitionType("THRESHOLD_CLAIM");
        try {
            return userAvatarRepository.save(ua);
        } catch (DataIntegrityViolationException e) {
            throw new ApiException(ErrorCode.AVATAR_ALREADY_OWNED.getHttpStatus(),
                    ErrorCode.AVATAR_ALREADY_OWNED.name(), "Avatar already owned");
        }
    }

    /**
     * Equip avatar (or null to reset to default). Validates ownership.
     */
    @Transactional
    public LearnerProfile equip(UUID userId, UUID avatarId) {
        LearnerProfile profile = learnerProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                        ErrorCode.RESOURCE_NOT_FOUND.name(), "Learner profile not found"));
        if (avatarId == null) {
            profile.setEquippedAvatar(null);
            return learnerProfileRepository.save(profile);
        }
        if (!userAvatarRepository.existsByUserIdAndAvatarId(userId, avatarId)) {
            throw new ApiException(ErrorCode.AVATAR_NOT_OWNED.getHttpStatus(),
                    ErrorCode.AVATAR_NOT_OWNED.name(), "Avatar not owned");
        }
        Avatar avatar = getOrThrow(avatarId);
        profile.setEquippedAvatar(avatar);
        return learnerProfileRepository.save(profile);
    }
}
