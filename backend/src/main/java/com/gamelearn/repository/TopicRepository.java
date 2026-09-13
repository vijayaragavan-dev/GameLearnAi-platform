package com.gamelearn.repository;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.gamelearn.entity.Topic;

public interface TopicRepository extends JpaRepository<Topic, UUID> {

    /** Active catalog for a subject in the stable ordering used for AI refs. */
    List<Topic> findBySubjectIdAndActiveTrueOrderByDisplayOrderAscIdAsc(UUID subjectId);

    long countBySubjectIdAndActiveTrue(UUID subjectId);

    /**
     * Batch 2 game content: active topics scoped to a subject with optional
     * topic/difficulty narrowing, in deterministic order.
     */
    @org.springframework.data.jpa.repository.Query("""
            SELECT t FROM Topic t
            WHERE t.subject.id = :subjectId
              AND (:topicId IS NULL OR t.id = :topicId)
              AND t.active = TRUE
              AND (:difficulty IS NULL OR t.difficulty = :difficulty)
            ORDER BY t.displayOrder ASC, t.id ASC
            """)
    List<Topic> findActiveForGame(UUID subjectId, UUID topicId,
            com.gamelearn.entity.enums.Difficulty difficulty);

    @org.springframework.data.jpa.repository.Query("""
            SELECT t FROM Topic t JOIN t.subject s
            WHERE t.active = TRUE AND s.active = TRUE
            ORDER BY s.displayOrder ASC, s.id ASC, t.displayOrder ASC, t.id ASC
            """)
    List<Topic> findAllActiveOrderedForArena();
}
