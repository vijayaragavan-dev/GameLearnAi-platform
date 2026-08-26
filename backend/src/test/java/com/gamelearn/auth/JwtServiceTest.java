package com.gamelearn.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.UUID;

import org.junit.jupiter.api.Test;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;

class JwtServiceTest {

    private static final String SECRET = "unit-test-signing-secret-0123456789abcdef-SecretForTestsOnly";
    private static final String ISSUER = "gamelearn-test";
    private static final UUID USER_ID = UUID.randomUUID();

    private JwtService service(long expirationMinutes) {
        JwtProperties properties = new JwtProperties();
        properties.setSecret(SECRET);
        properties.setExpirationMinutes(expirationMinutes);
        properties.setIssuer(ISSUER);
        return new JwtService(properties);
    }

    @Test
    void generatedTokenCarriesIdentityClaimsAndRoundTrips() {
        JwtService jwtService = service(60);

        String token = jwtService.generateToken(USER_ID, "learner@example.test", "Learner One");
        Claims claims = jwtService.parseAndValidate(token);

        assertThat(claims.getSubject()).isEqualTo(USER_ID.toString());
        assertThat(claims.getIssuer()).isEqualTo(ISSUER);
        assertThat(claims.get("email", String.class)).isEqualTo("learner@example.test");
        assertThat(claims.get("displayName", String.class)).isEqualTo("Learner One");
        assertThat(claims.getExpiration().getTime())
                .isGreaterThan(System.currentTimeMillis());
        // No sensitive material in the payload.
        assertThat(token).doesNotContain("password");
    }

    @Test
    void expiredTokenIsRejected() {
        JwtService expiredService = service(-5);
        String token = expiredService.generateToken(USER_ID, "learner@example.test", "Learner");

        assertThatThrownBy(() -> expiredService.parseAndValidate(token))
                .isInstanceOf(ExpiredJwtException.class);
    }

    @Test
    void tamperedTokenFailsSignatureVerification() {
        JwtService jwtService = service(60);
        String token = jwtService.generateToken(USER_ID, "learner@example.test", "Learner");

        char[] chars = token.toCharArray();
        int signatureStart = token.lastIndexOf('.') + 10;
        chars[signatureStart] = chars[signatureStart] == 'A' ? 'B' : 'A';
        String tampered = new String(chars);

        assertThatThrownBy(() -> jwtService.parseAndValidate(tampered))
                .isInstanceOf(JwtException.class);
    }

    @Test
    void wrongIssuerIsRejected() {
        JwtProperties properties = new JwtProperties();
        properties.setSecret(SECRET);
        properties.setExpirationMinutes(60);
        properties.setIssuer("other-issuer");
        JwtService foreign = new JwtService(properties);

        String token = foreign.generateToken(USER_ID, "learner@example.test", "Learner");

        assertThatThrownBy(() -> service(60).parseAndValidate(token))
                .isInstanceOf(JwtException.class);
    }

    @Test
    void malformedTokenIsRejected() {
        assertThatThrownBy(() -> service(60).parseAndValidate("not-a-jwt"))
                .isInstanceOf(JwtException.class);
    }

    @Test
    void missingSecretFailsFastAtConstruction() {
        JwtProperties properties = new JwtProperties();

        assertThatThrownBy(() -> new JwtService(properties))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("JWT_SECRET");
    }

    @Test
    void shortSecretFailsFastAtConstruction() {
        JwtProperties properties = new JwtProperties();
        properties.setSecret("too-short");

        assertThatThrownBy(() -> new JwtService(properties))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("32");
    }
}
