package com.gamelearn.logging;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class RequestCorrelationIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void echoesClientSuppliedRequestId() throws Exception {
        MvcResult result = mockMvc.perform(get("/actuator/health")
                        .header(RequestCorrelationFilter.REQUEST_ID_HEADER, "integration-check-1"))
                .andReturn();

        assertThat(result.getResponse().getHeader(RequestCorrelationFilter.REQUEST_ID_HEADER))
                .isEqualTo("integration-check-1");
    }

    @Test
    void generatesRequestIdWhenClientOmitsIt() throws Exception {
        MvcResult result = mockMvc.perform(get("/actuator/health"))
                .andReturn();

        String requestId = result.getResponse().getHeader(RequestCorrelationFilter.REQUEST_ID_HEADER);
        assertThat(requestId).isNotBlank().hasSize(36);
    }
}
