package com.gamelearn.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.Map;
import java.util.UUID;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import com.gamelearn.dto.AuthResponse;
import com.gamelearn.dto.RegisterRequest;
import com.gamelearn.service.AuthService;

/**
 * Phase 10B - TUT-TEST-021: feature-disabled mode. The tutor flag stays at
 * its test-profile default (false): a valid request must receive the
 * controlled 503 BEFORE any validation work, with a FAILED TUTOR_DISABLED
 * audit row and model_name null.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AiTutorDisabledTest {

    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private AuthService authService;
    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    @DisplayName("TUT-TEST-021: tutor disabled -> controlled 503 + TUTOR_DISABLED audit row")
    void disabledFlagProducesControlled503() throws Exception {
        AuthResponse auth = authService.register(new RegisterRequest(
                "tutdisabled-" + UUID.randomUUID() + "@example.test",
                "Str0ng-Passw0rd!", "Learner tutdisabled"));
        UUID userId = auth.user().id();

        mockMvc.perform(post("/api/v1/ai/tutor")
                        .header("Authorization", "Bearer " + auth.token())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"question\":\"hello\"}"))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.errorCode").value("AI_SERVICE_UNAVAILABLE"))
                .andExpect(jsonPath("$.message").value("AI tutor is not enabled."))
                .andExpect(jsonPath("$.requestId").isNotEmpty());

        Map<String, Object> row = jdbcTemplate.queryForMap(
                "SELECT * FROM ai_interactions WHERE user_id=? AND interaction_type='TUTOR' "
                        + "ORDER BY created_at DESC, id DESC LIMIT 1",
                userId);
        // H2 hands JSON columns back as byte[] - normalize for assertions.
        row.replaceAll((key, value) -> value instanceof byte[] bytes
                ? new String(bytes, java.nio.charset.StandardCharsets.UTF_8) : value);
        org.assertj.core.api.Assertions.assertThat(row.get("status")).isEqualTo("FAILED");
        org.assertj.core.api.Assertions.assertThat((String) row.get("error_code"))
                .isEqualTo("TUTOR_DISABLED");
        org.assertj.core.api.Assertions.assertThat(row.get("model_name")).isNull();
        // No prompt/question material ever reaches storage.
        String rowText = String.valueOf(row);
        org.assertj.core.api.Assertions.assertThat(rowText).doesNotContain("hello");
    }
}
