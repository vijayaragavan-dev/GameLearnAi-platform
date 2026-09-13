package com.gamelearn.subject;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import com.gamelearn.entity.Subject;
import com.gamelearn.repository.SubjectRepository;

/**
 * Batch 1 / Phase 1: subject-world foundation verification.
 *
 * <p>Proves the 11-world catalog: the 5 existing V11 subjects are preserved
 * byte-for-byte and exactly 6 new canonical subjects exist. All assertions
 * are scoped to the deterministic {@code 11111111-...} seed namespace so
 * they stay stable when other test classes create ad-hoc subjects in the
 * shared test context.
 */
@SpringBootTest
@ActiveProfiles("test")
class SubjectWorldBatch1Test {

    private static final List<String> EXISTING_IDS = List.of(
            "11111111-1111-1111-1111-111111111101",
            "11111111-1111-1111-1111-111111111102",
            "11111111-1111-1111-1111-111111111103",
            "11111111-1111-1111-1111-111111111104",
            "11111111-1111-1111-1111-111111111105");

    private static final Map<String, String> EXPECTED_EXISTING = Map.of(
            "11111111-1111-1111-1111-111111111101", "Programming",
            "11111111-1111-1111-1111-111111111102", "Computer Networks",
            "11111111-1111-1111-1111-111111111103", "DBMS",
            "11111111-1111-1111-1111-111111111104", "Operating Systems",
            "11111111-1111-1111-1111-111111111105", "Data Structures");

    private static final Map<String, String> EXPECTED_NEW = Map.of(
            "11111111-1111-1111-1111-111111111106", "Object Oriented Programming",
            "11111111-1111-1111-1111-111111111107", "Object Oriented Software Engineering",
            "11111111-1111-1111-1111-111111111108", "Web Technologies",
            "11111111-1111-1111-1111-111111111109", "Artificial Intelligence and Machine Learning",
            "11111111-1111-1111-1111-111111111110", "Foundations of Data Science",
            "11111111-1111-1111-1111-111111111111", "Design and Analysis of Algorithms");

    @Autowired
    private SubjectRepository subjectRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void exactlyElevenCanonicalSubjectsExist() {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM subjects WHERE id LIKE '11111111-%'", Integer.class);
        assertThat(count).isEqualTo(11);
    }

    @Test
    void allCanonicalSubjectsAreActive() {
        Integer inactive = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM subjects WHERE id LIKE '11111111-%' AND is_active <> TRUE",
                Integer.class);
        assertThat(inactive).isEqualTo(0);
    }

    @Test
    void existingFiveSubjectsPreservedExactly() {
        for (String id : EXISTING_IDS) {
            Subject subject = subjectRepository.findById(UUID.fromString(id)).orElseThrow();
            assertThat(subject.getName()).isEqualTo(EXPECTED_EXISTING.get(id));
            assertThat(subject.isActive()).isTrue();
        }
        assertThat(subjectRepository.findById(UUID.fromString(EXISTING_IDS.get(0))).orElseThrow()
                        .getDisplayOrder())
                .isEqualTo(1);
        assertThat(subjectRepository.findById(UUID.fromString(EXISTING_IDS.get(4))).orElseThrow()
                        .getDisplayOrder())
                .isEqualTo(5);
    }

    @Test
    void sixNewSubjectsExistWithDeterministicIds() {
        EXPECTED_NEW.forEach((id, name) -> {
            Subject subject = subjectRepository.findById(UUID.fromString(id)).orElseThrow();
            assertThat(subject.getName()).isEqualTo(name);
            assertThat(subject.isActive()).isTrue();
        });
        assertThat(subjectRepository.findById(UUID.fromString("11111111-1111-1111-1111-111111111106"))
                        .orElseThrow()
                        .getDisplayOrder())
                .isEqualTo(6);
        assertThat(subjectRepository.findById(UUID.fromString("11111111-1111-1111-1111-111111111111"))
                        .orElseThrow()
                        .getDisplayOrder())
                .isEqualTo(11);
    }

    @Test
    void noDuplicateCanonicalSubjectNames() {
        List<Map<String, Object>> dupes = jdbcTemplate.queryForList(
                "SELECT name, COUNT(*) AS c FROM subjects WHERE id LIKE '11111111-%' "
                        + "GROUP BY name HAVING COUNT(*) > 1");
        assertThat(dupes).isEmpty();
    }

    @Test
    void canonicalDisplayOrdersAreUniqueAndSequential() {
        List<Integer> orders = jdbcTemplate.queryForList(
                "SELECT display_order FROM subjects WHERE id LIKE '11111111-%' ORDER BY display_order",
                Integer.class);
        assertThat(orders).containsExactly(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11);
    }

    @Test
    void existingSubjectSyllabusRemainsIntact() {
        Integer activeTopics = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM topics t JOIN subjects s ON s.id = t.subject_id "
                        + "WHERE s.id IN ('11111111-1111-1111-1111-111111111101','11111111-1111-1111-1111-111111111102',"
                        + "'11111111-1111-1111-1111-111111111103','11111111-1111-1111-1111-111111111104',"
                        + "'11111111-1111-1111-1111-111111111105') AND t.is_active = TRUE",
                Integer.class);
        assertThat(activeTopics).isEqualTo(15);
    }

    @Test
    void reseedIsRestartSafeAndDuplicateNameIsRejected() {
        // Replaying the V22 seed guard must not create duplicates.
        EXPECTED_NEW.forEach((id, name) -> {
            int updated = jdbcTemplate.update(
                    "INSERT INTO subjects (id, name, description, icon_key, is_active, display_order, created_at, updated_at) "
                            + "SELECT ?, ?, 'reseed probe', 'subject_probe', TRUE, 99, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL "
                            + "WHERE NOT EXISTS (SELECT 1 FROM subjects WHERE id = ?)",
                    id, name, id);
            assertThat(updated).isEqualTo(0);
        });
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM subjects WHERE id LIKE '11111111-%'", Integer.class);
        assertThat(count).isEqualTo(11);

        // The unique name constraint still guards canonical identity.
        Subject dupe = new Subject();
        dupe.setName("Programming");
        dupe.setDescription("dupe probe");
        dupe.setIconKey("subject_probe_dupe");
        dupe.setActive(true);
        dupe.setDisplayOrder(99);
        assertThatThrownBy(() -> subjectRepository.saveAndFlush(dupe))
                .isInstanceOf(DataIntegrityViolationException.class);
    }
}
