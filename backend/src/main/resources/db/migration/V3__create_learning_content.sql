-- GameLearn AI - learning content (Database Specification sections 9-11)
-- subjects, topics, lessons.

CREATE TABLE subjects (
    id            CHAR(36)      NOT NULL,
    name          VARCHAR(100)  NOT NULL,
    description   TEXT          NULL,
    icon_key      VARCHAR(100)  NULL,
    is_active     BOOLEAN       NOT NULL DEFAULT TRUE,
    display_order INT           NOT NULL DEFAULT 0,
    created_at    TIMESTAMP     NOT NULL,
    updated_at    TIMESTAMP     NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_subjects_name UNIQUE (name)
);

CREATE TABLE topics (
    id            CHAR(36)      NOT NULL,
    subject_id    CHAR(36)      NOT NULL,
    name          VARCHAR(150)  NOT NULL,
    description   TEXT          NULL,
    difficulty    VARCHAR(20)   NOT NULL,
    display_order INT           NOT NULL,
    is_active     BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP     NOT NULL,
    updated_at    TIMESTAMP     NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_topics_subject_id_name UNIQUE (subject_id, name),
    CONSTRAINT fk_topics__subjects FOREIGN KEY (subject_id) REFERENCES subjects (id)
);

CREATE INDEX idx_topics_subject_id ON topics (subject_id);

CREATE TABLE lessons (
    id          CHAR(36)      NOT NULL,
    topic_id    CHAR(36)      NOT NULL,
    title       VARCHAR(200)  NOT NULL,
    content     LONGTEXT      NOT NULL,
    summary     TEXT          NULL,
    difficulty  VARCHAR(20)   NOT NULL,
    source_type VARCHAR(30)   NOT NULL,
    is_active   BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP     NOT NULL,
    updated_at  TIMESTAMP     NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_lessons__topics FOREIGN KEY (topic_id) REFERENCES topics (id)
);

CREATE INDEX idx_lessons_topic_id ON lessons (topic_id);
