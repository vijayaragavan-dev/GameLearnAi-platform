package com.gamelearn.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.gamelearn.entity.UserAvatar;

public interface UserAvatarRepository extends JpaRepository<UserAvatar, UUID> {

    List<UserAvatar> findByUserId(UUID userId);

    Optional<UserAvatar> findByUserIdAndAvatarId(UUID userId, UUID avatarId);

    boolean existsByUserIdAndAvatarId(UUID userId, UUID avatarId);

    long countByUserId(UUID userId);
}
