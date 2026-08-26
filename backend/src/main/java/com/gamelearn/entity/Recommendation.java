package com.gamelearn.entity;

import java.time.Instant;

import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.entity.enums.RecommendationActivityType;
import com.gamelearn.entity.enums.RecommendationStatus;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "recommendations")
public class Recommendation extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "topic_id")
    private Topic topic;

    @Enumerated(EnumType.STRING)
    @Column(name = "activity_type", nullable = false, length = 40)
    private RecommendationActivityType activityType;

    @Enumerated(EnumType.STRING)
    @Column(name = "recommended_difficulty", length = 20)
    private Difficulty recommendedDifficulty;

    @Column(name = "reason", columnDefinition = "TEXT")
    private String reason;

    @Column(name = "priority", nullable = false)
    private int priority;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 30)
    private RecommendationStatus status;

    @Column(name = "generated_at", nullable = false)
    private Instant generatedAt;

    @Column(name = "consumed_at")
    private Instant consumedAt;

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public Topic getTopic() {
        return topic;
    }

    public void setTopic(Topic topic) {
        this.topic = topic;
    }

    public RecommendationActivityType getActivityType() {
        return activityType;
    }

    public void setActivityType(RecommendationActivityType activityType) {
        this.activityType = activityType;
    }

    public Difficulty getRecommendedDifficulty() {
        return recommendedDifficulty;
    }

    public void setRecommendedDifficulty(Difficulty recommendedDifficulty) {
        this.recommendedDifficulty = recommendedDifficulty;
    }

    public String getReason() {
        return reason;
    }

    public void setReason(String reason) {
        this.reason = reason;
    }

    public int getPriority() {
        return priority;
    }

    public void setPriority(int priority) {
        this.priority = priority;
    }

    public RecommendationStatus getStatus() {
        return status;
    }

    public void setStatus(RecommendationStatus status) {
        this.status = status;
    }

    public Instant getGeneratedAt() {
        return generatedAt;
    }

    public void setGeneratedAt(Instant generatedAt) {
        this.generatedAt = generatedAt;
    }

    public Instant getConsumedAt() {
        return consumedAt;
    }

    public void setConsumedAt(Instant consumedAt) {
        this.consumedAt = consumedAt;
    }
}
