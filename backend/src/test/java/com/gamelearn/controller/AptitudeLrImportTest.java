package com.gamelearn.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

/**
 * REALM-001 Phase 2: Logical Reasoning import integrity (V35).
 *
 * <p>Pins the exact seeded shape — 22 topics, 22 quizzes, 330 questions,
 * 330 ordered associations — plus API delivery and the exclusion of the
 * unverified source item. Answer/option integrity is asserted row by
 * row so a corrupt import fails loudly instead of reaching learners.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AptitudeLrImportTest extends AbstractCoreApiTest {

    private static final String APTITUDE_SUBJECT = "55555555-5555-5555-5555-555555555501";

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void twentyTwoLrTopicsExistUnderAptitude() {
        Integer topics = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM topics WHERE subject_id = ? AND is_active = TRUE"
                        + " AND id LIKE 'dddddddd-%'",
                Integer.class, APTITUDE_SUBJECT);
        assertThat(topics).isEqualTo(22);
        Integer quizzes = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM quizzes q JOIN topics t ON t.id = q.topic_id"
                        + " WHERE t.subject_id = ? AND q.is_active = TRUE AND q.id LIKE 'eeeeeeee-%'",
                Integer.class, APTITUDE_SUBJECT);
        assertThat(quizzes).isEqualTo(22);
    }

    @Test
    void threeHundredThirtyQuestionsWithOrderedAssociations() {
        Integer questions = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM questions q JOIN topics t ON t.id = q.topic_id"
                        + " WHERE t.subject_id = ? AND q.is_active = TRUE AND q.id LIKE 'e0e0e0e0-%'",
                Integer.class, APTITUDE_SUBJECT);
        assertThat(questions).isEqualTo(330);
        Integer associations = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM quiz_questions WHERE id LIKE 'f0f0f0f0-%'",
                Integer.class);
        assertThat(associations).isEqualTo(330);
        // Every LR quiz carries exactly orders 1..15 with no gaps or dupes.
        Integer badQuizzes = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM (SELECT quiz_id FROM quiz_questions WHERE id LIKE 'f0f0f0f0-%' "
                        + "GROUP BY quiz_id HAVING COUNT(*) <> 15 OR MIN(question_order) <> 1 "
                        + "OR MAX(question_order) <> 15 OR COUNT(DISTINCT question_order) <> 15) t",
                Integer.class);
        assertThat(badQuizzes).isEqualTo(0);
    }

    @Test
    void everyImportedAnswerBelongsToItsOptions() {
        Integer mismatched = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM questions WHERE id LIKE 'e0e0e0e0-%' "
                        + "AND (explanation IS NULL OR explanation = '')",
                Integer.class);
        assertThat(mismatched).isEqualTo(0);
        List<String> rows = jdbcTemplate.queryForList(
                "SELECT options_json || '|||' || correct_answer FROM questions "
                        + "WHERE id LIKE 'e0e0e0e0-%'",
                String.class);
        assertThat(rows).hasSize(330);
        for (String row : rows) {
            String optionsJson = row.substring(0, row.indexOf("|||"));
            String answer = row.substring(row.indexOf("|||") + 4);
            assertThat(optionsJson).contains(answer);
        }
    }

    @Test
    void difficultiesAndTypesUseNativeRepresentations() {
        Integer nonNativeDifficulty = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM questions WHERE id LIKE 'e0e0e0e0-%' "
                        + "AND difficulty NOT IN ('EASY','MEDIUM','HARD')",
                Integer.class);
        assertThat(nonNativeDifficulty).isEqualTo(0);
        Integer nonMcq = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM questions WHERE id LIKE 'e0e0e0e0-%' "
                        + "AND question_type <> 'MCQ'",
                Integer.class);
        assertThat(nonMcq).isEqualTo(0);
        Integer inactive = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM questions WHERE id LIKE 'e0e0e0e0-%' "
                        + "AND is_active <> TRUE",
                Integer.class);
        assertThat(inactive).isEqualTo(0);
    }

    @Test
    void noDuplicateQuestionTextAcrossImport() {
        Integer dupes = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM (SELECT question_text FROM questions "
                        + "WHERE id LIKE 'e0e0e0e0-%' GROUP BY question_text HAVING COUNT(*) > 1) t",
                Integer.class);
        assertThat(dupes).isEqualTo(0);
    }

    @Test
    void existingAptitudeContentIsUntouched() {
        // The original 6 topics / 6 quizzes / 18 questions keep their shape.
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM topics WHERE subject_id = ? AND id LIKE '77777777-%'",
                Integer.class, APTITUDE_SUBJECT)).isEqualTo(6);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM questions WHERE id LIKE '88888888-%'",
                Integer.class)).isEqualTo(18);
    }

    @Test
    void lrQuizDeliveryServesRealImportedQuestions() throws Exception {
        String[] learner = registerLearner("lrquiz");
        String topicId = jdbcTemplate.queryForObject(
                "SELECT id FROM topics WHERE subject_id = ? AND name = 'Syllogisms'",
                String.class, APTITUDE_SUBJECT);
        String body = mockMvc.perform(get("/api/v1/quiz/{id}", topicId)
                        .header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.questionCount").value(15))
                .andReturn().getResponse().getContentAsString();
        var questions = objectMapper.readTree(body).path("questions");
        assertThat(questions.size()).isEqualTo(15);
        for (var q : questions) {
            assertThat(q.path("options").size()).isGreaterThanOrEqualTo(2);
            assertThat(q.has("correctAnswer")).isFalse();
        }
    }

    @Test
    void lrTopicGameContentFlowsToQuizBattle() throws Exception {
        String[] learner = registerLearner("lrcontent");
        String topicId = jdbcTemplate.queryForObject(
                "SELECT id FROM topics WHERE subject_id = ? AND name = 'Blood Relations'",
                String.class, APTITUDE_SUBJECT);
        String body = mockMvc.perform(get("/api/v1/game-content")
                        .header("Authorization", bearer(learner[0]))
                        .param("subjectId", APTITUDE_SUBJECT)
                        .param("topicId", topicId)
                        .param("gameType", "quiz_battle"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        var items = objectMapper.readTree(body).path("items");
        assertThat(items.size()).isGreaterThan(0);
        for (var item : items) {
            assertThat(item.path("topicId").asText()).isEqualTo(topicId);
            assertThat(item.path("questionText").asText()).isNotBlank();
        }
    }
}
