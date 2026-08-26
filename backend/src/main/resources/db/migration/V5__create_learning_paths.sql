-- GameLearn AI - personalized learning paths
-- (Database Specification sections 12-13)

CREATE TABLE learning_paths (
    id          CHAR(36)      NOT NULL,
    user_id     CHAR(36)      NOT NULL,
    subject_id  CHAR(36)      NOT NULL,
    title       VARCHAR(200)  NOT NULL,
    description TEXT          NULL,
    status      VARCHAR(30)   NOT NULL,
    generated_by VARCHAR(30)  NOT NULL,
    created_at  TIMESTAMP     NOT NULL,
    updated_at  TIMESTAMP     NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_learning_paths__users FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_learning_paths__subjects FOREIGN KEY (subject_id) REFERENCES subjects (id)
);

CREATE INDEX idx_learning_paths_user_subject ON learning_paths (user_id, subject_id);
CREATE INDEX idx_learning_paths_subject_id ON learning_paths (subject_id);

CREATE TABLE learning_path_nodes (
    id                CHAR(36)      NOT NULL,
    learning_path_id  CHAR(36)      NOT NULL,
    topic_id          CHAR(36)      NOT NULL,
    sequence_number   INT           NOT NULL,
    required_mastery  DECIMAL(5,2)  NULL,
    status            VARCHAR(30)   NOT NULL,
    created_at        TIMESTAMP     NOT NULL,
    updated_at        TIMESTAMP     NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_learning_path_nodes_path_seq UNIQUE (learning_path_id, sequence_number),
    CONSTRAINT fk_learning_path_nodes__learning_paths FOREIGN KEY (learning_path_id) REFERENCES learning_paths (id),
    CONSTRAINT fk_learning_path_nodes__topics FOREIGN KEY (topic_id) REFERENCES topics (id)
);

CREATE INDEX idx_learning_path_nodes_topic_id ON learning_path_nodes (topic_id);
