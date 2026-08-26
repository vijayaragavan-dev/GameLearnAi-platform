package com.gamelearn.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.gamelearn.entity.Lesson;

public interface LessonRepository extends JpaRepository<Lesson, java.util.UUID> {

    java.util.Optional<Lesson> findFirstByTopicIdAndActiveTrueOrderByCreatedAtAscIdAsc(java.util.UUID topicId);

}
