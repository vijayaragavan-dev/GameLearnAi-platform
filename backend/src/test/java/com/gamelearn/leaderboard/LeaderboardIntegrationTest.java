package com.gamelearn.leaderboard;

import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import org.hamcrest.Matchers;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import com.gamelearn.dto.AuthResponse;
import com.gamelearn.dto.RegisterRequest;
import com.gamelearn.entity.LearnerProfile;
import com.gamelearn.entity.Quiz;
import com.gamelearn.entity.QuizAttempt;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.XpTransaction;
import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.entity.enums.QuizAttemptStatus;
import com.gamelearn.gamification.LeaderboardRateLimiter;
import com.gamelearn.persistence.PersistenceTestFixtures;
import com.gamelearn.repository.LearnerProfileRepository;
import com.gamelearn.repository.QuizAttemptRepository;
import com.gamelearn.repository.QuizRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.UserRepository;
import com.gamelearn.repository.XpTransactionRepository;
import com.gamelearn.service.AuthService;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@org.springframework.transaction.annotation.Transactional
class LeaderboardIntegrationTest {

    @Autowired MockMvc mockMvc;
    @Autowired AuthService authService;
    @Autowired UserRepository userRepository;
    @Autowired LearnerProfileRepository learnerProfileRepository;
    @Autowired SubjectRepository subjectRepository;
    @Autowired TopicRepository topicRepository;
    @Autowired QuizRepository quizRepository;
    @Autowired QuizAttemptRepository quizAttemptRepository;
    @Autowired XpTransactionRepository xpTransactionRepository;
    @Autowired JdbcTemplate jdbcTemplate;
    @Autowired LeaderboardRateLimiter rateLimiter;

    @BeforeEach
    void clearLimiter() { rateLimiter.clearAll(); }

    private AuthResponse register(String label) {
        return authService.register(new RegisterRequest(
                label + "-" + UUID.randomUUID() + "@example.test",
                "Str0ng-Passw0rd!", "Learner " + label));
    }

    private void setXp(UUID userId, int totalXp) {
        LearnerProfile p = learnerProfileRepository.findByUserId(userId).orElseThrow();
        p.setTotalXp(totalXp);
        learnerProfileRepository.saveAndFlush(p);
    }

    private void setCreatedAt(UUID userId, Instant instant) {
        // Direct SQL because BaseEntity createdAt is @CreationTimestamp updatable=false, JPA won't update via entity
        jdbcTemplate.update("UPDATE users SET created_at=? WHERE id=?", Timestamp.from(instant), userId.toString());
        jdbcTemplate.update("UPDATE learner_profiles SET created_at=? WHERE user_id=?", Timestamp.from(instant), userId.toString());
        // also flush JPA cache
        userRepository.flush();
        learnerProfileRepository.flush();
    }

    private Subject ensureSubject(String name) {
        var existing = subjectRepository.findAll().stream().filter(s -> s.getName().equals(name)).findFirst();
        if (existing.isPresent()) return existing.get();
        Subject s = new Subject(); s.setName(name + "-" + UUID.randomUUID()); s.setDescription("test"); s.setIconKey("icon_test"); s.setActive(true); s.setDisplayOrder(99);
        return subjectRepository.save(s);
    }

    // helper to create subject XP via xp transaction linked to quiz attempt
    private void addSubjectXp(UUID userId, Subject subject, int amount) {
        // find or create topic+quiz for subject
        Topic topic = topicRepository.findBySubjectIdAndActiveTrueOrderByDisplayOrderAscIdAsc(subject.getId()).stream().findFirst().orElseGet(() -> {
            Topic t = PersistenceTestFixtures.topic("LBTopic", subject);
            return topicRepository.save(t);
        });
        Quiz quiz = quizRepository.findAll().stream().filter(q -> q.getTopic().getId().equals(topic.getId())).findFirst().orElseGet(() -> {
            Quiz q = PersistenceTestFixtures.quiz("LBQuiz", topic);
            return quizRepository.save(q);
        });
        // create quiz attempt
        QuizAttempt qa = new QuizAttempt();
        qa.setQuiz(quiz);
        qa.setUser(userRepository.findById(userId).orElseThrow());
        qa.setScore(BigDecimal.valueOf(80));
        qa.setCorrectCount(4); qa.setTotalQuestions(5);
        qa.setDifficultyAtAttempt(Difficulty.MEDIUM);
        qa.setStartedAt(Instant.now()); qa.setSubmittedAt(Instant.now()); qa.setDurationSeconds(30);
        qa.setStatus(QuizAttemptStatus.COMPLETED);
        qa = quizAttemptRepository.save(qa);
        XpTransaction xp = new XpTransaction();
        xp.setUser(userRepository.findById(userId).orElseThrow());
        xp.setAmount(amount);
        xp.setEventType(com.gamelearn.entity.enums.XpEventType.QUIZ_COMPLETED);
        xp.setReferenceType("QUIZ_ATTEMPT");
        xp.setReferenceId(qa.getId());
        xp.setDescription("LB subject xp");
        xpTransactionRepository.save(xp);
        // also update total_xp to keep consistent? For overall vs subject difference we keep separate: overall total_xp not automatically updated from subject xp in this helper; we set overall separately via setXp.
    }

