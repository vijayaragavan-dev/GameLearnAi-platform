package com.gamelearn.entity;

import java.time.LocalDate;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "streaks")
public class Streak extends BaseEntity {

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "current_streak_days", nullable = false)
    private int currentStreakDays;

    @Column(name = "longest_streak_days", nullable = false)
    private int longestStreakDays;

    @Column(name = "last_learning_date")
    private LocalDate lastLearningDate;

    @Column(name = "timezone", nullable = false, length = 64)
    private String timezone;

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public int getCurrentStreakDays() {
        return currentStreakDays;
    }

    public void setCurrentStreakDays(int currentStreakDays) {
        this.currentStreakDays = currentStreakDays;
    }

    public int getLongestStreakDays() {
        return longestStreakDays;
    }

    public void setLongestStreakDays(int longestStreakDays) {
        this.longestStreakDays = longestStreakDays;
    }

    public LocalDate getLastLearningDate() {
        return lastLearningDate;
    }

    public void setLastLearningDate(LocalDate lastLearningDate) {
        this.lastLearningDate = lastLearningDate;
    }

    public String getTimezone() {
        return timezone;
    }

    public void setTimezone(String timezone) {
        this.timezone = timezone;
    }
}
