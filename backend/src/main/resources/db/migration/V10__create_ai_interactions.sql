-- GameLearn AI - AI interaction metadata
-- (Database Specification section 26)

CREATE TABLE ai_interactions (
    id                   CHAR(36)      NOT NULL,
    user_id              CHAR(36)      NOT NULL,
    interaction_type     VARCHAR(40)   NOT NULL,
    model_name           VARCHAR(100)  NULL,
    prompt_version       VARCHAR(30)   NULL,
    request_context_json JSON          NULL,
    response_json        JSON          NULL,
    status               VARCHAR(30)   NOT NULL,
    latency_ms           INT           NULL,
    error_code           VARCHAR(80)   NULL,
    created_at           TIMESTAMP     NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_ai_interactions__users FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE INDEX idx_ai_interactions_user_created ON ai_interactions (user_id, created_at);
