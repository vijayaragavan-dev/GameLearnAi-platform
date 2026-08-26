package com.gamelearn.entity;

import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import jakarta.persistence.Column;
import jakarta.persistence.Id;
import jakarta.persistence.MappedSuperclass;

/**
 * Base for entities whose rows carry both created_at and updated_at.
 * IDs are application-generated UUID v4 values stored as CHAR(36)
 * (Database Specification section 3).
 */
@MappedSuperclass
public abstract class BaseEntity {

    @Id
    @org.hibernate.annotations.UuidGenerator
    @Column(name = "id", nullable = false, updatable = false, columnDefinition = "CHAR(36)")
    private UUID id;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private java.time.Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private java.time.Instant updatedAt;

    public UUID getId() {
        return id;
    }

    public java.time.Instant getCreatedAt() {
        return createdAt;
    }

    public java.time.Instant getUpdatedAt() {
        return updatedAt;
    }

    @Override
    public boolean equals(Object other) {
        if (this == other) {
            return true;
        }
        if (other == null || getClass() != other.getClass()) {
            return false;
        }
        BaseEntity base = (BaseEntity) other;
        return id != null && id.equals(base.id);
    }

    @Override
    public int hashCode() {
        return getClass().hashCode();
    }
}
