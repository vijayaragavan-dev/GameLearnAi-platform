package com.gamelearn.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;

import java.util.List;
import java.util.UUID;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;

import com.gamelearn.ai.gemini.GeminiClient;
import com.gamelearn.dto.AuthResponse;
import com.gamelearn.dto.RegisterRequest;
import com.gamelearn.entity.AiInteraction;
import com.gamelearn.entity.LearningPath;
import com.gamelearn.entity.LearningPathNode;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.entity.enums.GeneratedBy;
import com.gamelearn.entity.enums.LearningPathStatus;
import com.gamelearn.exception.ApiException;
import com.gamelearn.repository.AiInteractionRepository;
import com.gamelearn.repository.LearningPathNodeRepository;
import com.gamelearn.repository.LearningPathRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.UserRepository;

/**
 * Regeneration safety (Learning Path AI Specification sections 11 and 29;
 * central API Contract sections 5.1/5.5): the replacement is generated and
 * fully validated BEFORE anything is archived; persistence failures roll
 * back to a fully intact old ACTIVE path.
 */
@SpringBootTest(properties = {
        "gamelearn.ai.learning-path.enabled=true",
        "gamelearn.ai.gemini.api-key=test-key",
        "gamelearn.ai.gemini.model=gemini-test-model",
        "gamelearn.ai.learning-path.retry.backoff-base=1ms",
        "gamelearn.ai.learning-path.deadline=5s"
})
@ActiveProfiles("test")
class LearningPathRegenerationIntegrationTest {

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
    private LearningPathNodeRepository learningPathNodeRepository;

    @Autowired
    private AiInteractionRepository aiInteractionRepository;

    @MockitoBean
    private GeminiClient geminiClient;

