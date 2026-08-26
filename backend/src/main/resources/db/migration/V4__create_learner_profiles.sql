-- GameLearn AI - learner profile (1:1 with users)
-- (Database Specification section 8)
--
-- Placed after learning content because current_subject_id and
-- current_topic_id reference subjects/topics.

CREATE TABLE learner_profiles (
    id                  CHAR(36)      NOT NULL,
    user_id             CHAR(36)      NOT NULL,
    current_level       INT           NOT NULL DEFAULT 1,
    total_xp            INT           NOT NULL DEFAULT 0,
    overall_mastery     DECIMAL(5,2)  NOT NULL DEFAULT 0,
    current_subject_id  CHAR(36)      NULL,
    current_topic_id    CHAR(36)      NULL,
    created_at          TIMESTAMP     NOT NULL,
    updated_at          TIMESTAMP     NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_learner_profiles_user_id UNIQUE (user_id),
    CONSTRAINT fk_learner_profiles__users FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_learner_profiles__subjects FOREIGN KEY (current_subject_id) REFERENCES subjects (id),
    CONSTRAINT fk_learner_profiles__topics FOREIGN KEY (current_topic_id) REFERENCES topics (id)
);

CREATE INDEX idx_learner_profiles_current_subject ON learner_profiles (current_subject_id);
CREATE INDEX idx_learner_profiles_current_topic ON learner_profiles (current_topic_id);
