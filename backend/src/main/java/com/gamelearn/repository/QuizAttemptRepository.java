package com.gamelearn.repository;

import java.util.List;
import java.util.UUID;

import org.springframework.data.domain.Limit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.gamelearn.entity.QuizAttempt;
import com.gamelearn.entity.enums.QuizAttemptStatus;

public interface QuizAttemptRepository extends JpaRepository<QuizAttempt, java.util.UUID> {

    /** Gamification Spec section 7.1: COUNT_QUIZ_ATTEMPTS predicate input. */
    long countByUserId(UUID userId);

    /**
     * Assessment Spec section 11.4 (R-GUARD): true when the learner already
     * has ANY real quiz attempt whose quiz belongs to the given subject.
     */
    @org.springframework.data.jpa.repository.Query(
            "select count(a) > 0 from QuizAttempt a "
            + "join a.quiz q join q.topic t "
            + "where a.user.id = :userId and t.subject.id = :subjectId")
    boolean existsByUserIdAndQuizSubjectId(@org.springframework.data.repository.query.Param("userId") UUID userId,
                                           @org.springframework.data.repository.query.Param("subjectId") UUID subjectId);

    /**
     * DASH-001 (Dashboard Spec section 8.10, decision D2): the learner's
     * most recent COMPLETED attempts with quiz and topic joined in one query
     * (no N+1), ordered submitted_at DESC NULLS LAST then attempt id ASC,
     * bounded by the caller.
     */
    @Query("""
            select a from QuizAttempt a join fetch a.quiz q join fetch q.topic t
            where a.user.id = :userId and a.status = :status
            order by a.submittedAt desc nulls last, a.id asc""")
    List<QuizAttempt> findRecentForDashboard(@Param("userId") UUID userId,
                                             @Param("status") QuizAttemptStatus status,
                                             Limit limit);
}
