package com.gamelearn.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import com.gamelearn.repository.AchievementRepository;
import com.gamelearn.repository.AiInteractionRepository;
import com.gamelearn.repository.LearnerProfileRepository;
import com.gamelearn.repository.LearningPathNodeRepository;
import com.gamelearn.repository.LearningPathRepository;
import com.gamelearn.repository.LessonRepository;
import com.gamelearn.repository.ProgressRepository;
import com.gamelearn.repository.QuestionAttemptRepository;
import com.gamelearn.repository.QuestionRepository;
import com.gamelearn.repository.QuizAttemptRepository;
import com.gamelearn.repository.QuizQuestionRepository;
import com.gamelearn.repository.QuizRepository;
import com.gamelearn.repository.RecommendationRepository;
import com.gamelearn.repository.StreakRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicMasteryRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.UserAchievementRepository;
import com.gamelearn.repository.UserRepository;
import com.gamelearn.repository.XpTransactionRepository;

@SpringBootTest
@ActiveProfiles("test")
class PersistenceContextTest {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private LearnerProfileRepository learnerProfileRepository;

    @Autowired
    private SubjectRepository subjectRepository;

    @Autowired
    private TopicRepository topicRepository;

    @Autowired
    private LessonRepository lessonRepository;

    @Autowired
    private LearningPathRepository learningPathRepository;

    @Autowired
    private LearningPathNodeRepository learningPathNodeRepository;

    @Autowired
    private QuizRepository quizRepository;

    @Autowired
    private QuestionRepository questionRepository;

    @Autowired
    private QuizQuestionRepository quizQuestionRepository;

    @Autowired
    private QuizAttemptRepository quizAttemptRepository;

    @Autowired
    private QuestionAttemptRepository questionAttemptRepository;

    @Autowired
    private TopicMasteryRepository topicMasteryRepository;

    @Autowired
    private ProgressRepository progressRepository;

    @Autowired
    private RecommendationRepository recommendationRepository;

    @Autowired
    private XpTransactionRepository xpTransactionRepository;

    @Autowired
    private AchievementRepository achievementRepository;

    @Autowired
    private UserAchievementRepository userAchievementRepository;

    @Autowired
    private StreakRepository streakRepository;

    @Autowired
    private AiInteractionRepository aiInteractionRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void allTwentyRepositoriesAreAvailable() {
        assertThat(userRepository).isNotNull();
        assertThat(learnerProfileRepository).isNotNull();
        assertThat(subjectRepository).isNotNull();
        assertThat(topicRepository).isNotNull();
        assertThat(lessonRepository).isNotNull();
        assertThat(learningPathRepository).isNotNull();
        assertThat(learningPathNodeRepository).isNotNull();
        assertThat(quizRepository).isNotNull();
        assertThat(questionRepository).isNotNull();
        assertThat(quizQuestionRepository).isNotNull();
        assertThat(quizAttemptRepository).isNotNull();
        assertThat(questionAttemptRepository).isNotNull();
        assertThat(topicMasteryRepository).isNotNull();
        assertThat(progressRepository).isNotNull();
        assertThat(recommendationRepository).isNotNull();
        assertThat(xpTransactionRepository).isNotNull();
        assertThat(achievementRepository).isNotNull();
        assertThat(userAchievementRepository).isNotNull();
        assertThat(streakRepository).isNotNull();
        assertThat(aiInteractionRepository).isNotNull();
    }

    @Test
    void completeFlywayChainIsApplied() {
        // installed_rank > 0 excludes Flyway's internal
        // "<< Flyway Schema History table created >>" marker row (rank -1).
        Integer appliedMigrations = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM flyway_schema_history WHERE success = TRUE AND installed_rank > 0",
                Integer.class);
        assertThat(appliedMigrations).isEqualTo(20);
    }

    @Test
    void seedSubjectsArePresent() {
        Long seededSubjects = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM subjects WHERE id LIKE '11111111-%'", Long.class);
        assertThat(seededSubjects).isEqualTo(5);
    }
}
