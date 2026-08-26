package com.gamelearn.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.gamelearn.entity.Progress;

public interface ProgressRepository extends JpaRepository<Progress, java.util.UUID> {

    java.util.List<Progress> findByUserIdOrderByLastActivityAtDescIdAsc(java.util.UUID userId);

    java.util.Optional<Progress> findByUserIdAndTopicId(java.util.UUID userId, java.util.UUID topicId);

}
