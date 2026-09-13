-- GameLearn AI - Batch 2 / Phase 3: subject/game compatibility authority.
-- The backend owns which games are educationally appropriate for each
-- subject; clients must never infer compatibility. Presence of a row means
-- the (subject, game) combination is supported; absence means it is not.
-- Each row carries the educational rationale for the mapping.
-- Additive only: no existing table, row, constraint or index is modified.

CREATE TABLE subject_game_compat (
    id            CHAR(36)      NOT NULL,
    subject_id    CHAR(36)      NOT NULL,
    game_type     VARCHAR(60)   NOT NULL,
    rationale     VARCHAR(500)  NOT NULL,
    display_order INT           NOT NULL,
    is_active     BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP     NOT NULL,
    updated_at    TIMESTAMP     NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_subject_game_compat_subject_game UNIQUE (subject_id, game_type),
    CONSTRAINT fk_subject_game_compat__subjects FOREIGN KEY (subject_id) REFERENCES subjects (id)
);

CREATE INDEX idx_subject_game_compat_subject ON subject_game_compat (subject_id);
CREATE INDEX idx_subject_game_compat_game ON subject_game_compat (game_type);
