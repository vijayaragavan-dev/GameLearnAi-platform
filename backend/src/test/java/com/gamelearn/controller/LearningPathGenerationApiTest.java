package com.gamelearn.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.UUID;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MvcResult;

import com.gamelearn.ai.gemini.GeminiClient;
import com.gamelearn.repository.LearningPathRepository;
import com.gamelearn.repository.UserRepository;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;

/**
 * PATH-002 transport contract and security (central API Contract section 5):
 * LP19 cross-user isolation, unauthenticated access, input validation,
 * idempotency status codes 200/201.
 */
@SpringBootTest(properties = {
        "gamelearn.ai.learning-path.enabled=true",
        "gamelearn.ai.gemini.api-key=test-key",
        "gamelearn.ai.gemini.model=gemini-test-model",
        "gamelearn.ai.learning-path.retry.backoff-base=1ms"
})
@AutoConfigureMockMvc
@ActiveProfiles("test")
class LearningPathGenerationApiTest extends AbstractCoreApiTest {

    @Autowired
    private LearningPathRepository learningPathRepository;

    @Autowired
    private UserRepository userRepository;

    @MockitoBean
    private GeminiClient geminiClient;

    private Subject subjectWithThreeTopics(String label) {
        Subject subject = newActiveSubject(label, 1);
        String[] names = {"Alpha", "Beta", "Gamma"};
        for (int i = 0; i < 3; i++) {
            Topic topic = new Topic();
            topic.setSubject(subject);
            topic.setName(names[i]);
            topic.setDescription(names[i] + " description");
            topic.setDifficulty(com.gamelearn.entity.enums.Difficulty.values()[i]);
            topic.setDisplayOrder(i + 1);
            topic.setActive(true);
            topicRepository.save(topic);
        }
        return subject;
    }

    private String candidateJson() {
        return """
                {"title":"Api Plan","description":"Covering Alpha, Beta and Gamma.","nodes":[
                  {"topicRef":1,"sequence":1},{"topicRef":2,"sequence":2},{"topicRef":3,"sequence":3}]}
                """;
    }

