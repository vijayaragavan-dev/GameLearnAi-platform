package com.gamelearn.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import com.gamelearn.entity.AiInteraction;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.AiInteractionStatus;
import com.gamelearn.entity.enums.AiInteractionType;
import com.gamelearn.repository.AiInteractionRepository;
import com.gamelearn.repository.UserRepository;

@SpringBootTest
@ActiveProfiles("test")
class AiInteractionRepositoryTest {

    @Autowired
    private AiInteractionRepository aiInteractionRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void interactionMetadataRoundTrips() {
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("ai"));

        AiInteraction interaction = PersistenceTestFixtures.aiInteraction(user);
        interaction.setInteractionType(AiInteractionType.QUIZ_GENERATION);
        interaction.setStatus(AiInteractionStatus.FALLBACK);
        interaction.setErrorCode("AI_TIMEOUT");
        AiInteraction saved = aiInteractionRepository.saveAndFlush(interaction);

        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getCreatedAt()).isNotNull();

        AiInteraction reloaded = aiInteractionRepository.findById(saved.getId()).orElseThrow();
        assertThat(reloaded.getInteractionType()).isEqualTo(AiInteractionType.QUIZ_GENERATION);
        assertThat(reloaded.getStatus()).isEqualTo(AiInteractionStatus.FALLBACK);
        assertThat(reloaded.getErrorCode()).isEqualTo("AI_TIMEOUT");
        assertThat(reloaded.getModelName()).isEqualTo("gemini-test");
        assertThat(reloaded.getRequestContextJson()).isEqualTo("{\"question\":\"what?\"}");
        assertThat(reloaded.getResponseJson()).isEqualTo("{\"answer\":\"because\"}");
        assertThat(reloaded.getLatencyMs()).isEqualTo(420);
    }

    @Test
    void enumsAndJsonArePersistedAsExpectedRawValues() {
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("airaw"));
        AiInteraction saved = aiInteractionRepository.saveAndFlush(
                PersistenceTestFixtures.aiInteraction(user));

        var raw = jdbcTemplate.queryForMap(
                "SELECT interaction_type, status, request_context_json FROM ai_interactions WHERE id = ?",
                saved.getId());
        assertThat(raw.get("interaction_type")).isEqualTo("TUTOR");
        assertThat(raw.get("status")).isEqualTo("SUCCESS");

        // H2 hands JSON back as bytes; MySQL returns text. Normalize to text.
        assertThat(asText(raw.get("request_context_json"))).contains("what?");
    }

    private static String asText(Object value) {
        if (value instanceof byte[] bytes) {
            return new String(bytes, java.nio.charset.StandardCharsets.UTF_8);
        }
        return String.valueOf(value);
    }
}
