package com.gamelearn.entity;

import java.math.BigDecimal;

import com.gamelearn.entity.enums.PathNodeStatus;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "learning_path_nodes")
public class LearningPathNode extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "learning_path_id", nullable = false)
    private LearningPath learningPath;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "topic_id", nullable = false)
    private Topic topic;

    @Column(name = "sequence_number", nullable = false)
    private int sequenceNumber;

    @Column(name = "required_mastery", precision = 5, scale = 2)
    private BigDecimal requiredMastery;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 30)
    private PathNodeStatus status;

    public LearningPath getLearningPath() {
        return learningPath;
    }

    public void setLearningPath(LearningPath learningPath) {
        this.learningPath = learningPath;
    }

    public Topic getTopic() {
        return topic;
    }

    public void setTopic(Topic topic) {
        this.topic = topic;
    }

    public int getSequenceNumber() {
        return sequenceNumber;
    }

    public void setSequenceNumber(int sequenceNumber) {
        this.sequenceNumber = sequenceNumber;
    }

    public BigDecimal getRequiredMastery() {
        return requiredMastery;
    }

    public void setRequiredMastery(BigDecimal requiredMastery) {
        this.requiredMastery = requiredMastery;
    }

    public PathNodeStatus getStatus() {
        return status;
    }

    public void setStatus(PathNodeStatus status) {
        this.status = status;
    }
}
