package com.gamelearn.service;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamelearn.dto.AvatarCatalogItem;
import com.gamelearn.dto.AvatarCollectionItem;
import com.gamelearn.dto.AvatarCollectionResponse;
import com.gamelearn.dto.ProfileAvatarResponse;
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
    private final ObjectMapper objectMapper;

    public AvatarService(AvatarRepository avatarRepository,
                         UserAvatarRepository userAvatarRepository,
                         UserRepository userRepository,
                         LearnerProfileRepository learnerProfileRepository,
                         CreditService creditService,
                         AvatarRequirementEvaluator requirementEvaluator,
                         ObjectMapper objectMapper) {
        this.avatarRepository = avatarRepository;
        this.userAvatarRepository = userAvatarRepository;
        this.userRepository = userRepository;
        this.learnerProfileRepository = learnerProfileRepository;
        this.creditService = creditService;
        this.requirementEvaluator = requirementEvaluator;
        this.objectMapper = objectMapper;
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
     * Equip avatar (or null to reset to default). Validates ownership and active status.
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
        if (!avatar.isActive()) {
            throw new ApiException(ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                    ErrorCode.RESOURCE_NOT_FOUND.name(), "Avatar not available");
        }
        profile.setEquippedAvatar(avatar);
        return learnerProfileRepository.save(profile);
    }

    // --- DTO mappings for L3 ---

    @Transactional(readOnly = true)
    public List<AvatarCatalogItem> catalogItems() {
        return catalog(false).stream().map(this::toCatalogItem).toList();
    }

    @Transactional(readOnly = true)
    public AvatarCollectionResponse collection(UUID userId) {
        List<Avatar> catalog = catalog(false);
        var ownedList = owned(userId);
        var ownedIds = new java.util.HashSet<UUID>();
        for (var ua : ownedList) ownedIds.add(ua.getAvatar().getId());
        LearnerProfile profile = learnerProfileRepository.findByUserId(userId).orElse(null);
        UUID equippedId = profile != null && profile.getEquippedAvatar() != null ? profile.getEquippedAvatar().getId() : null;
        int balance = creditService.balance(userId);
        List<AvatarCollectionItem> items = new java.util.ArrayList<>();
        for (Avatar av : catalog) {
            boolean owned = ownedIds.contains(av.getId());
            boolean equipped = av.getId().equals(equippedId);
            var eval = requirementEvaluator.evaluate(userId, av);
            String state;
            boolean eligible = eval.eligible();
            Integer creditsShort = null;
            if (equipped) state = "EQUIPPED";
            else if (owned) state = "OWNED";
            else if (!eligible) state = "LOCKED";
            else if (av.getCreditCost() != null) {
                if (balance >= av.getCreditCost()) state = "PURCHASABLE";
                else {
                    state = "INSUFFICIENT_CREDITS";
                    creditsShort = av.getCreditCost() - balance;
                }
            } else {
                state = "ELIGIBLE_TO_CLAIM";
            }
            List<AvatarCollectionItem.RequirementCheck> checks = eval.checklist().stream()
                    .map(c -> new AvatarCollectionItem.RequirementCheck(c.label(), c.required(), c.current(), c.met()))
                    .toList();
            items.add(new AvatarCollectionItem(
                    av.getId().toString(), av.getCode(), av.getDisplayName(), av.getDescription(),
                    av.getAssetKey(), av.getRarity(), av.getCreditCost(), av.isActive(), av.getDisplayOrder(),
                    owned, equipped, state, eligible,
                    av.getCreditCost(), balance, creditsShort, checks));
        }
        AvatarCatalogItem equippedItem = null;
        if (equippedId != null) {
            Avatar eq = avatarRepository.findById(equippedId).orElse(null);
            if (eq != null) equippedItem = toCatalogItem(eq);
        }
        return new AvatarCollectionResponse(balance, equippedId == null ? null : equippedId.toString(), equippedItem, items);
    }

    @Transactional(readOnly = true)
    public ProfileAvatarResponse profileAvatar(UUID userId) {
        LearnerProfile profile = learnerProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                        ErrorCode.RESOURCE_NOT_FOUND.name(), "Learner profile not found"));
        Avatar equipped = profile.getEquippedAvatar();
        if (equipped == null) {
            AvatarCatalogItem def = new AvatarCatalogItem(
                    "00000000-0000-0000-0000-000000000000",
                    "initiates_spark", "Nova Spark", "Curious and bright — your first companion.",
                    "characters/nova_spark", "INITIATE", null, true, 0, null);
            return new ProfileAvatarResponse(null, def);
        }
        return new ProfileAvatarResponse(equipped.getId().toString(), toCatalogItem(equipped));
    }

    private AvatarCatalogItem toCatalogItem(Avatar av) {
        AvatarCatalogItem.RequirementInfo req = null;
        if (av.getRequirementJson() != null && !av.getRequirementJson().isBlank() && !"null".equals(av.getRequirementJson().trim())) {
            try {
                String raw = av.getRequirementJson().trim();
                if (raw.startsWith("\"") && raw.endsWith("\"")) {
                    try { raw = objectMapper.readValue(raw, String.class); } catch (Exception ignored) {}
                }
                var map = objectMapper.readValue(raw, new com.fasterxml.jackson.core.type.TypeReference<java.util.Map<String, Object>>() {});
                Integer levelMin = map.get("levelMin") == null ? null : ((Number) map.get("levelMin")).intValue();
                Double syllabusCompletionMin = map.get("syllabusCompletionMin") == null ? null : ((Number) map.get("syllabusCompletionMin")).doubleValue();
                String syllabusSubjectId = map.get("syllabusSubjectId") == null ? null : map.get("syllabusSubjectId").toString();
                Integer streakCurrentMin = map.get("streakCurrentMin") == null ? null : ((Number) map.get("streakCurrentMin")).intValue();
                Integer streakLongestMin = map.get("streakLongestMin") == null ? null : ((Number) map.get("streakLongestMin")).intValue();
                Integer bossBattlesMin = map.get("bossBattlesMin") == null ? null : ((Number) map.get("bossBattlesMin")).intValue();
                Integer masteredCountMin = map.get("masteredCountMin") == null ? null : ((Number) map.get("masteredCountMin")).intValue();
                req = new AvatarCatalogItem.RequirementInfo(levelMin, syllabusCompletionMin, syllabusSubjectId, streakCurrentMin, streakLongestMin, bossBattlesMin, masteredCountMin);
            } catch (Exception ignored) {}
        }
        return new AvatarCatalogItem(
                av.getId().toString(), av.getCode(), av.getDisplayName(), av.getDescription(),
                av.getAssetKey(), av.getRarity(), av.getCreditCost(), av.isActive(), av.getDisplayOrder(), req);
    }
}
