package com.gamelearn.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;

import com.gamelearn.entity.Subject;

import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class SubjectApiTest extends AbstractCoreApiTest {

    private static final String SUBJECTS_URL = "/api/v1/subjects";

    @Test
    void listsOnlyActiveSubjectsOrderedByDisplayOrder() throws Exception {
        String[] learner = registerLearner("subj");
        Subject first = newActiveSubject("alphasubj", -10);
        Subject second = newActiveSubject("betasubj", 5);
        newInactiveSubject("hiddensubj");

        String response = mockMvc.perform(get(SUBJECTS_URL).header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andReturn()
                .getResponse()
                .getContentAsString();

        var names = objectMapper.readTree(response).findValuesAsText("name");
        int firstPos = names.indexOf(first.getName());
        int secondPos = names.indexOf(second.getName());
        int seededProgrammingPos = names.indexOf("Programming");

        assertThat(firstPos).isGreaterThanOrEqualTo(0);
        assertThat(seededProgrammingPos).isGreaterThanOrEqualTo(0);
        // display_order: -10 < 1 (seeded Programming) < 5
        assertThat(firstPos).isLessThan(seededProgrammingPos);
        assertThat(seededProgrammingPos).isLessThan(secondPos);
        // Inactive subjects are never listed.
        assertThat(names.stream().noneMatch(name -> name.contains("hiddensubj"))).isTrue();
    }

    @Test
    void subjectJsonShapeMatchesContract() throws Exception {
        String[] learner = registerLearner("shape");
        Subject subject = newActiveSubject("shapesubj", 42);

        mockMvc.perform(get(SUBJECTS_URL).header("Authorization", bearer(learner[0])))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.name == '" + subject.getName() + "')].id").isNotEmpty())
                .andExpect(jsonPath("$[?(@.name == '" + subject.getName() + "')].description")
                        .value("shapesubj description"))
                .andExpect(jsonPath("$[?(@.name == '" + subject.getName() + "')].iconKey")
                        .value("icon_shapesubj"))
                .andExpect(jsonPath("$[?(@.name == '" + subject.getName() + "')].isActive").value(true))
                .andExpect(jsonPath("$[?(@.name == '" + subject.getName() + "')].displayOrder").value(42));
    }

    @Test
    void subjectsRequireAuthentication() throws Exception {
        mockMvc.perform(get(SUBJECTS_URL))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.errorCode").value("UNAUTHORIZED"));
    }
}
