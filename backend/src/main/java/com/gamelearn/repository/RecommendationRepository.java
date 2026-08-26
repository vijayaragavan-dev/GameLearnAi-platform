package com.gamelearn.repository;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import com.gamelearn.entity.Recommendation;
import com.gamelearn.entity.enums.RecommendationStatus;

public interface RecommendationRepository extends JpaRepository<Recommendation, UUID> {

    List<Recommendation> findByUserIdAndTopicIdAndStatus(UUID userId, UUID topicId,
                                                         RecommendationStatus status);

    List<Recommendation> findByUserIdAndStatusOrderByPriorityAscGeneratedAtDesc(
            UUID userId, RecommendationStatus status);
}
