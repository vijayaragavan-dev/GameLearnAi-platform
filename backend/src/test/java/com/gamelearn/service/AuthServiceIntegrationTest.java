package com.gamelearn.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;

import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.auth.AuthenticatedUser;
import com.gamelearn.dto.AuthResponse;
import com.gamelearn.dto.RegisterRequest;
import com.gamelearn.entity.LearnerProfile;
import com.gamelearn.entity.enums.UserStatus;
import com.gamelearn.exception.ApiException;
import com.gamelearn.repository.LearnerProfileRepository;
import com.gamelearn.repository.UserRepository;

@SpringBootTest
@ActiveProfiles("test")
class AuthServiceIntegrationTest {

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @MockitoSpyBean
    private LearnerProfileRepository learnerProfileRepository;

    private RegisterRequest request(String label) {
        return new RegisterRequest(
                label + "-" + UUID.randomUUID() + "@example.test",
                "Str0ng-Passw0rd!",
                "Learner " + label);
    }

    @Test
    void registrationCreatesActiveUserAndProfileAtomically() {
        RegisterRequest request = request("atomic");
        AuthResponse response = authService.register(request);

        assertThat(response.token()).isNotBlank();
        assertThat(response.tokenType()).isEqualTo("Bearer");
        assertThat(response.user().email()).isEqualTo(request.email());
        assertThat(response.user().displayName()).isEqualTo("Learner atomic");

        var raw = jdbcTemplate.queryForMap(
                "SELECT u.status, u.password_hash, p.current_level, p.total_xp, p.overall_mastery "
                        + "FROM users u JOIN learner_profiles p ON p.user_id = u.id WHERE u.email = ?",
                request.email());
        assertThat(raw.get("status")).isEqualTo("ACTIVE");
        assertThat((String) raw.get("password_hash")).startsWith("$2");
        // Plaintext never persisted.
        assertThat((String) raw.get("password_hash")).doesNotContain("Str0ng-Passw0rd!");
        assertThat(((Number) raw.get("current_level")).intValue()).isEqualTo(1);
        assertThat(((Number) raw.get("total_xp")).intValue()).isZero();
    }

    @Test
    void duplicateRegistrationIsRejectedWithConflict() {
        RegisterRequest first = request("dup");
        authService.register(first);

        RegisterRequest duplicate =
                new RegisterRequest(first.email(), "Another-Passw0rd!", "Other Name");

        assertThatThrownBy(() -> authService.register(duplicate))
                .isInstanceOf(ApiException.class)
                .satisfies(error -> assertThat(((ApiException) error).getHttpStatus()).isEqualTo(409));
    }

    @Test
    void failedProfileCreationRollsBackEntireRegistration() {
        RegisterRequest request = request("rollback");

        doThrow(new IllegalStateException("simulated profile failure"))
                .when(learnerProfileRepository).save(any(LearnerProfile.class));

        assertThatThrownBy(() -> authService.register(request))
                .isInstanceOf(IllegalStateException.class);

        Integer users = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM users WHERE email = ?", Integer.class, request.email());
        Integer profiles = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM learner_profiles p JOIN users u ON u.id = p.user_id "
                        + "WHERE u.email = ?",
                Integer.class, request.email());
        assertThat(users).as("user must be rolled back").isZero();
        assertThat(profiles).as("no partial profile may remain").isZero();

        Integer tokens = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM users WHERE email = ? AND password_hash LIKE 'Str0ng%'",
                Integer.class, request.email());
        assertThat(tokens).isZero();
    }

    @Test
    void loginReturnsTokenForCorrectCredentials() {
        RegisterRequest request = request("login");

        authService.register(request);

        AuthResponse response = authService.login(
                new com.gamelearn.dto.LoginRequest(request.email(), "Str0ng-Passw0rd!"));
        assertThat(response.token()).isNotBlank();
        assertThat(response.user().email()).isEqualTo(request.email());
    }

    @Test
    void unknownEmailAndWrongPasswordProduceIdenticalErrors() {
        RegisterRequest request = request("enum");
        authService.register(request);

        ApiException unknownEmail = catchLogin("ghost-" + UUID.randomUUID() + "@example.test", "whatever-1");
        ApiException wrongPassword = catchLogin(request.email(), "definitely-wrong");

        assertThat(unknownEmail.getMessage()).isEqualTo(wrongPassword.getMessage());
        assertThat(unknownEmail.getHttpStatus()).isEqualTo(401);
        assertThat(unknownEmail.getErrorCode()).isEqualTo(wrongPassword.getErrorCode());
    }

    private ApiException catchLogin(String email, String password) {
        return org.junit.jupiter.api.Assertions.assertThrows(ApiException.class,
                () -> authService.login(new com.gamelearn.dto.LoginRequest(email, password)));
    }

    @Test
    void suspendedAccountCannotLogIn() {
        RegisterRequest request = request("susp");
        AuthResponse response = authService.register(request);

        var user = userRepository.findById(response.user().id()).orElseThrow();
        user.setStatus(UserStatus.SUSPENDED);
        userRepository.saveAndFlush(user);

        assertThatThrownBy(() -> authService.login(
                new com.gamelearn.dto.LoginRequest(request.email(), "Str0ng-Passw0rd!")))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("Invalid email or password");
    }

    @Test
    void validateReturnsIdentityFromAuthenticatedPrincipalOnly() {
        RegisterRequest request = request("valid");
        AuthResponse registered = authService.register(request);

        AuthenticatedUser principal = new AuthenticatedUser(
                registered.user().id(), registered.user().email(), registered.user().displayName());
        AuthResponse validated = authService.validate(principal);

        assertThat(validated.user().id()).isEqualTo(registered.user().id());
        assertThat(validated.token()).isNull();

        // A different principal can never see another user's identity.
        AuthenticatedUser stranger = new AuthenticatedUser(
                UUID.randomUUID(), "stranger@example.test", "Stranger");
        assertThatThrownBy(() -> authService.validate(stranger))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("Invalid email or password");
    }
}
