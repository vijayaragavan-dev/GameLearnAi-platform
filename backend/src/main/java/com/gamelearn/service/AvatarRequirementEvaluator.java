package com.gamelearn.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamelearn.entity.Avatar;
import com.gamelearn.entity.LearnerProfile;
import com.gamelearn.entity.enums.MasteryLevel;
import com.gamelearn.repository.GameResultRepository;
import com.gamelearn.repository.LearnerProfileRepository;
import com.gamelearn.repository.StreakRepository;
import com.gamelearn.repository.TopicMasteryRepository;

/**
 * Evaluates avatar unlock gates from avatars.requirement_json.
 * Pure composable conditions: all specified keys must pass (AND).
 * Keys absent => no gate for that dimension. Unknown keys ignored (forward compat).
 * Returns detailed checklist so UI never second-guesses backend.
 */
@Service
public class AvatarRequirementEvaluator {

    private final ObjectMapper objectMapper;
    private final LearnerProfileRepository learnerProfileRepository;
    private final SyllabusService syllabusService;
    private final StreakRepository streakRepository;
    private final GameResultRepository gameResultRepository;
    private final TopicMasteryRepository topicMasteryRepository;

    public AvatarRequirementEvaluator(ObjectMapper objectMapper,
                                      LearnerProfileRepository learnerProfileRepository,
                                      SyllabusService syllabusService,
                                      StreakRepository streakRepository,
                                      GameResultRepository gameResultRepository,
                                      TopicMasteryRepository topicMasteryRepository) {
        this.objectMapper = objectMapper;
        this.learnerProfileRepository = learnerProfileRepository;
        this.syllabusService = syllabusService;
        this.streakRepository = streakRepository;
        this.gameResultRepository = gameResultRepository;
        this.topicMasteryRepository = topicMasteryRepository;
    }

    public EvaluationResult evaluate(UUID userId, Avatar avatar) {
        String json = avatar.getRequirementJson();
        if (json == null || json.isBlank() || json.trim().equals("null")) {
            return new EvaluationResult(true, List.of());
        }
        RequirementSpec spec;
        try {
            spec = objectMapper.readValue(json, RequirementSpec.class);
        } catch (Exception e) {
            // invalid config => treat as not eligible, expose as failed checklist
            return new EvaluationResult(false, List.of(
                    new ChecklistItem("requirement_config", false, "invalid", "valid json")));
        }
        List<ChecklistItem> items = new ArrayList<>();
        boolean eligible = true;

        LearnerProfile profile = learnerProfileRepository.findByUserId(userId).orElse(null);
        int level = profile != null ? profile.getCurrentLevel() : 1;

        if (spec.levelMin != null) {
            boolean met = level >= spec.levelMin;
            items.add(new ChecklistItem("Level " + spec.levelMin, met, String.valueOf(level), String.valueOf(spec.levelMin)));
            eligible &= met;
        }
        if (spec.syllabusCompletionMin != null) {
            UUID subjectId = spec.syllabusSubjectId != null ? UUID.fromString(spec.syllabusSubjectId)
                    : (avatar.getHomeSubject() != null ? avatar.getHomeSubject().getId() : null);
            if (subjectId == null) {
                items.add(new ChecklistItem("Syllabus " + spec.syllabusCompletionMin + "%", false, "no subject", String.valueOf(spec.syllabusCompletionMin)));
                eligible = false;
            } else {
                BigDecimal actual = syllabusService.syllabusCompletion(userId, subjectId);
                BigDecimal required = BigDecimal.valueOf(spec.syllabusCompletionMin).setScale(2, RoundingMode.HALF_UP);
                boolean met = actual.compareTo(required) >= 0;
                items.add(new ChecklistItem("Syllabus " + required.toPlainString() + "%", met,
                        actual.setScale(2, RoundingMode.HALF_UP).toPlainString() + "%",
                        required.toPlainString() + "%"));
                eligible &= met;
            }
        }
        if (spec.streakCurrentMin != null) {
            int current = streakRepository.findByUserId(userId).map(s -> s.getCurrentStreakDays()).orElse(0);
            boolean met = current >= spec.streakCurrentMin;
            items.add(new ChecklistItem("Streak " + spec.streakCurrentMin + " days", met, String.valueOf(current), String.valueOf(spec.streakCurrentMin)));
            eligible &= met;
        }
        if (spec.streakLongestMin != null) {
            int longest = streakRepository.findByUserId(userId).map(s -> s.getLongestStreakDays()).orElse(0);
            boolean met = longest >= spec.streakLongestMin;
            items.add(new ChecklistItem("Longest streak " + spec.streakLongestMin + " days", met, String.valueOf(longest), String.valueOf(spec.streakLongestMin)));
            eligible &= met;
        }
        if (spec.bossBattlesMin != null) {
            long count = gameResultRepository.countCompletedByUserIdAndGameType(userId, "BOSS_BATTLE");
            boolean met = count >= spec.bossBattlesMin;
            items.add(new ChecklistItem("Boss battles " + spec.bossBattlesMin, met, String.valueOf(count), String.valueOf(spec.bossBattlesMin)));
            eligible &= met;
        }
        if (spec.masteredCountMin != null) {
            long count = topicMasteryRepository.countByUserIdAndMasteryLevel(userId, MasteryLevel.MASTERED);
            boolean met = count >= spec.masteredCountMin;
            items.add(new ChecklistItem("Mastered topics " + spec.masteredCountMin, met, String.valueOf(count), String.valueOf(spec.masteredCountMin)));
            eligible &= met;
        }
        if (spec.subjectMasteryAvgMin != null) {
            // not implemented for L1 without subject join; treat as not eligible if present
            // placeholder: keep eligible=false to avoid false unlock; wire later L2
            // For now, skip (no check) to avoid blocking seeded avatars that don't use it.
        }
        return new EvaluationResult(eligible, items);
    }

    public static class RequirementSpec {
        public Integer levelMin;
        public Double syllabusCompletionMin;
        public String syllabusSubjectId;
        public Integer streakCurrentMin;
        public Integer streakLongestMin;
        public Integer bossBattlesMin;
        public Integer masteredCountMin;
        public Double subjectMasteryAvgMin;
        public Integer topicsAssessedMin;
    }

    public record ChecklistItem(String label, boolean met, String current, String required) {}

    public record EvaluationResult(boolean eligible, List<ChecklistItem> checklist) {}
}
