package com.gamelearn.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Gamification rate-limit configuration for PROG-101 (Gate 2).
 * Single configurable bucket for NEW game-result submissions per user per rolling window.
 * Idempotent replays (same clientRequestId) never consume a slot.
 */
@Component
@ConfigurationProperties(prefix = "gamelearn.gamification.game-result-rate-limit")
public class GameResultRateLimitProperties {

    /**
     * Maximum number of NEW game-result submissions per user per window.
     * Default 30/hour matches Gate 2 acceptance criteria.
     */
    private int maxSubmissionsPerHour = 30;

    /**
     * Window size in minutes. Default 60 (hourly rolling window).
     */
    private int windowMinutes = 60;

    public int getMaxSubmissionsPerHour() {
        return maxSubmissionsPerHour;
    }

    public void setMaxSubmissionsPerHour(int maxSubmissionsPerHour) {
        this.maxSubmissionsPerHour = maxSubmissionsPerHour;
    }

    public int getWindowMinutes() {
        return windowMinutes;
    }

    public void setWindowMinutes(int windowMinutes) {
        this.windowMinutes = windowMinutes;
    }
}
