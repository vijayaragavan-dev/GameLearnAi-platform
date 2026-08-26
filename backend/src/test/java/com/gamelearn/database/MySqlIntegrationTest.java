package com.gamelearn.database;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * Verifies the persistence foundation against a REAL MySQL server:
 * connectivity, JPA initialization and the complete Phase 1 migration chain.
 *
 * <p>The container starts EMPTY; Flyway must migrate it to exactly the schema
 * defined by GameLearn_AI_Database_Specification.md (20 business tables).</p>
 *
 * <p>Skipped automatically when no Docker daemon is available; the H2-based
 * suite covers those environments.</p>
 */
@SpringBootTest
@ActiveProfiles("test")
@Testcontainers(disabledWithoutDocker = true)
class MySqlIntegrationTest {

    private static final List<String> EXPECTED_TABLES = List.of(
            "users", "learner_profiles", "subjects", "topics", "lessons",
            "learning_paths", "learning_path_nodes", "quizzes", "questions",
            "quiz_questions", "quiz_attempts", "question_attempts",
            "topic_mastery", "progress", "recommendations", "xp_transactions",
            "achievements", "user_achievements", "streaks", "ai_interactions");

    @Container
    @ServiceConnection
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0");

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private com.gamelearn.repository.UserRepository userRepository;

    @Autowired
    private com.gamelearn.repository.AiInteractionRepository aiInteractionRepository;

    @Test
    void connectsToRealMySql() {
        String version = jdbcTemplate.queryForObject("SELECT VERSION()", String.class);
        assertThat(version).startsWith("8.");
    }

    @Test
    void completeMigrationChainIsAppliedOnRealMySql() {
        Integer appliedMigrations = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM flyway_schema_history "
                        + "WHERE success = 1 AND installed_rank > 0",
                Integer.class);
        assertThat(appliedMigrations).isEqualTo(11);

        Integer failedMigrations = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM flyway_schema_history WHERE success = 0",
                Integer.class);
        assertThat(failedMigrations).isZero();
    }

    @Test
    void allTwentyBusinessTablesExistOnRealMySql() {
        List<String> tables = jdbcTemplate.queryForList(
                "SELECT table_name FROM information_schema.tables "
                        + "WHERE table_schema = DATABASE() AND table_name <> 'flyway_schema_history' "
                        + "ORDER BY table_name",
                String.class);
        assertThat(tables).containsExactlyInAnyOrderElementsOf(EXPECTED_TABLES);
    }

    @Test
    void requiredForeignKeysExistOnRealMySql() {
        Integer foreignKeys = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM information_schema.table_constraints "
                        + "WHERE table_schema = DATABASE() "
                        + "AND constraint_type = 'FOREIGN KEY'",
                Integer.class);
        // 29 approved relationships across the 20 tables (Database Specification section 27).
        assertThat(foreignKeys).isEqualTo(29);
    }

    @Test
    void requiredUniqueConstraintsExistOnRealMySql() {
        List<String> uniqueConstraints = jdbcTemplate.queryForList(
                "SELECT constraint_name FROM information_schema.table_constraints "
                        + "WHERE table_schema = DATABASE() AND constraint_type = 'UNIQUE'",
                String.class);
        assertThat(uniqueConstraints).containsExactlyInAnyOrder(
                "uq_users_email",
                "uq_learner_profiles_user_id",
                "uq_subjects_name",
                "uq_topics_subject_id_name",
                "uq_learning_path_nodes_path_seq",
                "uq_quiz_questions_quiz_question",
                "uq_quiz_questions_quiz_order",
                "uq_topic_mastery_user_topic",
                "uq_achievements_code",
                "uq_user_achievements_user_achievement",
                "uq_streaks_user_id");
    }

    @Test
    void requiredIndexesExistOnRealMySql() {
        List<String> indexes = jdbcTemplate.queryForList(
                "SELECT DISTINCT index_name FROM information_schema.statistics "
                        + "WHERE table_schema = DATABASE() "
                        + "AND index_name LIKE 'idx_%'",
                String.class);
        assertThat(indexes).containsExactlyInAnyOrder(
                "idx_topics_subject_id",
                "idx_learner_profiles_current_subject",
                "idx_learner_profiles_current_topic",
                "idx_learning_paths_user_subject",
                "idx_learning_paths_subject_id",
                "idx_learning_path_nodes_topic_id",
                "idx_lessons_topic_id",
                "idx_quizzes_topic_id",
                "idx_questions_topic_id",
                "idx_quiz_attempts_user_quiz",
                "idx_quiz_attempts_user_submitted",
                "idx_quiz_attempts_quiz_id",
                "idx_question_attempts_attempt",
                "idx_question_attempts_question",
                "idx_topic_mastery_topic_id",
                "idx_progress_user_topic",
                "idx_progress_topic_id",
                "idx_progress_node_id",
                "idx_recommendations_user_status",
                "idx_recommendations_topic_id",
                "idx_xp_transactions_user_created",
                "idx_user_achievements_achievement",
                "idx_ai_interactions_user_created");
    }

    @Test
    void seedSubjectsArePresentOnRealMySql() {
        Long seededSubjects = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM subjects WHERE id LIKE '11111111-%'", Long.class);
        assertThat(seededSubjects).isEqualTo(5);
    }

    @Test
    void jsonColumnsStoreDocumentsNotEscapedLiterals() {
        com.gamelearn.entity.User user = new com.gamelearn.entity.User();
        user.setEmail("json-probe-" + java.util.UUID.randomUUID() + "@example.test");
        user.setPasswordHash("$2a$mysql-json-probe");
        user.setDisplayName("Json Probe");
        user = userRepository.saveAndFlush(user);

        com.gamelearn.entity.AiInteraction interaction = new com.gamelearn.entity.AiInteraction();
        interaction.setUser(user);
        interaction.setInteractionType(com.gamelearn.entity.enums.AiInteractionType.TUTOR);
        interaction.setStatus(com.gamelearn.entity.enums.AiInteractionStatus.SUCCESS);
        interaction.setRequestContextJson("{\"question\":\"why?\"}");
        interaction.setResponseJson("{\"answer\":\"because\"}");
        interaction = aiInteractionRepository.saveAndFlush(interaction);

        // Raw JDBC read: MySQL must have parsed and stored real JSON documents
        // (JSON_UNQUOTE strips the quotes a JSON string scalar carries).
        String rawRequest = jdbcTemplate.queryForObject(
                "SELECT JSON_UNQUOTE(JSON_EXTRACT(request_context_json, '$.question')) "
                        + "FROM ai_interactions WHERE id = ?",
                String.class, interaction.getId().toString());
        assertThat(rawRequest).isEqualTo("why?");

        com.gamelearn.entity.AiInteraction reloaded =
                aiInteractionRepository.findById(interaction.getId()).orElseThrow();
        assertThat(reloaded.getRequestContextJson()).contains("why?");
        assertThat(reloaded.getRequestContextJson()).doesNotContain("\\\"");
    }
}
