package com.gamelearn.repository;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.gamelearn.entity.Streak;

import jakarta.persistence.LockModeType;

public interface StreakRepository extends JpaRepository<Streak, java.util.UUID> {

    /**
     * Gamification Spec section 13.1: the streak row is locked
     * (PESSIMISTIC_WRITE) for the read-decide-write cycle; acquired AFTER the
     * adaptive engine's mastery/profile locks in every transaction, so the
     * established lock order is preserved.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select s from Streak s where s.user.id = :userId")
    Optional<Streak> findWithLock(@Param("userId") UUID userId);

    Optional<Streak> findByUserId(UUID userId);
}
