package com.gamelearn.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import com.gamelearn.ai.gemini.GeminiClient;
import com.gamelearn.ai.gemini.GeminiPermanentException;
import com.gamelearn.ai.gemini.GeminiPrompt;
import com.gamelearn.ai.gemini.GeminiTransientException;
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
import com.gamelearn.entity.enums.PathNodeStatus;
import com.gamelearn.exception.ApiException;
import com.gamelearn.repository.AiInteractionRepository;
import com.gamelearn.repository.LearningPathNodeRepository;
import com.gamelearn.repository.LearningPathRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.UserRepository;

/**
 * Service-level AI-LP acceptance runs against H2 with a stubbed GeminiClient
 * (Learning Path AI Specification sections 41-43). Covers LP01-LP26 and
 * LP29/LP31-adjacent behaviour at service level.
 */
@SpringBootTest(properties = {
        "gamelearn.ai.learning-path.enabled=true",
        "gamelearn.ai.gemini.api-key=test-key",
        "gamelearn.ai.gemini.model=gemini-test-model",
        "gamelearn.ai.learning-path.retry.backoff-base=1ms",
        "gamelearn.ai.learning-path.deadline=5s"
})
@ActiveProfiles("test")
class LearningPathGenerationIntegrationTest {

    @Autowired
    private LearningPathGenerationService generationService;

    @Autowired
    private GeneratedPathResponseMapper responseMapper;

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

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------
    private User newUser(String label) {
        AuthResponse auth = authService.register(new RegisterRequest(
                label + "-" + UUID.randomUUID() + "@example.test",
                "Str0ng-Passw0rd!", "Learner " + label));
        return userRepository.findById(auth.user().id()).orElseThrow();
    }

    private Subject newSubject(String label) {
        Subject subject = new Subject();
        subject.setName(label + " " + UUID.randomUUID());
        subject.setDescription(label);
        subject.setIconKey("icon");
        subject.setActive(true);
        subject.setDisplayOrder(1);
        return subjectRepository.save(subject);
    }

    private Topic newTopic(Subject subject, String name, Difficulty difficulty, int order) {
        Topic topic = new Topic();
        topic.setSubject(subject);
        topic.setName(name);
        topic.setDescription(name + " description");
        topic.setDifficulty(difficulty);
        topic.setDisplayOrder(order);
        topic.setActive(true);
        return topicRepository.save(topic);
    }

    /**
     * Valid 3-node candidate over refs 1..3 (stable catalog order). The
     * description names the topics so the approved C-4 relevance floor passes.
     */
    private String validCandidateJson(String title) {
        return """
                {"title":"%s","description":"Covering Alpha, Beta and Gamma.","nodes":[
                  {"topicRef":1,"sequence":1,"requiredMastery":10,"objective":"Start Alpha here","rationale":"Foundation"},
                  {"topicRef":2,"sequence":2,"requiredMastery":40,"objective":"Continue with Beta","rationale":"Practice"},
                  {"topicRef":3,"sequence":3,"requiredMastery":70,"objective":"Finish via Gamma","rationale":"Advanced"}]}
                """.formatted(title);
    }

