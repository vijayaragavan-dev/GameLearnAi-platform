package com.gamelearn.assessment;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamelearn.adaptive.AdaptiveEngine;
import com.gamelearn.dto.AssessmentDeliveryResponse;
import com.gamelearn.dto.AssessmentQuestion;
import com.gamelearn.dto.AssessmentResultResponse;
import com.gamelearn.dto.AssessmentSubmissionRequest;
import com.gamelearn.dto.AssessmentSubmissionResponse;
import com.gamelearn.dto.AssessmentTopicBaseline;
import com.gamelearn.dto.AssessmentResultResponse.AssessmentTopicResult;
import com.gamelearn.entity.LearnerProfile;
import com.gamelearn.entity.Question;
import com.gamelearn.entity.Subject;
import com.gamelearn.entity.Topic;
import com.gamelearn.entity.TopicMastery;
import com.gamelearn.entity.User;
import com.gamelearn.entity.enums.MasteryTrend;
import com.gamelearn.entity.enums.QuestionType;
import com.gamelearn.exception.ApiException;
import com.gamelearn.exception.ErrorCode;
import com.gamelearn.repository.LearnerProfileRepository;
import com.gamelearn.repository.QuestionRepository;
import com.gamelearn.repository.QuizAttemptRepository;
import com.gamelearn.repository.SubjectRepository;
import com.gamelearn.repository.TopicMasteryRepository;
import com.gamelearn.repository.TopicRepository;
import com.gamelearn.repository.UserRepository;

/**
 * Assessment Engine (Phase 8B) — ASMT-001/002/003
 * (GameLearn_AI_Assessment_Specification v1.0.0 APPROVED; API Contract
 * v1.2.0 section 5B).
 *
 * <p>Stateless placement model: ASMT-001 deterministically delivers up to
 * K=3 active MCQ questions per active topic (no writes); ASMT-002 recomputes
 * the identical selection, grades with the approved Phase 4 equality rule,
 * seeds T01-mirror {@code topic_mastery} baselines and refreshes the profile
 * subset inside ONE transaction guarded by R-GUARD; ASMT-003 derives the
 * result from persisted state.</p>
 *
 * <p>Ownership boundaries (owner-ratified C1/C2): this service NEVER writes
 * {@code current_level}/{@code total_xp}, XP/achievement/streak rows, quiz
 * attempts, progress, learning-path structures or recommendations, and NEVER
 * invokes Gemini. Adaptive mathematics are reused via the approved pure
 * helper {@link AdaptiveEngine#resolveLevel(BigDecimal)} — nothing is
 * duplicated.</p>
 */
@Service
public class AssessmentService {

    /** Approved selection size per topic (A2). */
    public static final int QUESTIONS_PER_TOPIC = 3;
    /** Approved initial difficulty for every baseline (A3). */
    public static final String BASELINE_DIFFICULTY = "EASY";

    private final SubjectRepository subjectRepository;
    private final TopicRepository topicRepository;
    private final QuestionRepository questionRepository;
    private final QuizAttemptRepository quizAttemptRepository;
    private final TopicMasteryRepository topicMasteryRepository;
    private final LearnerProfileRepository learnerProfileRepository;
    private final UserRepository userRepository;
    private final ObjectMapper objectMapper;

    /** Injectable for deterministic tests; UTC system clock in production. */
    private Clock clock = Clock.systemUTC();

    public AssessmentService(SubjectRepository subjectRepository,
                             TopicRepository topicRepository,
                             QuestionRepository questionRepository,
                             QuizAttemptRepository quizAttemptRepository,
                             TopicMasteryRepository topicMasteryRepository,
                             LearnerProfileRepository learnerProfileRepository,
                             UserRepository userRepository,
                             ObjectMapper objectMapper) {
        this.subjectRepository = subjectRepository;
        this.topicRepository = topicRepository;
        this.questionRepository = questionRepository;
        this.quizAttemptRepository = quizAttemptRepository;
        this.topicMasteryRepository = topicMasteryRepository;
        this.learnerProfileRepository = learnerProfileRepository;
        this.userRepository = userRepository;
        this.objectMapper = objectMapper;
    }

    void setClock(Clock clock) {
        this.clock = clock;
    }

    // ------------------------------------------------------------------
    // Deterministic selection (shared by ASMT-001 and ASMT-002)
    // ------------------------------------------------------------------

    /** One assessed topic and its selected questions (delivery order). */
    public record SelectedTopic(Topic topic, List<Question> questions) {
    }

    record Selection(Subject subject, List<SelectedTopic> topics, List<Question> flat) {
    }

