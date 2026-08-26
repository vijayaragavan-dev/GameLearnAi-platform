-- GameLearn AI - quiz and question attempts
-- (Database Specification sections 17-18)

CREATE TABLE quiz_attempts (
    id                    CHAR(36)      NOT NULL,
    quiz_id               CHAR(36)      NOT NULL,
    user_id               CHAR(36)      NOT NULL,
    score                 DECIMAL(5,2)  NOT NULL,
    correct_count         INT           NOT NULL,
    total_questions       INT           NOT NULL,
    difficulty_at_attempt VARCHAR(20)   NOT NULL,
    started_at            TIMESTAMP     NOT NULL,
    submitted_at          TIMESTAMP     NULL,
    duration_seconds      INT           NULL,
    status                VARCHAR(30)   NOT NULL,
    created_at            TIMESTAMP     NOT NULL,
    updated_at            TIMESTAMP     NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_quiz_attempts__quizzes FOREIGN KEY (quiz_id) REFERENCES quizzes (id),
    CONSTRAINT fk_quiz_attempts__users FOREIGN KEY (user_id) REFERENCES users (id)
);

CREATE INDEX idx_quiz_attempts_user_quiz ON quiz_attempts (user_id, quiz_id);
CREATE INDEX idx_quiz_attempts_user_submitted ON quiz_attempts (user_id, submitted_at);
CREATE INDEX idx_quiz_attempts_quiz_id ON quiz_attempts (quiz_id);

CREATE TABLE question_attempts (
    id                     CHAR(36)      NOT NULL,
    quiz_attempt_id        CHAR(36)      NOT NULL,
    question_id            CHAR(36)      NOT NULL,
    selected_answer        VARCHAR(255)  NULL,
    is_correct             BOOLEAN       NOT NULL,
    response_time_seconds  INT           NULL,
    created_at             TIMESTAMP     NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_question_attempts__quiz_attempts FOREIGN KEY (quiz_attempt_id) REFERENCES quiz_attempts (id),
    CONSTRAINT fk_question_attempts__questions FOREIGN KEY (question_id) REFERENCES questions (id)
);

CREATE INDEX idx_question_attempts_attempt ON question_attempts (quiz_attempt_id);
CREATE INDEX idx_question_attempts_question ON question_attempts (question_id);
