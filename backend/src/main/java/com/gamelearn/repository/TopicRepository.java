package com.gamelearn.repository;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.gamelearn.entity.Topic;

public interface TopicRepository extends JpaRepository<Topic, UUID> {

    /** Active catalog for a subject in the stable ordering used for AI refs. */
    List<Topic> findBySubjectIdAndActiveTrueOrderByDisplayOrderAscIdAsc(UUID subjectId);
}
