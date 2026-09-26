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
import org.springframework.test.context.ActiveProfiles;

import com.gamelearn.entity.Realm;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.repository.QuestionRepository;
import com.gamelearn.repository.RealmRepository;

/**
 * REALM-001: realm catalogue, realm-scoped subjects, and the Aptitude
 * end-to-end content path (games → content → result → XP).
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class RealmApiTest extends AbstractCoreApiTest {

    private static final String REALMS_URL = "/api/v1/realms";

    @Autowired
    private RealmRepository realmRepository;

    @Autowired
    private QuestionRepository questionRepository;

    private Subject aptitudeSubject() {
        return subjectRepository.findAll().stream()
                .filter(s -> "Aptitude".equals(s.getName()))
                .findFirst()
                .orElseThrow(() -> new AssertionError("Aptitude subject not seeded"));
    }

    @Test
    void listsActiveRealmsWithStableKeysInDisplayOrder() throws Exception {
        String[] learner = registerLearner("realms");

        String response = mockMvc.perform(get(REALMS_URL).header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andReturn().getResponse().getContentAsString();

        var keys = objectMapper.readTree(response).findValuesAsText("realmKey");
        assertThat(keys).containsExactly("COMPUTER_SCIENCE", "APTITUDE");
    }

    @Test
    void getRealmByKeyIsCaseInsensitive() throws Exception {
        String[] learner = registerLearner("realmkey");

        mockMvc.perform(get(REALMS_URL + "/aptitude").header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.realmKey").value("APTITUDE"))
                .andExpect(jsonPath("$.name").value("Aptitude"));

        mockMvc.perform(get(REALMS_URL + "/COMPUTER_SCIENCE").header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Computer Science"));
    }

    @Test
    void unknownRealmReturns404() throws Exception {
        String[] learner = registerLearner("realm404");

        mockMvc.perform(get(REALMS_URL + "/NOPE").header("Authorization", bearer(learner[0])))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode").value("RESOURCE_NOT_FOUND"));
    }

    @Test
    void inactiveRealmReturns404() throws Exception {
        String[] learner = registerLearner("realminactive");
        Realm hidden = new Realm();
        hidden.setRealmKey("HIDDEN_REALM");
        hidden.setName("Hidden");
        hidden.setActive(false);
        hidden.setDisplayOrder(99);
        realmRepository.save(hidden);

        mockMvc.perform(get(REALMS_URL + "/HIDDEN_REALM").header("Authorization", bearer(learner[0])))
                .andExpect(status().isNotFound());

        // Inactive realms never appear in the catalogue.
        String response = mockMvc.perform(get(REALMS_URL).header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        assertThat(objectMapper.readTree(response).findValuesAsText("realmKey"))
                .doesNotContain("HIDDEN_REALM");
    }

    @Test
    void realmSubjectsAreScopedToTheirRealm() throws Exception {
        String[] learner = registerLearner("realmscope");

        String aptitude = mockMvc
                .perform(get(REALMS_URL + "/APTITUDE/subjects").header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        var aptitudeNames = objectMapper.readTree(aptitude).findValuesAsText("name");
        assertThat(aptitudeNames).containsExactly("Aptitude");

        String cs = mockMvc
                .perform(get(REALMS_URL + "/COMPUTER_SCIENCE/subjects").header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        var csNames = objectMapper.readTree(cs).findValuesAsText("name");
        assertThat(csNames).contains("Programming");
        assertThat(csNames).doesNotContain("Aptitude");
    }

    @Test
    void seededSubjectsCarryExplicitRealmKeys() throws Exception {
        String[] learner = registerLearner("realmkeys");

        String response = mockMvc.perform(get("/api/v1/subjects").header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();

        var tree = objectMapper.readTree(response);
        // Every subject row in this context is seeded (V11–V28, V31):
        // all carry an explicit realm after the V30 backfill.
        for (var node : tree) {
            String name = node.get("name").asText();
            assertThat(node.get("realmKey").asText())
                    .as("seeded subject %s must carry a realm", name)
                    .isNotEmpty();
        }
        // Spot-check the two known seeds.
        assertThat(tree.findValuesAsText("name")).contains("Programming", "Aptitude");
    }

    @Test
    void subjectJsonShapeIsBackwardCompatibleWithRealmKey() throws Exception {
        String[] learner = registerLearner("realmshape");

        mockMvc.perform(get("/api/v1/subjects").header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.name == 'Aptitude')].realmKey").value("APTITUDE"))
                .andExpect(jsonPath("$[?(@.name == 'Programming')].realmKey").value("COMPUTER_SCIENCE"));
    }

    @Test
    void realmsRequireAuthentication() throws Exception {
        mockMvc.perform(get(REALMS_URL))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.errorCode").value("UNAUTHORIZED"));
        mockMvc.perform(get(REALMS_URL + "/APTITUDE"))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(get(REALMS_URL + "/APTITUDE/subjects"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void aptitudeGameContentFlowServesRealQuestions() throws Exception {
        String[] learner = registerLearner("aptflow");
        Subject aptitude = aptitudeSubject();

        // Backend-authoritative compatibility: exactly the two MCQ games.
        String games = mockMvc
                .perform(get("/api/v1/subjects/" + aptitude.getId() + "/games")
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        var gameTypes = objectMapper.readTree(games).findValuesAsText("gameType");
        assertThat(gameTypes).containsExactlyInAnyOrder("quiz_battle", "speed_run");

        // Topic listing for the aptitude subject resolves real skill topics.
        List<Topic> topics = topicRepository.findAll().stream()
                .filter(t -> t.getSubject().getId().equals(aptitude.getId()))
                .toList();
        assertThat(topics).hasSize(6);
        Topic percentages = topics.stream()
                .filter(t -> "Percentages".equals(t.getName()))
                .findFirst()
                .orElseThrow();

        // Game content serves genuine aptitude questions (not CS content).
        String content = mockMvc
                .perform(get("/api/v1/game-content")
                        .param("subjectId", aptitude.getId().toString())
                        .param("topicId", percentages.getId().toString())
                        .param("gameType", "quiz_battle")
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items").isArray())
                .andReturn().getResponse().getContentAsString();
        var texts = objectMapper.readTree(content).findValuesAsText("questionText");
        assertThat(texts).isNotEmpty();
        assertThat(texts.stream().anyMatch(t -> t.contains("25% of 200"))).isTrue();
        var topicNames = objectMapper.readTree(content).findValuesAsText("topicName");
        assertThat(topicNames).contains("Percentages");

        // Seeded question rows exist for every aptitude topic: 6 topics x 3.
        var aptitudeTopicIds = topicRepository.findAll().stream()
                .filter(t -> t.getSubject().getId().equals(
                        subjectRepository.findAll().stream()
                                .filter(s -> "Aptitude".equals(s.getName()))
                                .findFirst().orElseThrow().getId()))
                .map(t -> t.getId())
                .collect(java.util.stream.Collectors.toSet());
        long aptitudeQuestions = questionRepository.findAll().stream()
                .filter(q -> aptitudeTopicIds.contains(q.getTopic().getId()))
                .count();
        assertThat(aptitudeQuestions).isEqualTo(18);
    }

    @Test
    void aptitudeResultSubmissionAwardsXpThroughCommonContract() throws Exception {
        String[] learner = registerLearner("aptxp");

        String body = """
                {"clientRequestId": "%s", "gameType": "quiz_battle",
                 "difficulty": "EASY", "completed": true,
                 "score": 100, "durationSeconds": 60, "bestCombo": 3}
                """.formatted(UUID.randomUUID());

        // NOTE: game-result submit returns 200 by existing contract
        // (GameResultController has no CREATED mapping) - asserted as-is.
        mockMvc.perform(post("/api/v1/me/game-results")
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.xpEarned").isNumber())
                .andExpect(jsonPath("$.xpEarned").value(
                        org.hamcrest.Matchers.greaterThan(0)));
    }

    @Test
    void unsupportedGameForAptitudeIsRejected() throws Exception {
        String[] learner = registerLearner("aptnogame");
        Subject aptitude = aptitudeSubject();

        // memory_match is CONCEPT-kind; aptitude seeds no concept content
        // and no compat row, so the platform refuses honestly with 400
        // VALIDATION_FAILED (existing game-content contract).
        mockMvc.perform(get("/api/v1/game-content")
                        .param("subjectId", aptitude.getId().toString())
                        .param("gameType", "memory_match")
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_FAILED"));
    }
}
