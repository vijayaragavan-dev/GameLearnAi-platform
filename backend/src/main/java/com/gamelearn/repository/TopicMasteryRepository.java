package com.gamelearn.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.domain.Limit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.gamelearn.entity.Subject;
import com.gamelearn.entity.TopicMastery;

import jakarta.persistence.LockModeType;

public interface TopicMasteryRepository extends JpaRepository<TopicMastery, UUID> {

    /**
     * Adaptive Engine spec section 19: the mastery row is locked
     * (PESSIMISTIC_WRITE) during read-modify-write to prevent lost updates.
     * Lock ordering is fixed: topic_mastery first, learner_profiles second.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select t from TopicMastery t where t.user.id = :userId and t.topic.id = :topicId")
    Optional<TopicMastery> findWithLock(@Param("userId") UUID userId, @Param("topicId") UUID topicId);

    List<TopicMastery> findByUserId(UUID userId);

    /** Assessment Spec section 11.4 (R-GUARD): any baseline on these topics. */
    boolean existsByUserIdAndTopicIdIn(UUID userId, List<UUID> topicIds);

    /**
     * AI-TUTOR v1.0.0 section 7 (TC4): the learner's single stored mastery
     * row for a focused topic - plain read, NO lock (tutor never mutates).
     */
    Optional<TopicMastery> findByUserIdAndTopicId(UUID userId, UUID topicId);

    /** Test/verification helper: total baseline rows for a learner. */
    long countByUserId(UUID userId);

    /** Gamification Spec section 7.1: TOPIC_MASTERY_COUNT predicate input. */
    long countByUserIdAndMasteryLevel(UUID userId, com.gamelearn.entity.enums.MasteryLevel masteryLevel);

    /**
     * DASH-001 (Dashboard Spec section 8.3): the learner's most recent
     * mastery rows with topic names joined in one query (no N+1), ordered
     * last_assessed_at DESC NULLS LAST, topic_id ASC, bounded by the caller.
     */
    @Query("""
            select tm from TopicMastery tm join fetch tm.topic
            where tm.user.id = :userId
            order by tm.lastAssessedAt desc nulls last, tm.topic.id asc""")
    List<TopicMastery> findRecentTopicsForDashboard(@Param("userId") UUID userId, Limit limit);

    /**
     * DASH-001 (Dashboard Spec section 8.9, decision D3): distinct subjects
     * reachable from the learner's mastery rows via topic lineage — the
     * exact R-GUARD criterion (Assessment Spec section 11.4(a)) aggregated,
     * ordered display_order ASC then subject id ASC.
     */
    @Query("""
            select distinct s from TopicMastery tm
            join tm.topic t join t.subject s
            where tm.user.id = :userId
            order by s.displayOrder asc, s.id asc""")
    List<Subject> findDistinctAssessedSubjects(@Param("userId") UUID userId);
}
