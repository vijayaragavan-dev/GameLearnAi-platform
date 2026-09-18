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

    /**
     * Gate 14.2 recommendation-outcome derivation: one learner's
     * recommendations for one topic in generation order, so a post
     * observation window can be bounded by the next recommendation
     * (no double attribution). Read-only derivation input.
     */
    List<Recommendation> findByUserIdAndTopicIdOrderByGeneratedAtAscIdAsc(
            UUID userId, UUID topicId);
}
