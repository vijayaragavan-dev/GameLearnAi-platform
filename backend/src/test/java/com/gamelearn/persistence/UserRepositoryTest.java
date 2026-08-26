package com.gamelearn.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.UserStatus;
import com.gamelearn.repository.UserRepository;

@SpringBootTest
@ActiveProfiles("test")
class UserRepositoryTest {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void savesAndFindsUserWithUuidId() {
        User user = PersistenceTestFixtures.user("find");
        User saved = userRepository.saveAndFlush(user);

        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getCreatedAt()).isNotNull();
        assertThat(saved.getUpdatedAt()).isNotNull();

        User reloaded = userRepository.findById(saved.getId()).orElseThrow();
        assertThat(reloaded.getEmail()).isEqualTo(user.getEmail());
        assertThat(reloaded.getDisplayName()).isEqualTo(user.getDisplayName());
    }

    @Test
    void updatesUserFields() {
        User saved = userRepository.saveAndFlush(PersistenceTestFixtures.user("update"));

        saved.setDisplayName("Updated Name");
        saved.setStatus(UserStatus.SUSPENDED);
        userRepository.saveAndFlush(saved);

        User reloaded = userRepository.findById(saved.getId()).orElseThrow();
        assertThat(reloaded.getDisplayName()).isEqualTo("Updated Name");
        assertThat(reloaded.getStatus()).isEqualTo(UserStatus.SUSPENDED);
    }

    @Test
    void deletesUser() {
        User saved = userRepository.saveAndFlush(PersistenceTestFixtures.user("delete"));
        userRepository.delete(saved);
        userRepository.flush();

        assertThat(userRepository.findById(saved.getId())).isEmpty();
    }

    @Test
    void duplicateEmailIsRejectedByDatabase() {
        User first = userRepository.saveAndFlush(PersistenceTestFixtures.user("dup"));

        User second = PersistenceTestFixtures.user("dup");
        second.setEmail(first.getEmail());

        assertThatThrownBy(() -> userRepository.saveAndFlush(second))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void statusIsPersistedAsStringNotOrdinal() {
        User saved = userRepository.saveAndFlush(PersistenceTestFixtures.user("enum"));

        String raw = jdbcTemplate.queryForObject(
                "SELECT status FROM users WHERE id = ?", String.class, saved.getId());
        assertThat(raw).isEqualTo("ACTIVE");

        saved.setStatus(UserStatus.SUSPENDED);
        userRepository.saveAndFlush(saved);

        raw = jdbcTemplate.queryForObject(
                "SELECT status FROM users WHERE id = ?", String.class, saved.getId());
        assertThat(raw).isEqualTo("SUSPENDED");
    }
}
