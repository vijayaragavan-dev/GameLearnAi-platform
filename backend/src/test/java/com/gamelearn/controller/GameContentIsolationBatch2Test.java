package com.gamelearn.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import com.fasterxml.jackson.databind.JsonNode;

/**
 * Batch 2 / Phase 4: subject-scoped game content isolation, including the
 * adversarial cross-subject matrix. A mismatched subject/topic combination
 * is rejected — never silently served from another subject.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class GameContentIsolationBatch2Test extends AbstractCoreApiTest {

    private static final String DBMS = "11111111-1111-1111-1111-111111111103";
    private static final String DBMS_TOPIC = "22222222-2222-2222-2222-222222222223";

    @Test
    void dbmsTopicReturnsDbmsOnlyContent() throws Exception {
        String[] learner = registerLearner("isoDbms");
        String response = mockMvc.perform(get("/api/v1/game-content")
                        .header("Authorization", bearer(learner[0]))
                        .param("subjectId", DBMS)
                        .param("topicId", DBMS_TOPIC)
                        .param("gameType", "quiz_battle"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.mode").value("SUBJECT"))
                .andReturn().getResponse().getContentAsString();
        JsonNode items = objectMapper.readTree(response).path("items");
        assertThat(items.size()).isEqualTo(4);
        for (JsonNode item : items) {
            assertThat(item.path("subjectId").asText()).isEqualTo(DBMS);
            assertThat(item.path("topicId").asText()).isEqualTo(DBMS_TOPIC);
            assertThat(item.path("gameType").asText()).isEqualTo("quiz_battle");
            assertThat(item.path("questionText").asText()).isNotBlank();
            assertThat(item.path("options").size()).isGreaterThan(0);
        }
    }

    @ParameterizedTest(name = "subject {0} with foreign topic {1} is rejected")
    @CsvSource({
            DBMS + ", 22222222-2222-2222-2222-222222222232",
            "11111111-1111-1111-1111-111111111104, 22222222-2222-2222-2222-222222222221",
            "11111111-1111-1111-1111-111111111109, 22222222-2222-2222-2222-222222222330",
            "11111111-1111-1111-1111-111111111110, 22222222-2222-2222-2222-222222222306",
            "11111111-1111-1111-1111-111111111111, 22222222-2222-2222-2222-222222222241",
            "11111111-1111-1111-1111-111111111106, 22222222-2222-2222-2222-222222222211",
            "11111111-1111-1111-1111-111111111108, 22222222-2222-2222-2222-222222222222",
            "11111111-1111-1111-1111-111111111107, 22222222-2222-2222-2222-222222222244",
            "11111111-1111-1111-1111-111111111101, 22222222-2222-2222-2222-222222222253"
    })
    void crossSubjectTopicCombinationsAreRejected(String subjectId, String topicId) throws Exception {
        String[] learner = registerLearner("isox");
        mockMvc.perform(get("/api/v1/game-content")
                        .header("Authorization", bearer(learner[0]))
                        .param("subjectId", subjectId)
                        .param("topicId", topicId)
                        .param("gameType", "quiz_battle"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_FAILED"));
    }

    @Test
    void nonexistentSubjectTopicAndEmptyContent() throws Exception {
        String[] learner = registerLearner("iso404");
        mockMvc.perform(get("/api/v1/game-content")
                        .header("Authorization", bearer(learner[0]))
                        .param("subjectId", "00000000-0000-0000-0000-000000000000")
                        .param("gameType", "quiz_battle"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode").value("RESOURCE_NOT_FOUND"));
        mockMvc.perform(get("/api/v1/game-content")
                        .header("Authorization", bearer(learner[0]))
                        .param("subjectId", DBMS)
                        .param("topicId", "00000000-0000-0000-0000-000000000000")
                        .param("gameType", "quiz_battle"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode").value("RESOURCE_NOT_FOUND"));
        // OOP topic 246 (Variables and Literals) has no questions: truthful 404
        // for the question family, while the definition family still serves.
        // (Topic 245 gained V28 questions; 246 remains the empty-topic probe.)
        mockMvc.perform(get("/api/v1/game-content")
                        .header("Authorization", bearer(learner[0]))
                        .param("subjectId", "11111111-1111-1111-1111-111111111106")
                        .param("topicId", "22222222-2222-2222-2222-222222222246")
                        .param("gameType", "quiz_battle"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode").value("RESOURCE_NOT_FOUND"));
        mockMvc.perform(get("/api/v1/game-content")
                        .header("Authorization", bearer(learner[0]))
                        .param("subjectId", "11111111-1111-1111-1111-111111111106")
                        .param("topicId", "22222222-2222-2222-2222-222222222246")
                        .param("gameType", "memory_match"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].definition").isNotEmpty());
    }

    @Test
    void unsupportedGameAndDifficultyAreRejected() throws Exception {
        String[] learner = registerLearner("iso400");
        mockMvc.perform(get("/api/v1/game-content")
                        .header("Authorization", bearer(learner[0]))
                        .param("subjectId", DBMS)
                        .param("gameType", "connectivity_lab"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_FAILED"));
        mockMvc.perform(get("/api/v1/game-content")
                        .header("Authorization", bearer(learner[0]))
                        .param("subjectId", DBMS)
                        .param("gameType", "not_a_game"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_FAILED"));
        mockMvc.perform(get("/api/v1/game-content")
                        .header("Authorization", bearer(learner[0]))
                        .param("subjectId", DBMS)
                        .param("gameType", "quiz_battle")
                        .param("difficulty", "IMPOSSIBLE"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_FAILED"));
        mockMvc.perform(get("/api/v1/game-content")
                        .header("Authorization", bearer(learner[0]))
                        .param("subjectId", DBMS)
                        .param("gameType", "quiz_battle")
                        .param("limit", "51"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_FAILED"));
    }

    @Test
    void answersAreNeverExposedAndUnitStaysConsistent() throws Exception {
        String[] learner = registerLearner("isosafe");
        String response = mockMvc.perform(get("/api/v1/game-content")
                        .header("Authorization", bearer(learner[0]))
                        .param("subjectId", "11111111-1111-1111-1111-111111111106")
                        .param("topicId", "22222222-2222-2222-2222-222222222244")
                        .param("gameType", "quiz_battle")
                        .param("limit", "3"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        assertThat(response).doesNotContain("correctAnswer");
        assertThat(response).doesNotContain("correct_answer");
        assertThat(response).doesNotContain("explanation");
        JsonNode items = objectMapper.readTree(response).path("items");
        assertThat(items.size()).isEqualTo(3);
        for (JsonNode item : items) {
            assertThat(item.path("unitId").asText())
                    .isEqualTo("77777777-7777-7777-7777-777777777701");
        }
    }

    @Test
    void difficultyFilterAndLimitAreHonored() throws Exception {
        String[] learner = registerLearner("isofilter");
        String response = mockMvc.perform(get("/api/v1/game-content")
                        .header("Authorization", bearer(learner[0]))
                        .param("subjectId", "11111111-1111-1111-1111-111111111111")
                        .param("gameType", "quiz_battle")
                        .param("difficulty", "HARD")
                        .param("limit", "2"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        JsonNode items = objectMapper.readTree(response).path("items");
        assertThat(items.size()).isEqualTo(2);
        for (JsonNode item : items) {
            assertThat(item.path("difficulty").asText()).isEqualTo("HARD");
            assertThat(item.path("subjectId").asText())
                    .isEqualTo("11111111-1111-1111-1111-111111111111");
        }
    }

    @Test
    void structureGameServesTopicMetadata() throws Exception {
        String[] learner = registerLearner("isostruct");
        String response = mockMvc.perform(get("/api/v1/game-content")
                        .header("Authorization", bearer(learner[0]))
                        .param("subjectId", "11111111-1111-1111-1111-111111111102")
                        .param("gameType", "connectivity_lab"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        JsonNode items = objectMapper.readTree(response).path("items");
        assertThat(items.size()).isEqualTo(3);
        List<String> names = new java.util.ArrayList<>();
        for (JsonNode item : items) {
            assertThat(item.path("kind").asText()).isEqualTo("STRUCTURE");
            assertThat(item.path("subjectId").asText())
                    .isEqualTo("11111111-1111-1111-1111-111111111102");
            names.add(item.path("topicName").asText());
        }
        assertThat(names).containsExactly(
                "Networking Fundamentals", "OSI & TCP-IP Models", "IP Addressing & Routing");
    }

    @Test
    void contentRequiresAuthentication() throws Exception {
        mockMvc.perform(get("/api/v1/game-content")
                        .param("subjectId", DBMS)
                        .param("gameType", "quiz_battle"))
                .andExpect(status().isUnauthorized());
    }
}
