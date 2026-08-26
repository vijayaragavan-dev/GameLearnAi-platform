package com.gamelearn.repository;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.gamelearn.entity.User;

import jakarta.persistence.LockModeType;

public interface UserRepository extends JpaRepository<User, UUID> {

    boolean existsByEmail(String email);

    Optional<User> findByEmail(String email);

    /**
     * Adaptive Engine spec section 19 serialization anchor for FIRST-TIME
     * topic_mastery creation: a mastery row that does not exist yet cannot
     * lock itself, so concurrent creators take this always-existing row lock,
     * then re-check under it. Never held together with other locks except as
     * the outermost acquisition, so the fixed mastery -> profile ordering is
     * preserved.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select u from User u where u.id = :userId")
    Optional<User> findWithLock(@Param("userId") UUID userId);
}