    // ------------------------------------------------------------------
    // LP01 / LP21 / LP22 / LP24 - happy path, audit, response mapping
    // ------------------------------------------------------------------
    @Test
    @DisplayName("LP01/LP24: valid learner+subject generates an ACTIVE AI path with derived gates")
    void generatesActiveAiPath() {
        User user = newUser("lp01");
        Subject subject = newSubject("lp01");
        newTopic(subject, "Alpha", Difficulty.EASY, 1);
        newTopic(subject, "Beta", Difficulty.MEDIUM, 2);
        newTopic(subject, "Gamma", Difficulty.HARD, 3);

        org.mockito.Mockito.when(geminiClient.generate(any()))
                .thenReturn(validCandidateJson("Test Title"));

        var outcome = generationService.generate(user.getId(), subject.getId(),
                false, null, "req-lp01");

        assertThat(outcome.created()).isTrue();
        assertThat(outcome.generatedBy()).isEqualTo(GeneratedBy.AI);

        List<LearningPath> paths = learningPathRepository
                .findByUserIdAndSubjectIdOrderByCreatedAtAsc(user.getId(), subject.getId());
        assertThat(paths).hasSize(1);
        LearningPath path = paths.get(0);
        assertThat(path.getStatus()).isEqualTo(LearningPathStatus.ACTIVE);
        assertThat(path.getGeneratedBy()).isEqualTo(GeneratedBy.AI);
        assertThat(path.getTitle()).isEqualTo("Test Title");

        List<LearningPathNode> nodes = learningPathNodeRepository
                .findByLearningPathIdOrderBySequenceNumberAsc(path.getId());
        assertThat(nodes).extracting(LearningPathNode::getSequenceNumber).containsExactly(1, 2, 3);
        assertThat(nodes).extracting(n -> n.getRequiredMastery())
                .containsExactly(new BigDecimal("0.00"), new BigDecimal("40.00"),
                        new BigDecimal("70.00"));
        assertThat(nodes).extracting(n -> n.getStatus().name())
                .containsExactly("AVAILABLE", "LOCKED", "LOCKED");

        // Audit: one sanitized SUCCESS row with model + prompt version + latency.
        List<AiInteraction> audits = aiInteractionRepository.findAll().stream()
                .filter(a -> a.getUser().getId().equals(user.getId()))
                .toList();
        assertThat(audits).hasSize(1);
        AiInteraction audit = audits.get(0);
        assertThat(audit.getStatus().name()).isEqualTo("SUCCESS");
        assertThat(audit.getInteractionType().name()).isEqualTo("LEARNING_PATH");
        assertThat(audit.getModelName()).isEqualTo("gemini-test-model");
        assertThat(audit.getPromptVersion()).isEqualTo("learning-path-v1.0");
        assertThat(audit.getLatencyMs()).isNotNull();
        assertThat(audit.getRequestContextJson()).doesNotContain(user.getEmail());
    }

    @Test
    @DisplayName("LP24: response mapping exposes persisted fields plus optional aiMetadata")
    void responseMappingMatchesContract() {
        User user = newUser("lp24");
        Subject subject = newSubject("lp24");
        newTopic(subject, "Alpha", Difficulty.EASY, 1);
        newTopic(subject, "Beta", Difficulty.MEDIUM, 2);
        newTopic(subject, "Gamma", Difficulty.HARD, 3);
        org.mockito.Mockito.when(geminiClient.generate(any()))
                .thenReturn(validCandidateJson("Contract Shape"));
        generationService.generate(user.getId(), subject.getId(), false, null, "req-lp24");

        LearningPath path = learningPathRepository
                .findByUserIdAndSubjectIdOrderByCreatedAtAsc(user.getId(), subject.getId()).get(0);
        var plan = new com.gamelearn.ai.validation.ValidatedPathPlan("t", "d", List.of());
        var response = responseMapper.toResponse(path,
                new com.gamelearn.ai.validation.ValidatedPathPlan(
                        path.getTitle(), path.getDescription(),
                        java.util.stream.IntStream.rangeClosed(1, 3)
                                .mapToObj(i -> new com.gamelearn.ai.validation.ValidatedPathPlan
                                        .PlannedNode(null, i, BigDecimal.ZERO, "obj-" + i, "rat-" + i))
                                .toList()));

        assertThat(response.id()).isEqualTo(path.getId());
        assertThat(response.subjectId()).isEqualTo(subject.getId());
        assertThat(response.status()).isEqualTo("ACTIVE");
        assertThat(response.generatedBy()).isEqualTo("AI");
        assertThat(response.createdAt()).isNotNull();
        assertThat(response.updatedAt()).isNotNull();
        assertThat(response.nodes()).hasSize(3);
        assertThat(response.nodes().get(0).topicName()).isNotBlank();
        assertThat(response.aiMetadata()).isNotNull();
        assertThat(response.aiMetadata().nodes().get(0).objective()).isEqualTo("obj-1");
    }

