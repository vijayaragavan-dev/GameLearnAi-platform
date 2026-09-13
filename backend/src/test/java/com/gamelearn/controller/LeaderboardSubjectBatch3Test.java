package com.gamelearn.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;
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
 * Batch 3 / Phase 7A-7C: leaderboard identity across the 11-subject world.
 * No production change was required (identity is join-derived per subject);
 * these tests prove isolation, global semantics and error behavior.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class LeaderboardSubjectBatch3Test extends AbstractCoreApiTest {

    private static final String DBMS = "11111111-1111-1111-1111-111111111103";
    private static final String OS = "11111111-1111-1111-1111-111111111104";
    private static final String OOP = "11111111-1111-1111-1111-111111111106";
    private static final String DAA = "11111111-1111-1111-1111-111111111111";

    private static final List<String> ALL_SUBJECTS = List.of(
            "11111111-1111-1111-1111-111111111101",
            "11111111-1111-1111-1111-111111111102",
            DBMS, OS,
            "11111111-1111-1111-1111-111111111105",
            OOP,
            "11111111-1111-1111-1111-111111111107",
            "11111111-1111-1111-1111-111111111108",
            "11111111-1111-1111-1111-111111111109",
            "11111111-1111-1111-1111-111111111110",
            DAA);

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void subjectBoardsAreIsolatedByIdentity() throws Exception {
        String[] learner = registerLearner("board7");
        UUID userId = userByEmail(learner[1]).getId();
        submitAllCorrect(learner[0], "55555555-5555-5555-5555-555555555523"); // DBMS only

        JsonNode dbms = position(learner[0], DBMS);
        // Rank is shared-DB dependent (other test classes also earn DBMS XP);
        // what matters is ranked-with-XP here and unranked elsewhere.
        assertThat(dbms.path("rank").asInt()).isGreaterThanOrEqualTo(1);
        assertThat(dbms.path("rank").asInt()).isLessThanOrEqualTo(dbms.path("totalPlayers").asInt());
        assertThat(dbms.path("subjectXp").asLong()).isGreaterThan(0);

        // Similar-named worlds stay unranked: OS, OOP, DAA.
        for (String other : List.of(OS, OOP, DAA)) {
            JsonNode pos = position(learner[0], other);
            assertThat(pos.path("rank").asInt())
                    .as("rank on %s", other)
                    .isEqualTo(pos.path("totalPlayers").asInt() + 1);
        }
        // And the DBMS row is the only subject-XP attribution for this user.
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(DISTINCT t.subject_id) FROM xp_transactions x "
                        + "JOIN quiz_attempts a ON a.id = x.reference_id "
                        + "JOIN quizzes q ON q.id = a.quiz_id "
                        + "JOIN topics t ON t.id = q.topic_id "
                        + "WHERE x.user_id = ? AND x.reference_type = 'QUIZ_ATTEMPT'",
                Integer.class, userId.toString())).isEqualTo(1);
    }

    @Test
    void subjectXpIsCountedOnce() throws Exception {
        String[] learner = registerLearner("boardonce");
        UUID userId = userByEmail(learner[1]).getId();
        submitAllCorrect(learner[0], "55555555-5555-5555-5555-555555555523");
        Long expected = jdbcTemplate.queryForObject(
                "SELECT COALESCE(SUM(x.amount),0) FROM xp_transactions x "
                        + "JOIN quiz_attempts a ON a.id = x.reference_id "
                        + "JOIN quizzes q ON q.id = a.quiz_id "
                        + "JOIN topics t ON t.id = q.topic_id "
                        + "WHERE x.user_id = ? AND t.subject_id = ? AND x.reference_type = 'QUIZ_ATTEMPT'",
                Long.class, userId.toString(), DBMS);
        JsonNode pos = position(learner[0], DBMS);
        assertThat(pos.path("subjectXp").asLong()).isEqualTo(expected);
    }

    @Test
    void globalBoardStaysGlobal() throws Exception {
        String[] learner = registerLearner("boardglobal");
        UUID userId = userByEmail(learner[1]).getId();
        submitAllCorrect(learner[0], "55555555-5555-5555-5555-555555555523");
        long overallBefore = overallTotalXp(learner[0]);
        long dbmsBefore = position(learner[0], DBMS).path("subjectXp").asLong();
        String gameBody = """
                {"clientRequestId": "%s", "gameType": "speed_run", "difficulty": "MEDIUM",
                 "completed": true, "score": 400, "durationSeconds": 60, "bestCombo": 2}
                """.formatted(UUID.randomUUID());
        mockMvc.perform(post("/api/v1/me/game-results")
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON).content(gameBody))
                .andExpect(status().isOk());
        // Overall absorbs game XP; the subject board does not move.
        assertThat(overallTotalXp(learner[0])).isGreaterThan(overallBefore);
        assertThat(position(learner[0], DBMS).path("subjectXp").asLong()).isEqualTo(dbmsBefore);
        assertThat(totalXpRow(userId)).isEqualTo(overallTotalXp(learner[0]));
    }

    @Test
    void allElevenSubjectBoardsResolve() throws Exception {
        String[] learner = registerLearner("board11");
        for (String subjectId : ALL_SUBJECTS) {
            mockMvc.perform(get("/api/v1/leaderboard/subject/" + subjectId)
                            .header("Authorization", bearer(learner[0])))
                    .andExpect(status().isOk());
        }
        mockMvc.perform(get("/api/v1/leaderboard/subject/00000000-0000-0000-0000-000000000000")
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode").value("RESOURCE_NOT_FOUND"));
    }

    @Test
    void identityCannotBeOverridden() throws Exception {
        String[] alice = registerLearner("boardalice");
        String[] bob = registerLearner("boardbob");
        submitAllCorrect(alice[0], "55555555-5555-5555-5555-555555555523");
        JsonNode alicePos = position(alice[0], DBMS);
        JsonNode bobPos = position(bob[0], DBMS);
        assertThat(alicePos.path("subjectXp").asLong()).isGreaterThan(0);
        assertThat(alicePos.path("rank").asInt()).isLessThan(bobPos.path("rank").asInt());
        assertThat(bobPos.path("rank").asInt()).isEqualTo(bobPos.path("totalPlayers").asInt() + 1);
        // No userId parameter exists to escalate with: caller context is authoritative.
        mockMvc.perform(get("/api/v1/me/leaderboard-position")
                        .header("Authorization", bearer(bob[0]))
                        .param("segment", "SUBJECT")
                        .param("subjectId", DBMS))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.rank").value(bobPos.path("rank").asInt()));
    }

    @Test
    void invalidLeaderboardInput() throws Exception {
        String[] learner = registerLearner("boardbad");
        mockMvc.perform(get("/api/v1/me/leaderboard-position")
                        .header("Authorization", bearer(learner[0]))
                        .param("segment", "SUBJECT"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_FAILED"));
        mockMvc.perform(get("/api/v1/leaderboard/overall")
                        .header("Authorization", bearer(learner[0]))
                        .param("size", "51"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_FAILED"));
        mockMvc.perform(get("/api/v1/leaderboard/subject/" + DBMS)
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk());
        mockMvc.perform(get("/api/v1/leaderboard/overall"))
                .andExpect(status().isUnauthorized());
    }

    private JsonNode position(String token, String subjectId) throws Exception {
        String body = mockMvc.perform(get("/api/v1/me/leaderboard-position")
                        .header("Authorization", "Bearer " + token)
                        .param("segment", "SUBJECT")
                        .param("subjectId", subjectId))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return objectMapper.readTree(body);
    }

    private long overallTotalXp(String token) throws Exception {
        String body = mockMvc.perform(get("/api/v1/me/leaderboard-position")
                        .header("Authorization", "Bearer " + token)
                        .param("segment", "OVERALL"))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return objectMapper.readTree(body).path("totalXp").asLong();
    }

    private long totalXpRow(UUID userId) {
        return jdbcTemplate.queryForObject("SELECT total_xp FROM learner_profiles WHERE user_id = ?",
                Long.class, userId.toString());
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
