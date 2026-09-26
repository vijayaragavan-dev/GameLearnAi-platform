package com.gamelearn.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

/**
 * Top-level learning domain (Phase: multi-realm foundation).
 *
 * <p>A realm groups subjects. Computer Science is the only realm with a
 * fully implemented learning structure today; every other realm row (if
 * ever seeded) is an explicit placeholder until its content contract
 * exists. Realm keys are stable, unique, machine-readable identifiers
 * (UPPER_SNAKE, matching the frontend {@code RealmId} contract) and
 * MUST never be renamed after creation.
 */
@Entity
@Table(name = "realms")
public class Realm extends BaseEntity {

    @Column(name = "realm_key", nullable = false, unique = true, length = 60)
    private String realmKey;

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "icon_key", length = 100)
    private String iconKey;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @Column(name = "display_order", nullable = false)
    private int displayOrder;

    public String getRealmKey() {
        return realmKey;
    }

    public void setRealmKey(String realmKey) {
        this.realmKey = realmKey;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getIconKey() {
        return iconKey;
    }

    public void setIconKey(String iconKey) {
        this.iconKey = iconKey;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    public int getDisplayOrder() {
        return displayOrder;
    }

    public void setDisplayOrder(int displayOrder) {
        this.displayOrder = displayOrder;
    }
}
