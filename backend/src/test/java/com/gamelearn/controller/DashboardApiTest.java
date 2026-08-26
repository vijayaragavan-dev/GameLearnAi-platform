package com.gamelearn.controller;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamelearn.auth.JwtProperties;
import com.gamelearn.auth.JwtService;
import com.gamelearn.dto.AuthResponse;
import com.gamelearn.dto.QuizSubmissionRequest;
import com.gamelearn.dto.RegisterRequest;
import com.gamelearn.entity.Achievement;
import com.gamelearn.entity.LearningPath;
import com.gamelearn.entity.LearningPathNode;
import com.gamelearn.entity.Question;
import com.gamelearn.entity.Quiz;
import com.gamelearn.entity.QuizAttempt;
import com.gamelearn.entity.QuizQuestion;
import com.gamelearn.entity.Recommendation;
import com.gamelearn.entity.Streak;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.TopicMastery;
import com.gamelearn.entity.User;
import com.gamelearn.entity.UserAchievement;
import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.entity.enums.GeneratedBy;
import com.gamelearn.entity.enums.LearningPathStatus;
import com.gamelearn.entity.enums.MasteryLevel;
import com.gamelearn.entity.enums.MasteryTrend;
import com.gamelearn.entity.enums.PathNodeStatus;
import com.gamelearn.entity.enums.QuestionType;
import com.gamelearn.entity.enums.QuizAttemptStatus;
import com.gamelearn.entity.enums.RecommendationActivityType;
import com.gamelearn.entity.enums.RecommendationStatus;
import com.gamelearn.entity.enums.SourceType;
import com.gamelearn.repository.AchievementRepository;
import com.gamelearn.repository.LearningPathNodeRepository;
import com.gamelearn.repository.LearningPathRepository;
import com.gamelearn.repository.QuestionRepository;
import com.gamelearn.repository.QuizQuestionRepository;
import com.gamelearn.repository.QuizRepository;
import com.gamelearn.repository.StreakRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicMasteryRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.UserAchievementRepository;
import com.gamelearn.repository.UserRepository;
import com.gamelearn.service.AuthService;
import com.gamelearn.service.DashboardService;
import com.gamelearn.service.QuizSubmissionService;

