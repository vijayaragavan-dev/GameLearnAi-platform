package com.gamelearn.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.gamelearn.entity.QuestionAttempt;

public interface QuestionAttemptRepository extends JpaRepository<QuestionAttempt, java.util.UUID> {
}