    @Test
    void LB01_overallOrderingByXpDesc() throws Exception {
        AuthResponse a = register("lb01a"); AuthResponse b = register("lb01b"); AuthResponse c = register("lb01c");
        setXp(a.user().id(), 90000); setXp(b.user().id(), 80000); setXp(c.user().id(), 100000);
        assertThat(learnerProfileRepository.findByUserId(a.user().id()).orElseThrow().getTotalXp()).isEqualTo(90000);
        assertThat(learnerProfileRepository.findByUserId(b.user().id()).orElseThrow().getTotalXp()).isEqualTo(80000);
        assertThat(learnerProfileRepository.findByUserId(c.user().id()).orElseThrow().getTotalXp()).isEqualTo(100000);
        // verify via position ranks
        int rankC = extractRank(c.token());
        int rankA = extractRank(a.token());
        int rankB = extractRank(b.token());
        assertThat(rankC).isLessThan(rankA);
        assertThat(rankA).isLessThan(rankB);
    }

    @Test
    void LB02_xpTieUsesCreatedAtAsc() throws Exception {
        AuthResponse a = register("lb02a"); AuthResponse b = register("lb02b");
        Instant early = Instant.now().minusSeconds(3600);
        Instant late = Instant.now();
        setXp(a.user().id(), 90000); setXp(b.user().id(), 90000);
        setCreatedAt(a.user().id(), early); setCreatedAt(b.user().id(), late);
        // verify rank order via position (more robust than absolute entries with shared DB)
        mockMvc.perform(get("/api/v1/me/leaderboard-position?segment=OVERALL").header("Authorization", "Bearer " + a.token()))
                .andExpect(status().isOk()).andExpect(jsonPath("$.rank").isNumber());
        mockMvc.perform(get("/api/v1/me/leaderboard-position?segment=OVERALL").header("Authorization", "Bearer " + b.token()))
                .andExpect(status().isOk()).andExpect(jsonPath("$.rank").isNumber());
        // a should rank before b
        int rankA = extractRank(a.token());
        int rankB = extractRank(b.token());
        assertThat(rankA).isLessThan(rankB);
    }