    @MockitoSpyBean
    private LearningPathNodeRepository learningPathNodeSpyRepository;

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------
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
        Difficulty[] levels = {Difficulty.EASY, Difficulty.MEDIUM, Difficulty.HARD};
        for (int i = 0; i < 3; i++) {
            Topic topic = new Topic();
            topic.setSubject(subject);
            topic.setName(names[i]);
            topic.setDescription(names[i] + " description");
            topic.setDifficulty(levels[i]);
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

    // ------------------------------------------------------------------
    // LP25 / LP30 - successful regeneration archives old AFTER validation
    // ------------------------------------------------------------------
    @Test
    @DisplayName("LP25/LP30: regeneration validates replacement first, then swaps atomically")
    void regenerationSwapsAtomically() {
        User user = newUser("reg25");
        Subject subject = threeTopicSubject("reg25");
        Mockito.when(geminiClient.generate(any()))
                .thenReturn(candidateJson("First Path"), candidateJson("Second Path"));

        generationService.generate(user.getId(), subject.getId(), false, null, "r1");
        var outcome = generationService.generate(user.getId(), subject.getId(), true, null, "r2");

        assertThat(outcome.created()).isTrue();
        List<LearningPath> paths = learningPathRepository
                .findByUserIdAndSubjectIdOrderByCreatedAtAsc(user.getId(), subject.getId());
        assertThat(paths).hasSize(2);

        LearningPath oldPath = paths.get(0);
        LearningPath newPath = paths.get(1);
        assertThat(oldPath.getStatus()).isEqualTo(LearningPathStatus.ARCHIVED);
        assertThat(oldPath.getTitle()).isEqualTo("First Path");
        assertThat(newPath.getStatus()).isEqualTo(LearningPathStatus.ACTIVE);
        assertThat(newPath.getTitle()).isEqualTo("Second Path");

        // Both generations audited; nodes belong only to their own path.
        List<AiInteraction> audits = aiInteractionRepository.findAll().stream()
                .filter(a -> a.getUser().getId().equals(user.getId())).toList();
        assertThat(audits).hasSize(2);
        assertThat(learningPathNodeRepository
                .findByLearningPathIdOrderBySequenceNumberAsc(oldPath.getId())).hasSize(3);
        assertThat(learningPathNodeRepository
                .findByLearningPathIdOrderBySequenceNumberAsc(newPath.getId())).hasSize(3);
    }

    // ------------------------------------------------------------------
    // LP27 - Gemini failure during regeneration: fallback replaces safely
    // ------------------------------------------------------------------
    @Test
    @DisplayName("LP27: Gemini outage during regeneration delivers SYSTEM replacement atomically")
    void regenerationWithGeminiDownDeliversSystemReplacement() {
        User user = newUser("reg27");
        Subject subject = threeTopicSubject("reg27");
        Mockito.when(geminiClient.generate(any())).thenReturn(candidateJson("AI Original"));
        generationService.generate(user.getId(), subject.getId(), false, null, "r1");

        Mockito.when(geminiClient.generate(any())).thenThrow(
                new com.gamelearn.ai.gemini.GeminiTransientException(
                        "LP_GEMINI_UNAVAILABLE", "Gemini down"));
        var outcome = generationService.generate(user.getId(), subject.getId(), true, null, "r2");

        // The approved fallback keeps the learner covered - delivered as SYSTEM.
        assertThat(outcome.generatedBy()).isEqualTo(GeneratedBy.SYSTEM);
        List<LearningPath> paths = learningPathRepository
                .findByUserIdAndSubjectIdOrderByCreatedAtAsc(user.getId(), subject.getId());
        assertThat(paths).hasSize(2);
        assertThat(paths.get(0).getStatus()).isEqualTo(LearningPathStatus.ARCHIVED);
        assertThat(paths.get(1).getStatus()).isEqualTo(LearningPathStatus.ACTIVE);
        assertThat(paths.get(1).getGeneratedBy()).isEqualTo(GeneratedBy.SYSTEM);
        // The AI original was NEVER destroyed by the failed attempt.
        assertThat(paths.get(0).getTitle()).isEqualTo("AI Original");
    }

    // ------------------------------------------------------------------
    // LP28 - persistence failure rolls back to fully intact OLD ACTIVE path
    // ------------------------------------------------------------------
    @Test
    @DisplayName("LP28/LP17/LP18: persistence failure rolls back; old path stays ACTIVE; audit survives")
    void persistenceFailureRollsBackCleanly() {
        User user = newUser("reg28");
        Subject subject = threeTopicSubject("reg28");
        Mockito.when(geminiClient.generate(any())).thenReturn(candidateJson("Original"));
        generationService.generate(user.getId(), subject.getId(), false, null, "r1");
        int nodeRowsBefore = learningPathNodeRepository.findAll().size();

        Mockito.when(geminiClient.generate(any())).thenReturn(candidateJson("Replacement"));
        Mockito.doThrow(new IllegalStateException("db exploded"))
                .when(learningPathNodeSpyRepository).saveAll(any());

        assertThatThrownBy(() -> generationService.generate(user.getId(), subject.getId(),
                true, null, "r2"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("could not be saved");

        // Rollback left EXACTLY the original state behind.
        List<LearningPath> paths = learningPathRepository
                .findByUserIdAndSubjectIdOrderByCreatedAtAsc(user.getId(), subject.getId());
        assertThat(paths).hasSize(1);
        assertThat(paths.get(0).getStatus()).isEqualTo(LearningPathStatus.ACTIVE);
        assertThat(paths.get(0).getTitle()).isEqualTo("Original");
        assertThat(nodeRowsBefore).isEqualTo(learningPathNodeRepository.findAll().size());

        // Independent FAILED audit row survived the rollback (spec section 30.2).
        List<AiInteraction> audits = aiInteractionRepository.findAll().stream()
                .filter(a -> a.getUser().getId().equals(user.getId())).toList();
        assertThat(audits).anySatisfy(a -> {
            assertThat(a.getStatus().name()).isEqualTo("FAILED");
            assertThat(a.getErrorCode()).isEqualTo("LP_PERSISTENCE_FAILED");
        });
    }

}