    // ------------------------------------------------------------------
    // LP02 / LP03 / LP04 / LP05 - learner context shapes reach the prompt
    // ------------------------------------------------------------------
    @Test
    @DisplayName("LP02: cold-start learner without mastery data generates successfully")
    void coldStartGeneratesSuccessfully() {
        User user = newUser("lp02");
        Subject subject = newSubject("lp02");
        newTopic(subject, "Alpha", Difficulty.EASY, 1);
        newTopic(subject, "Beta", Difficulty.EASY, 2);
        newTopic(subject, "Beta2", Difficulty.MEDIUM, 3);
        // Node evidence must match its own authoritative topic (spec 25.1):
        // ref 3 points at Beta2, so its objective references Beta2, not Gamma.
        org.mockito.Mockito.when(geminiClient.generate(any())).thenReturn("""
                {"title":"Cold Start Plan","description":"Covering Alpha, Beta and Beta2.","nodes":[
                  {"topicRef":1,"sequence":1,"requiredMastery":10,"objective":"Start Alpha here","rationale":"Foundation"},
                  {"topicRef":2,"sequence":2,"requiredMastery":40,"objective":"Continue with Beta","rationale":"Practice"},
                  {"topicRef":3,"sequence":3,"requiredMastery":70,"objective":"Finish via Beta2","rationale":"Advanced"}]}
                """);

        var outcome = generationService.generate(user.getId(), subject.getId(),
                false, null, "req-lp02");
        assertThat(outcome.created()).isTrue();
        assertThat(outcome.generatedBy()).isEqualTo(GeneratedBy.AI);
    }

    @Test
    @DisplayName("LP03/LP05: weak/strong/mixed mastery signals are supplied to Gemini verbatim")
    void masteryContextReachesPrompt() throws Exception {
        User user = newUser("lp03");
        Subject subject = newSubject("lp03");
        Topic weakTopic = newTopic(subject, "Weakling", Difficulty.EASY, 1);
        Topic strongTopic = newTopic(subject, "Stronghold", Difficulty.MEDIUM, 2);
        newTopic(subject, "Filler", Difficulty.HARD, 3);

        // Node evidence matches each node's authoritative topic (spec 25.1).
        String matchedCandidate = """
                {"title":"Mastery Plan","description":"Covering Weakling, Stronghold and Filler.","nodes":[
                  {"topicRef":1,"sequence":1,"objective":"Strengthen weakling fundamentals first","rationale":"Weak signal"},
                  {"topicRef":2,"sequence":2,"objective":"Polish stronghold mastery quickly","rationale":"Strong signal"},
                  {"topicRef":3,"sequence":3,"objective":"Survey filler topics last","rationale":"Quick review"}]}
                """;
        org.mockito.Mockito.when(geminiClient.generate(any()))
                .thenReturn(matchedCandidate, matchedCandidate);

        generationService.generate(user.getId(), subject.getId(), false, null, "req-lp03-a");

        var mastery = new com.gamelearn.entity.TopicMastery();
        mastery.setUser(userRepository.findById(user.getId()).orElseThrow());
        mastery.setTopic(weakTopic);
        mastery.setMasteryScore(new BigDecimal("22.00"));
        mastery.setMasteryLevel(com.gamelearn.entity.enums.MasteryLevel.BEGINNER);
        mastery.setTrend(com.gamelearn.entity.enums.MasteryTrend.DECLINING);
        mastery.setCurrentDifficulty(Difficulty.EASY);
        mastery.setAttemptCount(2);
        mastery.setRecentAccuracy(BigDecimal.ZERO);
        topicMasteryRepository.save(mastery);

        var strong = new com.gamelearn.entity.TopicMastery();
        strong.setUser(userRepository.findById(user.getId()).orElseThrow());
        strong.setTopic(strongTopic);
        strong.setMasteryScore(new BigDecimal("95.00"));
        strong.setMasteryLevel(com.gamelearn.entity.enums.MasteryLevel.MASTERED);
        strong.setTrend(com.gamelearn.entity.enums.MasteryTrend.IMPROVING);
        strong.setCurrentDifficulty(Difficulty.MEDIUM);
        strong.setAttemptCount(4);
        strong.setRecentAccuracy(new BigDecimal("95.00"));
        topicMasteryRepository.save(strong);

        generationService.generate(user.getId(), subject.getId(), true, null, "req-lp03-b");

        ArgumentCaptor<GeminiPrompt> captor = ArgumentCaptor.forClass(GeminiPrompt.class);
        verify(geminiClient, times(2)).generate(captor.capture());
        String firstPrompt = captor.getAllValues().get(0).promptText();
        String secondPrompt = captor.getAllValues().get(1).promptText();

        assertThat(firstPrompt).contains("\"subjectName\":\"" + subject.getName() + "\"");
        assertThat(secondPrompt)
                .contains("\"masteryLevel\":\"BEGINNER\"").contains("\"trend\":\"DECLINING\"")
                .contains("\"masteryLevel\":\"MASTERED\"")
                .contains("weakTopicRefs").contains("strongTopicRefs")
                .contains("Weakling").contains("Stronghold");
    }

