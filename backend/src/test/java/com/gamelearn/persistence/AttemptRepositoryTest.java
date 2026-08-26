package com.gamelearn.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.math.BigDecimal;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import com.gamelearn.entity.Question;
import com.gamelearn.entity.QuestionAttempt;
import com.gamelearn.entity.Quiz;
import com.gamelearn.entity.QuizAttempt;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.entity.enums.QuizAttemptStatus;
import com.gamelearn.repository.QuestionAttemptRepository;
import com.gamelearn.repository.QuestionRepository;
import com.gamelearn.repository.QuizAttemptRepository;
import com.gamelearn.repository.QuizRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.UserRepository;

import jakarta.persistence.EntityManager;

@SpringBootTest
@ActiveProfiles("test")
class AttemptRepositoryTest {

    @Autowired
    private QuizAttemptRepository quizAttemptRepository;

    @Autowired
    private QuestionAttemptRepository questionAttemptRepository;

    @Autowired
    private QuizRepository quizRepository;

    @Autowired
    private QuestionRepository questionRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SubjectRepository subjectRepository;

    @Autowired
    private TopicRepository topicRepository;

    @Autowired
    private EntityManager entityManager;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private QuizAttempt persistedInProgressAttempt(String label) {
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user(label));
        Subject subject = subjectRepository.saveAndFlush(PersistenceTestFixtures.subject(label));
        Topic topic = topicRepository.saveAndFlush(PersistenceTestFixtures.topic(label, subject));
        Quiz quiz = quizRepository.saveAndFlush(PersistenceTestFixtures.quiz(label, topic));

        return quizAttemptRepository.saveAndFlush(
                PersistenceTestFixtures.quizAttempt(quiz, user));
    }

    @Test
    void inProgressAttemptHasNullableSubmissionFields() {
        QuizAttempt attempt = persistedInProgressAttempt("att");

        assertThat(attempt.getCreatedAt()).isNotNull();
        assertThat(attempt.getUpdatedAt()).isNotNull();
        assertThat(attempt.getStatus()).isEqualTo(QuizAttemptStatus.IN_PROGRESS);

        var raw = jdbcTemplate.queryForMap(
                "SELECT submitted_at, duration_seconds, status FROM quiz_attempts WHERE id = ?",
                attempt.getId());
        assertThat(raw.get("submitted_at")).isNull();
        assertThat(raw.get("duration_seconds")).isNull();
        assertThat(raw.get("status")).isEqualTo("IN_PROGRESS");
    }

    @Test
    void completingAttemptPersistsScoreAndSubmission() {
        QuizAttempt attempt = persistedInProgressAttempt("done");

        attempt.setStatus(QuizAttemptStatus.COMPLETED);
        attempt.setSubmittedAt(java.time.Instant.now());
        attempt.setDurationSeconds(95);
        attempt.setCorrectCount(4);
        attempt.setScore(new BigDecimal("80.00"));
        quizAttemptRepository.saveAndFlush(attempt);

        QuizAttempt reloaded = quizAttemptRepository.findById(attempt.getId()).orElseThrow();
        assertThat(reloaded.getStatus()).isEqualTo(QuizAttemptStatus.COMPLETED);
        assertThat(reloaded.getSubmittedAt()).isNotNull();
        assertThat(reloaded.getDurationSeconds()).isEqualTo(95);
        assertThat(reloaded.getScore()).isEqualByComparingTo(new BigDecimal("80.00"));
        assertThat(reloaded.getDifficultyAtAttempt()).isEqualTo(Difficulty.MEDIUM);
    }

    @Test
    void questionAttemptsLinkToQuizAttempt() {
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("qa"));
        Subject subject = subjectRepository.saveAndFlush(PersistenceTestFixtures.subject("qa"));
        Topic topic = topicRepository.saveAndFlush(PersistenceTestFixtures.topic("qa", subject));
        Quiz quiz = quizRepository.saveAndFlush(PersistenceTestFixtures.quiz("qa", topic));
        Question questionA = questionRepository.saveAndFlush(
                PersistenceTestFixtures.question("qA", topic));
        Question questionB = questionRepository.saveAndFlush(
                PersistenceTestFixtures.question("qB", topic));

        QuizAttempt attempt = quizAttemptRepository.saveAndFlush(
                PersistenceTestFixtures.quizAttempt(quiz, user));

        QuestionAttempt first = PersistenceTestFixtures.questionAttempt(attempt, questionA);
        QuestionAttempt second = PersistenceTestFixtures.questionAttempt(attempt, questionB);
        second.setCorrect(false);
        second.setSelectedAnswer("b");
        questionAttemptRepository.saveAndFlush(first);
        questionAttemptRepository.saveAndFlush(second);

        QuestionAttempt reloadedFirst = questionAttemptRepository.findById(first.getId()).orElseThrow();
        QuestionAttempt reloadedSecond = questionAttemptRepository.findById(second.getId()).orElseThrow();

        assertThat(reloadedFirst.getQuizAttempt().getId()).isEqualTo(attempt.getId());
        assertThat(reloadedFirst.isCorrect()).isTrue();
        assertThat(reloadedSecond.getQuestion().getId()).isEqualTo(questionB.getId());
        assertThat(reloadedSecond.isCorrect()).isFalse();
        // Immutable history row: created_at present, no updated_at column involved.
        assertThat(reloadedFirst.getCreatedAt()).isNotNull();
        assertThat(reloadedFirst.getId()).isNotEqualTo(reloadedSecond.getId());
    }

    @Test
    void questionAttemptRequiresExistingQuizAttempt() {
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("qaghost"));
        Subject subject = subjectRepository.saveAndFlush(PersistenceTestFixtures.subject("qaghost"));
        Topic topic = topicRepository.saveAndFlush(PersistenceTestFixtures.topic("qaghost", subject));
        Question question = questionRepository.saveAndFlush(
                PersistenceTestFixtures.question("qaghost", topic));

        QuizAttempt ghostReference = entityManager.getReference(QuizAttempt.class,
                java.util.UUID.randomUUID());
        QuestionAttempt orphan = PersistenceTestFixtures.questionAttempt(ghostReference, question);

        assertThatThrownBy(() -> questionAttemptRepository.saveAndFlush(orphan))
                .isInstanceOf(DataIntegrityViolationException.class);
    }
}
