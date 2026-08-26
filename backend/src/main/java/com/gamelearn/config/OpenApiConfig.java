package com.gamelearn.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityScheme;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI gameLearnOpenApi() {
        return new OpenAPI()
                .info(new Info()
                        .title("GameLearn AI API")
                        .version("0.2.0")
                        .description(
                                "GameLearn AI - Smart Adaptive Learning Adventure. "
                                        + "Phase 1 (database & persistence) and Phase 2 "
                                        + "(authentication) are implemented. Business "
                                        + "endpoints arrive with later phases."))
                .components(new Components()
                        .addSecuritySchemes("bearerAuth",
                                new SecurityScheme()
                                        .type(SecurityScheme.Type.HTTP)
                                        .scheme("bearer")
                                        .bearerFormat("JWT")
                                        .description("Paste the access token returned by "
                                                + "/api/v1/auth/login or /api/v1/auth/register")));
    }
}
