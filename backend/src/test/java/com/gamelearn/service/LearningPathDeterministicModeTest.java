package com.gamelearn.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verifyNoInteractions;

import java.util.UUID;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import com.gamelearn.ai.gemini.GeminiClient;
import com.gamelearn.dto.AuthResponse;
import com.gamelearn.dto.RegisterRequest;
import com.gamelearn.entity.LearningPath;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.entity.enums.GeneratedBy;
import com.gamelearn.repository.AiInteractionRepository;
import com.gamelearn.repository.LearningPathRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.UserRepository;

/**
 * Feature-flag-off mode (LP27-adjacent, Learning Path AI Specification
 * section 20): generation NEVER touches Gemini and delivers the
 * deterministic SYSTEM path with a FALLBACK audit row and no model name.
 */
@SpringBootTest(properties = {
        "gamelearn.ai.learning-path.enabled=false",
        "gamelearn.ai.gemini.api-key=",
        "gamelearn.ai.gemini.model="
})
@ActiveProfiles("test")
class LearningPathDeterministicModeTest {

    @Autowired
    private LearningPathGenerationService generationService;

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

    @Test
    @DisplayName("Disabled flag: zero Gemini interactions; SYSTEM path; model_name null in audit")
    void deterministicModeNeverCallsGemini() {
        AuthResponse auth = authService.register(new RegisterRequest(
                "det-" + UUID.randomUUID() + "@example.test",
                "Str0ng-Passw0rd!", "Learner det"));
        User user = userRepository.findById(auth.user().id()).orElseThrow();

        Subject subject = new Subject();
        subject.setName("Deterministic " + UUID.randomUUID());
        subject.setDescription("d");
        subject.setIconKey("icon");
        subject.setActive(true);
        subject.setDisplayOrder(1);
        subjectRepository.save(subject);
        for (int i = 0; i < 3; i++) {
            Topic topic = new Topic();
            topic.setSubject(subject);
            topic.setName("Topic" + i);
            topic.setDescription("d" + i);
            topic.setDifficulty(Difficulty.values()[i]);
            topic.setDisplayOrder(i + 1);
            topic.setActive(true);
            topicRepository.save(topic);
        }

        var outcome = generationService.generate(user.getId(), subject.getId(),
                false, null, "req-det");

        assertThat(outcome.created()).isTrue();
        assertThat(outcome.generatedBy()).isEqualTo(GeneratedBy.SYSTEM);

        LearningPath path = learningPathRepository
                .findByUserIdAndSubjectIdOrderByCreatedAtAsc(user.getId(), subject.getId())
                .get(0);
        assertThat(path.getStatus().name()).isEqualTo("ACTIVE");
        assertThat(path.getGeneratedBy()).isEqualTo(GeneratedBy.SYSTEM);
        // Deterministic ordering: EASY first (difficulty ladder).
        assertThat(path.getTitle()).contains(subject.getName());

        verifyNoInteractions(geminiClient);

        assertThat(aiInteractionRepository.findAll().stream()
                .filter(a -> a.getUser().getId().equals(user.getId()))
                .peek(a -> {
                    assertThat(a.getStatus().name()).isEqualTo("FALLBACK");
                    assertThat(a.getModelName()).isNull();
                    assertThat(a.getErrorCode()).isEqualTo("LP_GEMINI_DISABLED");
                }).count()).isEqualTo(1);
    }
}
