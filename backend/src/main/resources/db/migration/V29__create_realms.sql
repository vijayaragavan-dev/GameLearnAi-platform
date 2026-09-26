-- REALM-001: top-level learning-domain classification.
-- Realms group subjects. Computer Science is the only realm with a fully
-- implemented learning structure; rows for future realms (if ever seeded)
-- are explicit placeholders until their content contract exists.
CREATE TABLE realms (
    id            CHAR(36)      NOT NULL,
    realm_key     VARCHAR(60)   NOT NULL,
    name          VARCHAR(100)  NOT NULL,
    description   TEXT          NULL,
    icon_key      VARCHAR(100)  NULL,
    is_active     BOOLEAN       NOT NULL DEFAULT TRUE,
    display_order INT           NOT NULL,
    created_at    TIMESTAMP     NOT NULL,
    updated_at    TIMESTAMP     NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_realms_realm_key UNIQUE (realm_key)
);

-- Realm ownership on subjects. NULLABLE for migration safety: rows
-- predating the realm foundation are backfilled to Computer Science
-- in V30. New realm-scoped content MUST set an explicit realm.
ALTER TABLE subjects ADD COLUMN realm_id CHAR(36) NULL;

ALTER TABLE subjects ADD CONSTRAINT fk_subjects__realms
    FOREIGN KEY (realm_id) REFERENCES realms (id);

CREATE INDEX idx_subjects_realm_id ON subjects (realm_id);
