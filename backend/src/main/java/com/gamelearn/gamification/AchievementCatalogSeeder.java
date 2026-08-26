package com.gamelearn.gamification;

import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.gamelearn.entity.Achievement;
import com.gamelearn.repository.AchievementRepository;

/**
 * Idempotent runtime seeder for the six approved catalog entries
 * (Gamification Specification section 7.3 — insert-if-code-absent, never
 * updates existing rows, NOT a Flyway migration). Deterministic order.
 */
@Component
public class AchievementCatalogSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(AchievementCatalogSeeder.class);

    private final AchievementRepository achievementRepository;

    public AchievementCatalogSeeder(AchievementRepository achievementRepository) {
        this.achievementRepository = achievementRepository;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        for (Map.Entry<String, SeedSpec> entry : CATALOG.entrySet()) {
            String code = entry.getKey();
            SeedSpec spec = entry.getValue();
            if (achievementRepository.findByCode(code).isPresent()) {
                continue; // never update an existing row (spec section 7.3)
            }
            Achievement row = new Achievement();
            row.setCode(code);
            row.setName(spec.name());
            row.setDescription(spec.description());
            row.setIconKey(spec.iconKey());
            row.setRuleType(spec.ruleType());
            row.setRuleConfigJson("{\"threshold\": " + spec.threshold() + "}");
            row.setXpReward(spec.xpReward());
            row.setActive(true);
            try {
                achievementRepository.save(row);
                log.info("GAM_ACHIEVEMENT_SEEDED code={}", code);
            } catch (DataIntegrityViolationException raced) {
                // Another instance seeded the same code concurrently: fine.
            }
        }
    }

    private record SeedSpec(String name, String description, String iconKey,
                            String ruleType, int threshold, int xpReward) {
    }

    /** Exact six-entry starter catalog (owner-approved, spec section 7.3). */
    private static final Map<String, SeedSpec> CATALOG = Map.of(
            "FIRST_QUIZ", new SeedSpec("First Steps",
                    "Complete your first quiz.", "ach_first_quiz",
                    AchievementRules.COUNT_QUIZ_ATTEMPTS, 1, 20),
            "TEN_QUIZZES", new SeedSpec("Persistent Learner",
                    "Submit ten quizzes and keep the momentum going.", "ach_persistent_learner",
                    AchievementRules.COUNT_QUIZ_ATTEMPTS, 10, 50),
            "PERFECT_SCORE", new SeedSpec("Flawless Victory",
                    "Score a perfect 100% on any quiz.", "ach_flawless_victory",
                    AchievementRules.SINGLE_ATTEMPT_ACCURACY, 100, 30),
            "FIRST_MASTERED", new SeedSpec("Topic Mastered",
                    "Reach MASTERED mastery on a topic.", "ach_topic_mastered",
                    AchievementRules.TOPIC_MASTERY_COUNT, 1, 40),
            "STREAK_3", new SeedSpec("Three-Day Rhythm",
                    "Learn three days in a row.", "ach_streak_3",
                    AchievementRules.STREAK_DAYS, 3, 20),
            "WEEK_WARRIOR", new SeedSpec("Week Warrior",
                    "Maintain a 7-day learning streak.", "ach_week_warrior",
                    AchievementRules.STREAK_DAYS, 7, 60));
}
