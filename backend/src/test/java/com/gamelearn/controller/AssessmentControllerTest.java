package com.gamelearn.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.UUID;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import com.gamelearn.service.AuthService;
import com.gamelearn.dto.AuthResponse;
import com.gamelearn.dto.RegisterRequest;

/**
 * Phase 8B — ASMT-001..003 HTTP boundary (API Contract v1.2.0 §5B):
 * authentication, path validation, error codes.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AssessmentControllerTest {

    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private AuthService authService;

    private String token(String label) {
        AuthResponse auth = authService.register(new RegisterRequest(
                label + "-" + UUID.randomUUID() + "@example.test",
                "Str0ng-Passw0rd!", "Learner " + label));
        return auth.token();
    }

    @Test
    @DisplayName("ASMT-TEST-022: anonymous access to every assessment endpoint is 401")
    void anonymousRejected() throws Exception {
        mockMvc.perform(get("/api/v1/assessment/" + UUID.randomUUID()))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(post("/api/v1/assessment/" + UUID.randomUUID() + "/submit")
                        .contentType("application/json").content("{\"answers\":[]}"))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(get("/api/v1/assessment/" + UUID.randomUUID() + "/result"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Malformed subject UUID => 400 MALFORMED_REQUEST")
    void malformedUuidRejected() throws Exception {
        String token = token("asmtctl");
        mockMvc.perform(get("/api/v1/assessment/not-a-uuid")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("MALFORMED_REQUEST"));
    }

    @Test
    @DisplayName("Unknown subject => 404 RESOURCE_NOT_FOUND on all endpoints")
    void unknownSubjectNotFound() throws Exception {
        String token = token("asmt404");
        UUID random = UUID.randomUUID();
        mockMvc.perform(get("/api/v1/assessment/" + random)
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode").value("RESOURCE_NOT_FOUND"));
        mockMvc.perform(get("/api/v1/assessment/" + random + "/result")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode").value("RESOURCE_NOT_FOUND"));
    }

    @Test
    @DisplayName("Empty answers body on submit => 400 VALIDATION_FAILED")
    void emptyAnswersValidation() throws Exception {
        String token = token("asmtvalid");
        mockMvc.perform(post("/api/v1/assessment/" + UUID.randomUUID() + "/submit")
                        .header("Authorization", "Bearer " + token)
                        .contentType("application/json")
                        .content("{\"answers\":[]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_FAILED"));
    }
}
