package com.gamelearn.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.LocalDate;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import com.gamelearn.entity.Achievement;
import com.gamelearn.entity.Streak;
import com.gamelearn.entity.User;
import com.gamelearn.entity.UserAchievement;
import com.gamelearn.entity.XpTransaction;
import com.gamelearn.repository.AchievementRepository;
import com.gamelearn.repository.StreakRepository;
import com.gamelearn.repository.UserAchievementRepository;
import com.gamelearn.repository.UserRepository;
import com.gamelearn.repository.XpTransactionRepository;

@SpringBootTest
@ActiveProfiles("test")
class GamificationRepositoryTest {

    @Autowired
    private XpTransactionRepository xpTransactionRepository;

    @Autowired
    private AchievementRepository achievementRepository;

    @Autowired
    private UserAchievementRepository userAchievementRepository;

    @Autowired
    private StreakRepository streakRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void xpHistoryRowPersistsWithReference() {
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("xp"));
        XpTransaction transaction = PersistenceTestFixtures.xpTransaction(user);
        transaction.setEventType(com.gamelearn.entity.enums.XpEventType.STREAK_BONUS);
        transaction.setAmount(10);
        XpTransaction saved = xpTransactionRepository.saveAndFlush(transaction);

        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getCreatedAt()).isNotNull();

        var raw = jdbcTemplate.queryForMap(
                "SELECT amount, event_type, reference_type, reference_id FROM xp_transactions WHERE id = ?",
                saved.getId());
        assertThat(raw.get("amount")).isEqualTo(10);
        assertThat(raw.get("event_type")).isEqualTo("STREAK_BONUS");
        assertThat(raw.get("reference_type")).isEqualTo("QUIZ_ATTEMPT");
        assertThat((String) raw.get("reference_id")).hasSize(36);
    }

    @Test
    void duplicateAchievementCodeIsRejected() {
        achievementRepository.saveAndFlush(PersistenceTestFixtures.achievement("codedup"));

        Achievement duplicate = PersistenceTestFixtures.achievement("other");
        // Reuse the exact code of the first achievement.
        duplicate.setCode(jdbcTemplate.queryForObject(
                "SELECT code FROM achievements ORDER BY created_at DESC LIMIT 1", String.class));

        assertThatThrownBy(() -> achievementRepository.saveAndFlush(duplicate))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void duplicateUserAchievementIsRejectedByDatabase() {
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("uadup"));
        Achievement achievement = achievementRepository.saveAndFlush(
                PersistenceTestFixtures.achievement("uadup"));

        userAchievementRepository.saveAndFlush(
                PersistenceTestFixtures.userAchievement(user, achievement));

        assertThatThrownBy(() -> userAchievementRepository.saveAndFlush(
                PersistenceTestFixtures.userAchievement(user, achievement)))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void onlyOneStreakRowPerUserIsAllowed() {
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("streakdup"));
        streakRepository.saveAndFlush(PersistenceTestFixtures.streak(user));

        assertThatThrownBy(() -> streakRepository.saveAndFlush(
                PersistenceTestFixtures.streak(user)))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void streakFieldsRoundTrip() {
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("streakrt"));

        Streak streak = PersistenceTestFixtures.streak(user);
        streak.setCurrentStreakDays(4);
        streak.setLongestStreakDays(9);
        streak.setLastLearningDate(LocalDate.of(2026, 8, 23));
        Streak saved = streakRepository.saveAndFlush(streak);

        assertThat(saved.getCreatedAt()).isNotNull();
        assertThat(saved.getUpdatedAt()).isNotNull();

        Streak reloaded = streakRepository.findById(saved.getId()).orElseThrow();
        assertThat(reloaded.getCurrentStreakDays()).isEqualTo(4);
        assertThat(reloaded.getLongestStreakDays()).isEqualTo(9);
        assertThat(reloaded.getLastLearningDate()).isEqualTo(LocalDate.of(2026, 8, 23));
        assertThat(reloaded.getTimezone()).isEqualTo("UTC");
        assertThat(reloaded.getUser().getId()).isEqualTo(user.getId());
    }
}
