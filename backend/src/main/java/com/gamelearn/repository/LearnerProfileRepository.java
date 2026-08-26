package com.gamelearn.repository;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.gamelearn.entity.LearnerProfile;

import jakarta.persistence.LockModeType;

public interface LearnerProfileRepository extends JpaRepository<LearnerProfile, UUID> {

    Optional<LearnerProfile> findByUserId(UUID userId);

    /**
     * Adaptive Engine spec section 19: profile row is locked AFTER the
     * topic_mastery row (fixed ordering prevents deadlocks).
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select p from LearnerProfile p where p.user.id = :userId")
    Optional<LearnerProfile> findWithLock(@Param("userId") UUID userId);
}
