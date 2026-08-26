-- GameLearn AI - adaptive state: topic mastery, progress, recommendations
-- (Database Specification sections 19-21)

CREATE TABLE topic_mastery (
    id                CHAR(36)      NOT NULL,
    user_id           CHAR(36)      NOT NULL,
    topic_id          CHAR(36)      NOT NULL,
    mastery_score     DECIMAL(5,2)  NOT NULL DEFAULT 0,
    mastery_level     VARCHAR(30)   NOT NULL,
    current_difficulty VARCHAR(20)  NOT NULL,
    attempt_count     INT           NOT NULL DEFAULT 0,
    recent_accuracy   DECIMAL(5,2)  NOT NULL DEFAULT 0,
    trend             VARCHAR(30)   NOT NULL,
    last_assessed_at  TIMESTAMP     NULL,
    created_at        TIMESTAMP     NOT NULL,
    updated_at        TIMESTAMP     NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_topic_mastery_user_topic UNIQUE (user_id, topic_id),
    CONSTRAINT fk_topic_mastery__users FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_topic_mastery__topics FOREIGN KEY (topic_id) REFERENCES topics (id)
);

CREATE INDEX idx_topic_mastery_topic_id ON topic_mastery (topic_id);

CREATE TABLE progress (
    id                      CHAR(36)      NOT NULL,
    user_id                 CHAR(36)      NOT NULL,
    topic_id                CHAR(36)      NOT NULL,
    learning_path_node_id   CHAR(36)      NULL,
    completion_percentage   DECIMAL(5,2)  NOT NULL DEFAULT 0,
    status                  VARCHAR(30)   NOT NULL,
    last_activity_at        TIMESTAMP     NULL,
    completed_at            TIMESTAMP     NULL,
    created_at              TIMESTAMP     NOT NULL,
    updated_at              TIMESTAMP     NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_progress__users FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_progress__topics FOREIGN KEY (topic_id) REFERENCES topics (id),
    CONSTRAINT fk_progress__learning_path_nodes FOREIGN KEY (learning_path_node_id) REFERENCES learning_path_nodes (id)
);

CREATE INDEX idx_progress_user_topic ON progress (user_id, topic_id);
CREATE INDEX idx_progress_topic_id ON progress (topic_id);
CREATE INDEX idx_progress_node_id ON progress (learning_path_node_id);

CREATE TABLE recommendations (
    id                       CHAR(36)      NOT NULL,
    user_id                  CHAR(36)      NOT NULL,
    topic_id                 CHAR(36)      NULL,
    activity_type            VARCHAR(40)   NOT NULL,
    recommended_difficulty   VARCHAR(20)   NULL,
    reason                   TEXT          NULL,
    priority                 INT           NOT NULL DEFAULT 0,
    status                   VARCHAR(30)   NOT NULL,
    generated_at             TIMESTAMP     NOT NULL,
    consumed_at              TIMESTAMP     NULL,
    created_at               TIMESTAMP     NOT NULL,
    updated_at               TIMESTAMP     NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_recommendations__users FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_recommendations__topics FOREIGN KEY (topic_id) REFERENCES topics (id)
);

CREATE INDEX idx_recommendations_user_status ON recommendations (user_id, status);
CREATE INDEX idx_recommendations_topic_id ON recommendations (topic_id);