/**
 * Phase 9B â€” DASH-001 HTTP contract verification (Dashboard Specification
 * v1.0.0 section 25, DASH-TEST-001..005, 007..022, 029..035). Mutation
 * protection lives in DashboardMutationProtectionTest, the query budget in
 * DashboardQueryBudgetTest and the OpenAPI surface in
 * DashboardOpenApiSurfaceTest.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class DashboardApiTest {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private AuthService authService;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private SubjectRepository subjectRepository;
    @Autowired
    private TopicRepository topicRepository;
    @Autowired
    private QuizRepository quizRepository;
    @Autowired
    private QuestionRepository questionRepository;
    @Autowired
    private QuizQuestionRepository quizQuestionRepository;
    @Autowired
    private TopicMasteryRepository topicMasteryRepository;
    @Autowired
    private com.gamelearn.repository.RecommendationRepository recommendationRepository;
    @Autowired
    private com.gamelearn.repository.QuizAttemptRepository attemptRepository;
    @Autowired
    private UserAchievementRepository userAchievementRepository;
    @Autowired
    private AchievementRepository achievementRepository;
    @Autowired
    private StreakRepository streakRepository;
    @Autowired
    private LearningPathRepository learningPathRepository;
    @Autowired
    private LearningPathNodeRepository learningPathNodeRepository;
    @Autowired
    private QuizSubmissionService quizSubmissionService;
    @Autowired
    private JdbcTemplate jdbcTemplate;
    @Autowired
    private JwtProperties jwtProperties;
    @MockitoSpyBean
    private DashboardService dashboardService;

    private record Principal(String token, UUID userId, String email) {
    }

    private Principal principal(String label) {
        AuthResponse auth = authService.register(new RegisterRequest(
                label + "-" + UUID.randomUUID() + "@example.test",
                "Str0ng-Passw0rd!", "Learner " + label));
        return new Principal(auth.token(), auth.user().id(), auth.user().email());
    }

    private record QuizWorld(Subject subject, Topic topic, Quiz quiz,
                             Question q1, Question q2) {
    }

    // ------------------------------------------------------------------
    // DASH-TEST-001 / 002 â€” authenticated access and anonymous rejection
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-001: authenticated request returns 200 with all ten sections")
    void authenticatedRequestReturnsAllTenSections() throws Exception {
        Principal learner = principal("dash001");
        QuizWorld world = seedQuizWorld();
        perfectSubmission(learner.userId(), world);

        MvcResult result = mockMvc.perform(get("/api/v1/dashboard")
                        .header("Authorization", "Bearer " + learner.token()))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode root = MAPPER.readTree(result.getResponse().getContentAsString());
        assertThat(fieldNames(root)).containsExactly(
                "learner", "currentSubject", "mastery", "gamification", "streak",
                "achievements", "recommendations", "learningPath", "assessment",
                "recentActivity");
    }

    @Test
    @DisplayName("DASH-TEST-002: anonymous request gets the 401 UNAUTHORIZED envelope")
    void anonymousRequestIsUnauthorized() throws Exception {
        mockMvc.perform(get("/api/v1/dashboard"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.status").value(401))
                .andExpect(jsonPath("$.errorCode").value("UNAUTHORIZED"))
                // Exact wording of the approved Phase 2 entry-point envelope.
                .andExpect(jsonPath("$.message")
                        .value("Authentication is required to access this resource"))
                .andExpect(jsonPath("$.path").value("/api/v1/dashboard"))
                .andExpect(jsonPath("$.requestId").isNotEmpty());
    }

    // ------------------------------------------------------------------
    // DASH-TEST-003 â€” cross-user isolation (both directions)
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-003: each learner sees ONLY their own dashboard data")
    void crossUserIsolationBothDirections() throws Exception {
        Principal rich = principal("isolation-rich");
        Principal other = principal("isolation-other");
        QuizWorld worldA = seedQuizWorld();
        perfectSubmission(rich.userId(), worldA);
        seedActivePath(rich.userId(), worldA.subject());

        String richBody = dashboardBody(rich);
        String otherBody = dashboardBody(other);

        JsonNode richRoot = MAPPER.readTree(richBody);
        assertThat(richRoot.get("learner").get("displayName").asText())
                .isEqualTo("Learner isolation-rich");
        assertThat(richBody).contains(worldA.topic().getId().toString());

        JsonNode otherRoot = MAPPER.readTree(otherBody);
        assertThat(otherRoot.get("learner").get("displayName").asText())
                .isEqualTo("Learner isolation-other");
        assertThat(otherRoot.get("mastery").get("topicsAssessed").asInt()).isZero();
        assertThat(otherRoot.get("learningPath").isNull()).isTrue();
        // None of the rich learner's identifiers may leak into the other body.
        assertThat(otherBody).doesNotContain(worldA.topic().getId().toString());
        assertThat(otherBody).doesNotContain(worldA.subject().getId().toString());
        assertThat(otherBody).doesNotContain(rich.userId().toString());
        assertThat(richBody).doesNotContain(other.userId().toString());
    }

    // ------------------------------------------------------------------
    // DASH-TEST-004 / 016 / 019 â€” brand-new learner zero state
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-004/016/019: brand-new learner returns the exact zero state")
    void newLearnerZeroState() throws Exception {
        Principal learner = principal("zero");
        JsonNode root = MAPPER.readTree(dashboardBody(learner));

        assertThat(root.get("learner").get("displayName").asText())
                .isEqualTo("Learner zero");
        assertThat(root.get("learner").get("overallMastery").doubleValue()).isEqualTo(0.0);
        assertThat(root.get("learner").get("currentSubjectId").isNull()).isTrue();
        assertThat(root.get("learner").get("currentTopicId").isNull()).isTrue();

        assertThat(root.get("currentSubject").isNull()).isTrue();

        assertThat(root.get("mastery").get("topicsAssessed").asInt()).isEqualTo(0);
        assertThat(root.get("mastery").get("topicsMastered").asInt()).isEqualTo(0);
        assertThat(root.get("mastery").get("recentTopics")).isEmpty();

        assertThat(root.get("gamification").get("totalXp").asInt()).isEqualTo(0);
        assertThat(root.get("gamification").get("currentLevel").asInt()).isEqualTo(1);
        assertThat(root.get("gamification").get("maxLevel").asInt()).isEqualTo(50);
        assertThat(root.get("gamification").get("nextLevelThresholdXp").asLong()).isEqualTo(100);
        assertThat(root.get("gamification").get("xpToNextLevel").asInt()).isEqualTo(100);

        assertThat(root.get("streak").get("currentStreakDays").asInt()).isEqualTo(0);
        assertThat(root.get("streak").get("longestStreakDays").asInt()).isEqualTo(0);
        assertThat(root.get("streak").get("lastLearningDate").isNull()).isTrue();
        assertThat(root.get("streak").get("timezone").asText()).isEqualTo("UTC");

        assertThat(root.get("achievements").get("unlockedCount").asLong()).isEqualTo(0);
        assertThat(root.get("achievements").get("recentUnlocks")).isEmpty();

        assertThat(root.get("recommendations")).isEmpty();
        assertThat(root.get("learningPath").isNull()).isTrue();
        assertThat(root.get("assessment").get("assessedSubjects")).isEmpty();
        assertThat(root.get("recentActivity").get("quizzes")).isEmpty();
    }

    // ------------------------------------------------------------------
    // DASH-TEST-005 â€” assessment-completed state (Case 1/8 matrix)
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-005: post-assessment baselines render; quizzes/recommendations stay empty")
    void postAssessmentState() throws Exception {
        Principal learner = principal("asmt");
        Subject subject = subject("asmt-subj", 5);
        Topic tA = topic("osia", subject);
        Topic tB = topic("ipa", subject);
        masteryRow(learner.userId(), tA, new BigDecimal("100.00"), MasteryLevel.MASTERED,
                Difficulty.EASY, MasteryTrend.INSUFFICIENT_DATA,
                Instant.parse("2026-08-24T08:00:00Z"));
        masteryRow(learner.userId(), tB, new BigDecimal("33.33"), MasteryLevel.BEGINNER,
                Difficulty.EASY, MasteryTrend.INSUFFICIENT_DATA,
                Instant.parse("2026-08-24T08:00:00Z"));
        setCurrentSubject(learner.userId(), subject.getId());
        // ASMT-002 refreshes the profile subset: overall mean + subject pointer.
        jdbcTemplate.update(
                "UPDATE learner_profiles SET current_subject_id=?, overall_mastery=66.67 "
                        + "WHERE user_id=?",
                subject.getId(), learner.userId());

        JsonNode root = MAPPER.readTree(dashboardBody(learner));

        assertThat(root.get("learner").get("overallMastery").doubleValue()).isEqualTo(66.67);
        assertThat(root.get("learner").get("currentSubjectId").asText())
                .isEqualTo(subject.getId().toString());
        assertThat(root.get("learner").get("currentTopicId").isNull()).isTrue();
        assertThat(root.get("currentSubject").get("id").asText())
                .isEqualTo(subject.getId().toString());
        assertThat(root.get("currentSubject").get("name").asText())
                .isEqualTo(subject.getName());
        assertThat(root.get("currentSubject").get("iconKey").asText())
                .isEqualTo(subject.getIconKey());
        assertThat(root.get("currentSubject").get("currentTopic").isNull()).isTrue();

        assertThat(root.get("mastery").get("topicsAssessed").asInt()).isEqualTo(2);
        assertThat(root.get("mastery").get("topicsMastered").asInt()).isEqualTo(1);
        JsonNode recentTopics = root.get("mastery").get("recentTopics");
        assertThat(recentTopics).hasSize(2);
        for (JsonNode item : recentTopics) {
            assertThat(item.get("masteryLevel").asText()).isIn("MASTERED", "BEGINNER");
            assertThat(item.get("currentDifficulty").asText()).isEqualTo("EASY");
            assertThat(item.get("trend").asText()).isEqualTo("INSUFFICIENT_DATA");
        }

        assertThat(root.get("assessment").get("assessedSubjects")).hasSize(1);
        assertThat(root.get("assessment").get("assessedSubjects").get(0)
                .get("subjectId").asText()).isEqualTo(subject.getId().toString());

        assertThat(root.get("recommendations")).isEmpty();
        assertThat(root.get("recentActivity").get("quizzes")).isEmpty();
        assertThat(root.get("learningPath").isNull()).isTrue();
        assertThat(root.get("gamification").get("totalXp").asInt()).isEqualTo(0);
        assertThat(root.get("streak").get("currentStreakDays").asInt()).isEqualTo(0);
    }

    // ------------------------------------------------------------------
    // DASH-TEST-006 â€” post-quiz recent activity
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-006: newest completed attempt leads recentActivity.quizzes")
    void postQuizRecentActivity() throws Exception {
        Principal learner = principal("quizact");
        QuizWorld world = seedQuizWorld();
        perfectSubmission(learner.userId(), world);

        JsonNode root = MAPPER.readTree(dashboardBody(learner));
        JsonNode quizzes = root.get("recentActivity").get("quizzes");
        assertThat(quizzes).hasSize(1);
        JsonNode first = quizzes.get(0);
        assertThat(first.get("topicId").asText()).isEqualTo(world.topic().getId().toString());
        assertThat(first.get("topicName").asText()).isEqualTo(world.topic().getName());
        assertThat(first.get("score").doubleValue()).isEqualTo(100.0);
        assertThat(first.get("correctCount").asInt()).isEqualTo(2);
        assertThat(first.get("totalQuestions").asInt()).isEqualTo(2);
        assertThat(first.get("submittedAt").isNull()).isFalse();
        assertThat(first.get("quizAttemptId").isNull()).isFalse();
    }

    // ------------------------------------------------------------------
    // DASH-TEST-007 / 008 â€” mastery values echoed verbatim incl. difficulty
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-007/008: stored mastery columns are displayed verbatim")
    void masteryValuesAreVerbatim() throws Exception {
        Principal learner = principal("verbatim");
        Subject subject = subject("verb-subj", 5);
        Topic tEasy = topic("ve-easy", subject);
        Topic tMedium = topic("ve-med", subject);
        Topic tHard = topic("ve-hard", subject);
        masteryRow(learner.userId(), tEasy, new BigDecimal("25.50"), MasteryLevel.DEVELOPING,
                Difficulty.EASY, MasteryTrend.IMPROVING, Instant.parse("2026-08-20T10:00:00Z"));
        masteryRow(learner.userId(), tMedium, new BigDecimal("61.11"), MasteryLevel.PROFICIENT,
                Difficulty.MEDIUM, MasteryTrend.DECLINING, Instant.parse("2026-08-22T10:00:00Z"));
        masteryRow(learner.userId(), tHard, new BigDecimal("91.67"), MasteryLevel.MASTERED,
                Difficulty.HARD, MasteryTrend.STABLE, Instant.parse("2026-08-24T10:00:00Z"));

        JsonNode recentTopics = MAPPER.readTree(dashboardBody(learner))
                .get("mastery").get("recentTopics");

        assertThat(recentTopics).hasSize(3);
        JsonNode hard = recentTopics.get(0);
        assertThat(hard.get("topicId").asText()).isEqualTo(tHard.getId().toString());
        assertThat(hard.get("topicName").asText()).isEqualTo(tHard.getName());
        assertThat(hard.get("masteryScore").doubleValue()).isEqualTo(91.67);
        assertThat(hard.get("masteryLevel").asText()).isEqualTo("MASTERED");
        assertThat(hard.get("currentDifficulty").asText()).isEqualTo("HARD");
        assertThat(hard.get("trend").asText()).isEqualTo("STABLE");
        assertThat(hard.get("lastAssessedAt").asText()).isEqualTo("2026-08-24T10:00:00Z");
        assertThat(recentTopics.get(1).get("currentDifficulty").asText()).isEqualTo("MEDIUM");
        assertThat(recentTopics.get(2).get("currentDifficulty").asText()).isEqualTo("EASY");
    }

    // ------------------------------------------------------------------
    // DASH-TEST-009 â€” gamification equals the GAM-001 computation
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-009: gamification block matches GAM-001 for the same state")
    void gamificationMatchesGamSummaryEndpoint() throws Exception {
        Principal earner = principal("parity");
        QuizWorld world = seedQuizWorld();
        perfectSubmission(earner.userId(), world);

        JsonNode dash = MAPPER.readTree(dashboardBody(earner)).get("gamification");
        MvcResult gamResult = mockMvc.perform(get("/api/v1/gamification/summary")
                        .header("Authorization", "Bearer " + earner.token()))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode gam = MAPPER.readTree(gamResult.getResponse().getContentAsString());

        assertThat(dash.get("totalXp").asLong())
                .isEqualTo(gam.get("totalXp").asLong());
        assertThat(dash.get("currentLevel").asInt())
                .isEqualTo(gam.get("currentLevel").asInt());
        assertThat(dash.get("maxLevel").asInt()).isEqualTo(50);
        assertThat(dash.get("nextLevelThresholdXp").asLong())
                .isEqualTo(gam.get("nextLevelThresholdXp").asLong());
        assertThat(dash.get("xpToNextLevel").asInt())
                .isEqualTo(gam.get("xpToNextLevel").asInt());
    }

    // ------------------------------------------------------------------
    // DASH-TEST-010 â€” max-level nullability
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-010: at MAX_LEVEL both next-level fields are null while XP shows")
    void maxLevelNullability() throws Exception {
        Principal capped = principal("dashmax");
        jdbcTemplate.update(
                "UPDATE learner_profiles SET total_xp=130000, current_level=50 WHERE user_id=?",
                capped.userId());

        JsonNode gamification = MAPPER.readTree(dashboardBody(capped)).get("gamification");
        assertThat(gamification.get("totalXp").asInt()).isEqualTo(130000);
        assertThat(gamification.get("currentLevel").asInt()).isEqualTo(50);
        assertThat(gamification.get("maxLevel").asInt()).isEqualTo(50);
        assertThat(gamification.get("nextLevelThresholdXp").isNull()).isTrue();
        assertThat(gamification.get("xpToNextLevel").isNull()).isTrue();
    }

    // ------------------------------------------------------------------
    // DASH-TEST-011 â€” streak display mirrors the row
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-011: streak block mirrors the stored row verbatim")
    void streakMirrorsStoredRow() throws Exception {
        Principal learner = principal("dashstreak");
        LocalDate today = LocalDate.now(java.time.ZoneOffset.UTC);
        Streak streak = new Streak();
        streak.setUser(user(learner.userId()));
        streak.setCurrentStreakDays(3);
        streak.setLongestStreakDays(5);
        streak.setLastLearningDate(today);
        streak.setTimezone("UTC");
        streakRepository.save(streak);

        JsonNode node = MAPPER.readTree(dashboardBody(learner)).get("streak");
        assertThat(node.get("currentStreakDays").asInt()).isEqualTo(3);
        assertThat(node.get("longestStreakDays").asInt()).isEqualTo(5);
        assertThat(node.get("lastLearningDate").asText()).isEqualTo(today.toString());
        assertThat(node.get("timezone").asText()).isEqualTo("UTC");
    }

    // ------------------------------------------------------------------
    // DASH-TEST-012 â€” achievements count + newest-first unlocks, locked absent
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-012: unlockedCount counts unlocks only; recentUnlocks newest first")
    void achievementUnlocksNewestFirstLockedAbsent() throws Exception {
        Principal learner = principal("dashach");
        Achievement older = achievement("old");
        Achievement newer = achievement("new");
        achievementRepository.saveAll(List.of(older, newer));
        unlock(user(learner.userId()), older, Instant.parse("2026-08-01T09:00:00Z"));
        unlock(user(learner.userId()), newer, Instant.parse("2026-08-02T09:00:00Z"));

        JsonNode achievements = MAPPER.readTree(dashboardBody(learner)).get("achievements");
        assertThat(achievements.get("unlockedCount").asLong()).isEqualTo(2);
        JsonNode recent = achievements.get("recentUnlocks");
        assertThat(recent).hasSize(2);
        assertThat(recent.get(0).get("code").asText()).isEqualTo(newer.getCode());
        assertThat(recent.get(0).get("name").asText()).isEqualTo(newer.getName());
        assertThat(recent.get(0).get("iconKey").asText()).isEqualTo(newer.getIconKey());
        assertThat(recent.get(0).get("unlockedAt").asText()).isEqualTo("2026-08-02T09:00:00Z");
        assertThat(recent.get(1).get("unlockedAt").asText()).isEqualTo("2026-08-01T09:00:00Z");
        assertThat(recent.get(1).get("code").asText()).isEqualTo(older.getCode());
        // Catalog entries never unlocked are absent from the dashboard list.
        assertThat(achievementRepository.count()).isGreaterThan(2);
        assertThat(recent.size()).isEqualTo(2);
    }

    private List<String> fieldNames(JsonNode node) {
        List<String> names = new ArrayList<>();
        node.fieldNames().forEachRemaining(names::add);
        return names;
    }

    // ------------------------------------------------------------------
    // DASH-TEST-013 â€” recommendation ordering priority ASC, fields verbatim
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-013: ACTIVE recommendations ordered priority ASC with verbatim fields")
    void recommendationsOrderedByPriority() throws Exception {
        Principal learner = principal("dashrec");
        Subject subject = subject("rec-subj", 5);
        Topic topicA = topic("rec-a", subject);
        Topic topicB = topic("rec-b", subject);
        recommendation(user(learner.userId()), topicB, 4,
                RecommendationActivityType.ADVANCE, Difficulty.HARD,
                "MASTERED_ADVANCE_CHALLENGE: ready.", Instant.parse("2026-08-23T18:02:11Z"));
        recommendation(user(learner.userId()), topicA, 1,
                RecommendationActivityType.REMEDIATION, Difficulty.EASY,
                "RECENT_DECLINE_REMEDIATION: targeted remediation.",
                Instant.parse("2026-08-24T09:12:45Z"));

        JsonNode recs = MAPPER.readTree(dashboardBody(learner)).get("recommendations");
        assertThat(recs).hasSize(2);
        assertThat(recs.get(0).get("priority").asInt()).isEqualTo(1);
        assertThat(recs.get(0).get("activityType").asText()).isEqualTo("REMEDIATION");
        assertThat(recs.get(0).get("recommendedDifficulty").asText()).isEqualTo("EASY");
        assertThat(recs.get(0).get("reason").asText())
                .isEqualTo("RECENT_DECLINE_REMEDIATION: targeted remediation.");
        assertThat(recs.get(0).get("generatedAt").asText()).isEqualTo("2026-08-24T09:12:45Z");
        assertThat(recs.get(0).get("topicName").asText()).isEqualTo(topicA.getName());
        assertThat(recs.get(1).get("priority").asInt()).isEqualTo(4);
        assertThat(recs.get(1).get("activityType").asText()).isEqualTo("ADVANCE");
    }

    // ------------------------------------------------------------------
    // DASH-TEST-014 (+E2) â€” active path card, current-subject precedence
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-014/E2: current-subject ACTIVE path wins; nodes sequence ASC")
    void activePathCardForCurrentSubject() throws Exception {
        Principal learner = principal("dashpath");
        Subject current = subject("path-cur", 5);
        Subject elsewhere = subject("path-other", 6);
        Topic t1 = topic("pt-a", current);
        Topic t2 = topic("pt-b", current);

        LearningPath olderPath = pathWithNodes(learner.userId(), current,
                LearningPathStatus.ACTIVE, List.of(t1),
                Instant.parse("2026-08-01T10:00:00Z"), "Older Path", false);
        LearningPath chosenPath = pathWithNodes(learner.userId(), current,
                LearningPathStatus.ACTIVE, List.of(t1, t2),
                Instant.parse("2026-08-05T10:00:00Z"), "Newest Current Path", true);
        pathWithNodes(learner.userId(), elsewhere, LearningPathStatus.ACTIVE,
                List.of(topic("po-a", elsewhere)),
                Instant.parse("2026-08-06T10:00:00Z"), "Elsewhere Path", false);
        setCurrentSubject(learner.userId(), current.getId());

        JsonNode card = MAPPER.readTree(dashboardBody(learner)).get("learningPath");
        assertThat(card.isNull()).isFalse();
        assertThat(card.get("id").asText()).isEqualTo(chosenPath.getId().toString());
        assertThat(card.get("subjectId").asText()).isEqualTo(current.getId().toString());
        assertThat(card.get("subjectName").asText()).isEqualTo(current.getName());
        assertThat(card.get("title").asText()).isEqualTo(chosenPath.getTitle());
        assertThat(card.get("status").asText()).isEqualTo("ACTIVE");
        assertThat(card.get("generatedBy").asText()).isEqualTo("SYSTEM");
        assertThat(card.get("createdAt").asText()).isEqualTo("2026-08-05T10:00:00Z");
        JsonNode nodes = card.get("nodes");
        assertThat(nodes).hasSize(2);
        assertThat(nodes.get(0).get("sequenceNumber").asInt()).isEqualTo(1);
        assertThat(nodes.get(0).get("topicId").asText()).isEqualTo(t1.getId().toString());
        assertThat(nodes.get(0).get("topicName").asText()).isEqualTo(t1.getName());
        assertThat(nodes.get(0).get("status").asText()).isEqualTo("AVAILABLE");
        assertThat(nodes.get(1).get("sequenceNumber").asInt()).isEqualTo(2);
        assertThat(nodes.get(1).get("topicId").asText()).isEqualTo(t2.getId().toString());
        assertThat(nodes.get(1).get("requiredMastery").doubleValue()).isEqualTo(40.0);
        assertThat(nodes.get(1).get("status").asText()).isEqualTo("LOCKED");
        // The non-selected paths remain untouched (no archival side effects).
        assertThat(learningPathRepository.findById(olderPath.getId())
                .orElseThrow().getStatus()).isEqualTo(LearningPathStatus.ACTIVE);
    }

    // ------------------------------------------------------------------
    // DASH-TEST-015 â€” no ACTIVE path anywhere -> null, nothing resurrected
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-015: archived/completed-only history yields learningPath null")
    void noActivePathYieldsNull() throws Exception {
        Principal learner = principal("dashedarch");
        Subject subject = subject("arch-subj", 5);
        pathWithNodes(learner.userId(), subject, LearningPathStatus.ARCHIVED,
                List.of(topic("ar-a", subject)),
                Instant.parse("2026-08-01T10:00:00Z"), "Old Archived", false);
        setCurrentSubject(learner.userId(), subject.getId());

        JsonNode root = MAPPER.readTree(dashboardBody(learner));
        assertThat(root.get("learningPath").isNull()).isTrue();

        Integer activeCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM learning_paths WHERE user_id=? AND status='ACTIVE'",
                Integer.class, learner.userId());
        assertThat(activeCount).isZero();
    }

    // ------------------------------------------------------------------
    // DASH-TEST-017 / Case 7 â€” null current subject, D1 fallback to any ACTIVE
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-017: null current subject still renders most recent ACTIVE path")
    void fallbackToAnyActivePathWhenCurrentSubjectNull() throws Exception {
        Principal learner = principal("dashfallback");
        Subject subject = subject("fb-subj", 5);
        pathWithNodes(learner.userId(), subject, LearningPathStatus.ACTIVE,
                List.of(topic("fb-a", subject)),
                Instant.parse("2026-08-02T10:00:00Z"), "Fallback Path", false);
        // profile pointer stays NULL.

        JsonNode root = MAPPER.readTree(dashboardBody(learner));
        assertThat(root.get("learner").get("currentSubjectId").isNull()).isTrue();
        assertThat(root.get("currentSubject").isNull()).isTrue();
        assertThat(root.get("learningPath").isNull()).isFalse();
        assertThat(root.get("learningPath").get("title").asText()).isEqualTo("Fallback Path");
    }

    // ------------------------------------------------------------------
    // DASH-TEST-018 â€” assessed subjects across multiple subjects, catalog order
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-018: assessedSubjects lists both subjects in catalog order")
    void assessedSubjectsAcrossSubjectsInCatalogOrder() throws Exception {
        Principal learner = principal("dashmulti");
        Subject laterDisplay = subject("multi-later", 8);
        Subject earlierDisplay = subject("multi-earlier", 7);
        masteryRow(learner.userId(), topic("ml-a", earlierDisplay), new BigDecimal("50.00"),
                MasteryLevel.PROFICIENT, Difficulty.EASY, MasteryTrend.INSUFFICIENT_DATA,
                Instant.parse("2026-08-21T08:00:00Z"));
        masteryRow(learner.userId(), topic("mn-a", laterDisplay), new BigDecimal("60.00"),
                MasteryLevel.PROFICIENT, Difficulty.EASY, MasteryTrend.INSUFFICIENT_DATA,
                Instant.parse("2026-08-22T08:00:00Z"));

        JsonNode assessed = MAPPER.readTree(dashboardBody(learner))
                .get("assessment").get("assessedSubjects");
        assertThat(assessed).hasSize(2);
        assertThat(assessed.get(0).get("subjectId").asText())
                .isEqualTo(earlierDisplay.getId().toString());
        assertThat(assessed.get(0).get("subjectName").asText())
                .isEqualTo(earlierDisplay.getName());
        assertThat(assessed.get(1).get("subjectId").asText())
                .isEqualTo(laterDisplay.getId().toString());
    }

    // ------------------------------------------------------------------
    // DASH-TEST-020 â€” inactive current-subject guard
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-020: deactivated current subject yields currentSubject null")
    void inactiveCurrentSubjectIsHidden() throws Exception {
        Principal learner = principal("dashinact");
        Subject subject = subject("inact-subj", 5);
        setCurrentSubject(learner.userId(), subject.getId());
        jdbcTemplate.update("UPDATE subjects SET is_active = false WHERE id = ?",
                subject.getId());

        JsonNode root = MAPPER.readTree(dashboardBody(learner));
        assertThat(root.get("currentSubject").isNull()).isTrue();
        // Raw pointer stays visible in the learner section (spec section 8.2 note).
        assertThat(root.get("learner").get("currentSubjectId").asText())
                .isEqualTo(subject.getId().toString());
    }

    // ------------------------------------------------------------------
    // DASH-TEST-021 â€” deterministic ordering across repeated calls
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-021: two consecutive calls return identical bodies")
    void repeatedCallsAreIdentical() throws Exception {
        Principal learner = principal("dashstable");
        QuizWorld world = seedQuizWorld();
        perfectSubmission(learner.userId(), world);
        seedActivePath(learner.userId(), world.subject());

        String first = dashboardBody(learner);
        String second = dashboardBody(learner);
        assertThat(first).isEqualTo(second);
    }

    // ------------------------------------------------------------------
    // DASH-TEST-022 â€” collection bounds 3/5/5/5
    // ------------------------------------------------------------------


    @Test
    @DisplayName("DASH-TEST-022: recommendations<=3, recentTopics<=5, unlocks<=5, quizzes<=5")
    void collectionBoundsEnforced() throws Exception {
        Principal learner = principal("dashbounds");
        Subject subject = subject("bound-subj", 5);
        User user = user(learner.userId());

        for (int i = 1; i <= 6; i++) {
            Topic topic = topic("bd-" + i, subject);
            masteryRow(learner.userId(), topic, new BigDecimal("40.00"),
                    MasteryLevel.PROFICIENT, Difficulty.EASY, MasteryTrend.STABLE,
                    Instant.now().minusSeconds(i * 60L));
            recommendation(user, topic, i % 2 == 0 ? 2 : 1,
                    RecommendationActivityType.PRACTICE, Difficulty.EASY,
                    "BOUND_TEST_" + i, Instant.now().minusSeconds(i * 30L));
        }
        for (int i = 1; i <= 6; i++) {
            Achievement achievement = achievement("bd" + i);
            achievementRepository.save(achievement);
            unlock(user, achievement, Instant.now().minusSeconds(i * 120L));
        }
        for (int i = 1; i <= 7; i++) {
            rawAttempt(user, subject, QuizAttemptStatus.COMPLETED,
                    Instant.now().minusSeconds(i * 90L));
        }

        JsonNode root = MAPPER.readTree(dashboardBody(learner));
        assertThat(root.get("recommendations").size()).isEqualTo(3);
        assertThat(root.get("mastery").get("recentTopics").size()).isEqualTo(5);
        assertThat(root.get("achievements").get("recentUnlocks").size()).isEqualTo(5);
        assertThat(root.get("recentActivity").get("quizzes").size()).isEqualTo(5);
        // Counts are NOT bounded by the display slices.
        assertThat(root.get("mastery").get("topicsAssessed").asInt()).isEqualTo(6);
        assertThat(root.get("achievements").get("unlockedCount").asLong()).isEqualTo(6);
    }

    // ------------------------------------------------------------------
    // DASH-TEST-029 â€” exact contract: every field of section 8, no extras
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-029: rich fixture exposes EXACTLY the approved field set")
    void exactContractFieldScan() throws Exception {
        Principal learner = principal("dashcontract");
        QuizWorld world = seedQuizWorld();
        perfectSubmission(learner.userId(), world);
        seedActivePath(learner.userId(), world.subject());
        Achievement ach = achievement("ct");
        achievementRepository.save(ach);
        unlock(user(learner.userId()), ach, Instant.now());
        recommendation(user(learner.userId()), world.topic(), 1,
                RecommendationActivityType.QUIZ, Difficulty.MEDIUM,
                "CONTRACT_REASON", Instant.now());

        String body = dashboardBody(learner);
        JsonNode root = MAPPER.readTree(body);

        assertThat(fieldNames(root)).containsExactly(
                "learner", "currentSubject", "mastery", "gamification", "streak",
                "achievements", "recommendations", "learningPath", "assessment",
                "recentActivity");
        assertThat(fieldNames(root.get("learner"))).containsExactly(
                "displayName", "overallMastery", "currentSubjectId", "currentTopicId");
        assertThat(fieldNames(root.get("currentSubject"))).containsExactly(
                "id", "name", "iconKey", "currentTopic");
        assertThat(fieldNames(root.get("currentSubject").get("currentTopic")))
                .containsExactly("topicId", "topicName", "difficulty");
        assertThat(fieldNames(root.get("mastery"))).containsExactly(
                "topicsAssessed", "topicsMastered", "recentTopics");
        assertThat(fieldNames(root.get("mastery").get("recentTopics").get(0)))
                .containsExactly("topicId", "topicName", "masteryScore", "masteryLevel",
                        "currentDifficulty", "trend", "lastAssessedAt");
        assertThat(fieldNames(root.get("gamification"))).containsExactly(
                "totalXp", "currentLevel", "maxLevel", "nextLevelThresholdXp",
                "xpToNextLevel");
        assertThat(fieldNames(root.get("streak"))).containsExactly(
                "currentStreakDays", "longestStreakDays", "lastLearningDate", "timezone");
        assertThat(fieldNames(root.get("achievements"))).containsExactly(
                "unlockedCount", "recentUnlocks");
        assertThat(fieldNames(root.get("achievements").get("recentUnlocks").get(0)))
                .containsExactly("code", "name", "iconKey", "unlockedAt");
        assertThat(fieldNames(root.get("recommendations").get(0))).containsExactly(
                "topicId", "topicName", "activityType", "recommendedDifficulty",
                "priority", "reason", "generatedAt");
        assertThat(fieldNames(root.get("learningPath"))).containsExactly(
                "id", "subjectId", "subjectName", "title", "status", "generatedBy",
                "createdAt", "nodes");
        assertThat(fieldNames(root.get("learningPath").get("nodes").get(0)))
                .containsExactly("id", "topicId", "topicName", "sequenceNumber",
                        "requiredMastery", "status");
        assertThat(fieldNames(root.get("assessment"))).containsExactly("assessedSubjects");
        assertThat(fieldNames(root.get("assessment").get("assessedSubjects").get(0)))
                .containsExactly("subjectId", "subjectName");
        assertThat(fieldNames(root.get("recentActivity"))).containsExactly("quizzes");
        assertThat(fieldNames(root.get("recentActivity").get("quizzes").get(0)))
                .containsExactly("quizAttemptId", "topicId", "topicName", "score",
                        "correctCount", "totalQuestions", "submittedAt");

        // Forbidden material must never appear anywhere in the payload.
        assertThat(body).doesNotContain(learner.email());
        assertThat(body.toLowerCase()).doesNotContain("password");
        assertThat(body.toLowerCase()).doesNotContain("gemini");
        assertThat(body.toLowerCase()).doesNotContain("promptversion");
        assertThat(body.toLowerCase()).doesNotContain("aimetadata");
        assertThat(body.toLowerCase()).doesNotContain("correctanswer");
        assertThat(body.toLowerCase()).doesNotContain("explanation");
        assertThat(body.toLowerCase()).doesNotContain("$2a$");
    }

    // ------------------------------------------------------------------
    // DASH-TEST-030 â€” unexpected failure yields the safe 500 envelope
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-030: forced service failure maps to safe INTERNAL_ERROR envelope")
    void internalFailureProducesSafeEnvelope() throws Exception {
        doThrow(new RuntimeException("boom-secret-internals"))
                .when(dashboardService).dashboard(any());

        String body = mockMvc.perform(get("/api/v1/dashboard")
                        .header("Authorization",
                                "Bearer " + principal("dash500").token()))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.status").value(500))
                .andExpect(jsonPath("$.errorCode").value("INTERNAL_ERROR"))
                .andExpect(jsonPath("$.message").value("An unexpected internal error occurred"))
                .andExpect(jsonPath("$.path").value("/api/v1/dashboard"))
                .andExpect(jsonPath("$.requestId").isNotEmpty())
                .andReturn().getResponse().getContentAsString();

        assertThat(body).doesNotContain("boom-secret-internals");
    }

    // ------------------------------------------------------------------
    // DASH-TEST-031 â€” expired/garbled tokens are 401, not 500
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-031: expired and garbled tokens yield 401")
    void expiredAndGarbledTokensRejected() throws Exception {
        JwtProperties expiredProps = new JwtProperties();
        expiredProps.setSecret(jwtProperties.getSecret());
        expiredProps.setIssuer(jwtProperties.getIssuer());
        expiredProps.setExpirationMinutes(-5); // already expired at issuance
        JwtService expiredTokenService = new JwtService(expiredProps);

        Principal learner = principal("dashexpired");
        String expired = expiredTokenService.generateToken(
                learner.userId(), learner.email(), "Learner dashexpired");

        mockMvc.perform(get("/api/v1/dashboard").header("Authorization", "Bearer " + expired))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(get("/api/v1/dashboard")
                        .header("Authorization", "Bearer garbage.token.value"))
                .andExpect(status().isUnauthorized());
    }

    // ------------------------------------------------------------------
    // DASH-TEST-032 â€” method guard
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-032: POST/PUT/DELETE on /dashboard are 405 METHOD_NOT_ALLOWED")
    void methodGuardReturns405() throws Exception {
        Principal learner = principal("dashmethod");
        String bearer = "Bearer " + learner.token();

        mockMvc.perform(post("/api/v1/dashboard").header("Authorization", bearer))
                .andExpect(status().isMethodNotAllowed())
                .andExpect(jsonPath("$.errorCode").value("METHOD_NOT_ALLOWED"));
        mockMvc.perform(put("/api/v1/dashboard").header("Authorization", bearer))
                .andExpect(status().isMethodNotAllowed());
        mockMvc.perform(delete("/api/v1/dashboard").header("Authorization", bearer))
                .andExpect(status().isMethodNotAllowed());
    }

    // ------------------------------------------------------------------
    // DASH-TEST-033 â€” only COMPLETED attempts are listed
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-033: IN_PROGRESS/ABANDONED attempts are excluded by design")
    void incompleteAttemptsExcluded() throws Exception {
        Principal learner = principal("dashfilter");
        Subject subject = subject("filter-subj", 5);
        User user = user(learner.userId());

        rawAttempt(user, subject, QuizAttemptStatus.ABANDONED,
                Instant.parse("2026-08-23T23:00:00Z"));
        rawAttempt(user, subject, QuizAttemptStatus.IN_PROGRESS, null);
        QuizAttempt completed = rawAttempt(user, subject, QuizAttemptStatus.COMPLETED,
                Instant.parse("2026-08-22T12:00:00Z"));

        JsonNode quizzes = MAPPER.readTree(dashboardBody(learner))
                .get("recentActivity").get("quizzes");
        assertThat(quizzes).hasSize(1);
        assertThat(quizzes.get(0).get("quizAttemptId").asText())
                .isEqualTo(completed.getId().toString());
        assertThat(quizzes.get(0).get("submittedAt").asText())
                .isEqualTo("2026-08-22T12:00:00Z");
    }

    // ------------------------------------------------------------------
    // DASH-TEST-034 â€” defensive NULL-topic recommendation passthrough
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-034: null-topic recommendation renders with null ids, ordering intact")
    void nullTopicRecommendationDefense() throws Exception {
        Principal learner = principal("dashnulltopic");
        Subject subject = subject("nullt-subj", 5);
        Topic topic = topic("nullt-a", subject);
        recommendation(user(learner.userId()), topic, 2,
                RecommendationActivityType.PRACTICE, Difficulty.EASY,
                "NORMAL_TOPIC_REC", Instant.parse("2026-08-20T08:00:00Z"));
        recommendation(user(learner.userId()), null, 1,
                RecommendationActivityType.QUIZ, null,
                "NULL_TOPIC_REC", Instant.parse("2026-08-21T08:00:00Z"));

        JsonNode recs = MAPPER.readTree(dashboardBody(learner)).get("recommendations");
        assertThat(recs).hasSize(2);
        assertThat(recs.get(0).get("priority").asInt()).isEqualTo(1);
        assertThat(recs.get(0).get("topicId").isNull()).isTrue();
        assertThat(recs.get(0).get("topicName").isNull()).isTrue();
        assertThat(recs.get(0).get("recommendedDifficulty").isNull()).isTrue();
        assertThat(recs.get(0).get("reason").asText()).isEqualTo("NULL_TOPIC_REC");
        assertThat(recs.get(1).get("priority").asInt()).isEqualTo(2);
        assertThat(recs.get(1).get("topicName").asText()).isEqualTo(topic.getName());
    }

    // ------------------------------------------------------------------
    // DASH-TEST-035 â€” suspended account token rejected
    // ------------------------------------------------------------------

    @Test
    @DisplayName("DASH-TEST-035: suspended account gets 401 even with a valid token")
    void suspendedAccountRejected() throws Exception {
        Principal learner = principal("dashsuspend");
        jdbcTemplate.update("UPDATE users SET status='SUSPENDED' WHERE id=?", learner.userId());
        mockMvc.perform(get("/api/v1/dashboard")
                        .header("Authorization", "Bearer " + learner.token()))
                .andExpect(status().isUnauthorized());
    }

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------

    private String dashboardBody(Principal principal) throws Exception {
        return mockMvc.perform(get("/api/v1/dashboard")
                        .header("Authorization", "Bearer " + principal.token()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
    }

    private User user(UUID userId) {
        return userRepository.findById(userId).orElseThrow();
    }

    private Subject subject(String label, int displayOrder) {
        Subject subject = new Subject();
        subject.setName(label + "-" + UUID.randomUUID());
        subject.setDescription(label + " description");
        subject.setIconKey("icon_" + label);
        subject.setActive(true);
        subject.setDisplayOrder(displayOrder);
        return subjectRepository.saveAndFlush(subject);
    }

    private Topic topic(String label, Subject subject) {
        Topic topic = new Topic();
        topic.setSubject(subject);
        topic.setName(label + "-" + UUID.randomUUID());
        topic.setDescription(label + " description");
        topic.setDifficulty(Difficulty.EASY);
        topic.setDisplayOrder(1);
        topic.setActive(true);
        return topicRepository.saveAndFlush(topic);
    }

    private QuizWorld seedQuizWorld() {
        Subject subject = subject("w", 5);
        Topic topic = topic("wt", subject);
        Quiz quiz = new Quiz();
        quiz.setTopic(topic);
        quiz.setTitle("Dashboard Quiz " + UUID.randomUUID());
        quiz.setDescription("d");
        quiz.setDifficulty(Difficulty.MEDIUM);
        quiz.setSourceType(SourceType.CURATED);
        quiz.setTimeLimitSeconds(600);
        quiz.setActive(true);
        quiz = quizRepository.saveAndFlush(quiz);
        Question q1 = question("alpha", topic);
        Question q2 = question("beta", topic);
        associate(quiz, q1, 1);
        associate(quiz, q2, 2);
        return new QuizWorld(subject, topic, quiz, q1, q2);
    }

    private Question question(String correct, Topic topic) {
        Question question = new Question();
        question.setTopic(topic);
        question.setQuestionText("Answer " + correct + "?");
        question.setQuestionType(QuestionType.MCQ);
        question.setDifficulty(Difficulty.EASY);
        question.setOptionsJson("{\"options\":[\"" + correct + "\",\"wrong\"]}");
        question.setCorrectAnswer(correct);
        question.setExplanation("because");
        question.setSourceType(SourceType.CURATED);
        question.setActive(true);
        return questionRepository.save(question);
    }

    private void associate(Quiz quiz, Question question, int order) {
        QuizQuestion link = new QuizQuestion();
        link.setQuiz(quiz);
        link.setQuestion(question);
        link.setQuestionOrder(order);
        quizQuestionRepository.save(link);
    }

    /** Runs the real QUIZ-002 pipeline: adaptive state + XP + achievements. */
    private void perfectSubmission(UUID userId, QuizWorld world) {
        quizSubmissionService.submit(userId, world.quiz().getId(),
                new QuizSubmissionRequest(List.of(
                        new QuizSubmissionRequest.SubmittedAnswer(world.q1().getId(), "alpha"),
                        new QuizSubmissionRequest.SubmittedAnswer(world.q2().getId(), "beta"))));
    }

    private void masteryRow(UUID userId, Topic topic, BigDecimal score, MasteryLevel level,
                            Difficulty difficulty, MasteryTrend trend, Instant lastAssessedAt) {
        TopicMastery mastery = new TopicMastery();
        mastery.setUser(user(userId));
        mastery.setTopic(topic);
        mastery.setMasteryScore(score);
        mastery.setMasteryLevel(level);
        mastery.setCurrentDifficulty(difficulty);
        mastery.setAttemptCount(1);
        mastery.setRecentAccuracy(score);
        mastery.setTrend(trend);
        mastery.setLastAssessedAt(lastAssessedAt);
        topicMasteryRepository.saveAndFlush(mastery);
    }

    private void recommendation(User user, Topic topic, int priority,
                                RecommendationActivityType activityType, Difficulty difficulty,
                                String reason, Instant generatedAt) {
        Recommendation recommendation = new Recommendation();
        recommendation.setUser(user);
        recommendation.setTopic(topic);
        recommendation.setActivityType(activityType);
        recommendation.setRecommendedDifficulty(difficulty);
        recommendation.setReason(reason);
        recommendation.setPriority(priority);
        recommendation.setStatus(RecommendationStatus.ACTIVE);
        recommendation.setGeneratedAt(generatedAt);
        recommendationRepository.save(recommendation);
    }

    private Achievement achievement(String label) {
        Achievement achievement = new Achievement();
        achievement.setCode(label.toUpperCase() + "_" + UUID.randomUUID());
        achievement.setName(label + " Achievement");
        achievement.setDescription(label + " description");
        achievement.setIconKey("achievement_" + label);
        achievement.setRuleType("THRESHOLD");
        achievement.setRuleConfigJson("{\"threshold\":100}");
        achievement.setXpReward(50);
        achievement.setActive(true);
        return achievement;
    }

    private void unlock(User user, Achievement achievement, Instant unlockedAt) {
        UserAchievement unlock = new UserAchievement();
        unlock.setUser(user);
        unlock.setAchievement(achievement);
        unlock.setUnlockedAt(unlockedAt);
        userAchievementRepository.save(unlock);
    }

    /**
     * Persists a path with ordered nodes, then pins created_at via SQL so the
     * deterministic created_at DESC / id ASC selection is test-controlled.
     */
    private LearningPath pathWithNodes(UUID userId, Subject subject,
                                       LearningPathStatus status, List<Topic> topics,
                                       Instant createdAt, String title,
                                       boolean lockSecondNode) {
        LearningPath path = new LearningPath();
        path.setUser(user(userId));
        path.setSubject(subject);
        path.setTitle(title);
        path.setStatus(status);
        path.setGeneratedBy(GeneratedBy.SYSTEM);
        path = learningPathRepository.saveAndFlush(path);
        jdbcTemplate.update("UPDATE learning_paths SET created_at=? WHERE id=?",
                Timestamp.from(createdAt), path.getId());
        int sequence = 1;
        for (Topic topic : topics) {
            LearningPathNode node = new LearningPathNode();
            node.setLearningPath(path);
            node.setTopic(topic);
            node.setSequenceNumber(sequence);
            node.setRequiredMastery(sequence == 1
                    ? BigDecimal.ZERO : new BigDecimal("40.00"));
            node.setStatus(sequence == 1 || !lockSecondNode
                    ? PathNodeStatus.AVAILABLE : PathNodeStatus.LOCKED);
            learningPathNodeRepository.save(node);
            sequence++;
        }
        learningPathNodeRepository.flush();
        return path;
    }

    private LearningPath seedActivePath(UUID userId, Subject subject) {
        return pathWithNodes(userId, subject, LearningPathStatus.ACTIVE,
                List.of(topic("sap-" + UUID.randomUUID(), subject)),
                Instant.now(), "Active Path " + UUID.randomUUID(), false);
    }

    private void setCurrentSubject(UUID userId, UUID subjectId) {
        jdbcTemplate.update(
                "UPDATE learner_profiles SET current_subject_id=? WHERE user_id=?",
                subjectId, userId);
    }

    private QuizAttempt rawAttempt(User user, Subject subject, QuizAttemptStatus status,
                                   Instant submittedAt) {
        Topic topic = topic("att-" + UUID.randomUUID(), subject);
        Quiz quiz = new Quiz();
        quiz.setTopic(topic);
        quiz.setTitle("Attempt Quiz " + UUID.randomUUID());
        quiz.setDifficulty(Difficulty.EASY);
        quiz.setSourceType(SourceType.CURATED);
        quiz.setActive(true);
        quiz = quizRepository.saveAndFlush(quiz);
        QuizAttempt attempt = new QuizAttempt();
        attempt.setQuiz(quiz);
        attempt.setUser(user);
        attempt.setScore(new BigDecimal("75.00"));
        attempt.setCorrectCount(3);
        attempt.setTotalQuestions(4);
        attempt.setDifficultyAtAttempt(Difficulty.EASY);
        attempt.setStartedAt(submittedAt == null
                ? Instant.now() : submittedAt.minusSeconds(60));
        attempt.setSubmittedAt(submittedAt);
        attempt.setStatus(status);
        return attemptRepository.saveAndFlush(attempt);
    }
}