    @Test
    void LB04_currentUserRankComputed() throws Exception {
        AuthResponse a = register("lb04a"); AuthResponse b = register("lb04b");
        setXp(a.user().id(), 50000); setXp(b.user().id(), 60000);
        int rankA = extractRank(a.token());
        int rankB = extractRank(b.token());
        assertThat(rankB).isLessThan(rankA);
        mockMvc.perform(get("/api/v1/leaderboard/overall").header("Authorization", "Bearer " + a.token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.me.totalXp").value(50000));
    }

    @Test
    void LB05_outsidePageStillReturnsMe() throws Exception {
        AuthResponse a = register("lb05a");
        for (int i=0;i<5;i++) { AuthResponse x = register("lb05x"+i); setXp(x.user().id(), 1000 + i*100); }
        setXp(a.user().id(), 10);
        mockMvc.perform(get("/api/v1/leaderboard/overall?page=1&size=2").header("Authorization", "Bearer " + a.token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.entries.length()").value(2))
                .andExpect(jsonPath("$.me").exists())
                .andExpect(jsonPath("$.me.totalXp").value(10));
    }

    @Test
    void LB06_nearbyCorrect() throws Exception {
        AuthResponse me = register("lb06me");
        setXp(me.user().id(), 500);
        for (int i=0;i<4;i++) { AuthResponse x = register("lb06x"+i); setXp(x.user().id(), 400 + i*50); } // 400,450,550,600
        // ordering: 600,550,500(me),450,400
        mockMvc.perform(get("/api/v1/leaderboard/overall").header("Authorization", "Bearer " + me.token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.nearby").isArray())
                .andExpect(jsonPath("$.nearby[?(@.isMe==true)]").exists());
    }

    @Test
    void LB07_topCorrect() throws Exception {
        AuthResponse a = register("lb07a"); setXp(a.user().id(), 100);
        for (int i=0;i<5;i++) { AuthResponse x = register("lb07x"+i); setXp(x.user().id(), 90000+i); }
        mockMvc.perform(get("/api/v1/leaderboard/overall?includeTop=true").header("Authorization", "Bearer " + a.token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.top").isArray())
                .andExpect(jsonPath("$.top.length()").value(org.hamcrest.Matchers.greaterThanOrEqualTo(3)));
    }

    @Test
    void LB08_paginationCorrect() throws Exception {
        for (int i=0;i<8;i++) { AuthResponse x = register("lb08x"+i); setXp(x.user().id(), 100+i); }
        AuthResponse me = register("lb08me"); setXp(me.user().id(), 50);
        mockMvc.perform(get("/api/v1/leaderboard/overall?page=2&size=3").header("Authorization", "Bearer " + me.token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.page").value(2))
                .andExpect(jsonPath("$.size").value(3))
                .andExpect(jsonPath("$.entries.length()").value(3));
    }

    @Test
    void LB09_subjectUsesSubjectScoreNotTotalXp() throws Exception {
        Subject subj = ensureSubject("LB09Subj");
        AuthResponse a = register("lb09a"); AuthResponse b = register("lb09b");
        setXp(a.user().id(), 100); setXp(b.user().id(), 1000); // b higher overall
        addSubjectXp(a.user().id(), subj, 500); // a higher subject
        addSubjectXp(b.user().id(), subj, 100);
        mockMvc.perform(get("/api/v1/leaderboard/subject/" + subj.getId()).header("Authorization", "Bearer " + a.token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.entries[0].displayName").value(a.user().displayName()))
                .andExpect(jsonPath("$.entries[0].subjectXp").value(500));
    }

    @Test
    void LB12_emptyLeaderboard() throws Exception {
        // use a fresh subject with no activity
        Subject subj = ensureSubject("LB12Empty");
        AuthResponse me = register("lb12me");
        mockMvc.perform(get("/api/v1/leaderboard/subject/" + subj.getId()).header("Authorization", "Bearer " + me.token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.entries").isArray())
                .andExpect(jsonPath("$.totalPlayers").value(0));
    }

    @Test
    void LB13_newUserZeroXp() throws Exception {
        AuthResponse me = register("lb13me");
        setXp(me.user().id(), 0);
        mockMvc.perform(get("/api/v1/leaderboard/overall").header("Authorization", "Bearer " + me.token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.me.totalXp").value(0))
                .andExpect(jsonPath("$.me.rank").isNumber());
    }

    @Test
    void LB15_invalidSubjectReturns404() throws Exception {
        AuthResponse me = register("lb15me");
        mockMvc.perform(get("/api/v1/leaderboard/subject/" + UUID.randomUUID()).header("Authorization", "Bearer " + me.token()))
                .andExpect(status().isNotFound());
    }

    @Test
    void LB16_invalidPaginationRejected() throws Exception {
        AuthResponse me = register("lb16me");
        mockMvc.perform(get("/api/v1/leaderboard/overall?page=0&size=20").header("Authorization", "Bearer " + me.token()))
                .andExpect(status().isBadRequest());
        mockMvc.perform(get("/api/v1/leaderboard/overall?page=1&size=100").header("Authorization", "Bearer " + me.token()))
                .andExpect(status().isBadRequest());
    }

    @Test
    void LB18_emailAbsent() throws Exception {
        AuthResponse me = register("lb18me");
        mockMvc.perform(get("/api/v1/leaderboard/overall").header("Authorization", "Bearer " + me.token()))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.not(org.hamcrest.Matchers.containsString("email"))))
                .andExpect(content().string(org.hamcrest.Matchers.not(org.hamcrest.Matchers.containsString("password"))));
    }

    @Test
    void LB19_avatarDefaultSafe() throws Exception {
        AuthResponse me = register("lb19me");
        mockMvc.perform(get("/api/v1/leaderboard/overall").header("Authorization", "Bearer " + me.token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.me.avatar.assetKey").value("characters/nova_spark"));
    }

    @Test
    void LB20_unsupportedSeasonRejected() throws Exception {
        AuthResponse me = register("lb20me");
        mockMvc.perform(get("/api/v1/leaderboard/overall?season=2025-Q1").header("Authorization", "Bearer " + me.token()))
                .andExpect(status().isBadRequest());
    }

    @Test
    void SECLB02_unauthenticatedRejected() throws Exception {
        mockMvc.perform(get("/api/v1/leaderboard/overall"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void positionEndpoint() throws Exception {
        AuthResponse me = register("lbPosMe"); setXp(me.user().id(), 200);
        AuthResponse other = register("lbPosOther"); setXp(other.user().id(), 400);
        mockMvc.perform(get("/api/v1/me/leaderboard-position?segment=OVERALL").header("Authorization", "Bearer " + me.token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.top").isArray());
    }

    private int extractRank(String token) throws Exception {
        String json = mockMvc.perform(get("/api/v1/me/leaderboard-position?segment=OVERALL").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        com.fasterxml.jackson.databind.ObjectMapper om = new com.fasterxml.jackson.databind.ObjectMapper();
        return om.readTree(json).get("rank").asInt();
    }
}
