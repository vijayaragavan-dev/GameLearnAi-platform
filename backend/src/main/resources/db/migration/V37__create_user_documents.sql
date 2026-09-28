-- GameLearn AI - USER-DOCUMENT RAG Phase B: document metadata foundation.
-- Authoritative MySQL metadata/lifecycle model for learner-uploaded documents.
-- Stores metadata ONLY: no PDF bytes, no extracted text, no embeddings.
-- (Bytes/text/vectors arrive in later phases and live outside this table.)
--
-- Ownership is server-authoritative: user_id always comes from the
-- authenticated principal (SecurityContext), never from client input.
-- Lifecycle: UPLOADED -> EXTRACTING -> CHUNKED -> INDEXED, with FAILED as
-- the explicit failure state (retry via FAILED -> EXTRACTING). Soft-delete
-- via is_active follows the content-table convention (units/lessons/topics).
-- Additive only: no existing table, constraint or index is modified.

CREATE TABLE user_documents (
    id           CHAR(36)     NOT NULL,
    user_id      CHAR(36)     NOT NULL,
    filename     VARCHAR(255) NOT NULL,
    content_type VARCHAR(100) NOT NULL,
    byte_size    BIGINT       NOT NULL,
    page_count   INT          NULL,
    status       VARCHAR(30)  NOT NULL DEFAULT 'UPLOADED',
    sha256       CHAR(64)     NULL,
    doc_version  INT          NOT NULL DEFAULT 1,
    is_active    BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP    NOT NULL,
    updated_at   TIMESTAMP    NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_user_documents__users FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT chk_user_documents_status CHECK (status IN ('UPLOADED','EXTRACTING','CHUNKED','INDEXED','FAILED')),
    CONSTRAINT chk_user_documents_byte_size CHECK (byte_size >= 0),
    CONSTRAINT chk_user_documents_page_count CHECK (page_count IS NULL OR page_count >= 0),
    CONSTRAINT chk_user_documents_doc_version CHECK (doc_version >= 1)
);

-- Ownership listing: documents owned by a user, newest first.
CREATE INDEX idx_user_documents_owner_created ON user_documents (user_id, created_at);

-- Retrieval authorization: servable (active + indexed) documents of a user.
CREATE INDEX idx_user_documents_owner_status ON user_documents (user_id, status);
