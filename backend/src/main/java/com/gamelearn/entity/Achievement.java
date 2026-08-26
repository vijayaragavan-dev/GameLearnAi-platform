package com.gamelearn.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

/**
 * Global achievement definition (Database Specification section 23).
 * rule_config_json carries configuration data only, never executable code.
 */
@Entity
@Table(name = "achievements")
public class Achievement extends BaseEntity {

    @Column(name = "code", nullable = false, length = 80)
    private String code;

    @Column(name = "name", nullable = false, length = 150)
    private String name;

    @Column(name = "description", nullable = false, columnDefinition = "TEXT")
    private String description;

    @Column(name = "icon_key", length = 100)
    private String iconKey;

    @Column(name = "rule_type", nullable = false, length = 50)
    private String ruleType;

    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.JSON)
    @Column(name = "rule_config_json", columnDefinition = "JSON")
    private String ruleConfigJson;

    @Column(name = "xp_reward", nullable = false)
    private int xpReward;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
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

    public String getRuleType() {
        return ruleType;
    }

    public void setRuleType(String ruleType) {
        this.ruleType = ruleType;
    }

    public String getRuleConfigJson() {
        return ruleConfigJson;
    }

    public void setRuleConfigJson(String ruleConfigJson) {
        this.ruleConfigJson = ruleConfigJson;
    }

    public int getXpReward() {
        return xpReward;
    }

    public void setXpReward(int xpReward) {
        this.xpReward = xpReward;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }
}
