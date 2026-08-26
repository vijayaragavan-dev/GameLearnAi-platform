package com.gamelearn.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.ActiveProfiles;

import com.gamelearn.entity.Lesson;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.repository.LessonRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicRepository;

import jakarta.persistence.EntityManager;

@SpringBootTest
@ActiveProfiles("test")
class ContentRepositoryTest {

    @Autowired
    private SubjectRepository subjectRepository;

    @Autowired
    private TopicRepository topicRepository;

    @Autowired
    private LessonRepository lessonRepository;

    @Autowired
    private EntityManager entityManager;

    @Test
    void savesSubjectAndTopicHierarchy() {
        Subject subject = subjectRepository.saveAndFlush(PersistenceTestFixtures.subject("hier"));
        Topic topic = topicRepository.saveAndFlush(PersistenceTestFixtures.topic("hier", subject));

        assertThat(topic.getId()).isNotNull();
        Topic reloaded = topicRepository.findById(topic.getId()).orElseThrow();
        assertThat(reloaded.getSubject().getId()).isEqualTo(subject.getId());
    }

    @Test
    void duplicateTopicNameWithinSameSubjectIsRejected() {
        Subject subject = subjectRepository.saveAndFlush(PersistenceTestFixtures.subject("dupname"));
        Topic first = topicRepository.saveAndFlush(PersistenceTestFixtures.topic("dupname", subject));

        Topic second = PersistenceTestFixtures.topic("dupname", subject);
        second.setName(first.getName());

        assertThatThrownBy(() -> topicRepository.saveAndFlush(second))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void sameTopicNameInDifferentSubjectsIsAllowed() {
        Subject subjectA = subjectRepository.saveAndFlush(PersistenceTestFixtures.subject("subjA"));
        Subject subjectB = subjectRepository.saveAndFlush(PersistenceTestFixtures.subject("subjB"));

        String sharedName = "Shared Topic " + UUID.randomUUID();
        Topic inA = PersistenceTestFixtures.topic("a", subjectA);
        inA.setName(sharedName);
        Topic inB = PersistenceTestFixtures.topic("b", subjectB);
        inB.setName(sharedName);

        topicRepository.saveAndFlush(inA);
        topicRepository.saveAndFlush(inB);

        assertThat(topicRepository.findAllById(java.util.List.of(inA.getId(), inB.getId()))).hasSize(2);
    }

    @Test
    void topicWithUnknownSubjectFailsForeignKey() {
        Subject ghostReference = entityManager.getReference(Subject.class, UUID.randomUUID());
        Topic orphan = PersistenceTestFixtures.topic("orphan", ghostReference);

        assertThatThrownBy(() -> topicRepository.saveAndFlush(orphan))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void lessonLongContentRoundTrips() {
        Subject subject = subjectRepository.saveAndFlush(PersistenceTestFixtures.subject("lesson"));
        Topic topic = topicRepository.saveAndFlush(PersistenceTestFixtures.topic("lesson", subject));

        String longContent = "x".repeat(80_000);
        Lesson lesson = PersistenceTestFixtures.lesson("long", topic);
        lesson.setContent(longContent);
        Lesson saved = lessonRepository.saveAndFlush(lesson);

        Lesson reloaded = lessonRepository.findById(saved.getId()).orElseThrow();
        assertThat(reloaded.getContent()).hasSize(80_000);
        assertThat(reloaded.getSourceType().name()).isEqualTo("CURATED");
    }

    @Test
    void lessonRequiresExistingTopic() {
        Topic ghostReference = entityManager.getReference(Topic.class, UUID.randomUUID());
        Lesson orphan = PersistenceTestFixtures.lesson("orphan", ghostReference);

        assertThatThrownBy(() -> lessonRepository.saveAndFlush(orphan))
                .isInstanceOf(DataIntegrityViolationException.class);
    }
}
