package com.gamelearn.auth;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
class PasswordHashingTest {

    @Autowired
    private PasswordEncoder passwordEncoder;

    private static final String RAW_PASSWORD = "CorrectHorse-7-Battery!";

    @Test
    void encodedPasswordIsNotReversibleAndNeverEqualsRaw() {
        String hash = passwordEncoder.encode(RAW_PASSWORD);

        assertThat(hash).isNotEqualTo(RAW_PASSWORD);
        assertThat(hash).startsWith("$2"); // BCrypt modular crypt format
        assertThat(hash).doesNotContain(RAW_PASSWORD);
        assertThat(passwordEncoder.matches(RAW_PASSWORD, hash)).isTrue();
        assertThat(passwordEncoder.matches("wrong-password", hash)).isFalse();
    }

    @Test
    void eachEncodingUsesAFreshSalt() {
        String first = passwordEncoder.encode(RAW_PASSWORD);
        String second = passwordEncoder.encode(RAW_PASSWORD);

        assertThat(first).isNotEqualTo(second);
        assertThat(passwordEncoder.matches(RAW_PASSWORD, first)).isTrue();
        assertThat(passwordEncoder.matches(RAW_PASSWORD, second)).isTrue();
    }

    @Test
    void caseAndWhitespaceVariationsDoNotMatch() {
        String hash = passwordEncoder.encode(RAW_PASSWORD);

        assertThat(passwordEncoder.matches(RAW_PASSWORD + " ", hash)).isFalse();
        assertThat(passwordEncoder.matches(RAW_PASSWORD.toLowerCase(), hash)).isFalse();
    }
}