    // ------------------------------------------------------------------
    // LP06-LP12 - deterministic output rejections fall back, never retried
    // ------------------------------------------------------------------
    @Test
    @DisplayName("LP06: malformed JSON -> one call, SYSTEM fallback path, FALLBACK audit")
    void malformedJsonFallsBack() {
        User user = newUser("lp06");
        Subject subject = newSubject("lp06");
        newTopic(subject, "A", Difficulty.EASY, 1);
        newTopic(subject, "B", Difficulty.MEDIUM, 2);
        newTopic(subject, "C", Difficulty.HARD, 3);
        org.mockito.Mockito.when(geminiClient.generate(any())).thenReturn("definitely not json");

        var outcome = generationService.generate(user.getId(), subject.getId(),
                false, null, "req-lp06");

        assertThat(outcome.generatedBy()).isEqualTo(GeneratedBy.SYSTEM);
        verify(geminiClient, times(1)).generate(any()); // deterministic: never retried

        LearningPath path = learningPathRepository
                .findByUserIdAndSubjectIdOrderByCreatedAtAsc(user.getId(), subject.getId()).get(0);
        assertThat(path.getStatus()).isEqualTo(LearningPathStatus.ACTIVE);
        assertThat(path.getGeneratedBy()).isEqualTo(GeneratedBy.SYSTEM);

        AiInteraction audit = auditsFor(user).get(0);
        assertThat(audit.getStatus().name()).isEqualTo("FALLBACK");
        assertThat(audit.getErrorCode()).isEqualTo("LP_MALFORMED_RESPONSE");
        assertThat(audit.getResponseJson()).contains("fallback");
    }

    @Test
    @DisplayName("LP07: schema-invalid output (missing title) falls back after a single call")
    void schemaFailureFallsBack() {
        User user = newUser("lp07");
        Subject subject = newSubject("lp07");
        threeTopics(subject);
        org.mockito.Mockito.when(geminiClient.generate(any())).thenReturn(
                "{\"description\":\"missing title\",\"nodes\":[]}");

        var outcome = generationService.generate(user.getId(), subject.getId(),
                false, null, "req-lp07");

        assertThat(outcome.generatedBy()).isEqualTo(GeneratedBy.SYSTEM);
        verify(geminiClient, times(1)).generate(any());
        assertThat(auditsFor(user).get(0).getErrorCode()).isEqualTo("LP_SCHEMA_VALIDATION_FAILED");
    }

    @Test
    @DisplayName("LP08: unknown topic reference is rejected and falls back")
    void unknownTopicFallsBack() {
        User user = newUser("lp08");
        Subject subject = newSubject("lp08");
        threeTopics(subject);
        org.mockito.Mockito.when(geminiClient.generate(any())).thenReturn(validCandidateJson()
                .replace("\"topicRef\":3", "\"topicRef\":99"));

        var outcome = generationService.generate(user.getId(), subject.getId(),
                false, null, "req-lp08");
        assertThat(outcome.generatedBy()).isEqualTo(GeneratedBy.SYSTEM);
        assertThat(auditsFor(user).get(0).getResponseJson()).contains("LP_SCHEMA_VALIDATION_FAILED");
    }

    @Test
    @DisplayName("LP10: duplicate topic references are rejected and fall back")
    void duplicateTopicFallsBack() {
        User user = newUser("lp10");
        Subject subject = newSubject("lp10");
        threeTopics(subject);
        org.mockito.Mockito.when(geminiClient.generate(any())).thenReturn("""
                {"title":"Dup","description":"d","nodes":[
                  {"topicRef":1,"sequence":1},{"topicRef":1,"sequence":2},{"topicRef":2,"sequence":3}]}
                """);
        var outcome = generationService.generate(user.getId(), subject.getId(),
                false, null, "req-lp10");
        assertThat(outcome.generatedBy()).isEqualTo(GeneratedBy.SYSTEM);
    }

