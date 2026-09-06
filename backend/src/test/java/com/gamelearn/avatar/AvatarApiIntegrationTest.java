package com.gamelearn.avatar;

import static org.assertj.core.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import java.math.BigDecimal;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamelearn.dto.AuthResponse;
import com.gamelearn.dto.RegisterRequest;
import com.gamelearn.entity.Avatar;
import com.gamelearn.entity.LearnerProfile;
import com.gamelearn.entity.Progress;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.XpTransaction;
import com.gamelearn.entity.enums.ProgressStatus;
import com.gamelearn.gamification.LeaderboardRateLimiter;
import com.gamelearn.persistence.PersistenceTestFixtures;
import com.gamelearn.repository.AvatarRepository;
import com.gamelearn.repository.LearnerProfileRepository;
import com.gamelearn.repository.ProgressRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.XpTransactionRepository;
import com.gamelearn.service.AuthService;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@org.springframework.transaction.annotation.Transactional
class AvatarApiIntegrationTest {

    @Autowired MockMvc mockMvc;
    @Autowired AuthService authService;
    @Autowired AvatarRepository avatarRepository;
    @Autowired LearnerProfileRepository learnerProfileRepository;
    @Autowired ProgressRepository progressRepository;
    @Autowired SubjectRepository subjectRepository;
    @Autowired TopicRepository topicRepository;
    @Autowired XpTransactionRepository xpTransactionRepository;
    @Autowired JdbcTemplate jdbcTemplate;
    @Autowired LeaderboardRateLimiter rateLimiter;
    @Autowired ObjectMapper objectMapper;
    @Autowired com.gamelearn.repository.UserCreditRepository userCreditRepository;
    @Autowired jakarta.persistence.EntityManager entityManager;

    @BeforeEach
    void clear() { rateLimiter.clearAll(); }

    private AuthResponse register(String label) {
        return authService.register(new RegisterRequest(label + "-" + UUID.randomUUID() + "@example.test", "Str0ng-Passw0rd!", "Learner " + label));
    }

    private void setLevel(UUID userId, int level) {
        entityManager.flush();
        jdbcTemplate.update("UPDATE learner_profiles SET current_level=? WHERE user_id=?", level, userId.toString());
        entityManager.clear();
    }

    private void giveCredits(UUID userId, int amount) {
        var ucOpt = userCreditRepository.findByUserId(userId);
        if (ucOpt.isPresent()) {
            var uc = ucOpt.get();
            uc.setBalance(amount);
            userCreditRepository.saveAndFlush(uc);
        } else {
            // fallback via jdbc if not visible yet, but use repository to create
            var user = learnerProfileRepository.findByUserId(userId).orElseThrow().getUser();
            var uc = new com.gamelearn.entity.UserCredit();
            uc.setUser(user);
            uc.setBalance(amount);
            userCreditRepository.saveAndFlush(uc);
        }
    }

    private Avatar findAvatarByCode(String code) {
        return avatarRepository.findByCode(code).orElseGet(() -> {
            // search by prefix containing code
            return avatarRepository.findByActiveTrueOrderByDisplayOrderAscIdAsc().stream()
                    .filter(a -> a.getCode().contains(code)).findFirst().orElseThrow();
        });
    }

