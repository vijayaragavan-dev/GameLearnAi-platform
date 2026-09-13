package com.gamelearn.repository;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.gamelearn.entity.Question;

public interface QuestionRepository extends JpaRepository<Question, java.util.UUID> {

    /**
     * Assessment Spec section 5: deterministic per-topic selection — up to
     * K active MCQ questions, created_at ASC then id ASC.
     */
    List<Question> findTop3ByTopicIdAndActiveTrueAndQuestionTypeOrderByCreatedAtAscIdAsc(
            UUID topicId, com.gamelearn.entity.enums.QuestionType questionType);

    /**
     * Batch 2 game content: active MCQ questions scoped to a subject with
     * optional topic/difficulty narrowing, in deterministic topic-then-
     * creation order. Subject filtering happens in the database so unrelated
     * subjects can never leak into subject-scoped game content.
     */
    @org.springframework.data.jpa.repository.Query("""
            SELECT q FROM Question q JOIN q.topic t
            WHERE t.subject.id = :subjectId
              AND (:topicId IS NULL OR t.id = :topicId)
              AND t.active = TRUE AND q.active = TRUE
              AND q.questionType = com.gamelearn.entity.enums.QuestionType.MCQ
              AND (:difficulty IS NULL OR q.difficulty = :difficulty)
            ORDER BY t.displayOrder ASC, q.createdAt ASC, q.id ASC
            """)
    List<Question> findActiveMcqForGame(UUID subjectId, UUID topicId,
            com.gamelearn.entity.enums.Difficulty difficulty);

    @org.springframework.data.jpa.repository.Query("""
            SELECT q FROM Question q JOIN q.topic t JOIN t.subject s
            WHERE t.active = TRUE AND s.active = TRUE AND q.active = TRUE
              AND q.questionType = com.gamelearn.entity.enums.QuestionType.MCQ
              AND (:difficulty IS NULL OR q.difficulty = :difficulty)
            ORDER BY s.displayOrder ASC, s.id ASC, t.displayOrder ASC, q.createdAt ASC, q.id ASC
            """)
    List<Question> findActiveMcqForGlobalArena(com.gamelearn.entity.enums.Difficulty difficulty);

    @org.springframework.data.jpa.repository.Query("""
            SELECT COUNT(q) FROM Question q JOIN q.topic t
            WHERE t.subject.id = :subjectId
              AND t.active = TRUE AND q.active = TRUE
              AND q.questionType = com.gamelearn.entity.enums.QuestionType.MCQ
            """)
    long countActiveMcqBySubjectId(UUID subjectId);
}
