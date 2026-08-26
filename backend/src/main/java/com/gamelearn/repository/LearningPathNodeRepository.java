package com.gamelearn.repository;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.gamelearn.entity.LearningPathNode;

public interface LearningPathNodeRepository extends JpaRepository<LearningPathNode, java.util.UUID> {

    List<LearningPathNode> findByLearningPathIdOrderBySequenceNumberAsc(UUID learningPathId);

    /**
     * DASH-001 (Dashboard Spec section 8.8): the path's nodes with topics
     * joined in one query (no N+1), ordered sequence_number ASC.
     */
    @Query("""
            select n from LearningPathNode n join fetch n.topic
            where n.learningPath.id = :learningPathId
            order by n.sequenceNumber asc""")
    List<LearningPathNode> findNodesForDashboard(@Param("learningPathId") UUID learningPathId);
}
