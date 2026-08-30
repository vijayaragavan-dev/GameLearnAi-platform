package com.gamelearn.entity;

import java.time.Instant;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

/**
 * Append-only record of a single completed educational game attempt. Holds the
 * per-game best-score / best-combo / plays / wins aggregates for the game hub
 * and dashboard widgets (Persistent Gamification + Player Progression).
 * Idempotency: (user_id, client_request_id) is unique; replaying the same
 * client request never produces a duplicate row nor a duplicate XP grant.
 */
@Entity
@Table(name = "game_results")
public class GameResult extends ImmutableEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "game_type", nullable = false, length = 60)
    private String gameType;

    /** Caller-provided idempotency key (UUID); same value re-submitted = no-op. */
    @Column(name = "client_request_id", nullable = false, length = 36, columnDefinition = "CHAR(36)")
    private UUID clientRequestId;

    @Column(name = "completed", nullable = false)
    private boolean completed;

    @Column(name = "score", nullable = false)
    private int score;

    @Column(name = "duration_seconds", nullable = false)
    private int durationSeconds;

    @Column(name = "best_combo", nullable = false)
    private int bestCombo;

    @Column(name = "xp_awarded", nullable = false)
    private int xpAwarded;

    @Column(name = "played_at", nullable = false)
    private Instant playedAt;

    public GameResult() {
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public String getGameType() {
        return gameType;
    }

    public void setGameType(String gameType) {
        this.gameType = gameType;
    }

    public UUID getClientRequestId() {
        return clientRequestId;
    }

    public void setClientRequestId(UUID clientRequestId) {
        this.clientRequestId = clientRequestId;
    }

    public boolean isCompleted() {
        return completed;
    }

    public void setCompleted(boolean completed) {
        this.completed = completed;
    }

    public int getScore() {
        return score;
    }

    public void setScore(int score) {
        this.score = score;
    }

    public int getDurationSeconds() {
        return durationSeconds;
    }

    public void setDurationSeconds(int durationSeconds) {
        this.durationSeconds = durationSeconds;
    }

    public int getBestCombo() {
        return bestCombo;
    }

    public void setBestCombo(int bestCombo) {
        this.bestCombo = bestCombo;
    }

    public int getXpAwarded() {
        return xpAwarded;
    }

    public void setXpAwarded(int xpAwarded) {
        this.xpAwarded = xpAwarded;
    }

    public Instant getPlayedAt() {
        return playedAt;
    }

    public void setPlayedAt(Instant playedAt) {
        this.playedAt = playedAt;
    }
}
