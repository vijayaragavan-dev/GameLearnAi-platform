-- GameLearn AI - Batch 1 / Phase 2: syllabus unit level.
-- Adds the Subject -> Unit -> Topic level used by the Batch 1 syllabus
-- expansion. Additive only:
--   * new `units` table (one subject per unit, unique name per subject);
--   * nullable `topics.unit_id` FK (NULL preserves all pre-existing topics
--     byte-for-byte; only Batch 1 topics carry a unit reference).
-- No existing row, constraint or index is modified.

CREATE TABLE units (
    id            CHAR(36)      NOT NULL,
    subject_id    CHAR(36)      NOT NULL,
    name          VARCHAR(150)  NOT NULL,
    description   TEXT          NULL,
    display_order INT           NOT NULL,
    is_active     BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP     NOT NULL,
    updated_at    TIMESTAMP     NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_units_subject_id_name UNIQUE (subject_id, name),
    CONSTRAINT fk_units__subjects FOREIGN KEY (subject_id) REFERENCES subjects (id)
);

CREATE INDEX idx_units_subject_id ON units (subject_id);

ALTER TABLE topics ADD COLUMN unit_id CHAR(36) NULL;

ALTER TABLE topics ADD CONSTRAINT fk_topics__units FOREIGN KEY (unit_id) REFERENCES units (id);

CREATE INDEX idx_topics_unit_id ON topics (unit_id);
