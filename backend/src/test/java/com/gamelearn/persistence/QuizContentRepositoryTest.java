package com.gamelearn.persistence;

import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.ActiveProfiles;

import com.gamelearn.entity.Question;
import com.gamelearn.entity.Quiz;
import com.gamelearn.entity.QuizQuestion;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.repository.QuestionRepository;
import com.gamelearn.repository.QuizQuestionRepository;
import com.gamelearn.repository.QuizRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicRepository;

import jakarta.persistence.EntityManager;

@SpringBootTest
@ActiveProfiles("test")
class QuizContentRepositoryTest {

    @Autowired
    private SubjectRepository subjectRepository;

    @Autowired
    private TopicRepository topicRepository;

    @Autowired
    private QuizRepository quizRepository;

    @Autowired
    private QuestionRepository questionRepository;

    @Autowired
    private QuizQuestionRepository quizQuestionRepository;

    @Autowired
    private EntityManager entityManager;

    @Test
    void duplicateQuizQuestionAssociationIsRejected() {
        Subject subject = subjectRepository.saveAndFlush(PersistenceTestFixtures.subject("qq"));
        Topic topic = topicRepository.saveAndFlush(PersistenceTestFixtures.topic("qq", subject));
        Quiz quiz = quizRepository.saveAndFlush(PersistenceTestFixtures.quiz("qq", topic));
        Question question = questionRepository.saveAndFlush(PersistenceTestFixtures.question("qq", topic));

        quizQuestionRepository.saveAndFlush(association(quiz, question, 1));

        assertThatThrownBy(() -> quizQuestionRepository.saveAndFlush(association(quiz, question, 2)))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void duplicateQuestionOrderWithinQuizIsRejected() {
        Subject subject = subjectRepository.saveAndFlush(PersistenceTestFixtures.subject("qorder"));
        Topic topic = topicRepository.saveAndFlush(PersistenceTestFixtures.topic("qorder", subject));
        Quiz quiz = quizRepository.saveAndFlush(PersistenceTestFixtures.quiz("qorder", topic));
        Question first = questionRepository.saveAndFlush(PersistenceTestFixtures.question("q1", topic));
        Question second = questionRepository.saveAndFlush(PersistenceTestFixtures.question("q2", topic));

        quizQuestionRepository.saveAndFlush(association(quiz, first, 1));

        assertThatThrownBy(() -> quizQuestionRepository.saveAndFlush(association(quiz, second, 1)))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    @Test
    void associationWithUnknownQuizFailsForeignKey() {
        Subject subject = subjectRepository.saveAndFlush(PersistenceTestFixtures.subject("qqghost"));
        Topic topic = topicRepository.saveAndFlush(PersistenceTestFixtures.topic("qqghost", subject));
        Question question = questionRepository.saveAndFlush(PersistenceTestFixtures.question("qqghost", topic));

        Quiz ghostQuiz = entityManager.getReference(Quiz.class, UUID.randomUUID());
        QuizQuestion association = association(ghostQuiz, question, 1);

        assertThatThrownBy(() -> quizQuestionRepository.saveAndFlush(association))
                .isInstanceOf(DataIntegrityViolationException.class);
    }

    private QuizQuestion association(Quiz quiz, Question question, int order) {
        QuizQuestion association = new QuizQuestion();
        association.setQuiz(quiz);
        association.setQuestion(question);
        association.setQuestionOrder(order);
        return association;
    }
}
