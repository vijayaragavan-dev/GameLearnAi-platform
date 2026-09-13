package com.gamelearn.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import com.fasterxml.jackson.databind.JsonNode;

/**
 * Batch 3 / Phase 8: adversarial API + security + data-integrity hardening
 * across the expanded 11-subject surface. All assertions use the existing
 * error envelope and existing validation semantics.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ApiSecurityHardeningBatch3Test extends AbstractCoreApiTest {

    private static final String DBMS = "11111111-1111-1111-1111-111111111103";
    private static final String OS = "11111111-1111-1111-1111-111111111104";
    private static final String DAA = "11111111-1111-1111-1111-111111111111";
    private static final String DSA = "11111111-1111-1111-1111-111111111105";

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void crossUserDataIsInaccessible() throws Exception {
        String[] alice = registerLearner("hardalice");
        String[] bob = registerLearner("hardbob");
        UUID bobId = userByEmail(bob[1]).getId();
        // Bob plays and quizzes; Alice must see none of it.
        String bobClientId = UUID.randomUUID().toString();
        mockMvc.perform(post("/api/v1/me/game-results")
                        .header("Authorization", bearer(bob[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(gameBody(bobClientId, "memory_match")))
                .andExpect(status().isOk());
        submitAllCorrect(bob[0], "55555555-5555-5555-5555-555555555523");
        String aliceGames = mockMvc.perform(get("/api/v1/me/game-results")
                        .header("Authorization", bearer(alice[0])))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        assertThat(aliceGames).doesNotContain(bobClientId);
        String aliceDash = mockMvc.perform(get("/api/v1/dashboard")
                        .header("Authorization", bearer(alice[0])))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        assertThat(aliceDash).doesNotContain(bobId.toString());
        // Bob's per-topic progress is invisible to Alice.
        mockMvc.perform(get("/api/v1/progress/22222222-2222-2222-2222-222222222223")
                        .header("Authorization", bearer(alice[0])))
                .andExpect(status().isNotFound());
    }

    @Test
    void foreignQuestionIdsAreRejected() throws Exception {
        String[] learner = registerLearner("hardfq");
        // OOP question answered inside the Programming quiz.
        String body = """
                {"answers": [{"questionId": "44444444-4444-4444-4444-444444444483",
                 "selectedAnswer": "Java Virtual Machine (JVM)"}]}
                """;
        // Existing QuizSubmissionService semantics reject foreign question ids
        // as MALFORMED_REQUEST (still HTTP 400 fail-closed, never served).
        mockMvc.perform(post("/api/v1/quiz/55555555-5555-5555-5555-555555555511/submit")
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("MALFORMED_REQUEST"));
        // DS question submitted to the DAA assessment.
        String asmt = """
                {"answers": [{"questionId": "44444444-4444-4444-4444-444444444471",
                 "selectedAnswer": "x"}]}
                """;
        mockMvc.perform(post("/api/v1/assessment/" + DAA + "/submit")
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON).content(asmt))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_FAILED"));
    }

    @Test
    void assessmentDeliveryIsSubjectScoped() throws Exception {
        String[] learner = registerLearner("hardasmt");
        String body = mockMvc.perform(get("/api/v1/assessment/" + DAA)
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.subjectId").value(DAA))
                .andReturn().getResponse().getContentAsString();
        JsonNode questions = objectMapper.readTree(body).path("questions");
        assertThat(questions.size()).isGreaterThan(0);
        for (JsonNode q : questions) {
            String owner = jdbcTemplate.queryForObject(
                    "SELECT subject_id FROM topics t JOIN questions qq ON qq.topic_id = t.id "
                            + "WHERE qq.id = ?",
                    String.class, q.path("questionId").asText());
            assertThat(owner).isEqualTo(DAA);
        }
        // Unknown subject fails closed.
        mockMvc.perform(get("/api/v1/assessment/00000000-0000-0000-0000-000000000000")
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isNotFound());
    }

    @Test
    void compatCatalogHasIntegrity() {
        // Exactly the 95 seeded mappings, all canonical on both axes.
        assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM subject_game_compat",
                Integer.class)).isEqualTo(95);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM subject_game_compat WHERE game_type NOT IN "
                        + "('quiz_battle','memory_match','drag_drop','speed_run','debug_arena',"
                        + "'unlock_code','concept_builder','sequence_master','target_challenge',"
                        + "'mystery_case','boss_battle','puzzle_arena','connectivity_lab',"
                        + "'snake_and_ladder')",
                Integer.class)).isEqualTo(0);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM subject_game_compat WHERE subject_id NOT IN "
                        + "('11111111-1111-1111-1111-111111111101','11111111-1111-1111-1111-111111111102',"
                        + "'11111111-1111-1111-1111-111111111103','11111111-1111-1111-1111-111111111104',"
                        + "'11111111-1111-1111-1111-111111111105','11111111-1111-1111-1111-111111111106',"
                        + "'11111111-1111-1111-1111-111111111107','11111111-1111-1111-1111-111111111108',"
                        + "'11111111-1111-1111-1111-111111111109','11111111-1111-1111-1111-111111111110',"
                        + "'11111111-1111-1111-1111-111111111111')",
                Integer.class)).isEqualTo(0);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM subject_game_compat WHERE rationale IS NULL OR rationale = ''",
                Integer.class)).isEqualTo(0);
    }

    @Test
    void seededQuestionContentHasIntegrity() throws Exception {
        List<Map<String, Object>> rows = jdbcTemplate.queryForList(
                "SELECT id, topic_id, question_text, difficulty, options_json, correct_answer "
                        + "FROM questions WHERE is_active = TRUE");
        assertThat(rows.size()).isGreaterThanOrEqualTo(147);
        Set<String> seen = new HashSet<>();
        for (Map<String, Object> row : rows) {
            // H2 surfaces TEXT/CLOB columns as byte[] via raw JDBC; decode.
            String text = toText(row.get("question_text"));
            String correct = toText(row.get("correct_answer"));
            assertThat(text).isNotBlank();
            assertThat(correct).isNotBlank();
            assertThat(List.of("EASY", "MEDIUM", "HARD")).contains(toText(row.get("difficulty")));
            List<String> options = parseOptions(toText(row.get("options_json")));
            assertThat(options).as("options for %s", row.get("id")).hasSizeGreaterThanOrEqualTo(2);
            assertThat(options).as("correct answer for %s", row.get("id")).contains(correct);
            String topicKey = row.get("topic_id") + "|" + text;
            assertThat(seen.add(topicKey)).as("duplicate question %s", row.get("id")).isTrue();
        }
        // Every quiz links same-topic questions with contiguous ordering.
        List<Map<String, Object>> badLinks = jdbcTemplate.queryForList(
                "SELECT qq.id FROM quiz_questions qq JOIN quizzes q ON q.id = qq.quiz_id "
                        + "JOIN questions quest ON quest.id = qq.question_id "
                        + "WHERE quest.topic_id <> q.topic_id");
        assertThat(badLinks).isEmpty();
        List<Map<String, Object>> gaps = jdbcTemplate.queryForList(
                "SELECT quiz_id FROM quiz_questions GROUP BY quiz_id "
                        + "HAVING COUNT(*) <> MAX(question_order) OR MIN(question_order) <> 1");
        assertThat(gaps).isEmpty();
    }

    @Test
    void migrationChainHasIntegrity() {
        List<String> versions = jdbcTemplate.queryForList(
                "SELECT version FROM flyway_schema_history WHERE success = TRUE AND installed_rank > 0 "
                        + "ORDER BY installed_rank",
                String.class);
        assertThat(versions).hasSize(28);
        for (int i = 0; i < versions.size(); i++) {
            assertThat(versions.get(i)).isEqualTo(String.valueOf(i + 1));
        }
    }

    @Test
    void errorEnvelopeIsConsistentAndLeakFree() throws Exception {
        String[] learner = registerLearner("hardenvelope");
        // 400 case.
        String bad = mockMvc.perform(get("/api/v1/game-content")
                        .header("Authorization", bearer(learner[0]))
                        .param("subjectId", DBMS)
                        .param("topicId", "22222222-2222-2222-2222-222222222232")
                        .param("gameType", "quiz_battle"))
                .andExpect(status().isBadRequest())
                .andReturn().getResponse().getContentAsString();
        assertEnvelope(bad, 400, "VALIDATION_FAILED", "/api/v1/game-content");
        // 404 case.
        String missing = mockMvc.perform(get("/api/v1/topics/00000000-0000-0000-0000-000000000000")
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isNotFound())
                .andReturn().getResponse().getContentAsString();
        assertEnvelope(missing, 404, "RESOURCE_NOT_FOUND", "/api/v1/topics/00000000-0000-0000-0000-000000000000");
        // 401 case.
        String anon = mockMvc.perform(get("/api/v1/progress"))
                .andExpect(status().isUnauthorized())
                .andReturn().getResponse().getContentAsString();
        assertEnvelope(anon, 401, "UNAUTHORIZED", "/api/v1/progress");
    }

    @Test
    void malformedGameResultsAreRejectedWithoutSideEffects() throws Exception {
        String[] learner = registerLearner("hardmalformed");
        UUID userId = userByEmail(learner[1]).getId();
        int before = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM game_results WHERE user_id = ?",
                Integer.class, userId.toString());
        mockMvc.perform(post("/api/v1/me/game-results")
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"clientRequestId": "%s", "gameType": "not_a_game", "difficulty": "MEDIUM",
                                 "completed": true, "score": 100, "durationSeconds": 10, "bestCombo": 1}
                                """.formatted(UUID.randomUUID())))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_FAILED"));
        // A second game type for the same learner still succeeds (no cross-type bypass issue,
        // limiter intact for legitimate traffic).
        mockMvc.perform(post("/api/v1/me/game-results")
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(gameBody(UUID.randomUUID().toString(), "drag_drop")))
                .andExpect(status().isOk());
        assertThat(jdbcTemplate.queryForObject("SELECT COUNT(*) FROM game_results WHERE user_id = ?",
                Integer.class, userId.toString())).isEqualTo(before + 1);
    }

    @Test
    void dsaVersusDaaStaySeparate() throws Exception {
        String[] learner = registerLearner("harddsa");
        // DSA topic content never resolves under DAA nor vice versa.
        mockMvc.perform(get("/api/v1/game-content")
                        .header("Authorization", bearer(learner[0]))
                        .param("subjectId", DAA)
                        .param("topicId", "22222222-2222-2222-2222-222222222241")
                        .param("gameType", "quiz_battle"))
                .andExpect(status().isBadRequest());
        mockMvc.perform(get("/api/v1/game-content")
                        .header("Authorization", bearer(learner[0]))
                        .param("subjectId", DSA)
                        .param("topicId", "22222222-2222-2222-2222-222222222349")
                        .param("gameType", "quiz_battle"))
                .andExpect(status().isBadRequest());
        // OS topic under DBMS subject is rejected on every scoped surface.
        mockMvc.perform(get("/api/v1/quiz/22222222-2222-2222-2222-222222222232")
                        .header("Authorization", bearer(learner[0]))
                        .param("subjectId", DBMS))
                .andExpect(status().isBadRequest());
        mockMvc.perform(post("/api/v1/learning-path/" + OS + "/generate")
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isCreated());
    }

    private void assertEnvelope(String body, int status, String code, String path) throws Exception {
        JsonNode root = objectMapper.readTree(body);
        assertThat(root.path("timestamp").asText()).isNotBlank();
        assertThat(root.path("status").asInt()).isEqualTo(status);
        assertThat(root.path("errorCode").asText()).isEqualTo(code);
        assertThat(root.path("message").asText()).isNotBlank();
        assertThat(root.path("path").asText()).isEqualTo(path);
        assertThat(root.path("requestId").asText()).isNotBlank();
        assertThat(body).doesNotContain("stackTrace");
        assertThat(body).doesNotContain("at com.gamelearn");
    }

    private String toText(Object value) throws Exception {
        if (value instanceof byte[] bytes) {
            return new String(bytes, java.nio.charset.StandardCharsets.UTF_8);
        }
        if (value instanceof java.sql.Clob clob) {
            return clob.getSubString(1, (int) clob.length());
        }
        return String.valueOf(value);
    }

    private List<String> parseOptions(String optionsJson) throws Exception {
        JsonNode root = objectMapper.readTree(optionsJson);
        if (root.isTextual()) {
            root = objectMapper.readTree(root.asText());
        }
        List<String> options = new java.util.ArrayList<>();
        for (JsonNode option : root.path("options")) {
            options.add(option.asText());
        }
        return options;
    }

    private String gameBody(String clientId, String gameType) {
        return """
                {"clientRequestId": "%s", "gameType": "%s", "difficulty": "MEDIUM",
                 "completed": true, "score": 300, "durationSeconds": 90, "bestCombo": 2}
                """.formatted(clientId, gameType);
    }

    private void submitAllCorrect(String token, String quizId) throws Exception {
        List<java.util.Map<String, Object>> rows = jdbcTemplate.queryForList(
                "SELECT q.id AS id, q.correct_answer AS correct_answer FROM quiz_questions qq "
                        + "JOIN questions q ON q.id = qq.question_id WHERE qq.quiz_id = ? "
                        + "ORDER BY qq.question_order ASC",
                quizId);
        StringBuilder answers = new StringBuilder();
        for (var row : rows) {
            if (answers.length() > 0) {
                answers.append(',');
            }
            answers.append("{\"questionId\": \"").append(row.get("id"))
                    .append("\", \"selectedAnswer\": ")
                    .append(objectMapper.writeValueAsString((String) row.get("correct_answer")))
                    .append('}');
        }
        mockMvc.perform(post("/api/v1/quiz/" + quizId + "/submit")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"answers\": [" + answers + "]}"))
                .andExpect(status().isCreated());
    }
}
