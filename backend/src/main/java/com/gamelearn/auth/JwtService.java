package com.gamelearn.auth;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;

import javax.crypto.SecretKey;

import org.springframework.stereotype.Service;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;

/**
 * Issues and verifies JWT access tokens (HS256).
 *
 * <p>Tokens carry only non-sensitive identity claims: subject (user UUID),
 * email and display name. Never tokens: passwords, hashes, API keys or any
 * secret material. Signature, expiry and issuer are always verified.</p>
 */
@Service
public class JwtService {

    private final JwtProperties properties;
    private final SecretKey signingKey;

    public JwtService(JwtProperties properties) {
        this.properties = properties;
        // Fail fast at construction when the secret is missing or weak.
        String secret = properties.getSecret();
        if (secret == null || secret.length() < JwtProperties.MIN_SECRET_LENGTH) {
            throw new IllegalStateException(
                    "JWT secret is missing or too short; provide at least "
                            + JwtProperties.MIN_SECRET_LENGTH + " characters via the JWT_SECRET environment variable");
        }
        this.signingKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    /**
     * Creates a signed access token for an authenticated user.
     */
    public String generateToken(UUID userId, String email, String displayName) {
        Instant now = Instant.now();
        Instant expiry = now.plusSeconds(properties.getExpirationMinutes() * 60);
        return Jwts.builder()
                .subject(userId.toString())
                .issuer(properties.getIssuer())
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiry))
                .claim("email", email)
                .claim("displayName", displayName)
                .signWith(signingKey)
                .compact();
    }

    /**
     * Verifies signature, expiry and issuer, then returns the parsed claims.
     * Any failure results in {@link JwtException} (never a partial result).
     */
    public Claims parseAndValidate(String token) {
        return Jwts.parser()
                .verifyWith(signingKey)
                .requireIssuer(properties.getIssuer())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public long getExpirationSeconds() {
        return properties.getExpirationMinutes() * 60;
    }
}
