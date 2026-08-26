package com.gamelearn.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.gamelearn.entity.QuizQuestion;

public interface QuizQuestionRepository extends JpaRepository<QuizQuestion, java.util.UUID> {

    java.util.List<QuizQuestion> findByQuizIdOrderByQuestionOrderAsc(java.util.UUID quizId);
}