    @Test
    @DisplayName("LP11/LP12: invalid mastery value or broken sequence falls back")
    void invalidMasteryOrSequenceFallsBack() {
        User user = newUser("lp11");
        Subject subject = newSubject("lp11");
        threeTopics(subject);
        org.mockito.Mockito.when(geminiClient.generate(any())).thenReturn(
                validCandidateJson().replace("\"requiredMastery\":40", "\"requiredMastery\":140"));
        assertThat(generationService.generate(user.getId(), subject.getId(), false, null, "r")
                .generatedBy()).isEqualTo(GeneratedBy.SYSTEM);

        org.mockito.Mockito.when(geminiClient.generate(any())).thenReturn(
                validCandidateJson().replace("\"sequence\":3,\"requiredMastery\":70",
                        "\"sequence\":9,\"requiredMastery\":70"));
        User user2 = newUser("lp12b");
        Subject subject2 = newSubject("lp12b");
        threeTopics(subject2);
        assertThat(generationService.generate(user2.getId(), subject2.getId(), false, null, "r2")
                .generatedBy()).isEqualTo(GeneratedBy.SYSTEM);
    }

    // ------------------------------------------------------------------
    // LP13 / LP14 / LP15 / LP16 - transport failures and fallback
    // ------------------------------------------------------------------
    @Test
    @DisplayName("LP13: timeout retries once then delivers SYSTEM fallback")
    void timeoutRetriesThenFallsBack() {
        User user = newUser("lp13");
        Subject subject = newSubject("lp13");
        threeTopics(subject);
        AtomicInteger calls = new AtomicInteger();
        org.mockito.Mockito.when(geminiClient.generate(any())).thenAnswer(invocation -> {
            calls.incrementAndGet();
            throw new GeminiTransientException("LP_GEMINI_TIMEOUT", "timed out");
        });

        var outcome = generationService.generate(user.getId(), subject.getId(),
                false, null, "req-lp13");

        assertThat(outcome.generatedBy()).isEqualTo(GeneratedBy.SYSTEM);
        assertThat(calls.get()).isEqualTo(2); // approved policy: exactly one retry
        assertThat(auditsFor(user).get(0).getErrorCode()).isEqualTo("LP_GEMINI_TIMEOUT");
    }

    @Test
    @DisplayName("LP14: permanent client failure is never retried and falls back")
    void permanentFailureNotRetried() {
        User user = newUser("lp14");
        Subject subject = newSubject("lp14");
        threeTopics(subject);
        AtomicInteger calls = new AtomicInteger();
        org.mockito.Mockito.when(geminiClient.generate(any())).thenAnswer(invocation -> {
            calls.incrementAndGet();
            throw new GeminiPermanentException("LP_GEMINI_REJECTED_CLIENT", "bad key");
        });

        var outcome = generationService.generate(user.getId(), subject.getId(),
                false, null, "req-lp14");
        assertThat(outcome.generatedBy()).isEqualTo(GeneratedBy.SYSTEM);
        assertThat(calls.get()).isEqualTo(1);
    }

    @Test
    @DisplayName("LP15: provider rate limiting retries once then falls back")
    void rateLimitRetriesThenFallsBack() {
        User user = newUser("lp15");
        Subject subject = newSubject("lp15");
        threeTopics(subject);
        AtomicInteger calls = new AtomicInteger();
        org.mockito.Mockito.when(geminiClient.generate(any())).thenAnswer(invocation -> {
            if (calls.incrementAndGet() <= 2) {
                throw new GeminiTransientException("LP_GEMINI_RATE_LIMITED", "429");
            }
            return validCandidateJson();
        });

        var outcome = generationService.generate(user.getId(), subject.getId(),
                false, null, "req-lp15");
        // After exhausting retries the deterministic path wins (approved policy).
        assertThat(outcome.generatedBy()).isEqualTo(GeneratedBy.SYSTEM);
        assertThat(calls.get()).isEqualTo(2);
    }

    // ------------------------------------------------------------------
    // LP20 / LP29 - idempotency with ZERO additional Gemini calls
    // ------------------------------------------------------------------
    @Test
    @DisplayName("LP20/LP29: second normal request returns the same ACTIVE path with zero AI calls")
    void idempotentReturnSkipsGemini() {
        User user = newUser("lp20");
        Subject subject = newSubject("lp20");
        threeTopics(subject);
        org.mockito.Mockito.when(geminiClient.generate(any()))
                .thenReturn(validCandidateJson());

        var first = generationService.generate(user.getId(), subject.getId(),
                false, null, "req-a");
        var second = generationService.generate(user.getId(), subject.getId(),
                false, null, "req-b");

        assertThat(first.created()).isTrue();
        assertThat(second.created()).isFalse();
        assertThat(second.pathId()).isEqualTo(first.pathId());
        verify(geminiClient, times(1)).generate(any());

        List<LearningPath> paths = learningPathRepository
                .findByUserIdAndSubjectIdOrderByCreatedAtAsc(user.getId(), subject.getId());
        assertThat(paths).hasSize(1);
        assertThat(paths.get(0).getStatus()).isEqualTo(LearningPathStatus.ACTIVE);
    }

