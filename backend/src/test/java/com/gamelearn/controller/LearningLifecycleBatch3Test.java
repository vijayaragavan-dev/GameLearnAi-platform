package com.gamelearn.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import com.fasterxml.jackson.databind.JsonNode;

/**
 * Batch 3 / Phase 6: the 11-subject world through the ONE authoritative
 * lifecycle — learning path → lesson/quiz → result → progress/mastery →
 * adaptive recommendation → XP/streak/achievement — with cross-subject
 * isolation. No production change was required (all systems are generic);
 * these tests prove it.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class LearningLifecycleBatch3Test extends AbstractCoreApiTest {

    private static final List<String> ALL_SUBJECTS = List.of(
            "11111111-1111-1111-1111-111111111101",
            "11111111-1111-1111-1111-111111111102",
            "11111111-1111-1111-1111-111111111103",
            "11111111-1111-1111-1111-111111111104",
            "11111111-1111-1111-1111-111111111105",
            "11111111-1111-1111-1111-111111111106",
            "11111111-1111-1111-1111-111111111107",
            "11111111-1111-1111-1111-111111111108",
            "11111111-1111-1111-1111-111111111109",
            "11111111-1111-1111-1111-111111111110",
            "11111111-1111-1111-1111-111111111111");

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private com.gamelearn.repository.TopicMasteryRepository topicMasteryRepository;

    @Test
    void pathsGenerateForAllElevenSubjects() throws Exception {
        for (String subjectId : ALL_SUBJECTS) {
            String[] learner = registerLearner("path11");
            String first = mockMvc.perform(post("/api/v1/learning-path/" + subjectId + "/generate")
                            .header("Authorization", bearer(learner[0]))
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isCreated())
                    .andReturn().getResponse().getContentAsString();
            JsonNode nodes = objectMapper.readTree(first).path("nodes");
            assertThat(nodes.size()).as("nodes for %s", subjectId).isGreaterThan(0);
            List<String> topicIds = new ArrayList<>();
            for (JsonNode node : nodes) {
                String topicId = node.path("topicId").asText(node.path("topic").asText(""));
                assertThat(topicId).as("node topic for %s", subjectId).isNotBlank();
                topicIds.add(topicId);
            }
            assertThat(topicIds).doesNotHaveDuplicates();
            for (String topicId : topicIds) {
                String owner = jdbcTemplate.queryForObject(
                        "SELECT subject_id FROM topics WHERE id = ?", String.class, topicId);
                assertThat(owner).as("node subject for %s", subjectId).isEqualTo(subjectId);
            }
            // Idempotent second generation returns the same ACTIVE path.
            mockMvc.perform(post("/api/v1/learning-path/" + subjectId + "/generate")
                            .header("Authorization", bearer(learner[0]))
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk());
            // Caller-scoped readback shows exactly one path.
            mockMvc.perform(get("/api/v1/learning-path/" + subjectId)
                            .header("Authorization", bearer(learner[0])))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.length()").value(1));
        }
    }

    @ParameterizedTest(name = "new subject {0} quiz lifecycle")
    @CsvSource({
            "11111111-1111-1111-1111-111111111106, 22222222-2222-2222-2222-222222222244, 55555555-5555-5555-5555-555555555544",
            "11111111-1111-1111-1111-111111111107, 22222222-2222-2222-2222-222222222264, 55555555-5555-5555-5555-555555555548",
            "11111111-1111-1111-1111-111111111108, 22222222-2222-2222-2222-222222222287, 55555555-5555-5555-5555-555555555553",
            "11111111-1111-1111-1111-111111111109, 22222222-2222-2222-2222-222222222306, 55555555-5555-5555-5555-555555555558",
            "11111111-1111-1111-1111-111111111110, 22222222-2222-2222-2222-222222222330, 55555555-5555-5555-5555-555555555563",
            "11111111-1111-1111-1111-111111111111, 22222222-2222-2222-2222-222222222349, 55555555-5555-5555-5555-555555555567"
    })
    void newSubjectQuizLifecycle(String subjectId, String topicId, String quizId) throws Exception {
        String[] learner = registerLearner("lifecycle");
        UUID userId = userByEmail(learner[1]).getId();

        submitAllCorrect(learner[0], quizId);

        // Exactly one mastery row, at MASTERED after a perfect first attempt.
        List<java.util.Map<String, Object>> mastery = jdbcTemplate.queryForList(
                "SELECT mastery_level, attempt_count FROM topic_mastery WHERE user_id = ? AND topic_id = ?",
                userId.toString(), topicId);
        assertThat(mastery).hasSize(1);
        assertThat(mastery.get(0).get("mastery_level")).isEqualTo("MASTERED");
        assertThat(((Number) mastery.get(0).get("attempt_count")).intValue()).isEqualTo(1);

        // Second submission updates the same row — never duplicates.
        submitAllCorrect(learner[0], quizId);
        Integer rows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM topic_mastery WHERE user_id = ? AND topic_id = ?",
                Integer.class, userId.toString(), topicId);
        Integer attempts = jdbcTemplate.queryForObject(
                "SELECT attempt_count FROM topic_mastery WHERE user_id = ? AND topic_id = ?",
                Integer.class, userId.toString(), topicId);
        assertThat(rows).isEqualTo(1);
        assertThat(attempts).isEqualTo(2);

        // Quiz XP is attributed to the quiz's subject (subject board sees it).
        Long subjectXp = jdbcTemplate.queryForObject(
                "SELECT COALESCE(SUM(x.amount),0) FROM xp_transactions x "
                        + "JOIN quiz_attempts a ON a.id = x.reference_id "
                        + "JOIN quizzes q ON q.id = a.quiz_id "
                        + "JOIN topics t ON t.id = q.topic_id "
                        + "WHERE x.user_id = ? AND t.subject_id = ? AND x.reference_type = 'QUIZ_ATTEMPT'",
                Long.class, userId.toString(), subjectId);
        assertThat(subjectXp).isGreaterThan(0);
        mockMvc.perform(get("/api/v1/leaderboard/subject/" + subjectId)
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk());
    }

    @Test
    void confusingTopicNamesStaySeparate() throws Exception {
        String[] learner = registerLearner("confuse");
        UUID userId = userByEmail(learner[1]).getId();
        // OOP quiz on "Java Platform" must not create Programming mastery.
        submitAllCorrect(learner[0], "55555555-5555-5555-5555-555555555544");
        Integer programmingMastery = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM topic_mastery m JOIN topics t ON t.id = m.topic_id "
                        + "WHERE m.user_id = ? AND t.subject_id = '11111111-1111-1111-1111-111111111101'",
                Integer.class, userId.toString());
        assertThat(programmingMastery).isEqualTo(0);
        // "Control Flow" (Programming 212) vs "Control Flow in Java" (OOP 248):
        // progress rows are per-topic and resolve to different subjects.
        var progTopic = topicRepository.findById(UUID.fromString("22222222-2222-2222-2222-222222222212")).orElseThrow();
        var oopTopic = topicRepository.findById(UUID.fromString("22222222-2222-2222-2222-222222222248")).orElseThrow();
        var user = userRepository.findById(userId).orElseThrow();
        newProgress(user, progTopic, new java.math.BigDecimal("100.00"),
                com.gamelearn.entity.enums.ProgressStatus.COMPLETED, java.time.Instant.now());
        newProgress(user, oopTopic, new java.math.BigDecimal("50.00"),
                com.gamelearn.entity.enums.ProgressStatus.IN_PROGRESS, java.time.Instant.now());
        String progBody = mockMvc.perform(get("/api/v1/progress/22222222-2222-2222-2222-222222222212")
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        String oopBody = mockMvc.perform(get("/api/v1/progress/22222222-2222-2222-2222-222222222248")
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        assertThat(objectMapper.readTree(progBody).path("completionPercentage").asText())
                .isNotEqualTo(objectMapper.readTree(oopBody).path("completionPercentage").asText());
    }

    @Test
    void principalIsolation() throws Exception {
        String[] alice = registerLearner("alice6");
        String[] bob = registerLearner("bob6");
        submitAllCorrect(alice[0], "55555555-5555-5555-5555-555555555544");
        // Bob sees no progress for Alice's topic and no paths in the subject.
        mockMvc.perform(get("/api/v1/progress/22222222-2222-2222-2222-222222222244")
                        .header("Authorization", bearer(bob[0])))
                .andExpect(status().isNotFound());
        mockMvc.perform(get("/api/v1/learning-path/11111111-1111-1111-1111-111111111106")
                        .header("Authorization", bearer(bob[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
        // Alice's mastery rows are exactly hers.
        UUID aliceId = userByEmail(alice[1]).getId();
        UUID bobId = userByEmail(bob[1]).getId();
        assertThat(topicMasteryRepository.findByUserIdAndTopicId(aliceId,
                UUID.fromString("22222222-2222-2222-2222-222222222244"))).isPresent();
        assertThat(topicMasteryRepository.findByUserIdAndTopicId(bobId,
                UUID.fromString("22222222-2222-2222-2222-222222222244"))).isEmpty();
    }

    @Test
    void mixedHistoryAcrossSubjects() throws Exception {
        String[] learner = registerLearner("mixed6");
        UUID userId = userByEmail(learner[1]).getId();
        submitAllCorrect(learner[0], "55555555-5555-5555-5555-555555555523"); // DBMS
        submitAllCorrect(learner[0], "55555555-5555-5555-5555-555555555544"); // OOP last
        // Per-topic mastery + active recommendation each; no cross contamination.
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM topic_mastery WHERE user_id = ?", Integer.class,
                userId.toString())).isEqualTo(2);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM recommendations WHERE user_id = ? AND status = 'ACTIVE'",
                Integer.class, userId.toString())).isEqualTo(2);
        // Overall mastery is the mean; current subject follows the last quiz.
        String overall = jdbcTemplate.queryForObject(
                "SELECT overall_mastery FROM learner_profiles WHERE user_id = ?", String.class,
                userId.toString());
        assertThat(new java.math.BigDecimal(overall)).isEqualByComparingTo("100.00");
        String current = jdbcTemplate.queryForObject(
                "SELECT current_subject_id FROM learner_profiles WHERE user_id = ?", String.class,
                userId.toString());
        assertThat(current).isEqualTo("11111111-1111-1111-1111-111111111106");
    }

    @Test
    void gameLifecycleIsSubjectNeutral() throws Exception {
        String[] learner = registerLearner("game6");
        UUID userId = userByEmail(learner[1]).getId();
        submitAllCorrect(learner[0], "55555555-5555-5555-5555-555555555523"); // DBMS quiz
        long xpBefore = totalXp(userId);
        String gameBody = """
                {"clientRequestId": "%s", "gameType": "quiz_battle", "difficulty": "MEDIUM",
                 "completed": true, "score": 500, "durationSeconds": 120, "bestCombo": 3}
                """.formatted(UUID.randomUUID());
        // NOTE: game-result submit returns 200 by existing contract
        // (GameResultController has no CREATED mapping) — asserted as-is.
        mockMvc.perform(post("/api/v1/me/game-results")
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON).content(gameBody))
                .andExpect(status().isOk());
        assertThat(totalXp(userId)).isGreaterThan(xpBefore);
        // Game XP never leaks into a subject board: FDS position stays unranked.
        String position = mockMvc.perform(get("/api/v1/me/leaderboard-position")
                        .header("Authorization", bearer(learner[0]))
                        .param("segment", "SUBJECT")
                        .param("subjectId", "11111111-1111-1111-1111-111111111110"))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        JsonNode pos = objectMapper.readTree(position);
        assertThat(pos.path("rank").asInt()).isEqualTo(pos.path("totalPlayers").asInt() + 1);
        // Game results create no mastery and do not move the current subject.
        assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM topic_mastery WHERE user_id = ?",
                Integer.class, userId.toString())).isEqualTo(1);
        assertThat(jdbcTemplate.queryForObject("SELECT current_subject_id FROM learner_profiles WHERE user_id = ?",
                String.class, userId.toString())).isEqualTo("11111111-1111-1111-1111-111111111103");
        // Idempotent replay grants nothing more.
        long xpAfterFirst = totalXp(userId);
        mockMvc.perform(post("/api/v1/me/game-results")
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON).content(gameBody))
                .andExpect(status().isOk());
        assertThat(totalXp(userId)).isEqualTo(xpAfterFirst);
    }

    @Test
    void legacyProgrammingRegression() throws Exception {
        String[] learner = registerLearner("legacy6");
        submitAllCorrect(learner[0], "55555555-5555-5555-5555-555555555511");
        UUID userId = userByEmail(learner[1]).getId();
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM topic_mastery WHERE user_id = ? AND topic_id = "
                        + "'22222222-2222-2222-2222-222222222211'",
                Integer.class, userId.toString())).isEqualTo(1);
        mockMvc.perform(post("/api/v1/learning-path/11111111-1111-1111-1111-111111111101/generate")
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isCreated());
    }

    private void submitAllCorrect(String token, String quizId) throws Exception {
        // Correct answers are read via JDBC: QuizQuestion.question is a lazy
        // proxy with no session in tests, and only the id is safely readable.
        List<java.util.Map<String, Object>> rows = jdbcTemplate.queryForList(
                "SELECT q.id AS id, q.correct_answer AS correct_answer FROM quiz_questions qq "
                        + "JOIN questions q ON q.id = qq.question_id WHERE qq.quiz_id = ? "
                        + "ORDER BY qq.question_order ASC",
                quizId);
        assertThat(rows).isNotEmpty();
        StringBuilder answers = new StringBuilder();
        for (var row : rows) {
            if (answers.length() > 0) {
                answers.append(',');
            }
            answers.append("{\"questionId\": \"").append(row.get("id"))
                    .append("\", \"selectedAnswer\": ").append(jsonEscape((String) row.get("correct_answer")))
                    .append('}');
        }
        mockMvc.perform(post("/api/v1/quiz/" + quizId + "/submit")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"answers\": [" + answers + "]}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.score").value(100.0));
    }

    private String jsonEscape(String value) throws Exception {
        return objectMapper.writeValueAsString(value);
    }

    private long totalXp(UUID userId) {
        return jdbcTemplate.queryForObject("SELECT total_xp FROM learner_profiles WHERE user_id = ?",
                Long.class, userId.toString());
    }
}
