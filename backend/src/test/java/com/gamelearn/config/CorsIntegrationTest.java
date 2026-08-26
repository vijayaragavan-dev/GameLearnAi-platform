package com.gamelearn.config;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class CorsIntegrationTest {

    private static final String ALLOWED_ORIGIN = "http://localhost:12345";
    private static final String FOREIGN_ORIGIN = "https://evil.example.com";

    @Autowired
    private MockMvc mockMvc;

    @Test
    void preflightFromAllowedOriginIsAccepted() throws Exception {
        mockMvc.perform(options("/actuator/health")
                        .header("Origin", ALLOWED_ORIGIN)
                        .header("Access-Control-Request-Method", "GET"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", ALLOWED_ORIGIN));
    }

    @Test
    void actualRequestFromAllowedOriginGetsCorsHeaders() throws Exception {
        mockMvc.perform(get("/actuator/health").header("Origin", ALLOWED_ORIGIN))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", ALLOWED_ORIGIN));
    }

    @Test
    void preflightFromDisallowedOriginIsRejected() throws Exception {
        mockMvc.perform(options("/actuator/health")
                        .header("Origin", FOREIGN_ORIGIN)
                        .header("Access-Control-Request-Method", "GET"))
                .andExpect(status().isForbidden())
                .andExpect(header().doesNotExist("Access-Control-Allow-Origin"));
    }

    @Test
    void wildcardOriginHeaderIsNeverEmitted() throws Exception {
        mockMvc.perform(get("/actuator/health").header("Origin", ALLOWED_ORIGIN))
                .andExpect(header().string("Access-Control-Allow-Origin", ALLOWED_ORIGIN));
    }
}
