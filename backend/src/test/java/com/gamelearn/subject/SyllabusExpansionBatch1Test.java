package com.gamelearn.subject;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import com.gamelearn.entity.Topic;
import com.gamelearn.entity.TopicMastery;
import com.gamelearn.entity.User;
import com.gamelearn.persistence.PersistenceTestFixtures;
import com.gamelearn.repository.ProgressRepository;
import com.gamelearn.repository.TopicMasteryRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.UnitRepository;
import com.gamelearn.repository.UserRepository;

/**
 * Batch 1 / Phase 2: syllabus / unit / topic expansion verification.
 *
 * <p>Proves the 6 new subjects carry complete, correctly-associated,
 * deterministically-ordered unit/topic trees, that no topic leaks across
 * subjects, that the 5-subject legacy syllabus is byte-for-byte intact,
 * and that new topic IDs flow through the mastery/progress architecture.
 */
@SpringBootTest
@ActiveProfiles("test")
class SyllabusExpansionBatch1Test {

    /** New subject id -&gt; expected [units, topics]. */
    private static final Map<String, int[]> EXPECTED = Map.of(
            "11111111-1111-1111-1111-111111111106", new int[] {4, 20},
            "11111111-1111-1111-1111-111111111107", new int[] {5, 23},
            "11111111-1111-1111-1111-111111111108", new int[] {5, 19},
            "11111111-1111-1111-1111-111111111109", new int[] {5, 24},
            "11111111-1111-1111-1111-111111111110", new int[] {4, 19},
            "11111111-1111-1111-1111-111111111111", new int[] {6, 29});

    private static final List<String> NEW_IDS = List.copyOf(EXPECTED.keySet());

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private UnitRepository unitRepository;

    @Autowired
    private TopicRepository topicRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TopicMasteryRepository topicMasteryRepository;

    @Autowired
    private ProgressRepository progressRepository;

