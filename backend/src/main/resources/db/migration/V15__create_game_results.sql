-- GameLearn AI - per-game persistent progression (Persistent Gamification + Player Progression phase).
-- Holds per-game best score, plays, wins, and XP earned; lets the hub / dashboard
-- show REAL historical numbers without inventing data.

CREATE TABLE game_results (
    id              CHAR(36)      NOT NULL,
    user_id         CHAR(36)      NOT NULL,
    game_type       VARCHAR(60)   NOT NULL,
    client_request_id CHAR(36)    NOT NULL,
    completed       BOOLEAN       NOT NULL,
    score           INT           NOT NULL DEFAULT 0,
    duration_seconds INT          NOT NULL DEFAULT 0,
    best_combo      INT           NOT NULL DEFAULT 0,
    xp_awarded      INT           NOT NULL DEFAULT 0,
    played_at       TIMESTAMP     NOT NULL,
    created_at      TIMESTAMP     NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_game_results_request UNIQUE (user_id, client_request_id),
    CONSTRAINT fk_game_results__users FOREIGN KEY (user_id) REFERENCES users (id)
);

-- Lookup tables for "best score per game" and "games played per game" widgets.
CREATE INDEX idx_game_results_user_game ON game_results (user_id, game_type, played_at);
CREATE INDEX idx_game_results_user_played ON game_results (user_id, played_at);

-- Existing XP-transaction ledger already supports a (reference_type, reference_id) ledger
-- pair; we use reference_type='GAME_RESULT' for game result XP entries. No schema change
-- required there. Add an index to keep idempotency lookups fast.
CREATE INDEX idx_xp_transactions_user_ref ON xp_transactions (user_id, reference_type, reference_id);
