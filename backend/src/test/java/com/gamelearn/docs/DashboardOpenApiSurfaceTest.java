package com.gamelearn.docs;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.ArrayList;
import java.util.List;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Phase 9B — DASH-TEST-036: the OpenAPI surface documents DASH-001 exactly
 * once, with authentication and the DashboardResponse schema — and exposes
 * NO other dashboard route (Dashboard Specification section 3.2 forbids
 * /dashboard/{userId}, /dashboard/admin etc.).
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class DashboardOpenApiSurfaceTest {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    @Autowired
    private MockMvc mockMvc;

    @Test
    @DisplayName("DASH-TEST-036: OpenAPI documents GET /api/v1/dashboard with bearer auth")
    void dashboardIsDocumentedExactlyOnce() throws Exception {
        String body = mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        JsonNode root = MAPPER.readTree(body);

        List<String> dashboardPaths = new ArrayList<>();
        root.get("paths").fieldNames().forEachRemaining(path -> {
            if (path.contains("/dashboard")) {
                dashboardPaths.add(path);
            }
        });
        assertThat(dashboardPaths).containsExactly("/api/v1/dashboard");

        JsonNode operation = root.get("paths").get("/api/v1/dashboard").get("get");
        assertThat(operation).isNotNull();
        // No other HTTP verb may be exposed on the dashboard path.
        List<String> verbs = new ArrayList<>();
        root.get("paths").get("/api/v1/dashboard").fieldNames()
                .forEachRemaining(verbs::add);
        assertThat(verbs).containsExactly("get");

        // Authentication is documented via the bearerAuth scheme.
        JsonNode security = operation.get("security");
        assertThat(security).isNotNull();
        boolean bearerDocumented = false;
        for (JsonNode requirement : security) {
            if (requirement.has("bearerAuth")) {
                bearerDocumented = true;
            }
        }
        assertThat(bearerDocumented).isTrue();

        // The 200 response references the DashboardResponse schema; no request body.
        JsonNode ok = operation.get("responses").get("200");
        assertThat(ok).isNotNull();
        assertThat(ok.get("content").get("application/json")
                .get("schema").get("$ref").asText())
                .endsWith("DashboardResponse");
        assertThat(operation.has("requestBody")).isFalse();
        assertThat(root.get("components").get("schemas").has("DashboardResponse")).isTrue();
        assertThat(root.get("components").get("schemas").has("LearningPathCard")).isTrue();
        assertThat(root.get("components").get("schemas").has("RecommendationItem")).isTrue();

        // 401 behavior documented.
        assertThat(operation.get("responses").has("401")).isTrue();
    }
}