    private Selection select(Subject subject) {
        List<Topic> topics = topicRepository
                .findBySubjectIdAndActiveTrueOrderByDisplayOrderAscIdAsc(subject.getId());
        List<SelectedTopic> selected = new ArrayList<>();
        List<Question> flat = new ArrayList<>();
        for (Topic topic : topics) {
            List<Question> questions = questionRepository
                    .findTop3ByTopicIdAndActiveTrueAndQuestionTypeOrderByCreatedAtAscIdAsc(
                            topic.getId(), QuestionType.MCQ);
            if (questions.isEmpty()) {
                continue; // spec section 5: zero-question topics are skipped
            }
            selected.add(new SelectedTopic(topic, questions));
            flat.addAll(questions);
        }
        return new Selection(subject, selected, flat);
    }

    private Subject requireActiveSubject(UUID subjectId) {
        return subjectRepository.findById(subjectId)
                .filter(Subject::isActive)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                        ErrorCode.RESOURCE_NOT_FOUND.name(),
                        "Subject not found"));
    }

    // ------------------------------------------------------------------
    // ASMT-001
    // ------------------------------------------------------------------

    @Transactional(readOnly = true)
    public AssessmentDeliveryResponse delivery(UUID subjectId) {
        Subject subject = requireActiveSubject(subjectId);
        Selection selection = select(subject);
        if (selection.flat().isEmpty()) {
            throw new ApiException(
                    ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                    ErrorCode.RESOURCE_NOT_FOUND.name(),
                    "No assessable content");
        }
        List<AssessmentQuestion> questions = new ArrayList<>(selection.flat().size());
        for (SelectedTopic st : selection.topics()) {
            for (Question q : st.questions()) {
                questions.add(new AssessmentQuestion(q.getId(), st.topic().getId(),
                        q.getQuestionText(), parseOptions(q.getOptionsJson()),
                        q.getDifficulty().name()));
            }
        }
        return new AssessmentDeliveryResponse(subject.getId(), questions);
    }

    /** Mirrors the QuizService redaction convention for options_json. */
    private List<String> parseOptions(String optionsJson) {
        if (optionsJson == null || optionsJson.isBlank()) {
            return List.of();
        }
        try {
            JsonNode node = objectMapper.readTree(optionsJson).path("options");
            return objectMapper.convertValue(node,
                    objectMapper.getTypeFactory()
                            .constructCollectionType(List.class, String.class));
        } catch (Exception malformedContent) {
            return List.of();
        }
    }

    // ------------------------------------------------------------------
    // ASMT-002
    // ------------------------------------------------------------------

    @Transactional
    public AssessmentSubmissionResponse submit(UUID userId, UUID subjectId,
                                               AssessmentSubmissionRequest request) {
        Subject subject = requireActiveSubject(subjectId);
        User learner = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.UNAUTHORIZED.getHttpStatus(),
                        ErrorCode.UNAUTHORIZED.name(),
                        "Invalid user"));
        Selection selection = select(subject);
        if (selection.flat().isEmpty()) {
            throw new ApiException(
                    ErrorCode.RESOURCE_NOT_FOUND.getHttpStatus(),
                    ErrorCode.RESOURCE_NOT_FOUND.name(),
                    "No assessable content");
        }
        validateAnswers(request, selection);

        // Serialization anchor FIRST (established lock order), then R-GUARD
        // re-check under the lock (spec sections 16/17).
        LearnerProfile profile = learnerProfileRepository.findWithLock(userId)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                        ErrorCode.INTERNAL_ERROR.name(),
                        "Learner profile missing"));
        List<UUID> assessedTopicIds = selection.topics().stream()
                .map(st -> st.topic().getId()).toList();
        if (topicMasteryRepository.existsByUserIdAndTopicIdIn(userId, assessedTopicIds)
                || quizAttemptRepository.existsByUserIdAndQuizSubjectId(userId, subjectId)) {
            throw new ApiException(
                    ErrorCode.DATA_CONFLICT.getHttpStatus(),
                    ErrorCode.DATA_CONFLICT.name(),
                    "Assessment baseline already established");
        }

        // Grade (approved Phase 4 equality rule; unanswered = incorrect).
        Instant submittedAt = Instant.now(clock);
        Map<UUID, Integer> correctByTopic = new HashMap<>();
        Map<UUID, Integer> totalByTopic = new HashMap<>();
        int correctCount = 0;
        var answeredById = new HashMap<UUID, String>();
        for (var answer : request.answers()) {
            answeredById.put(answer.questionId(), answer.selectedAnswer());
        }
        for (Question question : selection.flat()) {
            String selected = answeredById.get(question.getId());
            boolean isCorrect = selected != null
                    && selected.trim().equals(question.getCorrectAnswer().trim());
            UUID topicId = question.getTopic().getId();
            totalByTopic.merge(topicId, 1, Integer::sum);
            if (isCorrect) {
                correctCount++;
                correctByTopic.merge(topicId, 1, Integer::sum);
            }
        }

        BigDecimal score = accuracy(correctCount, selection.flat().size());

        // T01-mirror baselines (attempt_count=1, EASY, INSUFFICIENT_DATA).
        BigDecimal overall = BigDecimal.ZERO;
        List<AssessmentTopicBaseline> baselines = new ArrayList<>();
        for (SelectedTopic st : selection.topics()) {
            BigDecimal topicAccuracy = accuracy(
                    correctByTopic.getOrDefault(st.topic().getId(), 0),
                    totalByTopic.getOrDefault(st.topic().getId(), 0));
            overall = overall.add(topicAccuracy);
            TopicMastery row = new TopicMastery();
            row.setUser(learner);
            row.setTopic(st.topic());
            row.setMasteryScore(topicAccuracy);
            row.setMasteryLevel(AdaptiveEngine.resolveLevel(topicAccuracy));
            row.setCurrentDifficulty(com.gamelearn.entity.enums.Difficulty.EASY);
            row.setAttemptCount(1);
            row.setRecentAccuracy(topicAccuracy);
            row.setTrend(MasteryTrend.INSUFFICIENT_DATA);
            row.setLastAssessedAt(submittedAt);
            topicMasteryRepository.save(row);
            baselines.add(new AssessmentTopicBaseline(st.topic().getId(), topicAccuracy,
                    AdaptiveEngine.resolveLevel(topicAccuracy).name(), BASELINE_DIFFICULTY));
        }
        overall = overall.divide(BigDecimal.valueOf(baselines.size()), 2,
                java.math.RoundingMode.HALF_UP);

        // Profile subset refresh ONLY (C1: never current_level/total_xp).
        profile.setOverallMastery(overall);
        profile.setCurrentSubject(subject);
        learnerProfileRepository.save(profile);

        return new AssessmentSubmissionResponse(subject.getId(), score, overall, baselines);
    }

    private void validateAnswers(AssessmentSubmissionRequest request, Selection selection) {
        Set<UUID> seen = new HashSet<>();
        for (var answer : request.answers()) {
            if (!seen.add(answer.questionId())) {
                throw new ApiException(
                        ErrorCode.MALFORMED_REQUEST.getHttpStatus(),
                        ErrorCode.MALFORMED_REQUEST.name(),
                        "Duplicate answer for the same question");
            }
        }
        var selectableIds = new HashSet<UUID>();
        for (Question q : selection.flat()) {
            selectableIds.add(q.getId());
        }
        for (var answer : request.answers()) {
            if (!selectableIds.contains(answer.questionId())) {
                throw new ApiException(
                        ErrorCode.VALIDATION_FAILED.getHttpStatus(),
                        ErrorCode.VALIDATION_FAILED.name(),
                        "Answer references a question outside this assessment");
            }
        }
    }

    private static BigDecimal accuracy(int correct, int scope) {
        return BigDecimal.valueOf(correct * 100L)
                .divide(BigDecimal.valueOf(scope), 2, java.math.RoundingMode.HALF_UP);
    }

    // ------------------------------------------------------------------
    // ASMT-003 (derived read)
    // ------------------------------------------------------------------

    @Transactional(readOnly = true)
    public AssessmentResultResponse result(UUID userId, UUID subjectId) {
        Subject subject = requireActiveSubject(subjectId);
        LearnerProfile profile = learnerProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ApiException(
                        ErrorCode.INTERNAL_ERROR.getHttpStatus(),
                        ErrorCode.INTERNAL_ERROR.name(),
                        "Learner profile missing"));
        List<TopicMastery> masteries = topicMasteryRepository.findByUserId(userId);
        List<TopicMastery> scoped = masteriesForSubject(masteries, subject);
        List<AssessmentTopicResult> topics = new ArrayList<>(scoped.size());
        for (TopicMastery m : scoped) {
            topics.add(new AssessmentTopicResult(m.getTopic().getId(),
                    m.getTopic().getName(), m.getMasteryScore(),
                    m.getMasteryLevel().name(), m.getCurrentDifficulty().name()));
        }
        boolean assessed = !topics.isEmpty();
        return new AssessmentResultResponse(subject.getId(), assessed,
                assessed ? overallMean(scoped) : profile.getOverallMastery(),
                topics);
    }

    private List<TopicMastery> masteriesForSubject(List<TopicMastery> masteries,
                                                   Subject subject) {
        List<TopicMastery> scoped = new ArrayList<>();
        for (TopicMastery m : masteries) {
            if (m.getTopic().getSubject().getId().equals(subject.getId())) {
                scoped.add(m);
            }
        }
        return scoped;
    }

    private static BigDecimal overallMean(List<TopicMastery> scoped) {
        if (scoped.isEmpty()) {
            return BigDecimal.ZERO;
        }
        BigDecimal sum = BigDecimal.ZERO;
        for (TopicMastery m : scoped) {
            sum = sum.add(m.getMasteryScore());
        }
        return sum.divide(BigDecimal.valueOf(scoped.size()), 2,
                java.math.RoundingMode.HALF_UP);
    }
}
