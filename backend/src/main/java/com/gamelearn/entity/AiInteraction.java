package com.gamelearn.entity;

import com.gamelearn.entity.enums.AiInteractionStatus;
import com.gamelearn.entity.enums.AiInteractionType;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

/**
 * AI interaction metadata (Database Specification section 26).
 * Never stores API keys, JWTs, passwords or system secrets.
 */
@Entity
@Table(name = "ai_interactions")
public class AiInteraction extends ImmutableEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "interaction_type", nullable = false, length = 40)
    private AiInteractionType interactionType;

    @Column(name = "model_name", length = 100)
    private String modelName;

    @Column(name = "prompt_version", length = 30)
    private String promptVersion;

    // SqlTypes.JSON makes Hibernate bind the string as a real JSON document
    // (parsed by MySQL/H2) instead of a quoted string literal.
    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.JSON)
    @Column(name = "request_context_json", columnDefinition = "JSON")
    private String requestContextJson;

    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.JSON)
    @Column(name = "response_json", columnDefinition = "JSON")
    private String responseJson;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 30)
    private AiInteractionStatus status;

    @Column(name = "latency_ms")
    private Integer latencyMs;

    @Column(name = "error_code", length = 80)
    private String errorCode;

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public AiInteractionType getInteractionType() {
        return interactionType;
    }

    public void setInteractionType(AiInteractionType interactionType) {
        this.interactionType = interactionType;
    }

    public String getModelName() {
        return modelName;
    }

    public void setModelName(String modelName) {
        this.modelName = modelName;
    }

    public String getPromptVersion() {
        return promptVersion;
    }

    public void setPromptVersion(String promptVersion) {
        this.promptVersion = promptVersion;
    }

    public String getRequestContextJson() {
        return requestContextJson;
    }

    public void setRequestContextJson(String requestContextJson) {
        this.requestContextJson = requestContextJson;
    }

    public String getResponseJson() {
        return responseJson;
    }

    public void setResponseJson(String responseJson) {
        this.responseJson = responseJson;
    }

    public AiInteractionStatus getStatus() {
        return status;
    }

    public void setStatus(AiInteractionStatus status) {
        this.status = status;
    }

    public Integer getLatencyMs() {
        return latencyMs;
    }

    public void setLatencyMs(Integer latencyMs) {
        this.latencyMs = latencyMs;
    }

    public String getErrorCode() {
        return errorCode;
    }

    public void setErrorCode(String errorCode) {
        this.errorCode = errorCode;
    }
}
