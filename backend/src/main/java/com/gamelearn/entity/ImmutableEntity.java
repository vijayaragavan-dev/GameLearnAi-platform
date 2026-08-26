package com.gamelearn.entity;

import java.time.Instant;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;

import jakarta.persistence.Column;
import jakarta.persistence.Id;
import jakarta.persistence.MappedSuperclass;

/**
 * Base for append-only history/event tables that have created_at but no
 * updated_at (quiz_questions, question_attempts, xp_transactions,
 * user_achievements, ai_interactions).
 */
@MappedSuperclass
public abstract class ImmutableEntity {

    @Id
    @org.hibernate.annotations.UuidGenerator
    @Column(name = "id", nullable = false, updatable = false, columnDefinition = "CHAR(36)")
    private UUID id;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public UUID getId() {
        return id;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    @Override
    public boolean equals(Object other) {
        if (this == other) {
            return true;
        }
        if (other == null || getClass() != other.getClass()) {
            return false;
        }
        ImmutableEntity immutable = (ImmutableEntity) other;
        return id != null && id.equals(immutable.id);
    }

    @Override
    public int hashCode() {
        return getClass().hashCode();
    }
}
