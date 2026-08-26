package com.gamelearn.entity;

import java.math.BigDecimal;
import java.time.Instant;

import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.entity.enums.MasteryLevel;
import com.gamelearn.entity.enums.MasteryTrend;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "topic_mastery")
public class TopicMastery extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "topic_id", nullable = false)
    private Topic topic;

    @Column(name = "mastery_score", nullable = false, precision = 5, scale = 2)
    private BigDecimal masteryScore = BigDecimal.ZERO;

    @Enumerated(EnumType.STRING)
    @Column(name = "mastery_level", nullable = false, length = 30)
    private MasteryLevel masteryLevel;

    @Enumerated(EnumType.STRING)
    @Column(name = "current_difficulty", nullable = false, length = 20)
    private Difficulty currentDifficulty;

    @Column(name = "attempt_count", nullable = false)
    private int attemptCount;

    @Column(name = "recent_accuracy", nullable = false, precision = 5, scale = 2)
    private BigDecimal recentAccuracy = BigDecimal.ZERO;

    @Enumerated(EnumType.STRING)
    @Column(name = "trend", nullable = false, length = 30)
    private MasteryTrend trend;

    @Column(name = "last_assessed_at")
    private Instant lastAssessedAt;

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

    public BigDecimal getMasteryScore() {
        return masteryScore;
    }

    public void setMasteryScore(BigDecimal masteryScore) {
        this.masteryScore = masteryScore;
    }

    public MasteryLevel getMasteryLevel() {
        return masteryLevel;
    }

    public void setMasteryLevel(MasteryLevel masteryLevel) {
        this.masteryLevel = masteryLevel;
    }

    public Difficulty getCurrentDifficulty() {
        return currentDifficulty;
    }

    public void setCurrentDifficulty(Difficulty currentDifficulty) {
        this.currentDifficulty = currentDifficulty;
    }

    public int getAttemptCount() {
        return attemptCount;
    }

    public void setAttemptCount(int attemptCount) {
        this.attemptCount = attemptCount;
    }

    public BigDecimal getRecentAccuracy() {
        return recentAccuracy;
    }

    public void setRecentAccuracy(BigDecimal recentAccuracy) {
        this.recentAccuracy = recentAccuracy;
    }

    public MasteryTrend getTrend() {
        return trend;
    }

    public void setTrend(MasteryTrend trend) {
        this.trend = trend;
    }

    public Instant getLastAssessedAt() {
        return lastAssessedAt;
    }

    public void setLastAssessedAt(Instant lastAssessedAt) {
        this.lastAssessedAt = lastAssessedAt;
    }
}
