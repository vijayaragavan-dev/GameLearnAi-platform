package com.gamelearn.repository;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.gamelearn.entity.UserCredit;

import jakarta.persistence.LockModeType;

public interface UserCreditRepository extends JpaRepository<UserCredit, UUID> {

    Optional<UserCredit> findByUserId(UUID userId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select c from UserCredit c where c.user.id = :userId")
    Optional<UserCredit> findWithLock(@Param("userId") UUID userId);
}
