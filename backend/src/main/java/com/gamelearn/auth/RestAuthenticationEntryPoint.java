package com.gamelearn.auth;

import java.io.IOException;

import org.springframework.http.MediaType;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

import com.gamelearn.exception.ErrorResponse;
import com.gamelearn.logging.RequestCorrelationFilter;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * Answers unauthenticated access to protected endpoints with the standard
 * safe {@link ErrorResponse} JSON. Runs before Spring MVC, therefore outside
 * the reach of the global exception handler.
 */
@Component
public class RestAuthenticationEntryPoint implements AuthenticationEntryPoint {

    private final ObjectMapper objectMapper;

    public RestAuthenticationEntryPoint(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response,
                         AuthenticationException authException) throws IOException {
        ErrorResponse body = new ErrorResponse(java.time.Instant.now(), 401, "UNAUTHORIZED",
                "Authentication is required to access this resource",
                request.getRequestURI(),
                RequestCorrelationFilter.currentRequestId(), null);
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        objectMapper.writeValue(response.getOutputStream(), body);
    }
}