    private MvcResult generate(String token, UUID subjectId, String body) throws Exception {
        return mockMvc.perform(post("/api/v1/learning-path/{subjectId}/generate", subjectId)
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andReturn();
    }

    // ------------------------------------------------------------------
    // Security
    // ------------------------------------------------------------------
    @Test
    @DisplayName("Unauthenticated POST is rejected with the safe error envelope")
    void unauthenticatedIsRejected() throws Exception {
        Subject subject = subjectWithThreeTopics("sec401");
        mockMvc.perform(post("/api/v1/learning-path/{subjectId}/generate", subject.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.errorCode").value("UNAUTHORIZED"));
    }

    @Test
    @DisplayName("LP19: learners see and receive only their own paths")
    void crossUserIsolationHolds() throws Exception {
        String[] learnerA = registerLearner("lp19a");
        String[] learnerB = registerLearner("lp19b");
        Subject subject = subjectWithThreeTopics("lp19");
        Mockito.when(geminiClient.generate(any())).thenReturn(candidateJson());

        generate(learnerA[0], subject.getId(), "{}");

        // B's read model shows nothing of A's path.
        mockMvc.perform(get("/api/v1/learning-path/{id}", subject.getId())
                        .header("Authorization", bearer(learnerB[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));

        // B's own generation creates a SEPARATE path - never touches A's.
        MvcResult bResult = generate(learnerB[0], subject.getId(), "{}");
        assertThat(bResult.getResponse().getStatus()).isEqualTo(201);
        String bPathIdRaw = com.jayway.jsonpath.JsonPath.read(
                bResult.getResponse().getContentAsString(), "$.id");
        UUID bPathId = UUID.fromString(bPathIdRaw);

        // Each learner owns EXACTLY ONE path for the subject - never each other's.
        UUID aId = userRepository.findByEmail(learnerA[1]).orElseThrow().getId();
        UUID bId = userRepository.findByEmail(learnerB[1]).orElseThrow().getId();
        var ownedByA = learningPathRepository
                .findByUserIdAndSubjectIdOrderByCreatedAtAsc(aId, subject.getId());
        var ownedByB = learningPathRepository
                .findByUserIdAndSubjectIdOrderByCreatedAtAsc(bId, subject.getId());
        assertThat(ownedByA).hasSize(1);
        assertThat(ownedByB).hasSize(1);
        assertThat(ownedByA.get(0).getId()).isNotEqualTo(bPathId);
        assertThat(ownedByB.get(0).getId()).isEqualTo(bPathId);
    }

    // ------------------------------------------------------------------
    // Idempotency status codes (200 vs 201) + response shape at HTTP layer
    // ------------------------------------------------------------------
    @Test
    @DisplayName("First generation returns 201; repeat returns the SAME path with 200 and no AI call")
    void statusCodeContractHolds() throws Exception {
        String[] learner = registerLearner("lp200201");
        Subject subject = subjectWithThreeTopics("lp200201");
        Mockito.when(geminiClient.generate(any())).thenReturn(candidateJson());

        MvcResult first = generate(learner[0], subject.getId(), "{}");
        assertThat(first.getResponse().getStatus()).isEqualTo(201);
        String firstBody = first.getResponse().getContentAsString();

        Mockito.verify(geminiClient, Mockito.times(1)).generate(any());

        MvcResult second = generate(learner[0], subject.getId(), "{}");
        assertThat(second.getResponse().getStatus()).isEqualTo(200);
        assertThat(second.getResponse().getContentAsString()).isEqualTo(firstBody);
        Mockito.verify(geminiClient, Mockito.times(1)).generate(any()); // unchanged

        // Persisted fields exposed exactly as approved; no internals leak.
        assertThat(firstBody)
                .contains("\"subjectId\"").contains("\"status\":\"ACTIVE\"")
                .contains("\"generatedBy\":\"AI\"").contains("\"createdAt\"")
                .contains("\"sequenceNumber\":1").doesNotContain("promptVersion");

        // PATH-001 now reads back what generation created.
        mockMvc.perform(get("/api/v1/learning-path/{id}", subject.getId())
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].generatedBy").value("AI"));
    }

    // ------------------------------------------------------------------
    // Input validation
    // ------------------------------------------------------------------
    @Test
    @DisplayName("Oversized learningGoal is rejected with 400 before any AI work")
    void oversizedGoalRejected() throws Exception {
        String[] learner = registerLearner("goal300");
        Subject subject = subjectWithThreeTopics("goal300");
        String body = "{\"learningGoal\":\"" + "x".repeat(301) + "\"}";
        mockMvc.perform(post("/api/v1/learning-path/{subjectId}/generate", subject.getId())
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_FAILED"));
        Mockito.verifyNoInteractions(geminiClient);
    }

    @Test
    @DisplayName("Unknown or inactive subjects return 404 without touching Gemini")
    void unknownSubjectReturns404() throws Exception {
        String[] learner = registerLearner("subj404");
        Mockito.when(geminiClient.generate(any())).thenReturn(candidateJson());

        mockMvc.perform(post("/api/v1/learning-path/{subjectId}/generate", UUID.randomUUID())
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode").value("RESOURCE_NOT_FOUND"));

        Subject inactive = newInactiveSubject("inactive404");
        mockMvc.perform(post("/api/v1/learning-path/{subjectId}/generate", inactive.getId())
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isNotFound());
        Mockito.verifyNoInteractions(geminiClient);
    }

    @Test
    @DisplayName("Client-supplied authority fields are ignored; backend owns provenance")
    void authorityFieldsFromClientAreIgnored() throws Exception {
        String[] learnerA = registerLearner("authority");
        Subject subject = subjectWithThreeTopics("authority");
        Mockito.when(geminiClient.generate(any())).thenReturn(candidateJson());

        String hostileBody = "{\"userId\":\"00000000-0000-0000-0000-000000000000\","
                + "\"generatedBy\":\"HYBRID\",\"masteryScore\":100,"
                + "\"difficulty\":\"HARD\",\"regenerate\":false}";
        MvcResult result = generate(learnerA[0], subject.getId(), hostileBody);

        assertThat(result.getResponse().getStatus()).isEqualTo(201);
        String body = result.getResponse().getContentAsString();
        assertThat(body)
                .contains("\"generatedBy\":\"AI\"")   // backend decides provenance
                .doesNotContain("HYBRID");

        // The path belongs to the CALLER, not the injected userId.
        UUID callerId = userRepository.findByEmail(learnerA[1]).orElseThrow().getId();
        assertThat(learningPathRepository
                .findByUserIdAndSubjectIdOrderByCreatedAtAsc(callerId, subject.getId()))
                .hasSize(1);
    }
}
