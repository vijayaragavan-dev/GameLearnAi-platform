package com.gamelearn.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import javax.sql.DataSource;

/**
 * Docker-free verification that the complete Flyway migration chain produces
 * every table of the approved GameLearn AI schema (Database Specification
 * section 6). Runs against H2 in MySQL compatibility mode.
 */
@SpringBootTest
@ActiveProfiles("test")
class SchemaIntegrityTest {

    private static final List<String> EXPECTED_TABLES = List.of(
            "users", "learner_profiles", "subjects", "topics", "lessons",
            "learning_paths", "learning_path_nodes", "quizzes", "questions",
            "quiz_questions", "quiz_attempts", "question_attempts",
            "topic_mastery", "progress", "recommendations", "xp_transactions",
            "achievements", "user_achievements", "streaks", "ai_interactions");

    @Autowired
    private DataSource dataSource;

    @Test
    void migrationChainCreatesEverySpecifiedTable() throws Exception {
        List<String> tables = new ArrayList<>();
        try (Connection connection = dataSource.getConnection()) {
            DatabaseMetaData metadata = connection.getMetaData();
            try (ResultSet rs = metadata.getTables(null, null, "%", new String[] { "TABLE" })) {
                while (rs.next()) {
                    tables.add(rs.getString("TABLE_NAME").toLowerCase(Locale.ROOT));
                }
            }
        }

        assertThat(tables).containsAll(EXPECTED_TABLES);
    }
}
