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
 * Batch 2 / Phase 3: backend-authoritative subject/game compatibility.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class GameCompatibilityBatch2Test extends AbstractCoreApiTest {

    private static final Map<String, Integer> EXPECTED_COUNTS = Map.ofEntries(
            Map.entry("11111111-1111-1111-1111-111111111101", 10),
            Map.entry("11111111-1111-1111-1111-111111111102", 9),
            Map.entry("11111111-1111-1111-1111-111111111103", 10),
            Map.entry("11111111-1111-1111-1111-111111111104", 8),
            Map.entry("11111111-1111-1111-1111-111111111105", 8),
            Map.entry("11111111-1111-1111-1111-111111111106", 7),
            Map.entry("11111111-1111-1111-1111-111111111107", 9),
            Map.entry("11111111-1111-1111-1111-111111111108", 9),
            Map.entry("11111111-1111-1111-1111-111111111109", 7),
            Map.entry("11111111-1111-1111-1111-111111111110", 7),
            Map.entry("11111111-1111-1111-1111-111111111111", 11));

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void allElevenSubjectsResolveCompatibility() throws Exception {
        String[] learner = registerLearner("compat11");
        for (Map.Entry<String, Integer> entry : EXPECTED_COUNTS.entrySet()) {
            mockMvc.perform(get("/api/v1/subjects/" + entry.getKey() + "/games")
                            .header("Authorization", bearer(learner[0])))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.subjectId").value(entry.getKey()))
                    .andExpect(jsonPath("$.games.length()").value(entry.getValue()));
        }
    }

    @Test
    void unsupportedCombinationsAreNotExposed() throws Exception {
        String[] learner = registerLearner("compatneg");
        assertGamesDoNotContain(learner[0], "11111111-1111-1111-1111-111111111103",
                List.of("connectivity_lab", "debug_arena", "unlock_code", "sequence_master"));
        assertGamesDoNotContain(learner[0], "11111111-1111-1111-1111-111111111102",
                List.of("debug_arena", "drag_drop", "concept_builder", "puzzle_arena"));
        assertGamesDoNotContain(learner[0], "11111111-1111-1111-1111-111111111106",
                List.of("connectivity_lab", "mystery_case", "sequence_master", "puzzle_arena"));
        assertGamesDoNotContain(learner[0], "11111111-1111-1111-1111-111111111109",
                List.of("connectivity_lab", "debug_arena", "drag_drop", "sequence_master"));
    }

    @Test
    void everyCanonicalGameTypeHasAContentKind() {
        for (String gameType : com.gamelearn.gamification.GameType.allIds()) {
            assertThat(com.gamelearn.gamification.GameContentKind.forGameType(gameType)).isNotNull();
        }
        assertThat(com.gamelearn.gamification.GameType.allIds()).hasSize(14);
    }

    @Test
    void noDuplicateMappings() throws Exception {
        String[] learner = registerLearner("compatdupe");
        for (String subjectId : EXPECTED_COUNTS.keySet()) {
            String response = mockMvc.perform(get("/api/v1/subjects/" + subjectId + "/games")
                            .header("Authorization", bearer(learner[0])))
                    .andExpect(status().isOk())
                    .andReturn().getResponse().getContentAsString();
            List<String> types = objectMapper.readTree(response).findValuesAsText("gameType");
            assertThat(types).doesNotHaveDuplicates();
        }
        List<Map<String, Object>> dupes = jdbcTemplate.queryForList(
                "SELECT subject_id, game_type, COUNT(*) AS c FROM subject_game_compat "
                        + "GROUP BY subject_id, game_type HAVING COUNT(*) > 1");
        assertThat(dupes).isEmpty();
    }

    @Test
    void noOrphanMappings() {
        List<Map<String, Object>> orphans = jdbcTemplate.queryForList(
                "SELECT c.id FROM subject_game_compat c LEFT JOIN subjects s ON s.id = c.subject_id "
                        + "WHERE s.id IS NULL");
        assertThat(orphans).isEmpty();
        Integer inactiveSubjects = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM subject_game_compat c JOIN subjects s ON s.id = c.subject_id "
                        + "WHERE s.is_active <> TRUE",
                Integer.class);
        assertThat(inactiveSubjects).isEqualTo(0);
    }

    @Test
    void invalidSubjectIsRejected() throws Exception {
        String[] learner = registerLearner("compat404");
        mockMvc.perform(get("/api/v1/subjects/00000000-0000-0000-0000-000000000000/games")
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode").value("RESOURCE_NOT_FOUND"));
    }

    @Test
    void compatibilityRequiresAuthentication() throws Exception {
        mockMvc.perform(get("/api/v1/subjects/11111111-1111-1111-1111-111111111103/games"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.errorCode").value("UNAUTHORIZED"));
    }

    @Test
    void contentAvailabilityIsTruthful() throws Exception {
        String[] learner = registerLearner("compatavail");
        // DBMS (legacy): 12 seeded questions back the quiz family.
        String dbms = getGames(learner[0], "11111111-1111-1111-1111-111111111103");
        assertEntry(dbms, "quiz_battle", true, 12);
        assertEntry(dbms, "memory_match", true, 3);
        // OOP (new): 24 seeded questions (8 topics x 3 over V27+V28) back the quiz family.
        String oop = getGames(learner[0], "11111111-1111-1111-1111-111111111106");
        assertEntry(oop, "quiz_battle", true, 24);
        assertEntry(oop, "debug_arena", true, 24);
        // Every exposed game must carry a rationale and a non-negative count.
        for (String subjectId : EXPECTED_COUNTS.keySet()) {
            JsonNode games = objectMapper.readTree(getGames(learner[0], subjectId)).path("games");
            for (JsonNode game : games) {
                assertThat(game.path("rationale").asText()).isNotBlank();
                assertThat(game.path("contentCount").asLong()).isGreaterThanOrEqualTo(0);
                assertThat(game.path("hasContent").asBoolean())
                        .isEqualTo(game.path("contentCount").asLong() > 0);
            }
        }
    }

    private void assertGamesDoNotContain(String token, String subjectId, List<String> banned)
            throws Exception {
        String response = getGames(token, subjectId);
        List<String> types = objectMapper.readTree(response).findValuesAsText("gameType");
        assertThat(types).doesNotContainAnyElementsOf(banned);
    }

    private String getGames(String token, String subjectId) throws Exception {
        return mockMvc.perform(get("/api/v1/subjects/" + subjectId + "/games")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
    }

    private void assertEntry(String response, String gameType, boolean hasContent, long count)
            throws Exception {
        JsonNode games = objectMapper.readTree(response).path("games");
        JsonNode match = null;
        for (JsonNode game : games) {
            if (game.path("gameType").asText().equals(gameType)) {
                match = game;
            }
        }
        assertThat(match).as("game %s exposed", gameType).isNotNull();
        assertThat(match.path("hasContent").asBoolean()).isEqualTo(hasContent);
        assertThat(match.path("contentCount").asLong()).isEqualTo(count);
    }
}
