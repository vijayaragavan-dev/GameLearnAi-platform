package com.gamelearn.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
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

/**
 * Phase QA-6B: generic explicit topic-completion upsert
 * (PUT /api/v1/progress/{topicId}).
 *
 * <p>Covers authentication, first completion, idempotent repetition, user
 * isolation, unknown topics, invalid states, QA topics without quizzes, and
 * LR regression. Learning state only: no XP, mastery, streak, achievement,
 * quiz, or game side effects are possible through this endpoint.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ProgressUpsertApiTest extends AbstractCoreApiTest {

    private static final String QA_ALGEBRA_TOPIC = "b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b201";
    private static final String LR_SYLLOGISMS_TOPIC = "dddddddd-dddd-dddd-dddd-000000000010";

    private static final String COMPLETE_BODY =
            "{\"status\": \"COMPLETED\", \"completionPercentage\": 100}";

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private int progressRows(String email, String topicId) {
        return jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM progress p JOIN users u ON u.id = p.user_id"
                        + " WHERE u.email = ? AND p.topic_id = ?",
                Integer.class, email, topicId);
    }

    @Test
    void unauthenticatedRequestIsRejected() throws Exception {
        mockMvc.perform(put("/api/v1/progress/{id}", QA_ALGEBRA_TOPIC)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(COMPLETE_BODY))
                .andExpect(status().isUnauthorized());
        // Rejection happens before any persistence; nothing about this
        // anonymous caller can be attributed to a learner row.
    }

    @Test
    void firstCompletionCreatesOneProgressRow() throws Exception {
        String[] learner = registerLearner("progfirst");
        mockMvc.perform(put("/api/v1/progress/{id}", QA_ALGEBRA_TOPIC)
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(COMPLETE_BODY))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.topicId").value(QA_ALGEBRA_TOPIC))
                .andExpect(jsonPath("$.status").value("COMPLETED"))
                .andExpect(jsonPath("$.completionPercentage").value(100))
                .andExpect(jsonPath("$.completedAt").isNotEmpty());
        assertThat(progressRows(learner[1], QA_ALGEBRA_TOPIC)).isEqualTo(1);
    }

    @Test
    void repeatedCompletionStaysIdempotent() throws Exception {
        String[] learner = registerLearner("progidem");
        mockMvc.perform(put("/api/v1/progress/{id}", QA_ALGEBRA_TOPIC)
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(COMPLETE_BODY))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.completedAt").isNotEmpty());
        // H2 persists timestamps at microsecond precision while Instant
        // carries nanos, so stability is verified by row singularity plus a
        // populated completedAt — not by string equality across reads.
        mockMvc.perform(put("/api/v1/progress/{id}", QA_ALGEBRA_TOPIC)
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(COMPLETE_BODY))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("COMPLETED"))
                .andExpect(jsonPath("$.completedAt").isNotEmpty());
        assertThat(progressRows(learner[1], QA_ALGEBRA_TOPIC)).isEqualTo(1);
    }

    @Test
    void userIsolationHoldsAcrossLearners() throws Exception {
        String[] learnerA = registerLearner("proga");
        String[] learnerB = registerLearner("progb");
        mockMvc.perform(put("/api/v1/progress/{id}", QA_ALGEBRA_TOPIC)
                        .header("Authorization", bearer(learnerA[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(COMPLETE_BODY))
                .andExpect(status().isOk());
        // B must not see A's progress.
        mockMvc.perform(get("/api/v1/progress/{id}", QA_ALGEBRA_TOPIC)
                        .header("Authorization", bearer(learnerB[0])))
                .andExpect(status().isNotFound());
        // B completes independently: one row each, no cross-user mutation.
        mockMvc.perform(put("/api/v1/progress/{id}", QA_ALGEBRA_TOPIC)
                        .header("Authorization", bearer(learnerB[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(COMPLETE_BODY))
                .andExpect(status().isOk());
        assertThat(progressRows(learnerA[1], QA_ALGEBRA_TOPIC)).isEqualTo(1);
        assertThat(progressRows(learnerB[1], QA_ALGEBRA_TOPIC)).isEqualTo(1);
        mockMvc.perform(get("/api/v1/progress/{id}", QA_ALGEBRA_TOPIC)
                        .header("Authorization", bearer(learnerA[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("COMPLETED"));
    }

    @Test
    void unknownTopicReturnsNotFoundWithoutRow() throws Exception {
        String[] learner = registerLearner("progunknown");
        String ghost = UUID.randomUUID().toString();
        mockMvc.perform(put("/api/v1/progress/{id}", ghost)
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(COMPLETE_BODY))
                .andExpect(status().isNotFound());
        assertThat(progressRows(learner[1], ghost)).isEqualTo(0);
    }

    @Test
    void invalidCompletionStatesAreRejected() throws Exception {
        String[] learner = registerLearner("progbad");
        mockMvc.perform(put("/api/v1/progress/{id}", QA_ALGEBRA_TOPIC)
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\": \"IN_PROGRESS\", \"completionPercentage\": 50}"))
                .andExpect(status().isBadRequest());
        mockMvc.perform(put("/api/v1/progress/{id}", QA_ALGEBRA_TOPIC)
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\": \"COMPLETED\", \"completionPercentage\": 50}"))
                .andExpect(status().isBadRequest());
        assertThat(progressRows(learner[1], QA_ALGEBRA_TOPIC)).isEqualTo(0);
    }

    @Test
    void qaTopicWithoutQuizCompletesWithoutGameDependency() throws Exception {
        String[] learner = registerLearner("progqa");
        mockMvc.perform(put("/api/v1/progress/{id}", QA_ALGEBRA_TOPIC)
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(COMPLETE_BODY))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("COMPLETED"));
        assertThat(progressRows(learner[1], QA_ALGEBRA_TOPIC)).isEqualTo(1);
        // No quiz, mastery, XP, or game rows may appear as a side effect.
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM quizzes q JOIN topics t ON t.id = q.topic_id"
                        + " WHERE t.id = ?",
                Integer.class, QA_ALGEBRA_TOPIC)).isEqualTo(0);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM topic_mastery tm JOIN users u ON u.id = tm.user_id"
                        + " WHERE u.email = ?",
                Integer.class, learner[1])).isEqualTo(0);
    }

    @Test
    void lrTopicCompletionLeavesQuizMasteryGameUntouched() throws Exception {
        String[] learner = registerLearner("proglr");
        mockMvc.perform(put("/api/v1/progress/{id}", LR_SYLLOGISMS_TOPIC)
                        .header("Authorization", bearer(learner[0]))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(COMPLETE_BODY))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("COMPLETED"));
        // The LR quiz remains served; no mastery/XP/game rows were created.
        mockMvc.perform(get("/api/v1/quiz/{id}", LR_SYLLOGISMS_TOPIC)
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.questionCount").value(15));
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM topic_mastery tm JOIN users u ON u.id = tm.user_id"
                        + " WHERE u.email = ?",
                Integer.class, learner[1])).isEqualTo(0);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM quiz_attempts qa JOIN users u ON u.id = qa.user_id"
                        + " WHERE u.email = ?",
                Integer.class, learner[1])).isEqualTo(0);
    }
}
