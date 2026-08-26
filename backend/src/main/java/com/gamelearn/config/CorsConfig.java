package com.gamelearn.config;

import java.util.List;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

/**
 * Single source of truth for CORS. The produced {@link CorsConfigurationSource}
 * is consumed by Spring Security's CORS filter so pre-flight requests are
 * answered before authorization.
 */
@Configuration
@EnableConfigurationProperties(CorsProperties.class)
public class CorsConfig {

    @Bean
    public CorsConfigurationSource corsConfigurationSource(CorsProperties properties) {
        List<String> origins = properties.getAllowedOrigins();
        if (origins.isEmpty()) {
            throw new IllegalStateException(
                    "gamelearn.cors.allowed-origins must not be empty; "
                            + "configure explicit origins via the CORS_ALLOWED_ORIGINS environment variable");
        }
        if (origins.stream().anyMatch("*"::equals)) {
            throw new IllegalStateException(
                    "Wildcard origin '*' is not permitted; list explicit origins instead");
        }

        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(origins);
        configuration.setAllowedMethods(properties.getAllowedMethods());
        configuration.setAllowedHeaders(properties.getAllowedHeaders());
        configuration.setMaxAge(properties.getMaxAgeSeconds());
        configuration.setAllowCredentials(false);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
