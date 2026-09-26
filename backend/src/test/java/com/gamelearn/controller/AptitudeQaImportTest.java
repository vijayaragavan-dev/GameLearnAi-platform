package com.gamelearn.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

/**
 * REALM-001 Phase QA-2: Quantitative Aptitude learning-content import (V36).
 *
 * <p>Pins the exact seeded shape — 1 unit, 34 topics, 34 lessons — plus the
 * deliberate absence of graded rows (the CodeTantra QA source carries zero
 * authoritative answers, so no questions, quizzes, associations, or
 * GameContent QUESTION rows may exist for these topics). Existing Aptitude,
 * LR, and CS content must be untouched.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AptitudeQaImportTest extends AbstractCoreApiTest {

    private static final String APTITUDE_SUBJECT = "55555555-5555-5555-5555-555555555501";
    private static final String QA_UNIT = "b1b1b1b1-b1b1-b1b1-b1b1-b1b1b1b1b101";

    private static final String[] QA_TOPICS_IN_ORDER = {
        "Algebra", "Geometry", "Numbers", "Simplification & Approximation",
        "Ratio & Proportion", "Boats & Streams", "Simple Interest", "Average",
        "Progressions (AP, GP, HP)", "Trigonometry", "Logarithms", "Calendar",
        "Banker's Discount", "Surds & Indices", "Profit & Loss", "Time & Distance",
        "Pipes & Cisterns", "Partnership", "Permutations & Combinations",
        "Races & Game of Skill", "Chain Rule", "True Discount", "Percentage",
        "Alligation or Mixture", "Time & Work", "Compound Interest", "Statistics",
        "Stocks & Shares", "Mensuration", "Clocks", "Installments",
        "H.C.F. & L.C.M. of Numbers", "Probability", "Problems on Ages"
    };

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void quantitativeAptitudeUnitExists() {
        Integer units = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM units WHERE id = ? AND subject_id = ? AND is_active = TRUE"
                        + " AND name = 'Quantitative Aptitude' AND display_order = 3",
                Integer.class, QA_UNIT, APTITUDE_SUBJECT);
        assertThat(units).isEqualTo(1);
    }

    @Test
    void exactlyThirtyFourQaTopicsUnderNewUnit() {
        Integer topics = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM topics WHERE subject_id = ? AND unit_id = ? AND is_active = TRUE"
                        + " AND id LIKE 'b2b2b2b2-%'",
                Integer.class, APTITUDE_SUBJECT, QA_UNIT);
        assertThat(topics).isEqualTo(34);
    }

    @Test
    void topicNamesAndOrderMatchSourceExactly() {
        for (int i = 0; i < QA_TOPICS_IN_ORDER.length; i++) {
            String name = jdbcTemplate.queryForObject(
                    "SELECT name FROM topics WHERE subject_id = ? AND unit_id = ? AND display_order = ?",
                    String.class, APTITUDE_SUBJECT, QA_UNIT, 29 + i);
            assertThat(name).isEqualTo(QA_TOPICS_IN_ORDER[i]);
        }
    }

    @Test
    void exactlyThirtyFourLessonsOnePerTopic() {
        Integer lessons = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM lessons WHERE id LIKE 'b3b3b3b3-%' AND is_active = TRUE",
                Integer.class);
        assertThat(lessons).isEqualTo(34);
        Integer orphaned = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM lessons l WHERE l.id LIKE 'b3b3b3b3-%'"
                        + " AND NOT EXISTS (SELECT 1 FROM topics t WHERE t.id = l.topic_id"
                        + " AND t.unit_id = ? AND t.subject_id = ?)",
                Integer.class, QA_UNIT, APTITUDE_SUBJECT);
        assertThat(orphaned).isEqualTo(0);
        Integer perTopic = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM (SELECT topic_id FROM lessons WHERE id LIKE 'b3b3b3b3-%'"
                        + " GROUP BY topic_id HAVING COUNT(*) <> 1) t",
                Integer.class);
        assertThat(perTopic).isEqualTo(0);
    }

    @Test
    void lessonContentIsNonEmptyVerbatimHtml() {
        Integer empty = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM lessons WHERE id LIKE 'b3b3b3b3-%'"
                        + " AND (content IS NULL OR content = '')",
                Integer.class);
        assertThat(empty).isEqualTo(0);
        String algebra = jdbcTemplate.queryForObject(
                "SELECT l.content FROM lessons l JOIN topics t ON t.id = l.topic_id"
                        + " WHERE t.subject_id = ? AND t.name = 'Algebra' AND l.id LIKE 'b3b3b3b3-%'",
                String.class, APTITUDE_SUBJECT);
        assertThat(algebra).contains("CONCEPTUAL FOUNDATION");
        assertThat(algebra).contains("$");
    }

    @Test
    void noQaQuestionRowsWereCreated() {
        Integer questions = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM questions q JOIN topics t ON t.id = q.topic_id"
                        + " WHERE t.unit_id = ?",
                Integer.class, QA_UNIT);
        assertThat(questions).isEqualTo(0);
    }

    @Test
    void noQaQuizRowsWereCreated() {
        Integer quizzes = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM quizzes q JOIN topics t ON t.id = q.topic_id"
                        + " WHERE t.unit_id = ?",
                Integer.class, QA_UNIT);
        assertThat(quizzes).isEqualTo(0);
    }

    @Test
    void noQaQuizAssociationsWereCreated() {
        Integer associations = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM quiz_questions qq JOIN quizzes q ON q.id = qq.quiz_id"
                        + " JOIN topics t ON t.id = q.topic_id WHERE t.unit_id = ?",
                Integer.class, QA_UNIT);
        assertThat(associations).isEqualTo(0);
    }

    @Test
    void quizApiHonestlyReportsNoQuizForQaTopic() throws Exception {
        String[] learner = registerLearner("qaquiz");
        String topicId = jdbcTemplate.queryForObject(
                "SELECT id FROM topics WHERE subject_id = ? AND name = 'Algebra'",
                String.class, APTITUDE_SUBJECT);
        mockMvc.perform(get("/api/v1/quiz/{id}", topicId)
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isNotFound());
    }

    @Test
    void gameContentApiHonestlyReportsNoQuestionsForQaTopic() throws Exception {
        String[] learner = registerLearner("qacontent");
        String topicId = jdbcTemplate.queryForObject(
                "SELECT id FROM topics WHERE subject_id = ? AND name = 'Probability'",
                String.class, APTITUDE_SUBJECT);
        mockMvc.perform(get("/api/v1/game-content")
                        .header("Authorization", bearer(learner[0]))
                        .param("subjectId", APTITUDE_SUBJECT)
                        .param("topicId", topicId)
                        .param("gameType", "quiz_battle"))
                .andExpect(status().isNotFound());
    }

    @Test
    void existingAptitudeContentIsUntouched() {
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM topics WHERE subject_id = ? AND id LIKE '77777777-%'",
                Integer.class, APTITUDE_SUBJECT)).isEqualTo(6);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM questions WHERE id LIKE '88888888-%'",
                Integer.class)).isEqualTo(18);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM units WHERE subject_id = ? AND id LIKE '66666666-%'",
                Integer.class, APTITUDE_SUBJECT)).isEqualTo(2);
    }

    @Test
    void existingLrContentIsUntouched() {
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM topics WHERE id LIKE 'dddddddd-%'",
                Integer.class)).isEqualTo(22);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM quizzes WHERE id LIKE 'eeeeeeee-%'",
                Integer.class)).isEqualTo(22);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM questions WHERE id LIKE 'e0e0e0e0-%'",
                Integer.class)).isEqualTo(330);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM quiz_questions WHERE id LIKE 'f0f0f0f0-%'",
                Integer.class)).isEqualTo(330);
    }
}
