package com.gamelearn.exception;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;

/**
 * Exercises the global exception infrastructure through a throwaway probe
 * controller. Standalone MockMvc is used deliberately so the production
 * security configuration does not need test-only holes.
 */
class GlobalExceptionHandlerTest {

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(new ProbeController())
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    void validationFailureReturnsStructuredFieldErrors() throws Exception {
        String body = mockMvc.perform(post("/probe/validation")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"\"}"))
                .andExpect(status().isBadRequest())
                .andReturn().getResponse().getContentAsString();

        assertThat(body).contains("\"errorCode\":\"VALIDATION_FAILED\"");
        assertThat(body).contains("\"fieldErrors\":{");
        assertThat(body).contains("must not be blank");
    }

    @Test
    void malformedBodyReturnsSafeBadRequest() throws Exception {
        String body = mockMvc.perform(post("/probe/validation")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{not-json"))
                .andExpect(status().isBadRequest())
                .andReturn().getResponse().getContentAsString();

        ErrorResponse response = readError(body);
        assertThat(response.errorCode()).isEqualTo("MALFORMED_REQUEST");
        assertThat(response.fieldErrors()).isNull();
        assertThat(body).doesNotContain("JsonParser");
        assertThat(body).doesNotContain("\tat ");
    }

    @Test
    void apiExceptionCarriesCustomStatusAndCode() throws Exception {
        String body = mockMvc.perform(get("/probe/api-error"))
                .andExpect(status().is(HttpStatus.SERVICE_UNAVAILABLE.value()))
                .andReturn().getResponse().getContentAsString();

        ErrorResponse response = readError(body);
        assertThat(response.errorCode()).isEqualTo("FEATURE_UNAVAILABLE");
        assertThat(response.message()).isEqualTo("Feature temporarily unavailable");
        assertThat(response.path()).isEqualTo("/probe/api-error");
    }

    @Test
    void unexpectedExceptionNeverLeaksInternals() throws Exception {
        String body = mockMvc.perform(get("/probe/unexpected"))
                .andExpect(status().isInternalServerError())
                .andReturn().getResponse().getContentAsString();

        ErrorResponse response = readError(body);
        assertThat(response.errorCode()).isEqualTo("INTERNAL_ERROR");
        assertThat(response.message()).isEqualTo("An unexpected internal error occurred");
        assertThat(body).doesNotContain("classified-database-password");
        assertThat(body).doesNotContain("\tat ");
        assertThat(body).doesNotContain("IllegalStateException");
    }

    @Test
    void errorResponsesIncludeCorrelationIdAndTimestamp() throws Exception {
        String body = mockMvc.perform(get("/probe/unexpected"))
                .andExpect(status().isInternalServerError())
                .andReturn().getResponse().getContentAsString();

        ErrorResponse response = readError(body);
        assertThat(response.timestamp()).isNotNull();
        assertThat(response.requestId()).isNotBlank();
    }

    private ErrorResponse readError(String body) throws Exception {
        return new ObjectMapper().findAndRegisterModules().readValue(body, ErrorResponse.class);
    }

    record ProbeRequest(@NotBlank String name) {}

    @RestController
    @Validated
    static class ProbeController {

        @PostMapping("/probe/validation")
        String validate(@Valid @RequestBody ProbeRequest request) {
            return "ok";
        }

        @GetMapping("/probe/api-error")
        String apiError() {
            throw new ApiException(
                    HttpStatus.SERVICE_UNAVAILABLE.value(),
                    "FEATURE_UNAVAILABLE",
                    "Feature temporarily unavailable");
        }

        @GetMapping("/probe/unexpected")
        String unexpected() {
            throw new IllegalStateException("boom classified-database-password stack detail");
        }
    }
}