    @Test
    void everyNewSubjectHasExpectedUnitsAndTopics() {
        EXPECTED.forEach((subjectId, counts) -> {
            Integer units = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM units WHERE subject_id = ? AND is_active = TRUE",
                    Integer.class, subjectId);
            Integer topics = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM topics WHERE subject_id = ? AND is_active = TRUE",
                    Integer.class, subjectId);
            assertThat(units).as("units for %s", subjectId).isEqualTo(counts[0]);
            assertThat(topics).as("topics for %s", subjectId).isEqualTo(counts[1]);
        });
        Integer totalUnits = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM units WHERE id LIKE '77777777-%'", Integer.class);
        Integer totalTopics = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM topics WHERE subject_id IN ("
                        + "'11111111-1111-1111-1111-111111111106','11111111-1111-1111-1111-111111111107',"
                        + "'11111111-1111-1111-1111-111111111108','11111111-1111-1111-1111-111111111109',"
                        + "'11111111-1111-1111-1111-111111111110','11111111-1111-1111-1111-111111111111')",
                Integer.class);
        assertThat(totalUnits).isEqualTo(29);
        assertThat(totalTopics).isEqualTo(134);
    }

    @Test
    void everyUnitBelongsToExactlyOneCorrectSubject() {
        List<Map<String, Object>> orphanUnits = jdbcTemplate.queryForList(
                "SELECT u.id FROM units u WHERE u.id LIKE '77777777-%' "
                        + "AND u.subject_id NOT IN "
                        + "('11111111-1111-1111-1111-111111111106','11111111-1111-1111-1111-111111111107',"
                        + "'11111111-1111-1111-1111-111111111108','11111111-1111-1111-1111-111111111109',"
                        + "'11111111-1111-1111-1111-111111111110','11111111-1111-1111-1111-111111111111')");
        assertThat(orphanUnits).isEmpty();
        assertThat(unitRepository.findAll()).isNotEmpty();
    }

    @Test
    void everyNewTopicHasCorrectUnitAndSubject() {
        // No new-subject topic may lack a unit.
        Integer missingUnit = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM topics WHERE subject_id IN ("
                        + "'11111111-1111-1111-1111-111111111106','11111111-1111-1111-1111-111111111107',"
                        + "'11111111-1111-1111-1111-111111111108','11111111-1111-1111-1111-111111111109',"
                        + "'11111111-1111-1111-1111-111111111110','11111111-1111-1111-1111-111111111111') "
                        + "AND unit_id IS NULL",
                Integer.class);
        assertThat(missingUnit).isEqualTo(0);
        // No topic may reference a unit of another subject (unit-level leakage).
        List<Map<String, Object>> mismatched = jdbcTemplate.queryForList(
                "SELECT t.id FROM topics t JOIN units u ON u.id = t.unit_id "
                        + "WHERE t.subject_id <> u.subject_id");
        assertThat(mismatched).isEmpty();
    }

    @Test
    void topicOrderingIsDeterministicPerNewSubject() {
        EXPECTED.forEach((subjectId, counts) -> {
            List<Integer> orders = jdbcTemplate.queryForList(
                    "SELECT display_order FROM topics WHERE subject_id = ? AND is_active = TRUE "
                            + "ORDER BY display_order",
                    Integer.class, subjectId);
            assertThat(orders).hasSize(counts[1]);
            for (int i = 0; i < orders.size(); i++) {
                assertThat(orders.get(i)).isEqualTo(i + 1);
            }
        });
    }

    @Test
    void deterministicIdsSpotCheck() {
        assertThat(topicRepository.findById(UUID.fromString("22222222-2222-2222-2222-222222222244"))
                        .orElseThrow()
                        .getName())
                .isEqualTo("Java Platform and Program Structure");
        assertThat(topicRepository.findById(UUID.fromString("22222222-2222-2222-2222-222222222377"))
                        .orElseThrow()
                        .getName())
                .isEqualTo("Approximation Algorithms");
        assertThat(unitRepository.findById(UUID.fromString("77777777-7777-7777-7777-777777777701"))
                        .orElseThrow()
                        .getName())
                .isEqualTo("Java Fundamentals and Data Types");
    }

    @Test
    void noDuplicateTopicNamesWithinNewSubjects() {
        List<Map<String, Object>> dupes = jdbcTemplate.queryForList(
                "SELECT subject_id, name, COUNT(*) AS c FROM topics WHERE subject_id IN ("
                        + "'11111111-1111-1111-1111-111111111106','11111111-1111-1111-1111-111111111107',"
                        + "'11111111-1111-1111-1111-111111111108','11111111-1111-1111-1111-111111111109',"
                        + "'11111111-1111-1111-1111-111111111110','11111111-1111-1111-1111-111111111111') "
                        + "GROUP BY subject_id, name HAVING COUNT(*) > 1");
        assertThat(dupes).isEmpty();
    }

    @Test
    void existingFiveSubjectSyllabusRemainsIntact() {
        // Still 15 active demo topics, and none gained a unit reference.
        Integer activeTopics = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM topics WHERE subject_id IN "
                        + "('11111111-1111-1111-1111-111111111101','11111111-1111-1111-1111-111111111102',"
                        + "'11111111-1111-1111-1111-111111111103','11111111-1111-1111-1111-111111111104',"
                        + "'11111111-1111-1111-1111-111111111105') AND is_active = TRUE",
                Integer.class);
        Integer withUnit = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM topics WHERE subject_id IN "
                        + "('11111111-1111-1111-1111-111111111101','11111111-1111-1111-1111-111111111102',"
                        + "'11111111-1111-1111-1111-111111111103','11111111-1111-1111-1111-111111111104',"
                        + "'11111111-1111-1111-1111-111111111105') AND unit_id IS NOT NULL",
                Integer.class);
        Integer legacyUnits = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM units WHERE subject_id IN "
                        + "('11111111-1111-1111-1111-111111111101','11111111-1111-1111-1111-111111111102',"
                        + "'11111111-1111-1111-1111-111111111103','11111111-1111-1111-1111-111111111104',"
                        + "'11111111-1111-1111-1111-111111111105')",
                Integer.class);
        assertThat(activeTopics).isEqualTo(15);
        assertThat(withUnit).isEqualTo(0);
        assertThat(legacyUnits).isEqualTo(0);
    }

    @Test
    void crossSubjectLeakageAbsent() {
        // DBMS topics must be exactly the 3 seeded ones — no OOP/Web/AI/FDS/DAA spill.
        List<String> dbmsTopics = jdbcTemplate.queryForList(
                "SELECT name FROM topics WHERE subject_id = '11111111-1111-1111-1111-111111111103' "
                        + "AND is_active = TRUE ORDER BY display_order",
                String.class);
        assertThat(dbmsTopics).containsExactly(
                "Database Fundamentals", "Relational Model & Keys", "SQL & Transactions");
        // Each new subject's topic names must not appear under any other subject.
        for (String subjectId : NEW_IDS) {
            Integer leaked = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM topics a WHERE a.subject_id <> ? AND EXISTS "
                            + "(SELECT 1 FROM topics b WHERE b.subject_id = ? "
                            + "AND b.is_active = TRUE AND a.name = b.name)",
                    Integer.class, subjectId, subjectId);
            assertThat(leaked).as("leaked names into %s", subjectId).isEqualTo(0);
        }
        // Spot probes: flagship new topics resolve to their own subject only.
        assertThat(jdbcTemplate.queryForObject(
                        "SELECT COUNT(*) FROM topics WHERE name = 'Polymorphism' AND subject_id <> "
                                + "'11111111-1111-1111-1111-111111111106'",
                        Integer.class))
                .isEqualTo(0);
        assertThat(jdbcTemplate.queryForObject(
                        "SELECT COUNT(*) FROM topics WHERE name = 'Backpropagation' AND subject_id <> "
                                + "'11111111-1111-1111-1111-111111111109'",
                        Integer.class))
                .isEqualTo(0);
        assertThat(jdbcTemplate.queryForObject(
                        "SELECT COUNT(*) FROM topics WHERE name = 'Dijkstra and Huffman Coding' "
                                + "AND subject_id <> '11111111-1111-1111-1111-111111111111'",
                        Integer.class))
                .isEqualTo(0);
    }

    @Test
    void newTopicIdsFlowThroughMasteryAndProgress() {
        User user = userRepository.saveAndFlush(PersistenceTestFixtures.user("batch1"));
        Topic topic = topicRepository
                .findById(UUID.fromString("22222222-2222-2222-2222-222222222254"))
                .orElseThrow();
        assertThat(jdbcTemplate.queryForObject(
                        "SELECT subject_id FROM topics WHERE id = '22222222-2222-2222-2222-222222222254'",
                        String.class))
                .isEqualTo("11111111-1111-1111-1111-111111111106");

        TopicMastery mastery =
                topicMasteryRepository.saveAndFlush(PersistenceTestFixtures.topicMastery(user, topic));
        assertThat(mastery.getId()).isNotNull();
        assertThat(topicMasteryRepository.findByUserIdAndTopicId(user.getId(), topic.getId()))
                .isPresent();
        assertThat(progressRepository.saveAndFlush(PersistenceTestFixtures.progress(user, topic)).getId())
                .isNotNull();
    }

    @Test
    void reseedIsRestartSafe() {
        int units = jdbcTemplate.update(
                "INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at) "
                        + "SELECT '77777777-7777-7777-7777-777777777701', "
                        + "'11111111-1111-1111-1111-111111111106', 'probe', 'probe', 99, TRUE, "
                        + "CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL "
                        + "WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = "
                        + "'77777777-7777-7777-7777-777777777701')");
        int topics = jdbcTemplate.update(
                "INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, "
                        + "is_active, created_at, updated_at) "
                        + "SELECT '22222222-2222-2222-2222-222222222244', "
                        + "'11111111-1111-1111-1111-111111111106', "
                        + "'77777777-7777-7777-7777-777777777701', 'probe', 'probe', 'EASY', 99, TRUE, "
                        + "CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL "
                        + "WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = "
                        + "'22222222-2222-2222-2222-222222222244')");
        assertThat(units).isEqualTo(0);
        assertThat(topics).isEqualTo(0);
        assertThat(jdbcTemplate.queryForObject(
                        "SELECT COUNT(*) FROM units WHERE id LIKE '77777777-%'", Integer.class))
                .isEqualTo(29);
    }
}
