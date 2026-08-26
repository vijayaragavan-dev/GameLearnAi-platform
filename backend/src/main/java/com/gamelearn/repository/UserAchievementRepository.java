package com.gamelearn.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.domain.Limit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.gamelearn.entity.UserAchievement;

public interface UserAchievementRepository extends JpaRepository<UserAchievement, java.util.UUID> {

    /** One-time unlock guard (DB UNIQUE(user_id, achievement_id) backstop). */
    boolean existsByUserIdAndAchievementId(UUID userId, UUID achievementId);

    long countByUserId(UUID userId);

    List<UserAchievement> findByUserId(UUID userId);

    /**
     * DASH-001 (Dashboard Spec section 8.6): the learner's most recent
     * unlocks with catalog entries joined in one query (no N+1), ordered
     * unlocked_at DESC then achievement_id ASC, bounded by the caller.
     */
    @Query("""
            select ua from UserAchievement ua join fetch ua.achievement
            where ua.user.id = :userId
            order by ua.unlockedAt desc, ua.achievement.id asc""")
    List<UserAchievement> findRecentUnlocksForDashboard(@Param("userId") UUID userId, Limit limit);
}
