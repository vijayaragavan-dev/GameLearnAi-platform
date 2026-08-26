package com.gamelearn.config;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;

class CorsConfigTest {

    private final CorsConfig corsConfig = new CorsConfig();

    @Test
    void emptyOriginsFailFast() {
        CorsProperties properties = new CorsProperties();
        properties.setAllowedOrigins(List.of());

        assertThatThrownBy(() -> corsConfig.corsConfigurationSource(properties))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("must not be empty");
    }

    @Test
    void wildcardOriginFailsFast() {
        CorsProperties properties = new CorsProperties();
        properties.setAllowedOrigins(List.of("*"));

        assertThatThrownBy(() -> corsConfig.corsConfigurationSource(properties))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Wildcard");
    }

    @Test
    void explicitLocalPatternIsAccepted() {
        CorsProperties properties = new CorsProperties();
        properties.setAllowedOrigins(List.of("http://localhost:[*]"));

        CorsConfigurationSource source = corsConfig.corsConfigurationSource(properties);
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/actuator/health");
        CorsConfiguration configuration = source.getCorsConfiguration(request);

        assertThat(configuration).isNotNull();
        assertThat(configuration.getAllowedOriginPatterns()).containsExactly("http://localhost:[*]");
        assertThat(configuration.getAllowCredentials()).isFalse();
    }
}
