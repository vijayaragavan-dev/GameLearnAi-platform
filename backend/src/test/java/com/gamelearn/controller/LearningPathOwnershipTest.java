package com.gamelearn.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MvcResult;

import com.gamelearn.entity.LearningPath;
import com.gamelearn.entity.LearningPathNode;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.User;

import com.jayway.jsonpath.JsonPath;

import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class LearningPathOwnershipTest extends AbstractCoreApiTest {

    @Test
    void returnsCallerOwnedPathsOnlyWithOrderedNodes() throws Exception {
        String[] learnerA = registerLearner("pathA");
        Subject subject = newActiveSubject("pathsubj", 1);
        Topic topicOne = newTopic("nodeone", subject, true);
        Topic topicTwo = newTopic("nodetwo", subject, true);

        User userA = userByEmail(learnerA[1]);
        LearningPath path = newPath(userA, subject, "A Path");
        node(path, topicTwo, 2);
        node(path, topicOne, 1);

        MvcResult result = mockMvc.perform(get("/api/v1/learning-path/{id}", subject.getId())
                        .header("Authorization", bearer(learnerA[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].id").value(path.getId().toString()))
                .andExpect(jsonPath("$[0].subjectId").value(subject.getId().toString()))
                .andExpect(jsonPath("$[0].title").value("A Path"))
                .andExpect(jsonPath("$[0].status").value("ACTIVE"))
                .andExpect(jsonPath("$[0].generatedBy").value("SYSTEM"))
                .andExpect(jsonPath("$[0].nodes.length()").value(2))
                .andReturn();

        // Nodes must be ordered by sequence number (1 then 2).
        var seqs = JsonPath.<java.util.List<Integer>>read(
                result.getResponse().getContentAsString(), "$[0].nodes[*].sequenceNumber");
        assertThat(seqs).containsExactly(1, 2);
        var topicNames = JsonPath.<java.util.List<String>>read(
                result.getResponse().getContentAsString(), "$[0].nodes[*].topicName");
        assertThat(topicNames).containsExactly(topicOne.getName(), topicTwo.getName());
    }

    @Test
    void anotherLearnerCannotSeeSomeoneElsesPaths() throws Exception {
        String[] learnerA = registerLearner("ownerA");
        String[] learnerB = registerLearner("otherB");

        Subject subject = newActiveSubject("ownsubj", 1);
        Topic topic = newTopic("owntopic", subject, true);
        LearningPath path = newPath(userByEmail(learnerA[1]), subject, "Private A Path");
        node(path, topic, 1);

        // B asks for the same subject: A's private path must not appear.
        mockMvc.perform(get("/api/v1/learning-path/{id}", subject.getId())
                        .header("Authorization", bearer(learnerB[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));

        // A still sees it.
        mockMvc.perform(get("/api/v1/learning-path/{id}", subject.getId())
                        .header("Authorization", bearer(learnerA[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1));
    }

    @Test
    void unknownSubjectReturns404AndAnonymousReturns401() throws Exception {
        String[] learner = registerLearner("path404");

        mockMvc.perform(get("/api/v1/learning-path/{id}", UUID.randomUUID())
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode").value("RESOURCE_NOT_FOUND"));

        mockMvc.perform(get("/api/v1/learning-path/{id}", UUID.randomUUID()))
                .andExpect(status().isUnauthorized());
    }

    private void node(LearningPath path, Topic topic, int sequence) {
        LearningPathNode n = new LearningPathNode();
        n.setLearningPath(path);
        n.setTopic(topic);
        n.setSequenceNumber(sequence);
        n.setRequiredMastery(new java.math.BigDecimal("60.00"));
        n.setStatus(com.gamelearn.entity.enums.PathNodeStatus.AVAILABLE);
        learningPathNodeRepository.save(n);
    }
}
