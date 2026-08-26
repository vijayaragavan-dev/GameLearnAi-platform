package com.gamelearn.auth;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * JWT configuration. The signing secret MUST come from the environment
 * (JWT_SECRET); it is never hard-coded or committed. A missing or weak
 * secret fails application startup (fail safe).
 */
@ConfigurationProperties(prefix = "gamelearn.security.jwt")
public class JwtProperties {

    /**
     * Minimum length (characters) of the Base64/plain secret for HS256.
     * 32 characters = 256 bits of key material.
     */
    public static final int MIN_SECRET_LENGTH = 32;

    private String secret;
    private long expirationMinutes = 60;
    private String issuer = "gamelearn";

    public String getSecret() {
        return secret;
    }

    public void setSecret(String secret) {
        this.secret = secret;
    }

    public long getExpirationMinutes() {
        return expirationMinutes;
    }

    public void setExpirationMinutes(long expirationMinutes) {
        this.expirationMinutes = expirationMinutes;
    }

    public String getIssuer() {
        return issuer;
    }

    public void setIssuer(String issuer) {
        this.issuer = issuer;
    }
}
