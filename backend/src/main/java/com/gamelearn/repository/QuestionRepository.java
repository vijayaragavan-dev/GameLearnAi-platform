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
}
