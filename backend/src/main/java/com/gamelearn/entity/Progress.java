package com.gamelearn.entity;

import java.math.BigDecimal;
import java.time.Instant;

import com.gamelearn.entity.enums.ProgressStatus;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "progress")
public class Progress extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "topic_id", nullable = false)
    private Topic topic;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learning_path_node_id")
    private LearningPathNode learningPathNode;

    @Column(name = "completion_percentage", nullable = false, precision = 5, scale = 2)
    private BigDecimal completionPercentage = BigDecimal.ZERO;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 30)
    private ProgressStatus status;

    @Column(name = "last_activity_at")
    private Instant lastActivityAt;

    @Column(name = "completed_at")
    private Instant completedAt;

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

    public LearningPathNode getLearningPathNode() {
        return learningPathNode;
    }

    public void setLearningPathNode(LearningPathNode learningPathNode) {
        this.learningPathNode = learningPathNode;
    }

    public BigDecimal getCompletionPercentage() {
        return completionPercentage;
    }

    public void setCompletionPercentage(BigDecimal completionPercentage) {
        this.completionPercentage = completionPercentage;
    }

    public ProgressStatus getStatus() {
        return status;
    }

    public void setStatus(ProgressStatus status) {
        this.status = status;
    }

    public Instant getLastActivityAt() {
        return lastActivityAt;
    }

    public void setLastActivityAt(Instant lastActivityAt) {
        this.lastActivityAt = lastActivityAt;
    }

    public Instant getCompletedAt() {
        return completedAt;
    }

    public void setCompletedAt(Instant completedAt) {
        this.completedAt = completedAt;
    }
}
