package com.gamelearn.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.gamelearn.entity.Achievement;

public interface AchievementRepository extends JpaRepository<Achievement, java.util.UUID> {

    /** Deterministic evaluation order: rule_type ASC, then code ASC (spec 7.2). */
    List<Achievement> findByActiveTrueOrderByRuleTypeAscCodeAsc();

    Optional<Achievement> findByCode(String code);
}
