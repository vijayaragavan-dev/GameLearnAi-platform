-- GameLearn AI - credits and avatar ownership (Phase L1)
-- Credits are a separate cosmetic currency derived from XP events.
-- Ownership is server-authoritative: one row per (user, avatar).

-- Per-user spendable balance (1:1 with users, like streaks).
CREATE TABLE user_credits (
    id         CHAR(36)  NOT NULL,
    user_id    CHAR(36)  NOT NULL,
    balance    INT       NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_user_credits_user UNIQUE (user_id),
    CONSTRAINT fk_user_credits__users FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT chk_user_credits_balance CHECK (balance >= 0)
);

-- Append-only auditable ledger for credits (earn + spend).
-- Mirrors xp_transactions but carries signed amount and reason.
CREATE TABLE credit_ledger (
    id             CHAR(36)     NOT NULL,
    user_id        CHAR(36)     NOT NULL,
    amount         INT          NOT NULL,
    reason         VARCHAR(50)  NOT NULL,
    reference_type VARCHAR(50)  NULL,
    reference_id   CHAR(36)     NULL,
    description    VARCHAR(255) NULL,
    created_at     TIMESTAMP    NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_credit_ledger__users FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT chk_credit_ledger_amount CHECK (amount <> 0),
    CONSTRAINT chk_credit_ledger_reason CHECK (reason IN ('CREDIT_EARNED','CREDIT_SPENT'))
);

CREATE INDEX idx_credit_ledger_user_created ON credit_ledger (user_id, created_at);
CREATE INDEX idx_credit_ledger_user_ref ON credit_ledger (user_id, reference_type, reference_id);

-- Ownership ledger (one-time per avatar).
CREATE TABLE user_avatars (
    id               CHAR(36)     NOT NULL,
    user_id          CHAR(36)     NOT NULL,
    avatar_id        CHAR(36)     NOT NULL,
    acquired_at      TIMESTAMP    NOT NULL,
    acquisition_type VARCHAR(30)  NOT NULL,
    created_at       TIMESTAMP    NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_user_avatars_user_avatar UNIQUE (user_id, avatar_id),
    CONSTRAINT fk_user_avatars__users FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_user_avatars__avatars FOREIGN KEY (avatar_id) REFERENCES avatars (id),
    CONSTRAINT chk_user_avatars_type CHECK (acquisition_type IN ('GRANTED','PURCHASED','THRESHOLD_CLAIM'))
);

CREATE INDEX idx_user_avatars_user ON user_avatars (user_id, avatar_id);
CREATE INDEX idx_user_avatars_avatar ON user_avatars (avatar_id);
