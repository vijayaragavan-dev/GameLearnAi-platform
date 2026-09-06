package com.gamelearn.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.entity.Progress;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.enums.ProgressStatus;
import com.gamelearn.repository.ProgressRepository;
import com.gamelearn.repository.TopicRepository;

/**
 * Syllabus completion (Phase L1) — canonical definition (spec section 10, 15):
 * syllabusCompletion(subjectId, userId) = completed_topics / total_active_topics
 * where completed = progress.status==COMPLETED && completion_percentage == 100.00
 * and inactive topics are excluded from denominator. HALF_UP to 2dp, Decimal.
 */
@Service
public class SyllabusService {

    private final TopicRepository topicRepository;
    private final ProgressRepository progressRepository;

    public SyllabusService(TopicRepository topicRepository, ProgressRepository progressRepository) {
        this.topicRepository = topicRepository;
        this.progressRepository = progressRepository;
    }

    @Transactional(readOnly = true)
    public BigDecimal syllabusCompletion(UUID userId, UUID subjectId) {
        List<Topic> activeTopics = topicRepository.findBySubjectIdAndActiveTrueOrderByDisplayOrderAscIdAsc(subjectId);
        int total = activeTopics.size();
        if (total == 0) {
            return BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        }
        Set<UUID> topicIds = activeTopics.stream().map(Topic::getId).collect(Collectors.toSet());
        List<Progress> progresses = progressRepository.findByUserIdOrderByLastActivityAtDescIdAsc(userId);
        long completed = progresses.stream()
                .filter(p -> topicIds.contains(p.getTopic().getId()))
                .filter(p -> p.getStatus() == ProgressStatus.COMPLETED)
                .filter(p -> p.getCompletionPercentage() != null
                        && p.getCompletionPercentage().compareTo(new BigDecimal("100.00")) == 0)
                .map(p -> p.getTopic().getId())
                .distinct()
                .count();
        BigDecimal pct = BigDecimal.valueOf(completed * 100L)
                .divide(BigDecimal.valueOf(total), 2, RoundingMode.HALF_UP);
        return pct;
    }

    @Transactional(readOnly = true)
    public boolean isAtLeast(UUID userId, UUID subjectId, BigDecimal threshold) {
        BigDecimal actual = syllabusCompletion(userId, subjectId);
        return actual.compareTo(threshold) >= 0;
    }
}
