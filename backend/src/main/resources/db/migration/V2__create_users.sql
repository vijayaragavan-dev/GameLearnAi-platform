-- GameLearn AI - user identity
-- (Database Specification section 7)

CREATE TABLE users (
    id            CHAR(36)      NOT NULL,
    email         VARCHAR(255)  NOT NULL,
    password_hash VARCHAR(255)  NOT NULL,
    display_name  VARCHAR(100)  NOT NULL,
    status        VARCHAR(30)   NOT NULL DEFAULT 'ACTIVE',
    created_at    TIMESTAMP     NOT NULL,
    updated_at    TIMESTAMP     NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_users_email UNIQUE (email)
);