    @Test
    void AV01_catalogReturnsActive() throws Exception {
        AuthResponse me = register("av01");
        mockMvc.perform(get("/api/v1/avatars").header("Authorization", "Bearer " + me.token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].code").exists())
                .andExpect(jsonPath("$").isArray());
        String json = mockMvc.perform(get("/api/v1/avatars").header("Authorization", "Bearer " + me.token())).andReturn().getResponse().getContentAsString();
        JsonNode arr = objectMapper.readTree(json);
        assertThat(arr.size()).isGreaterThanOrEqualTo(24);
        for (JsonNode n : arr) assertThat(n.get("isActive").asBoolean()).isTrue();
    }

    @Test
    void AV03_collectionReturnsBalance() throws Exception {
        AuthResponse me = register("av03");
        giveCredits(me.user().id(), 5000);
        mockMvc.perform(get("/api/v1/avatars/me").header("Authorization", "Bearer " + me.token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.creditsAvailable").value(5000))
                .andExpect(jsonPath("$.items").isArray());
    }

    @Test
    void AV05_purchaseSucceeds() throws Exception {
        AuthResponse me = register("av05");
        setLevel(me.user().id(), 10);
        Avatar av = findAvatarByCode("common_lumen_coder");
        giveCredits(me.user().id(), av.getCreditCost() + 100);
        mockMvc.perform(post("/api/v1/avatars/" + av.getId() + "/purchase").header("Authorization", "Bearer " + me.token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[?(@.id=='" + av.getId() + "')].owned").value(true));
    }

    @Test
    void AV08_inactivePurchaseRejected() throws Exception {
        AuthResponse me = register("av08");
        // pick a purchasable common avatar to test inactive rejection
        Avatar av = findAvatarByCode("common_pixel_pilot");
        av.setActive(false); avatarRepository.saveAndFlush(av);
        mockMvc.perform(post("/api/v1/avatars/" + av.getId() + "/purchase").header("Authorization", "Bearer " + me.token()))
                .andExpect(status().isNotFound());
        av.setActive(true); avatarRepository.saveAndFlush(av);
    }

    @Test
    void AV09_thresholdUnmet403() throws Exception {
        AuthResponse me = register("av09");
        Avatar leg = findAvatarByCode("legendary_db_oracle");
        mockMvc.perform(post("/api/v1/avatars/" + leg.getId() + "/claim").header("Authorization", "Bearer " + me.token()))
                .andExpect(status().isForbidden());
    }

    @Test
    void AV10_exact70ClaimSucceeds() throws Exception {
        AuthResponse me = register("av10");
        // create isolated subject with exactly 10 topics
        Subject subj = new Subject(); subj.setName("AV10Subj-" + UUID.randomUUID()); subj.setDescription("av10"); subj.setIconKey("icon_av10"); subj.setActive(true); subj.setDisplayOrder(99);
        subj = subjectRepository.save(subj);
        Avatar leg = new Avatar(); leg.setCode("av10-leg-" + UUID.randomUUID()); leg.setDisplayName("AV10 Leg"); leg.setDescription("av10 leg"); leg.setRarity("LEGENDARY"); leg.setHomeSubject(subj); leg.setAssetKey("characters/av10_leg"); leg.setRequirementJson("{\"levelMin\":18,\"syllabusCompletionMin\":70.0,\"syllabusSubjectId\":\"" + subj.getId() + "\",\"bossBattlesMin\":5,\"streakCurrentMin\":7,\"masteredCountMin\":2}"); leg.setActive(true); leg.setDisplayOrder(99);
        leg = avatarRepository.save(leg);
        for (int i=0;i<10;i++) {
            Topic t = new Topic(); t.setSubject(subj); t.setName("T" + i + "-" + UUID.randomUUID()); t.setDescription("d"); t.setDifficulty(com.gamelearn.entity.enums.Difficulty.EASY); t.setDisplayOrder(i); t.setActive(true);
            t = topicRepository.save(t);
            if (i < 7) {
                Progress p = new Progress(); p.setUser(learnerProfileRepository.findByUserId(me.user().id()).orElseThrow().getUser()); p.setTopic(t); p.setStatus(ProgressStatus.COMPLETED); p.setCompletionPercentage(new BigDecimal("100.00")); p.setLastActivityAt(java.time.Instant.now()); p.setCompletedAt(java.time.Instant.now());
                progressRepository.save(p);
            }
        }
        setLevel(me.user().id(), 18);
        jdbcTemplate.update("DELETE FROM streaks WHERE user_id=?", me.user().id().toString());
        jdbcTemplate.update("INSERT INTO streaks (id, user_id, current_streak_days, longest_streak_days, last_learning_date, timezone, created_at, updated_at) VALUES (?,?,?,?,?,?,?,?)",
                UUID.randomUUID().toString(), me.user().id().toString(), 7, 7, java.sql.Date.valueOf(java.time.LocalDate.now()), "UTC", java.sql.Timestamp.from(java.time.Instant.now()), java.sql.Timestamp.from(java.time.Instant.now()));
        for (int i=0;i<5;i++) {
            jdbcTemplate.update("INSERT INTO game_results (id, user_id, game_type, client_request_id, completed, score, duration_seconds, best_combo, xp_awarded, played_at, created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?)",
                    UUID.randomUUID().toString(), me.user().id().toString(), "BOSS_BATTLE", UUID.randomUUID().toString(), true, 100, 30, 2, 10, java.sql.Timestamp.from(java.time.Instant.now()), java.sql.Timestamp.from(java.time.Instant.now()));
        }
        Topic t1 = topicRepository.findBySubjectIdAndActiveTrueOrderByDisplayOrderAscIdAsc(subj.getId()).get(0);
        jdbcTemplate.update("INSERT INTO topic_mastery (id, user_id, topic_id, mastery_score, mastery_level, current_difficulty, attempt_count, recent_accuracy, trend, last_assessed_at, created_at, updated_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
                UUID.randomUUID().toString(), me.user().id().toString(), t1.getId().toString(), new BigDecimal("90"), "MASTERED", "MEDIUM", 1, new BigDecimal("90"), "IMPROVING", java.sql.Timestamp.from(java.time.Instant.now()), java.sql.Timestamp.from(java.time.Instant.now()), java.sql.Timestamp.from(java.time.Instant.now()));
        Topic t2 = topicRepository.findBySubjectIdAndActiveTrueOrderByDisplayOrderAscIdAsc(subj.getId()).get(1);
        jdbcTemplate.update("INSERT INTO topic_mastery (id, user_id, topic_id, mastery_score, mastery_level, current_difficulty, attempt_count, recent_accuracy, trend, last_assessed_at, created_at, updated_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
                UUID.randomUUID().toString(), me.user().id().toString(), t2.getId().toString(), new BigDecimal("90"), "MASTERED", "MEDIUM", 1, new BigDecimal("90"), "IMPROVING", java.sql.Timestamp.from(java.time.Instant.now()), java.sql.Timestamp.from(java.time.Instant.now()), java.sql.Timestamp.from(java.time.Instant.now()));

        mockMvc.perform(post("/api/v1/avatars/" + leg.getId() + "/claim").header("Authorization", "Bearer " + me.token()))
                .andExpect(status().isOk());
    }

    @Test
    void AV12_claimDoesNotDeductCredits() throws Exception {
        AuthResponse me = register("av12");
        Subject subj = new Subject(); subj.setName("AV12Subj-" + UUID.randomUUID()); subj.setDescription("av12"); subj.setIconKey("icon_av12"); subj.setActive(true); subj.setDisplayOrder(99);
        subj = subjectRepository.save(subj);
        Avatar epic = new Avatar(); epic.setCode("av12-epic-" + UUID.randomUUID()); epic.setDisplayName("AV12 Epic"); epic.setDescription("av12 epic"); epic.setRarity("EPIC"); epic.setHomeSubject(subj); epic.setAssetKey("characters/av12_epic"); epic.setRequirementJson("{\"levelMin\":12,\"syllabusCompletionMin\":50.0,\"syllabusSubjectId\":\"" + subj.getId() + "\",\"streakCurrentMin\":7}"); epic.setActive(true); epic.setDisplayOrder(99);
        epic = avatarRepository.save(epic);
        for (int i=0;i<4;i++) {
            Topic t = new Topic(); t.setSubject(subj); t.setName("Tep" + i + "-" + UUID.randomUUID()); t.setDescription("d"); t.setDifficulty(com.gamelearn.entity.enums.Difficulty.EASY); t.setDisplayOrder(100+i); t.setActive(true);
            t = topicRepository.save(t);
            if (i < 2) {
                Progress p = new Progress(); p.setUser(learnerProfileRepository.findByUserId(me.user().id()).orElseThrow().getUser()); p.setTopic(t); p.setStatus(ProgressStatus.COMPLETED); p.setCompletionPercentage(new BigDecimal("100.00")); p.setLastActivityAt(java.time.Instant.now()); p.setCompletedAt(java.time.Instant.now());
                progressRepository.save(p);
            }
        }
        setLevel(me.user().id(), 12);
        jdbcTemplate.update("DELETE FROM streaks WHERE user_id=?", me.user().id().toString());
        jdbcTemplate.update("INSERT INTO streaks (id, user_id, current_streak_days, longest_streak_days, last_learning_date, timezone, created_at, updated_at) VALUES (?,?,?,?,?,?,?,?)",
                UUID.randomUUID().toString(), me.user().id().toString(), 7, 7, java.sql.Date.valueOf(java.time.LocalDate.now()), "UTC", java.sql.Timestamp.from(java.time.Instant.now()), java.sql.Timestamp.from(java.time.Instant.now()));
        giveCredits(me.user().id(), 1000);
        mockMvc.perform(post("/api/v1/avatars/" + epic.getId() + "/claim").header("Authorization", "Bearer " + me.token()))
                .andExpect(status().isOk());
        String json = mockMvc.perform(get("/api/v1/avatars/me").header("Authorization", "Bearer " + me.token())).andReturn().getResponse().getContentAsString();
        int bal = objectMapper.readTree(json).get("creditsAvailable").asInt();
        assertThat(bal).isEqualTo(1000);
    }

    @Test
    void AV20_equipOwnedSucceeds() throws Exception {
        AuthResponse me = register("av20");
        setLevel(me.user().id(), 10);
        Avatar av = findAvatarByCode("common_logic_leaf");
        giveCredits(me.user().id(), 5000);
        mockMvc.perform(post("/api/v1/avatars/" + av.getId() + "/purchase").header("Authorization", "Bearer " + me.token())).andExpect(status().isOk());
        mockMvc.perform(post("/api/v1/profile/avatar").header("Authorization", "Bearer " + me.token()).contentType(MediaType.APPLICATION_JSON).content("{\"avatarId\":\"" + av.getId() + "\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.equippedAvatarId").value(av.getId().toString()));
    }

    @Test
    void AV21_equipUnowned403() throws Exception {
        AuthResponse me = register("av21");
        Avatar av = findAvatarByCode("common_pixel_pilot");
        mockMvc.perform(post("/api/v1/profile/avatar").header("Authorization", "Bearer " + me.token()).contentType(MediaType.APPLICATION_JSON).content("{\"avatarId\":\"" + av.getId() + "\"}"))
                .andExpect(status().isForbidden());
    }

    @Test
    void AV24_unequipNull() throws Exception {
        AuthResponse me = register("av24");
        setLevel(me.user().id(), 10);
        Avatar av = findAvatarByCode("common_bit_bloom");
        giveCredits(me.user().id(), 5000);
        mockMvc.perform(post("/api/v1/avatars/" + av.getId() + "/purchase").header("Authorization", "Bearer " + me.token())).andExpect(status().isOk());
        mockMvc.perform(post("/api/v1/profile/avatar").header("Authorization", "Bearer " + me.token()).contentType(MediaType.APPLICATION_JSON).content("{\"avatarId\":\"" + av.getId() + "\"}")).andExpect(status().isOk());
        mockMvc.perform(post("/api/v1/profile/avatar").header("Authorization", "Bearer " + me.token()).contentType(MediaType.APPLICATION_JSON).content("{\"avatarId\":null}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.equippedAvatarId").doesNotExist());
        mockMvc.perform(get("/api/v1/profile/avatar").header("Authorization", "Bearer " + me.token()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.avatar.assetKey").value("characters/nova_spark"));
    }

    @Test
    void SEC_AV01_unauth() throws Exception {
        mockMvc.perform(get("/api/v1/avatars")).andExpect(status().isUnauthorized());
        mockMvc.perform(get("/api/v1/avatars/me")).andExpect(status().isUnauthorized());
    }

    @Test
    void SEC_AV05_noRawRequirementJson() throws Exception {
        AuthResponse me = register("sec05");
        mockMvc.perform(get("/api/v1/avatars").header("Authorization", "Bearer " + me.token()))
                .andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.not(org.hamcrest.Matchers.containsString("requirement_json"))));
    }
}

