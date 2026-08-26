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
 * Phase 10B - AI-001 OpenAPI surface (API Contract v1.4.0 section 5D):
 * exactly one tutor route, POST-only, bearer-authenticated, AiTutorResponse
 * schema, documented error codes, requestBody present, and NO other /ai
 * routes invented.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class Ai001OpenApiSurfaceTest {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    @Autowired
    private MockMvc mockMvc;

    @Test
    @DisplayName("OpenAPI documents POST /api/v1/ai/tutor with bearer auth + schema")
    void aiTutorIsDocumentedExactlyOnce() throws Exception {
        String body = mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        JsonNode root = MAPPER.readTree(body);

        List<String> tutorPaths = new ArrayList<>();
        root.get("paths").fieldNames().forEachRemaining(path -> {
            if (path.contains("/ai/")) {
                tutorPaths.add(path);
            }
        });
        assertThat(tutorPaths).containsExactly("/api/v1/ai/tutor");

        JsonNode pathItem = root.get("paths").get("/api/v1/ai/tutor");
        List<String> verbs = new ArrayList<>();
        pathItem.fieldNames().forEachRemaining(verbs::add);
        assertThat(verbs).containsExactly("post");

        JsonNode operation = pathItem.get("post");
        boolean bearerDocumented = false;
        for (JsonNode requirement : operation.get("security")) {
            if (requirement.has("bearerAuth")) {
                bearerDocumented = true;
            }
        }
        assertThat(bearerDocumented).isTrue();

        assertThat(operation.has("requestBody")).isTrue();
        JsonNode responses = operation.get("responses");
        assertThat(responses.get("200").get("content").get("application/json")
                .get("schema").get("$ref").asText()).endsWith("AiTutorResponse");
        assertThat(responses.has("400")).isTrue();
        assertThat(responses.has("401")).isTrue();
        assertThat(responses.has("429")).isTrue();
        assertThat(responses.has("503")).isTrue();

        assertThat(root.get("components").get("schemas").has("AiTutorResponse")).isTrue();
    }
}
