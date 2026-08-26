package com.gamelearn.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.gamelearn.auth.AuthenticatedUser;
import com.gamelearn.dto.AuthResponse;
import com.gamelearn.dto.LoginRequest;
import com.gamelearn.dto.RegisterRequest;
import com.gamelearn.service.AuthService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * Authentication endpoints (Backend + AI Specification section 11):
 * AUTH-002 register, AUTH-001 login (public);
 * AUTH-000 validate, AUTH-003 logout.
 */
@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Authentication", description = "Registration, login and token validation")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @Operation(summary = "Register a new learner account",
            description = "Creates the user account and learner profile atomically. "
                    + "Returns an access token for immediate use.")
    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(authService.register(request));
    }

    @Operation(summary = "Log in with email and password",
            description = "Returns a bearer access token. Failures always return a generic 401.")
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @Operation(summary = "Validate a bearer token",
            description = "Verifies the Authorization: Bearer token and returns the "
                    + "authenticated identity. Invalid, expired or missing tokens return 401.")
    @GetMapping("/validate")
    @SecurityRequirement(name = "bearerAuth")
    public ResponseEntity<AuthResponse> validate(@AuthenticationPrincipal AuthenticatedUser principal) {
        return ResponseEntity.ok(authService.validate(principal));
    }

    @Operation(summary = "Log out",
            description = "Stateless JWT logout acknowledgement. Clients discard the token; "
                    + "the server holds no session to revoke.")
    @PostMapping("/logout")
    @SecurityRequirement(name = "bearerAuth")
    public ResponseEntity<Void> logout() {
        authService.logout();
        return ResponseEntity.noContent().build();
    }
}
