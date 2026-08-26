package com.gamelearn.repository;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.gamelearn.entity.LearningPath;

public interface LearningPathRepository extends JpaRepository<LearningPath, java.util.UUID> {

    List<LearningPath> findByUserIdAndSubjectIdOrderByCreatedAtAsc(UUID userId, UUID subjectId);

    /**
     * DASH-001 (Dashboard Spec section 8.8, decision D1): the learner's
     * paths in a given status with subjects joined in one query (no N+1),
     * ordered created_at DESC then id ASC — the approved tie-break order.
     */
    @Query("""
            select p from LearningPath p join fetch p.subject
            where p.user.id = :userId and p.status = :status
            order by p.createdAt desc, p.id asc""")
    List<LearningPath> findByStatusForDashboard(@Param("userId") UUID userId,
                                                @Param("status") com.gamelearn.entity.enums.LearningPathStatus status);
}
