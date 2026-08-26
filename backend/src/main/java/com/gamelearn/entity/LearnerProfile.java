package com.gamelearn.entity;

import java.math.BigDecimal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "learner_profiles")
public class LearnerProfile extends BaseEntity {

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "current_level", nullable = false)
    private int currentLevel = 1;

    @Column(name = "total_xp", nullable = false)
    private int totalXp;

    @Column(name = "overall_mastery", nullable = false, precision = 5, scale = 2)
    private BigDecimal overallMastery = BigDecimal.ZERO;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "current_subject_id")
    private Subject currentSubject;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "current_topic_id")
    private Topic currentTopic;

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public int getCurrentLevel() {
        return currentLevel;
    }

    public void setCurrentLevel(int currentLevel) {
        this.currentLevel = currentLevel;
    }

    public int getTotalXp() {
        return totalXp;
    }

    public void setTotalXp(int totalXp) {
        this.totalXp = totalXp;
    }

    public BigDecimal getOverallMastery() {
        return overallMastery;
    }

    public void setOverallMastery(BigDecimal overallMastery) {
        this.overallMastery = overallMastery;
    }

    public Subject getCurrentSubject() {
        return currentSubject;
    }

    public void setCurrentSubject(Subject currentSubject) {
        this.currentSubject = currentSubject;
    }

    public Topic getCurrentTopic() {
        return currentTopic;
    }

    public void setCurrentTopic(Topic currentTopic) {
        this.currentTopic = currentTopic;
    }
}
