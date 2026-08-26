package com.gamelearn.persistence;

import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.math.BigDecimal;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.ActiveProfiles;

import com.gamelearn.entity.LearningPath;
import com.gamelearn.entity.LearningPathNode;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.GeneratedBy;
import com.gamelearn.entity.enums.LearningPathStatus;
import com.gamelearn.entity.enums.PathNodeStatus;
import com.gamelearn.repository.LearningPathNodeRepository;
import com.gamelearn.repository.LearningPathRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.UserRepository;

import jakarta.persistence.EntityManager;

@SpringBootTest
@ActiveProfiles("test")
class LearningPathRepositoryTest {

    @Autowired
    private LearningPathRepository learningPathRepository;

    @Autowired
    private LearningPathNodeRepository learningPathNodeRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SubjectRepository subjectRepository;

    @Autowired
    private TopicRepository topicRepository;

    @Autowired
    private EntityManager entityManager;

    @Test
    void duplicateSequenceNumberWithinPathIsRejected() {
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("lp"));
        Subject subject = subjectRepository.saveAndFlush(PersistenceTestFixtures.subject("lp"));
        Topic topicA = topicRepository.saveAndFlush(PersistenceTestFixtures.topic("lpA", subject));
        Topic topicB = topicRepository.saveAndFlush(PersistenceTestFixtures.topic("lpB", subject));

        LearningPath unsavedPath = new LearningPath();
        unsavedPath.setUser(user);
        unsavedPath.setSubject(subject);
        unsavedPath.setTitle("Path " + UUID.randomUUID());
        unsavedPath.setStatus(LearningPathStatus.ACTIVE);
        unsavedPath.setGeneratedBy(GeneratedBy.AI);
        LearningPath path = learningPathRepository.saveAndFlush(unsavedPath);

        learningPathNodeRepository.saveAndFlush(node(path, topicA, 1));

        assertThatThrownBy(() -> learningPathNodeRepository.saveAndFlush(node(path, topicB, 1)))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void nodeWithUnknownTopicFailsForeignKey() {
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("lpghost"));
        Subject subject = subjectRepository.saveAndFlush(PersistenceTestFixtures.subject("lpghost"));

        LearningPath path = new LearningPath();
        path.setUser(user);
        path.setSubject(subject);
        path.setTitle("Ghost Path " + UUID.randomUUID());
        path.setStatus(LearningPathStatus.ACTIVE);
        path.setGeneratedBy(GeneratedBy.SYSTEM);
        path = learningPathRepository.saveAndFlush(path);

        Topic ghostTopic = entityManager.getReference(Topic.class, UUID.randomUUID());
        LearningPathNode orphan = node(path, ghostTopic, 1);

        assertThatThrownBy(() -> learningPathNodeRepository.saveAndFlush(orphan))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    private LearningPathNode node(LearningPath path, Topic topic, int sequence) {
        LearningPathNode node = new LearningPathNode();
        node.setLearningPath(path);
        node.setTopic(topic);
        node.setSequenceNumber(sequence);
        node.setRequiredMastery(new BigDecimal("50.00"));
        node.setStatus(PathNodeStatus.AVAILABLE);
        return node;
    }
}
