package com.gamelearn.controller;

import java.math.BigDecimal;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamelearn.entity.LearningPath;
import com.gamelearn.entity.Lesson;
import com.gamelearn.entity.Progress;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.User;
import com.gamelearn.repository.LearningPathNodeRepository;
import com.gamelearn.repository.LearningPathRepository;
import com.gamelearn.repository.LessonRepository;
import com.gamelearn.repository.ProgressRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.UserRepository;

/**
 * Shared helpers for Phase 3 API tests: registers real learners through the
 * authentication flow and seeds content through the repositories.
 */
abstract class AbstractCoreApiTest {

    @Autowired
    protected MockMvc mockMvc;

    @Autowired
    protected ObjectMapper objectMapper;

    @Autowired
    protected SubjectRepository subjectRepository;

    @Autowired
    protected TopicRepository topicRepository;

    @Autowired
    protected UserRepository userRepository;

    @Autowired
    protected LessonRepository lessonRepository;

    @Autowired
    protected LearningPathRepository learningPathRepository;

    @Autowired
    protected LearningPathNodeRepository learningPathNodeRepository;

    @Autowired
    protected ProgressRepository progressRepository;

    /**
     * Registers a learner through the public auth API.
     *
     * @return [bearerToken, email]
     */
    protected String[] registerLearner(String label) throws Exception {
        String email = label + "-" + UUID.randomUUID() + "@example.test";
        String body = """
                {
                  "email": "%s",
                  "password": "Str0ng-Passw0rd!",
                  "displayName": "Learner %s"
                }
                """.formatted(email, label);
        MvcResult result = mockMvc.perform(
                        org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                                .post("/api/v1/auth/register")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body))
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers
                        .status().isCreated())
                .andReturn();
        JsonNode json = objectMapper.readTree(result.getResponse().getContentAsString());
        // Return the email exactly as the backend stored it (normalized).
        return new String[] { json.get("token").asText(), json.path("user").path("email").asText() };
    }

    protected String bearer(String token) {
        return "Bearer " + token;
    }

    protected Subject newActiveSubject(String label, int displayOrder) {
        Subject subject = new Subject();
        subject.setName(label + " " + UUID.randomUUID());
        subject.setDescription(label + " description");
        subject.setIconKey("icon_" + label);
        subject.setActive(true);
        subject.setDisplayOrder(displayOrder);
        return subjectRepository.save(subject);
    }

    protected Subject newInactiveSubject(String label) {
        Subject subject = newActiveSubject(label, 99);
        subject.setActive(false);
        return subjectRepository.save(subject);
    }

    protected Topic newTopic(String label, Subject subject, boolean active) {
        Topic topic = new Topic();
        topic.setSubject(subject);
        topic.setName(label + " " + UUID.randomUUID());
        topic.setDescription(label + " topic description");
        topic.setDifficulty(com.gamelearn.entity.enums.Difficulty.EASY);
        topic.setDisplayOrder(1);
        topic.setActive(active);
        return topicRepository.save(topic);
    }

    protected Lesson newLesson(String label, Topic topic, boolean active) {
        Lesson lesson = new Lesson();
        lesson.setTopic(topic);
        lesson.setTitle(label + " Lesson");
        lesson.setContent("<p>" + label + " content</p>");
        lesson.setSummary(label + " summary");
        lesson.setDifficulty(com.gamelearn.entity.enums.Difficulty.EASY);
        lesson.setSourceType(com.gamelearn.entity.enums.SourceType.CURATED);
        lesson.setActive(active);
        return lessonRepository.save(lesson);
    }

    protected LearningPath newPath(User user, Subject subject, String title) {
        LearningPath path = new LearningPath();
        path.setUser(user);
        path.setSubject(subject);
        path.setTitle(title);
        path.setStatus(com.gamelearn.entity.enums.LearningPathStatus.ACTIVE);
        path.setGeneratedBy(com.gamelearn.entity.enums.GeneratedBy.SYSTEM);
        return learningPathRepository.save(path);
    }

    protected Progress newProgress(User user, Topic topic, BigDecimal completion,
                                   com.gamelearn.entity.enums.ProgressStatus status,
                                   java.time.Instant lastActivityAt) {
        Progress progress = new Progress();
        progress.setUser(user);
        progress.setTopic(topic);
        progress.setCompletionPercentage(completion);
        progress.setStatus(status);
        progress.setLastActivityAt(lastActivityAt);
        return progressRepository.save(progress);
    }

    protected User userByEmail(String email) {
        return userRepository.findByEmail(email).orElseThrow();
    }
}
