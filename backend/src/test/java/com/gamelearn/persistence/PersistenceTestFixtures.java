package com.gamelearn.persistence;

import java.math.BigDecimal;
import java.time.Instant;

import com.gamelearn.entity.Achievement;
import com.gamelearn.entity.AiInteraction;
import com.gamelearn.entity.LearnerProfile;
import com.gamelearn.entity.Lesson;
import com.gamelearn.entity.Progress;
import com.gamelearn.entity.Question;
import com.gamelearn.entity.QuestionAttempt;
import com.gamelearn.entity.Quiz;
import com.gamelearn.entity.QuizAttempt;
import com.gamelearn.entity.Recommendation;
import com.gamelearn.entity.Streak;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.TopicMastery;
import com.gamelearn.entity.User;
import com.gamelearn.entity.UserAchievement;
import com.gamelearn.entity.XpTransaction;
import com.gamelearn.entity.enums.Difficulty;
import com.gamelearn.entity.enums.MasteryLevel;
import com.gamelearn.entity.enums.MasteryTrend;
import com.gamelearn.entity.enums.ProgressStatus;
import com.gamelearn.entity.enums.QuestionType;
import com.gamelearn.entity.enums.QuizAttemptStatus;
import com.gamelearn.entity.enums.RecommendationActivityType;
import com.gamelearn.entity.enums.RecommendationStatus;
import com.gamelearn.entity.enums.SourceType;
import com.gamelearn.entity.enums.UserStatus;
import com.gamelearn.entity.enums.XpEventType;

/**
 * Factory methods for building valid entities in tests. Values are unique
 * per call so test classes sharing the database never collide.
 */
public final class PersistenceTestFixtures {

    private PersistenceTestFixtures() {
    }

    public static User user(String label) {
        User user = new User();
        user.setEmail(label + "-" + java.util.UUID.randomUUID() + "@example.test");
        user.setPasswordHash("$2a$test-hash-" + java.util.UUID.randomUUID());
        user.setDisplayName("Learner " + label);
        user.setStatus(UserStatus.ACTIVE);
        return user;
    }

    public static Subject subject(String label) {
        Subject subject = new Subject();
        subject.setName(label + " Subject " + java.util.UUID.randomUUID());
        subject.setDescription(label + " description");
        subject.setIconKey("icon_" + label.toLowerCase());
        subject.setActive(true);
        subject.setDisplayOrder(0);
        return subject;
    }

    public static Topic topic(String label, Subject subject) {
        Topic topic = new Topic();
        topic.setSubject(subject);
        topic.setName(label + " Topic " + java.util.UUID.randomUUID());
        topic.setDescription(label + " topic description");
        topic.setDifficulty(Difficulty.EASY);
        topic.setDisplayOrder(0);
        topic.setActive(true);
        return topic;
    }

    public static Lesson lesson(String label, Topic topic) {
        Lesson lesson = new Lesson();
        lesson.setTopic(topic);
        lesson.setTitle(label + " Lesson");
        lesson.setContent("<html>" + label + " body ".repeat(200) + "</html>");
        lesson.setSummary(label + " summary");
        lesson.setDifficulty(Difficulty.EASY);
        lesson.setSourceType(SourceType.CURATED);
        lesson.setActive(true);
        return lesson;
    }

    public static Quiz quiz(String label, Topic topic) {
        Quiz quiz = new Quiz();
        quiz.setTopic(topic);
        quiz.setTitle(label + " Quiz");
        quiz.setDescription(label + " quiz description");
        quiz.setDifficulty(Difficulty.MEDIUM);
        quiz.setSourceType(SourceType.CURATED);
        quiz.setTimeLimitSeconds(600);
        quiz.setActive(true);
        return quiz;
    }

    public static Question question(String label, Topic topic) {
        Question question = new Question();
        question.setTopic(topic);
        question.setQuestionText(label + " question text?");
        question.setQuestionType(QuestionType.MCQ);
        question.setDifficulty(Difficulty.EASY);
        question.setOptionsJson("{\"options\":[\"a\",\"b\"]}");
        question.setCorrectAnswer("a");
        question.setExplanation(label + " explanation");
        question.setSourceType(SourceType.CURATED);
        question.setActive(true);
        return question;
    }

