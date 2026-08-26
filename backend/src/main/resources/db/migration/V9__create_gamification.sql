-- GameLearn AI - gamification: XP history, achievements, streaks
-- (Database Specification sections 22, 23, 24, 25)

CREATE TABLE xp_transactions (
    id             CHAR(36)      NOT NULL,
    user_id        CHAR(36)      NOT NULL,
    amount         INT           NOT NULL,
    event_type     VARCHAR(50)   NOT NULL,
    reference_type VARCHAR(50)   NULL,
    reference_id   CHAR(36)      NULL,
    description    VARCHAR(255)  NULL,
    created_at     TIMESTAMP     NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_xp_transactions__users FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE INDEX idx_xp_transactions_user_created ON xp_transactions (user_id, created_at);

CREATE TABLE achievements (
    id               CHAR(36)      NOT NULL,
    code             VARCHAR(80)   NOT NULL,
    name             VARCHAR(150)  NOT NULL,
    description      TEXT          NOT NULL,
    icon_key         VARCHAR(100)  NULL,
    rule_type        VARCHAR(50)   NOT NULL,
    rule_config_json JSON          NULL,
    xp_reward        INT           NOT NULL DEFAULT 0,
    is_active        BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMP     NOT NULL,
    updated_at       TIMESTAMP     NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_achievements_code UNIQUE (code)
);

CREATE TABLE user_achievements (
    id             CHAR(36)    NOT NULL,
    user_id        CHAR(36)    NOT NULL,
    achievement_id CHAR(36)    NOT NULL,
    unlocked_at    TIMESTAMP   NOT NULL,
    created_at     TIMESTAMP   NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_user_achievements_user_achievement UNIQUE (user_id, achievement_id),
    CONSTRAINT fk_user_achievements__users FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_user_achievements__achievements FOREIGN KEY (achievement_id) REFERENCES achievements (id)
);

CREATE INDEX idx_user_achievements_achievement ON user_achievements (achievement_id);

CREATE TABLE streaks (
    id                   CHAR(36)     NOT NULL,
    user_id              CHAR(36)     NOT NULL,
    current_streak_days  INT          NOT NULL DEFAULT 0,
    longest_streak_days  INT          NOT NULL DEFAULT 0,
    last_learning_date   DATE         NULL,
    timezone             VARCHAR(64)  NOT NULL,
    created_at           TIMESTAMP    NOT NULL,
    updated_at           TIMESTAMP    NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_streaks_user_id UNIQUE (user_id),
    CONSTRAINT fk_streaks__users FOREIGN KEY (user_id) REFERENCES users (id)
);
