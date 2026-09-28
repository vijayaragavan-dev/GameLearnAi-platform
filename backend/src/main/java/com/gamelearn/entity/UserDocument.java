package com.gamelearn.entity;

import com.gamelearn.entity.enums.DocumentStatus;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

/**
 * Authoritative metadata for one learner-uploaded document (USER-DOC RAG
 * Phase B). Metadata ONLY: no PDF bytes, no extracted text, no embeddings
 * are stored here (or anywhere in MySQL) — those arrive in later phases
 * and live outside this table.
 *
 * <p>Ownership is server-authoritative: {@code user} is always resolved
 * from the authenticated principal ({@code SecurityContext}), never from
 * client input. All authorization-sensitive access must go through
 * owner-scoped repository methods plus the service boundary.</p>
 *
 * <p>Lifecycle ({@link DocumentStatus}): UPLOADED -&gt; EXTRACTING -&gt;
 * CHUNKED -&gt; INDEXED, with FAILED as the explicit failure state.
 * Deletion is a soft-delete via {@code active} (the content-table
 * {@code is_active} convention): inactive rows are never served to
 * retrieval but remain for audit.</p>
 */
@Entity
@Table(name = "user_documents")
public class UserDocument extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "filename", nullable = false, length = 255)
    private String filename;

    @Column(name = "content_type", nullable = false, length = 100)
    private String contentType;

    @Column(name = "byte_size", nullable = false)
    private long byteSize;

    /** Known only after extraction; null while UPLOADED/EXTRACTING. */
    @Column(name = "page_count")
    private Integer pageCount;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 30)
    private DocumentStatus status = DocumentStatus.UPLOADED;

    /** Hex SHA-256 of the uploaded bytes; known only after upload. */
    @Column(name = "sha256", length = 64, columnDefinition = "CHAR(64)")
    private String sha256;

    /**
     * Application-managed document revision, incremented by future
     * re-index flows. This is NOT JPA optimistic locking (no entity in
     * this codebase uses {@code @Version}).
     */
    @Column(name = "doc_version", nullable = false)
    private int docVersion = 1;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public String getFilename() {
        return filename;
    }

    public void setFilename(String filename) {
        this.filename = filename;
    }

    public String getContentType() {
        return contentType;
    }

    public void setContentType(String contentType) {
        this.contentType = contentType;
    }

    public long getByteSize() {
        return byteSize;
    }

    public void setByteSize(long byteSize) {
        this.byteSize = byteSize;
    }

    public Integer getPageCount() {
        return pageCount;
    }

    public void setPageCount(Integer pageCount) {
        this.pageCount = pageCount;
    }

    public DocumentStatus getStatus() {
        return status;
    }

    public void setStatus(DocumentStatus status) {
        this.status = status;
    }

    public String getSha256() {
        return sha256;
    }

    public void setSha256(String sha256) {
        this.sha256 = sha256;
    }

    public int getDocVersion() {
        return docVersion;
    }

    public void setDocVersion(int docVersion) {
        this.docVersion = docVersion;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }
}
