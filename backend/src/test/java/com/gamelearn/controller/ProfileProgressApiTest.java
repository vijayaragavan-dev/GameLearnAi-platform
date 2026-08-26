package com.gamelearn.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MvcResult;

import com.gamelearn.entity.Progress;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.User;

import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ProfileProgressApiTest extends AbstractCoreApiTest {

    @Test
    void profileReturnsAuthenticatedLearnerOnlyWithApprovedDefaults() throws Exception {
        String[] learner = registerLearner("prof");

        MvcResult result = mockMvc.perform(get("/api/v1/profile")
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.email").value(learner[1]))
                .andExpect(jsonPath("$.displayName").value("Learner prof"))
                .andExpect(jsonPath("$.currentLevel").value(1))
                .andExpect(jsonPath("$.totalXp").value(0))
                .andExpect(jsonPath("$.overallMastery").value(0))
                .andExpect(jsonPath("$.currentSubjectId").doesNotExist())
                .andReturn();

        String body = result.getResponse().getContentAsString();
        // No security material, no account-status field.
        assertThat(body).doesNotContain("password");
        assertThat(body).doesNotContain("$2");
        assertThat(body).doesNotContain("status");
    }

    @Test
    void profileRequiresAuthentication() throws Exception {
        mockMvc.perform(get("/api/v1/profile"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void progressListsOwnRecordsNewestFirst() throws Exception {
        String[] learner = registerLearner("prog");

        Subject subject = newActiveSubject("progsubj", 1);
        Topic topicA = newTopic("progtA", subject, true);
        Topic topicB = newTopic("progtB", subject, true);
        User user = userByEmail(learner[1]);

        newProgress(user, topicA, new BigDecimal("25.00"),
                com.gamelearn.entity.enums.ProgressStatus.IN_PROGRESS,
                java.time.Instant.now().minusSeconds(600));
        Progress latest = newProgress(user, topicB, new BigDecimal("80.00"),
                com.gamelearn.entity.enums.ProgressStatus.IN_PROGRESS,
                java.time.Instant.now());

        MvcResult result = mockMvc.perform(get("/api/v1/progress")
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andReturn();

        var ids = com.jayway.jsonpath.JsonPath
                .<java.util.List<String>>read(result.getResponse().getContentAsString(), "$[*].id");
        assertThat(ids.get(0)).isEqualTo(latest.getId().toString());

        mockMvc.perform(get("/api/v1/progress"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void progressForTopicReturnsOwnRecordAnd404Otherwise() throws Exception {
        String[] learnerA = registerLearner("ptA");
        String[] learnerB = registerLearner("ptB");

        Subject subject = newActiveSubject("ptsubj", 1);
        Topic topic = newTopic("pttopic", subject, true);
        User userA = userByEmail(learnerA[1]);

        newProgress(userA, topic, new BigDecimal("55.50"),
                com.gamelearn.entity.enums.ProgressStatus.IN_PROGRESS,
                java.time.Instant.now());

        mockMvc.perform(get("/api/v1/progress/{topicId}", topic.getId())
                        .header("Authorization", bearer(learnerA[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.topicId").value(topic.getId().toString()))
                .andExpect(jsonPath("$.completionPercentage").value(55.50))
                .andExpect(jsonPath("$.status").value("IN_PROGRESS"))
                .andExpect(jsonPath("$.lastActivityAt").isNotEmpty());

        // User B has no progress for this topic: 404, and A's row is never leaked.
        MvcResult forbiddenPeek = mockMvc.perform(get("/api/v1/progress/{topicId}", topic.getId())
                        .header("Authorization", bearer(learnerB[0])))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode").value("RESOURCE_NOT_FOUND"))
                .andReturn();
        assertThat(forbiddenPeek.getResponse().getContentAsString())
                .doesNotContain(userA.getId().toString());

        // Unknown topic id -> same safe 404 shape.
        mockMvc.perform(get("/api/v1/progress/{topicId}", UUID.randomUUID())
                        .header("Authorization", bearer(learnerA[0])))
                .andExpect(status().isNotFound());
    }
}
