package com.gamelearn.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.HashSet;
import java.util.Set;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import com.fasterxml.jackson.databind.JsonNode;

/**
 * Batch 2 / Phase 5: global mixed arena mixes subjects intentionally while
 * subject mode stays strictly isolated.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class GlobalArenaBatch2Test extends AbstractCoreApiTest {

    @Test
    void globalArenaMixesSubjectsWithMetadata() throws Exception {
        String[] learner = registerLearner("arenaMix");
        String response = mockMvc.perform(get("/api/v1/game-content/global")
                        .header("Authorization", bearer(learner[0]))
                        .param("gameType", "quiz_battle")
                        .param("limit", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.mode").value("GLOBAL"))
                .andReturn().getResponse().getContentAsString();
        JsonNode items = objectMapper.readTree(response).path("items");
        assertThat(items.size()).isEqualTo(10);
        Set<String> subjects = new HashSet<>();
        for (JsonNode item : items) {
            assertThat(item.path("subjectId").asText()).isNotBlank();
            assertThat(item.path("subjectName").asText()).isNotBlank();
            assertThat(item.path("topicId").asText()).isNotBlank();
            assertThat(item.path("gameType").asText()).isEqualTo("quiz_battle");
            assertThat(item.path("difficulty").asText()).isNotBlank();
            assertThat(item.path("id").asText()).isNotBlank();
            subjects.add(item.path("subjectId").asText());
        }
        assertThat(subjects.size()).isGreaterThanOrEqualTo(2);
    }

    @Test
    void globalArenaIsDeterministic() throws Exception {
        String[] learner = registerLearner("arenaDet");
        String first = mockMvc.perform(get("/api/v1/game-content/global")
                        .header("Authorization", bearer(learner[0]))
                        .param("gameType", "memory_match")
                        .param("limit", "8"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        String second = mockMvc.perform(get("/api/v1/game-content/global")
                        .header("Authorization", bearer(learner[0]))
                        .param("gameType", "memory_match")
                        .param("limit", "8"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        assertThat(first).isEqualTo(second);
    }

    @Test
    void globalArenaRejectsBadInput() throws Exception {
        String[] learner = registerLearner("arena400");
        mockMvc.perform(get("/api/v1/game-content/global")
                        .header("Authorization", bearer(learner[0]))
                        .param("gameType", "not_a_game"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_FAILED"));
        mockMvc.perform(get("/api/v1/game-content/global")
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_FAILED"));
        mockMvc.perform(get("/api/v1/game-content/global")
                        .header("Authorization", bearer(learner[0]))
                        .param("gameType", "quiz_battle")
                        .param("limit", "0"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_FAILED"));
        mockMvc.perform(get("/api/v1/game-content/global")
                        .param("gameType", "quiz_battle"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void subjectModeIsUnaffectedByGlobalMode() throws Exception {
        String[] learner = registerLearner("arenaIso");
        String dbms = "11111111-1111-1111-1111-111111111103";
        String response = mockMvc.perform(get("/api/v1/game-content")
                        .header("Authorization", bearer(learner[0]))
                        .param("subjectId", dbms)
                        .param("gameType", "quiz_battle")
                        .param("limit", "20"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.mode").value("SUBJECT"))
                .andReturn().getResponse().getContentAsString();
        JsonNode items = objectMapper.readTree(response).path("items");
        assertThat(items.size()).isEqualTo(12);
        for (JsonNode item : items) {
            assertThat(item.path("subjectId").asText()).isEqualTo(dbms);
        }
    }
}
