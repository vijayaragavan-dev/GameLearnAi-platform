package com.gamelearn.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import com.fasterxml.jackson.databind.JsonNode;

/**
 * Phase 10: 11-world content completeness + playability foundation.
 * Verifies the V28 second content round, kind parity, compat/content
 * reconciliation, similar-concept isolation and legacy stability.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ContentCompletenessBatch10Test extends AbstractCoreApiTest {

    private static final Map<String, int[]> NEW_SUBJECTS = Map.of(
            "11111111-1111-1111-1111-111111111106", new int[] {20, 8, 24, 8},
            "11111111-1111-1111-1111-111111111107", new int[] {23, 10, 30, 10},
            "11111111-1111-1111-1111-111111111108", new int[] {19, 10, 30, 10},
            "11111111-1111-1111-1111-111111111109", new int[] {24, 10, 30, 10},
            "11111111-1111-1111-1111-111111111110", new int[] {19, 8, 24, 8},
            "11111111-1111-1111-1111-111111111111", new int[] {29, 12, 36, 12});

    private static final Map<String, String> EXPECTED_KINDS = Map.ofEntries(
            Map.entry("quiz_battle", "QUESTION"),
            Map.entry("speed_run", "QUESTION"),
            Map.entry("boss_battle", "QUESTION"),
            Map.entry("target_challenge", "QUESTION"),
            Map.entry("snake_and_ladder", "QUESTION"),
            Map.entry("unlock_code", "QUESTION"),
            Map.entry("puzzle_arena", "QUESTION"),
            Map.entry("mystery_case", "QUESTION"),
            Map.entry("debug_arena", "QUESTION"),
            Map.entry("memory_match", "CONCEPT"),
            Map.entry("concept_builder", "CONCEPT"),
            Map.entry("drag_drop", "STRUCTURE"),
            Map.entry("sequence_master", "STRUCTURE"),
            Map.entry("connectivity_lab", "STRUCTURE"));

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void coverageMatrixPerNewSubject() {
        NEW_SUBJECTS.forEach((subjectId, counts) -> {
            assertThat(activeTopics(subjectId)).as("topics %s", subjectId).isEqualTo(counts[0]);
            assertThat(backedTopics(subjectId)).as("backed topics %s", subjectId).isEqualTo(counts[1]);
            assertThat(questionCount(subjectId)).as("questions %s", subjectId).isEqualTo(counts[2]);
            assertThat(quizCount(subjectId)).as("quizzes %s", subjectId).isEqualTo(counts[3]);
            assertThat(difficulties(subjectId)).contains("EASY", "MEDIUM");
        });
        // HARD questions exist where educationally sensible (never forced).
        assertThat(difficulties("11111111-1111-1111-1111-111111111106")).contains("HARD");
        assertThat(difficulties("11111111-1111-1111-1111-111111111109")).contains("HARD");
        assertThat(difficulties("11111111-1111-1111-1111-111111111111")).contains("HARD");
        // Totals across the expansion: 58 backed topics, 174 questions, 58 quizzes.
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(DISTINCT t.id) FROM topics t JOIN questions q ON q.topic_id = t.id "
                        + "WHERE t.subject_id LIKE '11111111-1111-1111-1111-1111111111%' "
                        + "AND t.subject_id > '11111111-1111-1111-1111-111111111105' "
                        + "AND q.is_active = TRUE AND q.question_type = 'MCQ'",
                Integer.class)).isEqualTo(58);
    }

    @Test
    void everyNewUnitHasTwoBackedTopics() {
        List<Map<String, Object>> thin = jdbcTemplate.queryForList(
                "SELECT u.id, COUNT(DISTINCT CASE WHEN q.id IS NOT NULL THEN t.id END) AS backed "
                        + "FROM units u JOIN topics t ON t.unit_id = u.id "
                        + "LEFT JOIN questions q ON q.topic_id = t.id AND q.is_active = TRUE "
                        + "AND q.question_type = 'MCQ' "
                        + "WHERE u.id LIKE '77777777-%' GROUP BY u.id HAVING backed <> 2");
        assertThat(thin).isEmpty();
    }

    @Test
    void contentKindParityAcrossAllFourteenGames() {
        assertThat(EXPECTED_KINDS).hasSize(14);
        EXPECTED_KINDS.forEach((gameType, kind) -> assertThat(
                com.gamelearn.gamification.GameContentKind.forGameType(gameType).name())
                .as("kind for %s", gameType).isEqualTo(kind));
        assertThat(com.gamelearn.gamification.GameType.allIds()).hasSize(14);
    }

    @Test
    void compatReconciliationStaysTruthful() throws Exception {
        String[] learner = registerLearner("recon10");
        assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM subject_game_compat",
                Integer.class)).isEqualTo(95);
        for (String subjectId : List.of(
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
                "11111111-1111-1111-1111-111111111111")) {
            String body = mockMvc.perform(get("/api/v1/subjects/" + subjectId + "/games")
                            .header("Authorization", bearer(learner[0])))
                    .andExpect(status().isOk())
                    .andReturn().getResponse().getContentAsString();
            JsonNode games = objectMapper.readTree(body).path("games");
            assertThat(games.size()).isGreaterThan(0);
            for (JsonNode game : games) {
                assertThat(game.path("hasContent").asBoolean())
                        .as("%s/%s playable", subjectId, game.path("gameType").asText()).isTrue();
            }
        }
    }

    @Test
    void round2SeedIntegrityAndSemantics() {
        // Deterministic identity spot checks with semantic (not just structural) meaning.
        assertThat(questionText("44444444-4444-4444-4444-444444444570"))
                .contains("16-bit Unicode");
        assertThat(correctAnswer("44444444-4444-4444-4444-444444444579")).isEqualTo("ArrayList");
        assertThat(correctAnswer("44444444-4444-4444-4444-444444444613"))
                .isEqualTo("Admissible heuristic never overestimating");
        assertThat(correctAnswer("44444444-4444-4444-4444-444444444645")).isEqualTo("Theta(n log n)");
        assertThat(questionText("44444444-4444-4444-4444-444444444654")).contains("backtracking");
        // Round-2 quizzes link same-topic questions in contiguous order.
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM quiz_questions WHERE id >= "
                        + "'66666666-6666-6666-6666-666666666748' AND id <= "
                        + "'66666666-6666-6666-6666-666666666834'",
                Integer.class)).isEqualTo(87);
        assertThat(jdbcTemplate.queryForList(
                "SELECT qq.id FROM quiz_questions qq JOIN quizzes q ON q.id = qq.quiz_id "
                        + "JOIN questions quest ON quest.id = qq.question_id "
                        + "WHERE q.id LIKE '55555555-5555-5555-5555-5555555555%' "
                        + "AND quest.topic_id <> q.topic_id")).isEmpty();
        // Restart-safe reseed guard.
        int inserted = jdbcTemplate.update(
                "INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, "
                        + "options_json, correct_answer, explanation, source_type, is_active, "
                        + "created_at, updated_at) "
                        + "SELECT '44444444-4444-4444-4444-444444444570', "
                        + "'22222222-2222-2222-2222-222222222245', 'probe', 'MCQ', 'EASY', "
                        + "'{\"options\":[\"a\"]}', 'a', 'probe', 'CURATED', TRUE, "
                        + "CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL "
                        + "WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = "
                        + "'44444444-4444-4444-4444-444444444570')");
        assertThat(inserted).isEqualTo(0);
    }

    @Test
    void similarConceptsAcrossWorldsStayIsolated() throws Exception {
        String[] learner = registerLearner("sim10");
        // JDBC: OOP topic 263 vs Web topic 298 via the definition family (both backed).
        assertOwnContent(learner[0], "11111111-1111-1111-1111-111111111106",
                "22222222-2222-2222-2222-222222222263", "memory_match");
        assertOwnContent(learner[0], "11111111-1111-1111-1111-111111111108",
                "22222222-2222-2222-2222-222222222298", "memory_match");
        // Regression: AI/ML topic 316 vs FDS topic 339 via the question family (both backed).
        assertOwnContent(learner[0], "11111111-1111-1111-1111-111111111109",
                "22222222-2222-2222-2222-222222222316", "quiz_battle");
        assertOwnContent(learner[0], "11111111-1111-1111-1111-111111111110",
                "22222222-2222-2222-2222-222222222339", "quiz_battle");
        // Control Flow: Programming 212 backed, OOP 248 truthfully empty for questions.
        assertOwnContent(learner[0], "11111111-1111-1111-1111-111111111101",
                "22222222-2222-2222-2222-222222222212", "quiz_battle");
        mockMvc.perform(get("/api/v1/game-content")
                        .header("Authorization", bearer(learner[0]))
                        .param("subjectId", "11111111-1111-1111-1111-111111111106")
                        .param("topicId", "22222222-2222-2222-2222-222222222248")
                        .param("gameType", "quiz_battle"))
                .andExpect(status().isNotFound());
        // Cross-subject requests fail; B-only games expose nothing foreign.
        mockMvc.perform(get("/api/v1/game-content")
                        .header("Authorization", bearer(learner[0]))
                        .param("subjectId", "11111111-1111-1111-1111-111111111108")
                        .param("topicId", "22222222-2222-2222-2222-222222222263")
                        .param("gameType", "memory_match"))
                .andExpect(status().isBadRequest());
        mockMvc.perform(get("/api/v1/game-content")
                        .header("Authorization", bearer(learner[0]))
                        .param("subjectId", "11111111-1111-1111-1111-111111111106")
                        .param("gameType", "connectivity_lab"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void globalArenaCarriesUnitIdentity() throws Exception {
        String[] learner = registerLearner("arena10");
        String body = mockMvc.perform(get("/api/v1/game-content/global")
                        .header("Authorization", bearer(learner[0]))
                        .param("gameType", "quiz_battle")
                        .param("limit", "30"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.mode").value("GLOBAL"))
                .andReturn().getResponse().getContentAsString();
        JsonNode items = objectMapper.readTree(body).path("items");
        assertThat(items.size()).isGreaterThan(0);
        boolean sawUnit = false;
        for (JsonNode item : items) {
            for (String field : List.of("subjectId", "subjectName", "topicId", "topicName",
                    "gameType", "difficulty", "id")) {
                assertThat(item.path(field).asText()).as(field).isNotBlank();
            }
            if (item.hasNonNull("unitId")
                    && item.path("subjectId").asText().compareTo("11111111-1111-1111-1111-111111111106") >= 0) {
                sawUnit = true;
            }
        }
        assertThat(sawUnit).as("new-world items carry unitId").isTrue();
    }

    @Test
    void oldSubjectRegression() throws Exception {
        String[] learner = registerLearner("legacy10");
        // Legacy content counts unchanged by V28 (V12/V14 namespaces only).
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM questions WHERE id >= "
                        + "'44444444-4444-4444-4444-444444444401' AND id <= "
                        + "'44444444-4444-4444-4444-444444444482'",
                Integer.class)).isEqualTo(60);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM quizzes WHERE id >= "
                        + "'55555555-5555-5555-5555-555555555511' AND id <= "
                        + "'55555555-5555-5555-5555-555555555543'",
                Integer.class)).isEqualTo(15);
        assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM lessons", Integer.class))
                .isEqualTo(15);
        // Legacy quiz delivery still serves real options (H2 unwrap preserved).
        mockMvc.perform(get("/api/v1/quiz/22222222-2222-2222-2222-222222222211")
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.questions[0].options.length()").value(4));
        // Legacy compat counts unchanged.
        assertThat(compatCount("11111111-1111-1111-1111-111111111101")).isEqualTo(10);
        assertThat(compatCount("11111111-1111-1111-1111-111111111102")).isEqualTo(9);
        assertThat(compatCount("11111111-1111-1111-1111-111111111103")).isEqualTo(10);
        assertThat(compatCount("11111111-1111-1111-1111-111111111104")).isEqualTo(8);
        assertThat(compatCount("11111111-1111-1111-1111-111111111105")).isEqualTo(8);
    }

    private void assertOwnContent(String token, String subjectId, String topicId, String gameType)
            throws Exception {
        String body = mockMvc.perform(get("/api/v1/game-content")
                        .header("Authorization", "Bearer " + token)
                        .param("subjectId", subjectId)
                        .param("topicId", topicId)
                        .param("gameType", gameType))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        for (JsonNode item : objectMapper.readTree(body).path("items")) {
            assertThat(item.path("subjectId").asText()).isEqualTo(subjectId);
            assertThat(item.path("topicId").asText()).isEqualTo(topicId);
        }
    }

    private int activeTopics(String subjectId) {
        return jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM topics WHERE subject_id = ? AND is_active = TRUE",
                Integer.class, subjectId);
    }

    private int backedTopics(String subjectId) {
        return jdbcTemplate.queryForObject(
                "SELECT COUNT(DISTINCT t.id) FROM topics t JOIN questions q ON q.topic_id = t.id "
                        + "WHERE t.subject_id = ? AND t.is_active = TRUE AND q.is_active = TRUE "
                        + "AND q.question_type = 'MCQ'",
                Integer.class, subjectId);
    }

    private int questionCount(String subjectId) {
        return jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM questions q JOIN topics t ON t.id = q.topic_id "
                        + "WHERE t.subject_id = ? AND q.is_active = TRUE AND q.question_type = 'MCQ'",
                Integer.class, subjectId);
    }

    private int quizCount(String subjectId) {
        return jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM quizzes q JOIN topics t ON t.id = q.topic_id "
                        + "WHERE t.subject_id = ? AND q.is_active = TRUE",
                Integer.class, subjectId);
    }

    private List<String> difficulties(String subjectId) {
        return jdbcTemplate.queryForList(
                "SELECT DISTINCT q.difficulty FROM questions q JOIN topics t ON t.id = q.topic_id "
                        + "WHERE t.subject_id = ? AND q.is_active = TRUE",
                String.class, subjectId);
    }

    private int compatCount(String subjectId) {
        return jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM subject_game_compat WHERE subject_id = ? AND is_active = TRUE",
                Integer.class, subjectId);
    }

    private String questionText(String id) {
        return jdbcTemplate.queryForObject(
                "SELECT CAST(question_text AS VARCHAR(4000)) FROM questions WHERE id = ?",
                String.class, id);
    }

    private String correctAnswer(String id) {
        return jdbcTemplate.queryForObject(
                "SELECT CAST(correct_answer AS VARCHAR(4000)) FROM questions WHERE id = ?",
                String.class, id);
    }
}
