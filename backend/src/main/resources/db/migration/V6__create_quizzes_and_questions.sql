-- GameLearn AI - quizzes and questions
-- (Database Specification sections 14-16)

CREATE TABLE quizzes (
    id                 CHAR(36)      NOT NULL,
    topic_id           CHAR(36)      NOT NULL,
    title              VARCHAR(200)  NOT NULL,
    description        TEXT          NULL,
    difficulty         VARCHAR(20)   NOT NULL,
    source_type        VARCHAR(30)   NOT NULL,
    time_limit_seconds INT           NULL,
    is_active          BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at         TIMESTAMP     NOT NULL,
    updated_at         TIMESTAMP     NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_quizzes__topics FOREIGN KEY (topic_id) REFERENCES topics (id)
);

CREATE INDEX idx_quizzes_topic_id ON quizzes (topic_id);

CREATE TABLE questions (
    id             CHAR(36)      NOT NULL,
    topic_id       CHAR(36)      NOT NULL,
    question_text  TEXT          NOT NULL,
    question_type  VARCHAR(30)   NOT NULL,
    difficulty     VARCHAR(20)   NOT NULL,
    options_json   JSON          NULL,
    correct_answer VARCHAR(255)  NOT NULL,
    explanation    TEXT          NULL,
    source_type    VARCHAR(30)   NOT NULL,
    is_active      BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMP     NOT NULL,
    updated_at     TIMESTAMP     NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_questions__topics FOREIGN KEY (topic_id) REFERENCES topics (id)
);

CREATE INDEX idx_questions_topic_id ON questions (topic_id);

CREATE TABLE quiz_questions (
    id             CHAR(36)    NOT NULL,
    quiz_id        CHAR(36)    NOT NULL,
    question_id    CHAR(36)    NOT NULL,
    question_order INT         NOT NULL,
    created_at     TIMESTAMP   NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_quiz_questions_quiz_question UNIQUE (quiz_id, question_id),
    CONSTRAINT uq_quiz_questions_quiz_order UNIQUE (quiz_id, question_order),
    CONSTRAINT fk_quiz_questions__quizzes FOREIGN KEY (quiz_id) REFERENCES quizzes (id),
    CONSTRAINT fk_quiz_questions__questions FOREIGN KEY (question_id) REFERENCES questions (id)
);
