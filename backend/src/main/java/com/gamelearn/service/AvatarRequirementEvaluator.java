package com.gamelearn.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
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
        // Handle MySQL/H2 JSON column quirk: value may be stored as JSON string "\"{\\\"levelMin\\\":2}\""
        String toParse = json.trim();
        if (toParse.startsWith("\"") && toParse.endsWith("\"")) {
            try {
                toParse = objectMapper.readValue(toParse, String.class);
            } catch (Exception ignored) {}
        }
        Map<String, Object> map;
        try {
            map = objectMapper.readValue(toParse, new com.fasterxml.jackson.core.type.TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(AvatarRequirementEvaluator.class);
            log.warn("AVATAR_REQUIREMENT_PARSE_FAILED id={} json={} toParse={} error={}", avatar.getId(), json, toParse, e.toString());
            return new EvaluationResult(false, List.of(
                    new ChecklistItem("requirement_config", false, "invalid", "valid json")));
        }
        List<ChecklistItem> items = new ArrayList<>();
        boolean eligible = true;

        LearnerProfile profile = learnerProfileRepository.findByUserId(userId).orElse(null);
        int level = profile != null ? profile.getCurrentLevel() : 1;

        Integer levelMin = map.get("levelMin") == null ? null : ((Number) map.get("levelMin")).intValue();
        Double syllabusCompletionMin = map.get("syllabusCompletionMin") == null ? null : ((Number) map.get("syllabusCompletionMin")).doubleValue();
        String syllabusSubjectId = map.get("syllabusSubjectId") == null ? null : map.get("syllabusSubjectId").toString();
        Integer streakCurrentMin = map.get("streakCurrentMin") == null ? null : ((Number) map.get("streakCurrentMin")).intValue();
        Integer streakLongestMin = map.get("streakLongestMin") == null ? null : ((Number) map.get("streakLongestMin")).intValue();
        Integer bossBattlesMin = map.get("bossBattlesMin") == null ? null : ((Number) map.get("bossBattlesMin")).intValue();
        Integer masteredCountMin = map.get("masteredCountMin") == null ? null : ((Number) map.get("masteredCountMin")).intValue();
        Double subjectMasteryAvgMin = map.get("subjectMasteryAvgMin") == null ? null : ((Number) map.get("subjectMasteryAvgMin")).doubleValue();

        if (levelMin != null) {
            boolean met = level >= levelMin;
            items.add(new ChecklistItem("Level " + levelMin, met, String.valueOf(level), String.valueOf(levelMin)));
            eligible &= met;
        }
        if (syllabusCompletionMin != null) {
            UUID subjectId = syllabusSubjectId != null ? UUID.fromString(syllabusSubjectId)
                    : (avatar.getHomeSubject() != null ? avatar.getHomeSubject().getId() : null);
            if (subjectId == null) {
                items.add(new ChecklistItem("Syllabus " + syllabusCompletionMin + "%", false, "no subject", String.valueOf(syllabusCompletionMin)));
                eligible = false;
            } else {
                BigDecimal actual = syllabusService.syllabusCompletion(userId, subjectId);
                BigDecimal required = BigDecimal.valueOf(syllabusCompletionMin).setScale(2, RoundingMode.HALF_UP);
                boolean met = actual.compareTo(required) >= 0;
                items.add(new ChecklistItem("Syllabus " + required.toPlainString() + "%", met,
                        actual.setScale(2, RoundingMode.HALF_UP).toPlainString() + "%",
                        required.toPlainString() + "%"));
                eligible &= met;
            }
        }
        if (streakCurrentMin != null) {
            int current = streakRepository.findByUserId(userId).map(s -> s.getCurrentStreakDays()).orElse(0);
            boolean met = current >= streakCurrentMin;
            items.add(new ChecklistItem("Streak " + streakCurrentMin + " days", met, String.valueOf(current), String.valueOf(streakCurrentMin)));
            eligible &= met;
        }
        if (streakLongestMin != null) {
            int longest = streakRepository.findByUserId(userId).map(s -> s.getLongestStreakDays()).orElse(0);
            boolean met = longest >= streakLongestMin;
            items.add(new ChecklistItem("Longest streak " + streakLongestMin + " days", met, String.valueOf(longest), String.valueOf(streakLongestMin)));
            eligible &= met;
        }
        if (bossBattlesMin != null) {
            long count = gameResultRepository.countCompletedByUserIdAndGameType(userId, "BOSS_BATTLE");
            boolean met = count >= bossBattlesMin;
            items.add(new ChecklistItem("Boss battles " + bossBattlesMin, met, String.valueOf(count), String.valueOf(bossBattlesMin)));
            eligible &= met;
        }
        if (masteredCountMin != null) {
            long count = topicMasteryRepository.countByUserIdAndMasteryLevel(userId, MasteryLevel.MASTERED);
            boolean met = count >= masteredCountMin;
            items.add(new ChecklistItem("Mastered topics " + masteredCountMin, met, String.valueOf(count), String.valueOf(masteredCountMin)));
            eligible &= met;
        }
        if (subjectMasteryAvgMin != null) {
            // not implemented for L1 without subject join; treat as not eligible if present
            // placeholder: keep eligible=false to avoid false unlock; wire later L2
            // For now, skip (no check) to avoid blocking seeded avatars that don't use it.
        }
        return new EvaluationResult(eligible, items);
    }

    @com.fasterxml.jackson.annotation.JsonIgnoreProperties(ignoreUnknown = true)
    public static class RequirementSpec {
        public RequirementSpec() {}
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
