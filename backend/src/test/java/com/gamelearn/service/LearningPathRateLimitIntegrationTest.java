package com.gamelearn.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;

import java.util.UUID;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import com.gamelearn.ai.gemini.GenerationRateLimiter;
import com.gamelearn.ai.gemini.GeminiClient;
import com.gamelearn.dto.AuthResponse;
import com.gamelearn.dto.RegisterRequest;
import com.gamelearn.entity.LearningPath;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.entity.enums.GeneratedBy;
import com.gamelearn.exception.ApiException;
import com.gamelearn.repository.AiInteractionRepository;
import com.gamelearn.repository.LearningPathRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.UserRepository;

/**
 * LP31 (rate limiting, D10) and deterministic-only mode (feature flag off,
 * Learning Path AI Specification section 20/26.5).
 */
@SpringBootTest(properties = {
        "gamelearn.ai.learning-path.enabled=true",
        "gamelearn.ai.gemini.api-key=test-key",
        "gamelearn.ai.gemini.model=gemini-test-model",
        "gamelearn.ai.learning-path.retry.backoff-base=1ms",
        "gamelearn.ai.learning-path.rate-limit.max-requests-per-hour=2"
})
@ActiveProfiles("test")
class LearningPathRateLimitIntegrationTest {

    @Autowired
    private LearningPathGenerationService generationService;

    @Autowired
    private GenerationRateLimiter rateLimiter;

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SubjectRepository subjectRepository;

    @Autowired
    private TopicRepository topicRepository;

    @Autowired
    private LearningPathRepository learningPathRepository;

    @Autowired
    private AiInteractionRepository aiInteractionRepository;

    @MockitoBean
    private GeminiClient geminiClient;

    private User newUser(String label) {
        AuthResponse auth = authService.register(new RegisterRequest(
                label + "-" + UUID.randomUUID() + "@example.test",
                "Str0ng-Passw0rd!", "Learner " + label));
        return userRepository.findById(auth.user().id()).orElseThrow();
    }

    private Subject threeTopicSubject(String label) {
        Subject subject = new Subject();
        subject.setName(label + " " + UUID.randomUUID());
        subject.setDescription(label);
        subject.setIconKey("icon");
        subject.setActive(true);
        subject.setDisplayOrder(1);
        subjectRepository.save(subject);
        String[] names = {"Alpha", "Beta", "Gamma"};
        for (int i = 0; i < 3; i++) {
            Topic topic = new Topic();
            topic.setSubject(subject);
            topic.setName(names[i]);
            topic.setDescription(names[i] + " description");
            topic.setDifficulty(Difficulty.EASY);
            topic.setDisplayOrder(i + 1);
            topic.setActive(true);
            topicRepository.save(topic);
        }
        return subject;
    }

    private String candidateJson(String title) {
        return """
                {"title":"%s","description":"Covering Alpha, Beta and Gamma.","nodes":[
                  {"topicRef":1,"sequence":1},{"topicRef":2,"sequence":2},{"topicRef":3,"sequence":3}]}
                """.formatted(title);
    }

    @Test
    @DisplayName("LP31: Gemini-backed limit enforced; idempotent returns never consume slots")
    void rateLimitBlocksGeminiCallsButNotIdempotentReads() {
        User user = newUser("lp31");
        Subject subject = threeTopicSubject("lp31");
        Mockito.when(geminiClient.generate(any())).thenReturn(candidateJson("Plan"));

        generationService.generate(user.getId(), subject.getId(), false, null, "a"); // slot 1
        generationService.generate(user.getId(), subject.getId(), true, null, "b");  // slot 2

        // Third Gemini-backed attempt exceeds the configured maximum.
        assertThatThrownBy(() -> generationService.generate(user.getId(), subject.getId(),
                true, null, "c"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("limit reached");

        // Idempotent normal request still works and consumes NOTHING.
        var outcome = generationService.generate(user.getId(), subject.getId(), false, null, "d");
        assertThat(outcome.created()).isFalse();
        Mockito.verify(geminiClient, Mockito.times(2)).generate(any());

        // Another learner has a fresh budget.
        User other = newUser("lp31other");
        var theirs = generationService.generate(other.getId(), subject.getId(), false, null, "e");
        assertThat(theirs.created()).isTrue();

        // Exactly the successful attempts were audited (refused one made no call).
        assertThat(aiInteractionRepository.findAll().stream()
                .filter(a -> a.getUser().getId().equals(user.getId())).count()).isEqualTo(2);
        assertThat(rateLimiter.currentUsage(other.getId())).isEqualTo(1);

        var history = learningPathRepository
                .findByUserIdAndSubjectIdOrderByCreatedAtAsc(user.getId(), subject.getId());
        assertThat(history).extracting(p -> p.getStatus().name())
                .containsExactly("ARCHIVED", "ACTIVE");
    }
}
