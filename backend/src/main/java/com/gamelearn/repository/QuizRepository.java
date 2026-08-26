package com.gamelearn.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.gamelearn.entity.Quiz;

public interface QuizRepository extends JpaRepository<Quiz, java.util.UUID> {

    java.util.Optional<Quiz> findFirstByTopicIdAndActiveTrueOrderByCreatedAtAscIdAsc(java.util.UUID topicId);
}
