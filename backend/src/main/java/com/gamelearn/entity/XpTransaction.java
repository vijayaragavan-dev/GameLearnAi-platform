package com.gamelearn.entity;

import java.util.UUID;

import com.gamelearn.entity.enums.XpEventType;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

/**
 * Append-only XP audit history (Database Specification section 22).
 * Current-state XP lives on learner_profiles.
 */
@Entity
@Table(name = "xp_transactions")
public class XpTransaction extends ImmutableEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "amount", nullable = false)
    private int amount;

    @Enumerated(EnumType.STRING)
    @Column(name = "event_type", nullable = false, length = 50)
    private XpEventType eventType;

    @Column(name = "reference_type", length = 50)
    private String referenceType;

    @Column(name = "reference_id", columnDefinition = "CHAR(36)")
    private UUID referenceId;

    @Column(name = "description", length = 255)
    private String description;

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public int getAmount() {
        return amount;
    }

    public void setAmount(int amount) {
        this.amount = amount;
    }

    public XpEventType getEventType() {
        return eventType;
    }

    public void setEventType(XpEventType eventType) {
        this.eventType = eventType;
    }

    public String getReferenceType() {
        return referenceType;
    }

    public void setReferenceType(String referenceType) {
        this.referenceType = referenceType;
    }

    public UUID getReferenceId() {
        return referenceId;
    }

    public void setReferenceId(UUID referenceId) {
        this.referenceId = referenceId;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }
}
