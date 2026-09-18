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
 * connectivity, JPA initialization and the complete migration chain.
 *
 * <p>The container starts EMPTY; Flyway must migrate it to exactly the schema
 * defined by the committed migrations V1 through V28 (27 business tables:
 * the 20-table Phase 1 baseline plus units, game_results, avatars,
 * user_avatars, user_credits, credit_ledger and subject_game_compat).</p>
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
            "achievements", "user_achievements", "streaks", "ai_interactions",
            // V15 game results, V17/V18 avatar and credit ownership,
            // V23 units, V25 subject/game compatibility.
            "game_results", "avatars", "user_avatars", "user_credits",
            "credit_ledger", "units", "subject_game_compat");

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
        // One history row per committed migration file V1 through V28.
        // Keep in sync with PersistenceContextTest (H2) and the migration
        // directory; any new Flyway version must update both.
        assertThat(appliedMigrations).isEqualTo(28);

        Integer failedMigrations = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM flyway_schema_history WHERE success = 0",
                Integer.class);
        assertThat(failedMigrations).isZero();
    }

    @Test
    void allTwentySevenBusinessTablesExistOnRealMySql() {
        List<String> tables = jdbcTemplate.queryForList(
                "SELECT table_name FROM information_schema.tables "
                        + "WHERE table_schema = DATABASE() AND table_name <> 'flyway_schema_history' "
                        + "ORDER BY table_name",
                String.class);
        assertThat(tables).containsExactlyInAnyOrderElementsOf(EXPECTED_TABLES);
    }

    @Test
    void requiredForeignKeysExistOnRealMySql() {
        List<String> foreignKeys = jdbcTemplate.queryForList(
                "SELECT constraint_name FROM information_schema.table_constraints "
                        + "WHERE table_schema = DATABASE() "
                        + "AND constraint_type = 'FOREIGN KEY'",
                String.class);
        // Every relationship is an explicitly named fk_ constraint, so the
        // test pins the full set instead of a bare count: 29 approved Phase 1
        // relationships (Database Specification section 27) plus V15 (1),
        // V17 (1), V18 (4), V19 (1), V23 (2) and V25 (1).
        assertThat(foreignKeys).containsExactlyInAnyOrder(
                "fk_ai_interactions__users",
                "fk_avatars__subjects",
                "fk_credit_ledger__users",
                "fk_game_results__users",
                "fk_learner_profiles__avatars",
                "fk_learner_profiles__subjects",
                "fk_learner_profiles__topics",
                "fk_learner_profiles__users",
                "fk_learning_path_nodes__learning_paths",
                "fk_learning_path_nodes__topics",
                "fk_learning_paths__subjects",
                "fk_learning_paths__users",
                "fk_lessons__topics",
                "fk_progress__learning_path_nodes",
                "fk_progress__topics",
                "fk_progress__users",
                "fk_question_attempts__questions",
                "fk_question_attempts__quiz_attempts",
                "fk_questions__topics",
                "fk_quiz_attempts__quizzes",
                "fk_quiz_attempts__users",
                "fk_quiz_questions__questions",
                "fk_quiz_questions__quizzes",
                "fk_quizzes__topics",
                "fk_recommendations__topics",
                "fk_recommendations__users",
                "fk_streaks__users",
                "fk_subject_game_compat__subjects",
                "fk_topic_mastery__topics",
                "fk_topic_mastery__users",
                "fk_topics__subjects",
                "fk_topics__units",
                "fk_units__subjects",
                "fk_user_achievements__achievements",
                "fk_user_achievements__users",
                "fk_user_avatars__avatars",
                "fk_user_avatars__users",
                "fk_user_credits__users",
                "fk_xp_transactions__users");
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
                "uq_streaks_user_id",
                // V15 game-result idempotency, V17 avatar codes,
                // V18 ownership, V23 units, V25 compatibility.
                "uq_game_results_request",
                "uq_avatars_code",
                "uq_user_avatars_user_avatar",
                "uq_user_credits_user",
                "uq_units_subject_id_name",
                "uq_subject_game_compat_subject_game");
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
                "idx_ai_interactions_user_created",
                // V15 game results and reference lookup, V17 avatar catalog,
                // V18 ledgers and ownership, V19/V21 learner lookups,
                // V23 units hierarchy, V25 compatibility matrix.
                "idx_game_results_user_game",
                "idx_game_results_user_played",
                "idx_xp_transactions_user_ref",
                "idx_avatars_rarity",
                "idx_avatars_subject",
                "idx_avatars_active",
                "idx_credit_ledger_user_created",
                "idx_credit_ledger_user_ref",
                "idx_user_avatars_user",
                "idx_user_avatars_avatar",
                "idx_learner_profiles_equipped_avatar",
                "idx_learner_profiles_total_xp",
                "idx_users_status_created",
                "idx_units_subject_id",
                "idx_topics_unit_id",
                "idx_subject_game_compat_subject",
                "idx_subject_game_compat_game");
    }

    @Test
    void seedSubjectsArePresentOnRealMySql() {
        Long seededSubjects = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM subjects WHERE id LIKE '11111111-%'", Long.class);
        // 5 Phase 1 subjects (V11) plus 6 subject worlds (V22); both batches
        // share the deterministic 11111111- namespace.
        assertThat(seededSubjects).isEqualTo(11);
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
