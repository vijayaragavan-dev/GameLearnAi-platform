package com.gamelearn.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamelearn.ai.gemini.GeminiClient;
import com.gamelearn.dto.AuthResponse;
import com.gamelearn.dto.RegisterRequest;
import com.gamelearn.service.AuthService;

/**
 * Batch 3 / Phase 7D-7E: AI/tutor subject/unit/topic context authority.
 * The unitId extension is additive and optional; ambiguous names resolve by
 * stable identity, and cross-unit combinations are rejected explicitly.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestPropertySource(properties = {
        "gamelearn.ai.tutor.enabled=true",
        "gamelearn.ai.gemini.api-key=test-dummy-key-not-real",
        "gamelearn.ai.gemini.model=test-model",
        "gamelearn.ai.tutor.retry.backoff-base=10ms"
})
@Import(TutorUnitContextBatch3Test.SpyFreeConfig.class)
class TutorUnitContextBatch3Test {

    private static final String URL = "/api/v1/ai/tutor";
    private static final String OOP = "11111111-1111-1111-1111-111111111106";
    private static final String OOP_UNIT = "77777777-7777-7777-7777-777777777701";
    private static final String OOP_TOPIC = "22222222-2222-2222-2222-222222222244";
    private static final String OOSE_TOPIC = "22222222-2222-2222-2222-222222222264";
    private static final String LEGACY_TOPIC = "22222222-2222-2222-2222-222222222212";
    private static final String POLYMORPHISM = "22222222-2222-2222-2222-222222222254";

    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private ObjectMapper objectMapper;
    @Autowired
    private AuthService authService;
    @MockitoBean
    private GeminiClient geminiClient;

    @TestConfiguration(proxyBeanMethods = false)
    static class SpyFreeConfig {
        @Bean
        public GeminiClient recordingFallback() {
            return prompt -> "{\"answer\":\"unused\"}";
        }
    }

    @Test
    void topicWithUnitEchoesUnitIdentity() throws Exception {
        String token = register();
        when(geminiClient.generate(any(com.gamelearn.ai.gemini.GeminiPrompt.class),
                any(com.gamelearn.ai.gemini.GenerationOptions.class)))
                .thenReturn("{\"answer\":\"unit aware\"}");
        mockMvc.perform(post(URL)
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(tutorBody("Explain classes?", null, OOP_TOPIC, null)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.context.subjectId").value(OOP))
                .andExpect(jsonPath("$.context.topicId").value(OOP_TOPIC))
                .andExpect(jsonPath("$.context.unitId").value(OOP_UNIT))
                .andExpect(jsonPath("$.context.unitName").value("Java Fundamentals and Data Types"));
    }

    @Test
    void explicitMatchingUnitIsAccepted() throws Exception {
        String token = register();
        when(geminiClient.generate(any(com.gamelearn.ai.gemini.GeminiPrompt.class),
                any(com.gamelearn.ai.gemini.GenerationOptions.class)))
                .thenReturn("{\"answer\":\"matched\"}");
        mockMvc.perform(post(URL)
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(tutorBody("Explain classes?", OOP, OOP_TOPIC, OOP_UNIT)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.context.unitId").value(OOP_UNIT));
    }

    @Test
    void crossUnitCombinationsAreRejected() throws Exception {
        String token = register();
        // OOSE topic with an OOP unit.
        mockMvc.perform(post(URL)
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(tutorBody("Explain?", null, OOSE_TOPIC, OOP_UNIT)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.fieldErrors.topicId").value("topicId does not belong to unitId"));
        // OOP unit claimed under a DBMS subject.
        mockMvc.perform(post(URL)
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(tutorBody("Explain?",
                                "11111111-1111-1111-1111-111111111103", null, OOP_UNIT)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.fieldErrors.unitId").value("unitId does not belong to subjectId"));
        // Legacy topic without a unit never silently matches an explicit unit.
        mockMvc.perform(post(URL)
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(tutorBody("Explain?", null, LEGACY_TOPIC, OOP_UNIT)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_FAILED"));
        // Unknown unit.
        mockMvc.perform(post(URL)
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(tutorBody("Explain?", null, null,
                                "00000000-0000-0000-0000-000000000000")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.fieldErrors.unitId").value("Unknown or inactive unitId"));
    }

    @Test
    void unitOnlyRequestResolvesSubject() throws Exception {
        String token = register();
        when(geminiClient.generate(any(com.gamelearn.ai.gemini.GeminiPrompt.class),
                any(com.gamelearn.ai.gemini.GenerationOptions.class)))
                .thenReturn("{\"answer\":\"unit focus\"}");
        mockMvc.perform(post(URL)
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(tutorBody("What should I learn?", null, null, OOP_UNIT)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.context.subjectId").value(OOP))
                .andExpect(jsonPath("$.context.unitId").value(OOP_UNIT))
                .andExpect(jsonPath("$.context.topicId").doesNotExist());
    }

    @Test
    void ambiguousNameResolvesByStableIdentity() throws Exception {
        String token = register();
        when(geminiClient.generate(any(com.gamelearn.ai.gemini.GeminiPrompt.class),
                any(com.gamelearn.ai.gemini.GenerationOptions.class)))
                .thenReturn("{\"answer\":\"poly\"}");
        // "Polymorphism" by id: unambiguously the OOP topic in its unit.
        String body = tutorBody("What is Polymorphism?", null, POLYMORPHISM, null);
        String response = mockMvc.perform(post(URL)
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.context.subjectName").value("Object Oriented Programming"))
                .andExpect(jsonPath("$.context.unitName").value("Inheritance and Polymorphism"))
                .andReturn().getResponse().getContentAsString();
        JsonNode context = objectMapper.readTree(response).path("context");
        assertThat(context.path("subjectId").asText()).isEqualTo(OOP);
    }

    @Test
    void genericModeHasNoUnitLeakage() throws Exception {
        String token = register();
        when(geminiClient.generate(any(com.gamelearn.ai.gemini.GeminiPrompt.class),
                any(com.gamelearn.ai.gemini.GenerationOptions.class)))
                .thenReturn("{\"answer\":\"generic\"}");
        mockMvc.perform(post(URL)
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(tutorBody("What is learning?", null, null, null)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.context.subjectId").doesNotExist())
                .andExpect(jsonPath("$.context.unitId").doesNotExist())
                .andExpect(jsonPath("$.context.unitName").doesNotExist());
    }

    private String register() {
        AuthResponse auth = authService.register(new RegisterRequest(
                "tutor7-" + UUID.randomUUID() + "@example.test",
                "Str0ng-Passw0rd!", "Learner tutor7"));
        return auth.token();
    }

    private String tutorBody(String question, String subjectId, String topicId, String unitId) {
        StringBuilder body = new StringBuilder("{\"question\": \"").append(question).append('"');
        if (subjectId != null) {
            body.append(", \"subjectId\": \"").append(subjectId).append('"');
        }
        if (topicId != null) {
            body.append(", \"topicId\": \"").append(topicId).append('"');
        }
        if (unitId != null) {
            body.append(", \"unitId\": \"").append(unitId).append('"');
        }
        return body.append('}').toString();
    }
}
