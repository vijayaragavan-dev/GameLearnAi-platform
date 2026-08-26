package com.gamelearn.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.entity.Subject;
import com.gamelearn.entity.User;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.UserRepository;

/**
 * Verifies that the persistence layer supports atomic multi-write operations
 * with correct rollback (Database Specification section 30) — without
 * implementing any future business workflow.
 */
@SpringBootTest
@ActiveProfiles("test")
@Import(TransactionRollbackTest.AtomicWriter.class)
class TransactionRollbackTest {

    @Autowired
    private AtomicWriter atomicWriter;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private int userCount(String email) {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM users WHERE email = ?", Integer.class, email);
        return count == null ? 0 : count;
    }

    @Test
    void failedAtomicWriteLeavesNoPartialData() {
        String email = "rollback-" + UUID.randomUUID() + "@example.test";
        assertThat(userCount(email)).isZero();

        assertThatThrownBy(() -> atomicWriter.writeTwoRowsThenFail(email))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("simulated failure");

        assertThat(userCount(email)).as("user must be rolled back").isZero();
        assertThat(userCount("rollback-" + UUID.randomUUID() + "@example.test")).isZero();
    }

    @Test
    void successfulAtomicWritePersistsAllRows() {
        String email = "atomic-" + UUID.randomUUID() + "@example.test";

        atomicWriter.writeTwoRowsAtomically(email);

        assertThat(userCount(email)).isEqualTo(1);
    }

    @Service
    static class AtomicWriter {

        private final UserRepository userRepository;
        private final SubjectRepository subjectRepository;

        AtomicWriter(UserRepository userRepository, SubjectRepository subjectRepository) {
            this.userRepository = userRepository;
            this.subjectRepository = subjectRepository;
        }

        @Transactional
        void writeTwoRowsThenFail(String email) {
            User user = new User();
            user.setEmail(email);
            user.setPasswordHash("$2a$rollback-hash");
            user.setDisplayName("Rollback Probe");
            userRepository.saveAndFlush(user);

            Subject subject = PersistenceTestFixtures.subject("rollback");
            subjectRepository.saveAndFlush(subject);

            throw new IllegalStateException("simulated failure after two inserts");
        }

        @Transactional
        void writeTwoRowsAtomically(String email) {
            User user = new User();
            user.setEmail(email);
            user.setPasswordHash("$2a$atomic-hash");
            user.setDisplayName("Atomic Probe");
            userRepository.saveAndFlush(user);

            Subject subject = PersistenceTestFixtures.subject("atomic");
            subjectRepository.saveAndFlush(subject);
        }
    }
}
