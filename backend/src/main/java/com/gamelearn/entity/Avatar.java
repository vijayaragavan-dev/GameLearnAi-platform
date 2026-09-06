package com.gamelearn.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

/**
 * Avatar catalog entry (avatars table, Phase L1).
 * Original GameLearnAI IP only. Rarity constrained by chk_avatars_rarity,
 * cost by chk_avatars_credit_cost. requirement_json carries structured
 * unlock gate (null for purchasable/Common/Rare).
 */
@Entity
@Table(name = "avatars")
public class Avatar extends BaseEntity {

    @Column(name = "code", nullable = false, length = 80)
    private String code;

    @Column(name = "display_name", nullable = false, length = 100)
    private String displayName;

    @Column(name = "description", length = 200)
    private String description;

    @Column(name = "rarity", nullable = false, length = 30)
    private String rarity;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "home_subject_id")
    private Subject homeSubject;

    @Column(name = "asset_key", nullable = false, length = 120)
    private String assetKey;

    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.JSON)
    @Column(name = "requirement_json", columnDefinition = "JSON")
    private String requirementJson;

    @Column(name = "credit_cost")
    private Integer creditCost;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @Column(name = "display_order", nullable = false)
    private int displayOrder;

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getDisplayName() {
        return displayName;
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getRarity() {
        return rarity;
    }

    public void setRarity(String rarity) {
        this.rarity = rarity;
    }

    public Subject getHomeSubject() {
        return homeSubject;
    }

    public void setHomeSubject(Subject homeSubject) {
        this.homeSubject = homeSubject;
    }

    public String getAssetKey() {
        return assetKey;
    }

    public void setAssetKey(String assetKey) {
        this.assetKey = assetKey;
    }

    public String getRequirementJson() {
        return requirementJson;
    }

    public void setRequirementJson(String requirementJson) {
        this.requirementJson = requirementJson;
    }

    public Integer getCreditCost() {
        return creditCost;
    }

    public void setCreditCost(Integer creditCost) {
        this.creditCost = creditCost;
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
