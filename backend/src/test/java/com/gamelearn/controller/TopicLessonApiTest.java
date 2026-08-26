package com.gamelearn.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MvcResult;

import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;

import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class TopicLessonApiTest extends AbstractCoreApiTest {

    @Test
    void returnsActiveTopicWithContractShape() throws Exception {
        String[] learner = registerLearner("topic");
        Subject subject = newActiveSubject("topicsubj", 1);
        Topic topic = newTopic("ip", subject, true);

        mockMvc.perform(get("/api/v1/topics/{id}", topic.getId())
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(topic.getId().toString()))
                .andExpect(jsonPath("$.subjectId").value(subject.getId().toString()))
                .andExpect(jsonPath("$.subjectName").value(subject.getName()))
                .andExpect(jsonPath("$.name").value(topic.getName()))
                .andExpect(jsonPath("$.description").value("ip topic description"))
                .andExpect(jsonPath("$.difficulty").value("EASY"))
                .andExpect(jsonPath("$.displayOrder").value(1));
    }

    @Test
    void unknownOrInactiveTopicsReturn404WithoutLeakingExistence() throws Exception {
        String[] learner = registerLearner("t404");
        Subject subject = newActiveSubject("t404subj", 1);
        Topic inactive = newTopic("inactive", subject, false);

        MvcResult unknown = mockMvc.perform(get("/api/v1/topics/{id}", UUID.randomUUID())
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode").value("RESOURCE_NOT_FOUND"))
                .andExpect(jsonPath("$.message").value("Topic not found"))
                .andReturn();
        MvcResult hidden = mockMvc.perform(get("/api/v1/topics/{id}", inactive.getId())
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode").value("RESOURCE_NOT_FOUND"))
                .andExpect(jsonPath("$.message").value("Topic not found"))
                .andReturn();

        // Identical safe error semantics; the body carries no data beyond
        // the error envelope (the path field only echoes the caller-supplied URL).
        assertThat(hidden.getResponse().getContentAsString())
                .doesNotContain("Exception").doesNotContain("SQL");
        assertThat(unknown.getResponse().getContentAsString())
                .doesNotContain("Exception").doesNotContain("SQL");
    }

    @Test
    void malformedAndInjectedTopicIdsAreRejectedAs400() throws Exception {
        String[] learner = registerLearner("badid");

        MvcResult malformed = mockMvc.perform(get("/api/v1/topics/{id}", "not-a-uuid")
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("MALFORMED_REQUEST"))
                .andReturn();

        MvcResult injected = mockMvc.perform(get("/api/v1/topics/{id}", "' OR '1'='1")
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isBadRequest())
                .andReturn();

        assertThat(malformed.getResponse().getContentAsString()).doesNotContain("SQL");
        assertThat(injected.getResponse().getStatus()).isEqualTo(400);
    }

    @Test
    void topicsRequireAuthentication() throws Exception {
        mockMvc.perform(get("/api/v1/topics/{id}", UUID.randomUUID()))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void returnsCanonicalOldestActiveLessonOfTopic() throws Exception {
        String[] learner = registerLearner("lesson");
        Subject subject = newActiveSubject("lessonsujb", 1);
        Topic topic = newTopic("lessontopic", subject, true);
        com.gamelearn.entity.Lesson oldest = newLesson("first", topic, true);
        Thread.sleep(5); // ensure distinct created_at ordering
        newLesson("second", topic, true);

        mockMvc.perform(get("/api/v1/topics/{id}/lesson", topic.getId())
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(oldest.getId().toString()))
                .andExpect(jsonPath("$.topicId").value(topic.getId().toString()))
                .andExpect(jsonPath("$.title").value("first Lesson"))
                .andExpect(jsonPath("$.content").value("<p>first content</p>"))
                .andExpect(jsonPath("$.summary").value("first summary"))
                .andExpect(jsonPath("$.difficulty").value("EASY"))
                .andExpect(jsonPath("$.sourceType").value("CURATED"));
    }

    @Test
    void fallsBackToNextActiveLessonWhenCanonicalIsDeactivated() throws Exception {
        String[] learner = registerLearner("lessonfb");
        Subject subject = newActiveSubject("lessonfbsubj", 1);
        Topic topic = newTopic("lessonfbtopic", subject, true);
        com.gamelearn.entity.Lesson first = newLesson("gone", topic, true);
        Thread.sleep(5);
        com.gamelearn.entity.Lesson second = newLesson("stay", topic, true);

        first.setActive(false);
        lessonRepository.saveAndFlush(first);

        mockMvc.perform(get("/api/v1/topics/{id}/lesson", topic.getId())
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(second.getId().toString()));
    }

    @Test
    void lessonMissingCasesReturn404() throws Exception {
        String[] learner = registerLearner("lesson404");
        Subject subject = newActiveSubject("lesson404subj", 1);
        Topic withoutLessons = newTopic("nolesson", subject, true);
        Topic inactive = newTopic("inactivetopic", subject, false);
        newLesson("hiddenlesson", inactive, true);

        mockMvc.perform(get("/api/v1/topics/{id}/lesson", withoutLessons.getId())
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isNotFound());

        mockMvc.perform(get("/api/v1/topics/{id}/lesson", inactive.getId())
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isNotFound());
    }
}
