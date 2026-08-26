package com.gamelearn.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.ActiveProfiles;

import com.gamelearn.entity.LearnerProfile;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.User;
import com.gamelearn.repository.LearnerProfileRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.UserRepository;

@SpringBootTest
@ActiveProfiles("test")
class LearnerProfileRepositoryTest {

    @Autowired
    private LearnerProfileRepository learnerProfileRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SubjectRepository subjectRepository;

    @Autowired
    private TopicRepository topicRepository;

    @Test
    void savesProfileWithApprovedDefaults() {
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("prof"));
        LearnerProfile profile = learnerProfileRepository.saveAndFlush(
                PersistenceTestFixtures.learnerProfile(user));

        assertThat(profile.getId()).isNotNull();
        assertThat(profile.getCurrentLevel()).isEqualTo(1);
        assertThat(profile.getTotalXp()).isZero();
        assertThat(profile.getOverallMastery()).isEqualByComparingTo(java.math.BigDecimal.ZERO);
        assertThat(profile.getCurrentSubject()).isNull();
        assertThat(profile.getCurrentTopic()).isNull();

        LearnerProfile reloaded = learnerProfileRepository.findById(profile.getId()).orElseThrow();
        assertThat(reloaded.getUser().getId()).isEqualTo(user.getId());
        assertThat(reloaded.getCurrentLevel()).isEqualTo(1);
    }

    @Test
    void secondProfileForSameUserIsRejected() {
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("profdup"));
        learnerProfileRepository.saveAndFlush(PersistenceTestFixtures.learnerProfile(user));

        LearnerProfile duplicate = PersistenceTestFixtures.learnerProfile(user);
        assertThatThrownBy(() -> learnerProfileRepository.saveAndFlush(duplicate))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void currentSubjectAndTopicLinksRoundTrip() {
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("proflink"));
        Subject subject = subjectRepository.saveAndFlush(PersistenceTestFixtures.subject("proflink"));
        Topic topic = topicRepository.saveAndFlush(PersistenceTestFixtures.topic("proflink", subject));

        LearnerProfile profile = PersistenceTestFixtures.learnerProfile(user);
        profile.setCurrentSubject(subject);
        profile.setCurrentTopic(topic);
        profile.setTotalXp(120);
        profile = learnerProfileRepository.saveAndFlush(profile);

        LearnerProfile reloaded = learnerProfileRepository.findById(profile.getId()).orElseThrow();
        assertThat(reloaded.getCurrentSubject().getId()).isEqualTo(subject.getId());
        assertThat(reloaded.getCurrentTopic().getId()).isEqualTo(topic.getId());
        assertThat(reloaded.getTotalXp()).isEqualTo(120);
    }
}
