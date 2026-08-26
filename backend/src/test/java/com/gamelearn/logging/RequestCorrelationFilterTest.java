package com.gamelearn.logging;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.concurrent.atomic.AtomicInteger;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class RequestCorrelationFilterTest {

    private final RequestCorrelationFilter filter = new RequestCorrelationFilter();

    @Test
    void generatesRequestIdWhenHeaderMissing() throws Exception {
        MockHttpServletResponse response = new MockHttpServletResponse();
        filter.doFilter(requestWithoutHeader(), response, (req, res) -> {});

        String requestId = response.getHeader(RequestCorrelationFilter.REQUEST_ID_HEADER);
        assertThat(requestId).isNotBlank().hasSize(36);
    }

    @Test
    void preservesWellFormedClientRequestId() throws Exception {
        MockHttpServletRequest request = requestWithoutHeader();
        request.addHeader(RequestCorrelationFilter.REQUEST_ID_HEADER, "flutter-client-42");
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, (req, res) -> {});

        assertThat(response.getHeader(RequestCorrelationFilter.REQUEST_ID_HEADER))
                .isEqualTo("flutter-client-42");
    }

    @Test
    void replacesUnsafeRequestId() throws Exception {
        MockHttpServletRequest request = requestWithoutHeader();
        request.addHeader(RequestCorrelationFilter.REQUEST_ID_HEADER,
                "bad id with spaces\r\nInjected-Header: yes");
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, (req, res) -> {});

        String requestId = response.getHeader(RequestCorrelationFilter.REQUEST_ID_HEADER);
        assertThat(requestId).isNotEqualTo("bad id with spaces\r\nInjected-Header: yes");
        assertThat(requestId).hasSize(36).doesNotContain(" ").doesNotContain("\n");
    }

    @Test
    void clearsMdcAfterRequestCompletes() throws Exception {
        MockHttpServletRequest request = requestWithoutHeader();
        request.addHeader(RequestCorrelationFilter.REQUEST_ID_HEADER, "mdc-check");

        AtomicInteger invocations = new AtomicInteger();
        filter.doFilter(request, new MockHttpServletResponse(), (req, res) -> {
            invocations.incrementAndGet();
            assertThat(RequestCorrelationFilter.currentRequestId()).isEqualTo("mdc-check");
        });

        assertThat(invocations.get()).isEqualTo(1);
        assertThat(RequestCorrelationFilter.currentRequestId()).isEqualTo("unknown");
    }

    private MockHttpServletRequest requestWithoutHeader() {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/actuator/health");
        request.setRequestURI("/actuator/health");
        return request;
    }
}
