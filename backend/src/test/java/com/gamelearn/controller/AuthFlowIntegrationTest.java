package com.gamelearn.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AuthFlowIntegrationTest {

    private static final String REGISTER_URL = "/api/v1/auth/register";
    private static final String LOGIN_URL = "/api/v1/auth/login";
    private static final String VALIDATE_URL = "/api/v1/auth/validate";
    private static final String LOGOUT_URL = "/api/v1/auth/logout";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private String registerBody(String label) {
        return """
                {
                  "email": "%s",
                  "password": "Str0ng-Passw0rd!",
                  "displayName": "Learner %s"
                }
                """.formatted(label + "-" + UUID.randomUUID() + "@example.test", label);
    }

    /**
     * Registers a fresh learner and returns [token, userId].
     */
    private String[] registerAndExtract(String label) throws Exception {
        MvcResult result = mockMvc.perform(post(REGISTER_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registerBody(label)))
                .andExpect(status().isCreated())
                .andReturn();
        String body = result.getResponse().getContentAsString();
        String token = com.jayway.jsonpath.JsonPath.read(body, "$.token");
        String userId = com.jayway.jsonpath.JsonPath.read(body, "$.user.id");
        return new String[] { token, userId };
    }

    @Test
    void registrationReturns201WithTokenAndSafeUserView() throws Exception {
        String email = "flow-" + UUID.randomUUID() + "@example.test";
        String body = """
                { "email": "%s", "password": "Str0ng-Passw0rd!", "displayName": "Flow Learner" }
                """.formatted(email);

        mockMvc.perform(post(REGISTER_URL).contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.expiresInSeconds").isNumber())
                .andExpect(jsonPath("$.user.email").value(email))
                .andExpect(jsonPath("$.user.displayName").value("Flow Learner"))
                // No password material anywhere in the payload.
                .andExpect(result -> assertThat(result.getResponse().getContentAsString())
                        .doesNotContain("password")
                        .doesNotContain("$2"));
    }

    @Test
    void invalidRegistrationPayloadsReturn400WithFieldErrors() throws Exception {
        String badEmail = """
                { "email": "not-an-email", "password": "Str0ng-Passw0rd!", "displayName": "A B" }
                """;
        mockMvc.perform(post(REGISTER_URL).contentType(MediaType.APPLICATION_JSON).content(badEmail))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.fieldErrors.email").exists());

        String shortPassword = """
                { "email": "short-%s@example.test", "password": "short", "displayName": "A B" }
                """.formatted(UUID.randomUUID());
        mockMvc.perform(post(REGISTER_URL)
                        .contentType(MediaType.APPLICATION_JSON).content(shortPassword))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.password").exists());

        String blankName = """
                { "email": "blank-%s@example.test", "password": "Str0ng-Passw0rd!", "displayName": "" }
                """.formatted(UUID.randomUUID());
        mockMvc.perform(post(REGISTER_URL)
                        .contentType(MediaType.APPLICATION_JSON).content(blankName))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.displayName").exists());
    }

    @Test
    void duplicateRegistrationReturns409() throws Exception {
        String email = "dupflow-" + UUID.randomUUID() + "@example.test";
        String body = """
                { "email": "%s", "password": "Str0ng-Passw0rd!", "displayName": "Dup Learner" }
                """.formatted(email);

        mockMvc.perform(post(REGISTER_URL).contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isCreated());

        mockMvc.perform(post(REGISTER_URL).contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.errorCode").value("DATA_CONFLICT"));
    }

    @Test
    void malformedJsonIsRejectedSafely() throws Exception {
        mockMvc.perform(post(REGISTER_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{not json at all"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("MALFORMED_REQUEST"));
    }

    @Test
    void loginSuccessReturnsUsableToken() throws Exception {
        String email = "login-" + UUID.randomUUID() + "@example.test";
        String register = """
                { "email": "%s", "password": "Str0ng-Passw0rd!", "displayName": "Login Learner" }
                """.formatted(email);
        mockMvc.perform(post(REGISTER_URL).contentType(MediaType.APPLICATION_JSON).content(register))
                .andExpect(status().isCreated());

        String loginBody = """
                { "email": "%s", "password": "Str0ng-Passw0rd!" }
                """.formatted(email);
        mockMvc.perform(post(LOGIN_URL).contentType(MediaType.APPLICATION_JSON).content(loginBody))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.user.email").value(email));
    }

    @Test
    void loginFailuresAreUniformAndDoNotEnumerate() throws Exception {
        String unknownEmail = "ghost-" + UUID.randomUUID() + "@example.test";

        MvcResult unknown = mockMvc.perform(post(LOGIN_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "email": "%s", "password": "whatever-1" }
                                """.formatted(unknownEmail)))
                .andExpect(status().isUnauthorized())
                .andReturn();
        MvcResult wrongPassword = mockMvc.perform(post(LOGIN_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "email": "%s", "password": "totally-wrong-1" }
                                """.formatted("login-" + UUID.randomUUID() + "@example.test")))
                .andExpect(status().isUnauthorized())
                .andReturn();

        String first = unknown.getResponse().getContentAsString();
        String second = wrongPassword.getResponse().getContentAsString();
        assertThat(first).contains("Invalid email or password");
        // Identical generic message and code for both cases.
        String messageFirst = com.jayway.jsonpath.JsonPath.read(first, "$.message");
        String codeSecond = com.jayway.jsonpath.JsonPath.read(second, "$.errorCode");
        assertThat(second).contains(messageFirst);
        assertThat(codeSecond).isEqualTo("UNAUTHORIZED");
    }

    @Test
    void validateEndpointConfirmsIdentityForValidToken() throws Exception {
        String[] registered = registerAndExtract("valid");

        mockMvc.perform(get(VALIDATE_URL).header("Authorization", "Bearer " + registered[0]))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.id").value(registered[1]))
                .andExpect(jsonPath("$.token").doesNotExist());
    }

    @Test
    void validateRejectsMissingGarbledAndTamperedTokens() throws Exception {
        // Missing token.
        mockMvc.perform(get(VALIDATE_URL))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.errorCode").value("UNAUTHORIZED"));

        // Malformed bearer value.
        mockMvc.perform(get(VALIDATE_URL).header("Authorization", "Bearer garbage.token.value"))
                .andExpect(status().isUnauthorized());

        // Tampered signature: register two users, swap signature parts.
        String[] a = registerAndExtract("tamperA");
        String[] b = registerAndExtract("tamperB");
        String sigA = a[0].substring(a[0].lastIndexOf('.') + 1);
        String headAndPayloadB = b[0].substring(0, b[0].lastIndexOf('.'));
        mockMvc.perform(get(VALIDATE_URL)
                        .header("Authorization", "Bearer " + headAndPayloadB + "." + sigA))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void suspendedAccountTokenIsRejectedOnProtectedEndpoints() throws Exception {
        String[] registered = registerAndExtract("suspend");

        jdbcTemplate.update("UPDATE users SET status = 'SUSPENDED' WHERE id = ?",
                UUID.fromString(registered[1]));

        mockMvc.perform(get(VALIDATE_URL).header("Authorization", "Bearer " + registered[0]))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void protectedRoutesRequireAuthenticationWhilePublicStayOpen() throws Exception {
        // Protected without credentials -> 401 safe envelope.
        mockMvc.perform(post(LOGOUT_URL))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.status").value(401));

        // A future-phase route is also locked down by default.
        mockMvc.perform(get("/api/v1/dashboard"))
                .andExpect(status().isUnauthorized());

        // Public endpoints remain reachable anonymously.
        mockMvc.perform(get("/actuator/health")).andExpect(status().isOk());
        mockMvc.perform(get("/v3/api-docs")).andExpect(status().isOk());
    }

    @Test
    void logoutAcknowledgesForAuthenticatedCallerOnly() throws Exception {
        String[] registered = registerAndExtract("logout");

        mockMvc.perform(post(LOGOUT_URL).header("Authorization", "Bearer " + registered[0]))
                .andExpect(status().isNoContent());
    }

    @Test
    void identityComesFromTokenNotFromClientSuppliedFields() throws Exception {
        String[] userA = registerAndExtract("identityA");
        String[] userB = registerAndExtract("identityB");

        // A validating always sees A's identity; there is no parameter that
        // can substitute another user's id.
        for (int i = 0; i < 3; i++) {
            mockMvc.perform(get(VALIDATE_URL)
                            .header("Authorization", "Bearer " + userA[0])
                            .param("userId", userB[1])
                            .param("email", "attacker@example.test"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.user.id").value(userA[1]));
        }
    }

    @Test
    void passwordHashIsNeverStoredAsPlaintext() throws Exception {
        String email = "hashcheck-" + UUID.randomUUID() + "@example.test";
        String body = """
                { "email": "%s", "password": "PlaintextProbe-9!", "displayName": "Hash Probe" }
                """.formatted(email);
        mockMvc.perform(post(REGISTER_URL).contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isCreated());

        String hash = jdbcTemplate.queryForObject(
                "SELECT password_hash FROM users WHERE email = ?", String.class, email);
        assertThat(hash).startsWith("$2").hasSize(60);
        assertThat(hash).doesNotContain("PlaintextProbe");
    }
}
