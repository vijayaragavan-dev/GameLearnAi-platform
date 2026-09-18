package com.gamelearn.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.UUID;

import org.junit.jupiter.api.DisplayName;
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
import org.springframework.test.web.servlet.MvcResult;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamelearn.ai.gemini.GenerationOptions;
import com.gamelearn.ai.gemini.GeminiClient;
import com.gamelearn.ai.gemini.GeminiPrompt;
import com.gamelearn.dto.AuthResponse;
import com.gamelearn.dto.RegisterRequest;
import com.gamelearn.entity.Subject;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.service.AuthService;

/**
 * Gate 23: RAG sidecar unreachable - the tutor must fail safe with the
 * existing 503 envelope (never an ungrounded Gemini answer, never a
 * hang). The base URL points at a closed loopback port so connection
 * is refused within the bounded connect timeout.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@TestPropertySource(properties = {
        "gamelearn.ai.tutor.enabled=true",
        "gamelearn.ai.gemini.api-key=test-dummy-key-not-real",
        "gamelearn.ai.gemini.model=test-model",
        "gamelearn.ai.tutor.retry.backoff-base=10ms",
        "gamelearn.ai.rag.enabled=true",
        "gamelearn.ai.rag.service-token=test-sidecar-token",
        "gamelearn.ai.rag.base-url=http://127.0.0.1:9",
        "gamelearn.ai.rag.connect-timeout=500ms",
        "gamelearn.ai.rag.read-timeout=1s"
})
@Import(AiTutorRagDownTest.SpyFreeConfig.class)
class AiTutorRagDownTest {

    private static final ObjectMapper MAPPER = new ObjectMapper();
    private static final String URL = "/api/v1/ai/tutor";

    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private AuthService authService;
    @Autowired
    private SubjectRepository subjectRepository;
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
    @DisplayName("RAG-08: unreachable sidecar yields 503 without Gemini contact")
    void unreachableSidecarFailsSafe() throws Exception {
        AuthResponse auth = authService.register(new RegisterRequest(
                "ragdown-" + UUID.randomUUID() + "@example.test",
                "Str0ng-Passw0rd!", "Learner down"));
        Subject subject = new Subject();
        subject.setName("ragdown-" + UUID.randomUUID());
        subject.setDescription("down");
        subject.setIconKey("icon_down");
        subject.setActive(true);
        subject.setDisplayOrder(5);
        subject = subjectRepository.saveAndFlush(subject);

        when(geminiClient.generate(any(GeminiPrompt.class), any(GenerationOptions.class)))
                .thenReturn("{\"answer\":\"must never be used\"}");

        String body = MAPPER.createObjectNode()
                .put("question", "What is photosynthesis?")
                .put("subjectId", subject.getId().toString())
                .toString();
        MvcResult result = mockMvc.perform(post(URL)
                        .header("Authorization", "Bearer " + auth.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isServiceUnavailable())
                .andReturn();

        assertThat(result.getResponse().getContentAsString())
                .contains("AI_SERVICE_UNAVAILABLE");
        // No silent ungrounded fallback: Gemini never contacted.
        verify(geminiClient, never()).generate(any(GeminiPrompt.class),
                any(GenerationOptions.class));
    }
}