    public static Achievement achievement(String label) {
        Achievement achievement = new Achievement();
        achievement.setCode(label.toUpperCase() + "_" + java.util.UUID.randomUUID());
        achievement.setName(label + " Achievement");
        achievement.setDescription(label + " achievement description");
        achievement.setIconKey("achievement_" + label.toLowerCase());
        achievement.setRuleType("THRESHOLD");
        achievement.setRuleConfigJson("{\"threshold\":100}");
        achievement.setXpReward(50);
        achievement.setActive(true);
        return achievement;
    }

    public static LearnerProfile learnerProfile(User user) {
        LearnerProfile profile = new LearnerProfile();
        profile.setUser(user);
        return profile;
    }

    public static QuizAttempt quizAttempt(Quiz quiz, User user) {
        QuizAttempt attempt = new QuizAttempt();
        attempt.setQuiz(quiz);
        attempt.setUser(user);
        attempt.setScore(BigDecimal.ZERO);
        attempt.setCorrectCount(0);
        attempt.setTotalQuestions(5);
        attempt.setDifficultyAtAttempt(Difficulty.MEDIUM);
        attempt.setStartedAt(Instant.now());
        attempt.setStatus(QuizAttemptStatus.IN_PROGRESS);
        return attempt;
    }

    public static QuestionAttempt questionAttempt(QuizAttempt quizAttempt, Question question) {
        QuestionAttempt attempt = new QuestionAttempt();
        attempt.setQuizAttempt(quizAttempt);
        attempt.setQuestion(question);
        attempt.setSelectedAnswer("a");
        attempt.setCorrect(true);
        attempt.setResponseTimeSeconds(12);
        return attempt;
    }

    public static TopicMastery topicMastery(User user, Topic topic) {
        TopicMastery mastery = new TopicMastery();
        mastery.setUser(user);
        mastery.setTopic(topic);
        mastery.setMasteryLevel(MasteryLevel.BEGINNER);
        mastery.setCurrentDifficulty(Difficulty.EASY);
        mastery.setTrend(MasteryTrend.INSUFFICIENT_DATA);
        return mastery;
    }

    public static Progress progress(User user, Topic topic) {
        Progress progress = new Progress();
        progress.setUser(user);
        progress.setTopic(topic);
        progress.setStatus(ProgressStatus.NOT_STARTED);
        return progress;
    }

    public static Recommendation recommendation(User user, Topic topic) {
        Recommendation recommendation = new Recommendation();
        recommendation.setUser(user);
        recommendation.setTopic(topic);
        recommendation.setActivityType(RecommendationActivityType.PRACTICE);
        recommendation.setRecommendedDifficulty(Difficulty.EASY);
        recommendation.setReason("fixture reason");
        recommendation.setStatus(RecommendationStatus.ACTIVE);
        recommendation.setGeneratedAt(Instant.now());
        return recommendation;
    }

    public static XpTransaction xpTransaction(User user) {
        XpTransaction transaction = new XpTransaction();
        transaction.setUser(user);
        transaction.setAmount(25);
        transaction.setEventType(XpEventType.QUIZ_COMPLETED);
        transaction.setReferenceType("QUIZ_ATTEMPT");
        transaction.setReferenceId(java.util.UUID.randomUUID());
        transaction.setDescription("fixture xp event");
        return transaction;
    }

    public static Streak streak(User user) {
        Streak streak = new Streak();
        streak.setUser(user);
        streak.setTimezone("UTC");
        return streak;
    }

    public static UserAchievement userAchievement(User user, Achievement achievement) {
        UserAchievement unlock = new UserAchievement();
        unlock.setUser(user);
        unlock.setAchievement(achievement);
        unlock.setUnlockedAt(Instant.now());
        return unlock;
    }

    public static AiInteraction aiInteraction(User user) {
        AiInteraction interaction = new AiInteraction();
        interaction.setUser(user);
        interaction.setInteractionType(com.gamelearn.entity.enums.AiInteractionType.TUTOR);
        interaction.setModelName("gemini-test");
        interaction.setPromptVersion("v1");
        interaction.setRequestContextJson("{\"question\":\"what?\"}");
        interaction.setResponseJson("{\"answer\":\"because\"}");
        interaction.setStatus(com.gamelearn.entity.enums.AiInteractionStatus.SUCCESS);
        interaction.setLatencyMs(420);
        return interaction;
    }

    public static Instant now() {
        return Instant.now();
    }

    public static BigDecimal score(int value) {
        return BigDecimal.valueOf(value);
    }
}
