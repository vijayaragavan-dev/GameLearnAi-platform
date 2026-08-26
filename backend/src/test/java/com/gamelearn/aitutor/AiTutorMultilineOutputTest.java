package com.gamelearn.aitutor;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import java.util.Map;
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
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamelearn.ai.gemini.GenerationOptions;
import com.gamelearn.ai.gemini.GeminiClient;
import com.gamelearn.ai.gemini.GeminiPrompt;
import com.gamelearn.dto.AuthResponse;
import com.gamelearn.dto.RegisterRequest;
import com.gamelearn.service.AuthService;

/**
 * Phase 10D - end-to-end proof that the S-4 fix lets ordinary multiline
 * Gemini answers reach the learner untouched (HTTP 200, degraded=false,
 * refused=false, newlines preserved) while the audit row records the exact
 * answerChars count and no other learner state changes.
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
@Import(AiTutorMultilineOutputTest.FallbackConfig.class)
class AiTutorMultilineOutputTest {

    private static final ObjectMapper MAPPER = new ObjectMapper();
    private static final String URL = "/api/v1/ai/tutor";

    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private AuthService authService;
    @Autowired
    private JdbcTemplate jdbcTemplate;
    @MockitoBean
    private GeminiClient geminiClient;

    @TestConfiguration(proxyBeanMethods = false)
    static class FallbackConfig {
        @Bean
        public GeminiClient recordingFallback() {
            return prompt -> "{\"answer\":\"unused\"}";
        }
    }

    private record Principal(String token, UUID userId) {
    }

    private Principal principal(String label) {
        AuthResponse auth = authService.register(new RegisterRequest(
                label + "-" + UUID.randomUUID() + "@example.test",
                "Str0ng-Passw0rd!", "Learner " + label));
        return new Principal(auth.token(), auth.user().id());
    }

    @Test
    @DisplayName("S-4 fix e2e: multiline Gemini answer is delivered verbatim with clean flags")
    void multilineAnswerDeliveredEndToEnd() throws Exception {
        Principal learner = principal("multiline");

        when(geminiClient.generate(any(GeminiPrompt.class), any(GenerationOptions.class)))
                .thenReturn("{\"answer\":\"Photosynthesis has two stages.\\n\\n"
                        + "First, light reactions capture energy.\\n"
                        + "Then the Calvin cycle builds sugar.\\tRemember both.\"}");

        long beforeAuditRows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM ai_interactions WHERE user_id=?",
                Long.class, learner.userId());

        MvcResult result = mockMvc.perform(post(URL)
                        .header("Authorization", "Bearer " + learner.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body("Explain photosynthesis")))
                .andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        JsonNode root = MAPPER.readTree(result.getResponse().getContentAsString());
        String expectedAnswer = "Photosynthesis has two stages.\n\n"
                + "First, light reactions capture energy.\n"
                + "Then the Calvin cycle builds sugar.\tRemember both.";
        assertThat(root.get("answer").asText()).isEqualTo(expectedAnswer);
        assertThat(root.get("degraded").asBoolean()).isFalse();
        assertThat(root.get("refused").asBoolean()).isFalse();
        int newlineCount = expectedAnswer.split("\n", -1).length - 1;
        assertThat(newlineCount).isEqualTo(3);

        // Exactly one new sanitized audit row; answerChars counts the real answer.
        Long afterAuditRows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM ai_interactions WHERE user_id=?",
                Long.class, learner.userId());
        assertThat(afterAuditRows).isEqualTo(beforeAuditRows + 1);

        Map<String, Object> row = jdbcTemplate.queryForMap(
                "SELECT * FROM ai_interactions WHERE user_id=? AND interaction_type='TUTOR' "
                        + "ORDER BY created_at DESC, id DESC LIMIT 1",
                learner.userId());
        row.replaceAll((key, value) -> value instanceof byte[] bytes
                ? new String(bytes, java.nio.charset.StandardCharsets.UTF_8) : value);
        assertThat(row.get("status")).isEqualTo("SUCCESS");
        JsonNode responseJson = MAPPER.readTree((String) row.get("response_json"));
        assertThat(responseJson.get("answerChars").asInt()).isEqualTo(expectedAnswer.length());
        assertThat(responseJson.get("truncated").asBoolean()).isFalse();
        assertThat(String.valueOf(row)).doesNotContain("Calvin cycle");

        verify(geminiClient, times(1)).generate(any(GeminiPrompt.class),
                any(GenerationOptions.class));
    }

    private String body(String question) {
        return MAPPER.createObjectNode().put("question", question).toString();
    }
}
