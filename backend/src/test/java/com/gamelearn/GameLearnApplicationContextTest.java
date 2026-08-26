package com.gamelearn;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.core.env.Environment;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import javax.sql.DataSource;

@SpringBootTest
@ActiveProfiles("test")
class GameLearnApplicationContextTest {

    @Autowired
    private Environment environment;

    @Autowired
    private DataSource dataSource;

    @Test
    void applicationContextLoads() {
        assertThat(dataSource).isNotNull();
    }

    @Test
    void databaseConnectivityWorks() {
        JdbcTemplate jdbcTemplate = new JdbcTemplate(dataSource);
        Integer result = jdbcTemplate.queryForObject("SELECT 1", Integer.class);
        assertThat(result).isEqualTo(1);
    }

    @Test
    void flywayBaselineMigrationWasApplied() {
        JdbcTemplate jdbcTemplate = new JdbcTemplate(dataSource);
        Integer appliedMigrations = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM flyway_schema_history WHERE version = '1' AND success = TRUE",
                Integer.class);
        assertThat(appliedMigrations).isEqualTo(1);
    }

    @Test
    void hibernateNeverOwnsSchemaEvolution() {
        assertThat(environment.getProperty("spring.jpa.hibernate.ddl-auto")).isEqualTo("none");
        assertThat(environment.getProperty("spring.jpa.open-in-view")).isEqualTo("false");
    }

    @Test
    void actuatorExposesOnlySafeEndpoints() {
        String exposed = environment.getProperty("management.endpoints.web.exposure.include");
        assertThat(exposed).isEqualTo("health,info");
    }
}