    // ------------------------------------------------------------------
    // LP26 - catalog size edges
    // ------------------------------------------------------------------
    @Test
    @DisplayName("LP26: fewer than three topics still generates; empty catalog is 404")
    void catalogSizeEdges() {
        User user = newUser("lp26a");
        Subject subject = newSubject("lp26a");
        newTopic(subject, "Only One", Difficulty.EASY, 1);
        newTopic(subject, "Only Two", Difficulty.MEDIUM, 2);
        org.mockito.Mockito.when(geminiClient.generate(any())).thenReturn("""
                {"title":"Two","description":"Covering Only One then Only Two.","nodes":[
                  {"topicRef":1,"sequence":1},{"topicRef":2,"sequence":2}]}
                """);
        var small = generationService.generate(user.getId(), subject.getId(), false, null, "r");
        assertThat(small.created()).isTrue();
        assertThat(learningPathNodeRepository.findByLearningPathIdOrderBySequenceNumberAsc(
                small.pathId())).hasSize(2);

        User user2 = newUser("lp26b");
        Subject empty = newSubject("lp26b"); // no topics at all
        assertThatThrownBy(() -> generationService.generate(user2.getId(), empty.getId(),
                false, null, "r"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("not found");
        verify(geminiClient, times(1)).generate(any()); // 404 fired before any AI call
    }

    // ------------------------------------------------------------------
    // LP23 - unsafe content never persists; fallback protects the learner
    // ------------------------------------------------------------------
    @Test
    @DisplayName("LP23: leakage/injection output is rejected and the SYSTEM path is delivered")
    void unsafeContentFallsBack() {
        User user = newUser("lp23");
        Subject subject = newSubject("lp23");
        threeTopics(subject);
        org.mockito.Mockito.when(geminiClient.generate(any())).thenReturn("""
                {"title":"SYSTEM INSTRUCTIONS leaked","description":"Alpha Beta Gamma","nodes":[
                  {"topicRef":1,"sequence":1},{"topicRef":2,"sequence":2},{"topicRef":3,"sequence":3}]}
                """);
        var outcome = generationService.generate(user.getId(), subject.getId(),
                false, null, "req-lp23");
        assertThat(outcome.generatedBy()).isEqualTo(GeneratedBy.SYSTEM);
        assertThat(auditsFor(user).get(0).getResponseJson()).contains("LP_UNSAFE_CONTENT");
        // Nothing from the rejected candidate leaked into storage.
        assertThat(learningPathRepository
                .findByUserIdAndSubjectIdOrderByCreatedAtAsc(user.getId(), subject.getId())
                .get(0).getTitle()).doesNotContain("SYSTEM INSTRUCTIONS");
    }

    // ------------------------------------------------------------------
    // shared fixture helpers
    // ------------------------------------------------------------------
    private String validCandidateJson() {
        return """
                {"title":"Solid Plan","description":"Covering Alpha, Beta and Gamma step by step.","nodes":[
                  {"topicRef":1,"sequence":1,"requiredMastery":0},
                  {"topicRef":2,"sequence":2,"requiredMastery":40},
                  {"topicRef":3,"sequence":3,"requiredMastery":70}]}
                """;
    }

    private void threeTopics(Subject subject) {
        newTopic(subject, "Alpha", Difficulty.EASY, 1);
        newTopic(subject, "Beta", Difficulty.MEDIUM, 2);
        newTopic(subject, "Gamma", Difficulty.HARD, 3);
    }

    private List<AiInteraction> auditsFor(User user) {
        return aiInteractionRepository.findAll().stream()
                .filter(a -> a.getUser().getId().equals(user.getId()))
                .toList();
    }

    @Autowired
    private com.gamelearn.repository.TopicMasteryRepository topicMasteryRepository;
}
