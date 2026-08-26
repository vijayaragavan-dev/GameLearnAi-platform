import 'model_ids.dart';

/// ASMT-001 question (correct answers never present).
class AssessmentQuestion {
  const AssessmentQuestion({
    required this.questionId,
    required this.topicId,
    required this.questionText,
    required this.options,
    required this.difficulty,
  });

  final String questionId;
  final String topicId;
  final String questionText;
  final List<String> options;
  final String difficulty;

  factory AssessmentQuestion.fromJson(Map<String, dynamic> json) =>
      AssessmentQuestion(
        questionId: uuidOf(json['questionId'], 'AssessmentQuestion.questionId'),
        topicId: uuidOf(json['topicId'], 'AssessmentQuestion.topicId'),
        questionText: json['questionText'] as String? ?? '',
        options: (json['options'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        difficulty: json['difficulty'] as String? ?? 'EASY',
      );
}

/// ASMT-001 response.
class AssessmentDelivery {
  const AssessmentDelivery({required this.subjectId, required this.questions});

  final String subjectId;
  final List<AssessmentQuestion> questions;

  factory AssessmentDelivery.fromJson(Map<String, dynamic> json) =>
      AssessmentDelivery(
        subjectId: uuidOf(json['subjectId'], 'AssessmentDelivery.subjectId'),
        questions: (json['questions'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(AssessmentQuestion.fromJson)
            .toList(),
      );
}

/// ASMT-002 per-topic baseline summary.
class AssessmentTopicBaseline {
  const AssessmentTopicBaseline({
    required this.topicId,
    required this.accuracy,
    required this.masteryLevel,
    required this.currentDifficulty,
  });

  final String topicId;
  final double accuracy;
  final String masteryLevel;
  final String currentDifficulty;

  factory AssessmentTopicBaseline.fromJson(Map<String, dynamic> json) =>
      AssessmentTopicBaseline(
        topicId: uuidOf(json['topicId'], 'AssessmentTopicBaseline.topicId'),
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
        masteryLevel: json['masteryLevel'] as String? ?? '',
        currentDifficulty: json['currentDifficulty'] as String? ?? '',
      );
}

/// ASMT-002 response.
class AssessmentSubmissionResult {
  const AssessmentSubmissionResult({
    required this.subjectId,
    required this.score,
    required this.overallMastery,
    required this.topics,
  });

  final String subjectId;
  final double score;
  final double overallMastery;
  final List<AssessmentTopicBaseline> topics;

  factory AssessmentSubmissionResult.fromJson(Map<String, dynamic> json) =>
      AssessmentSubmissionResult(
        subjectId: uuidOf(json['subjectId'], 'AssessmentSubmission.subjectId'),
        score: (json['score'] as num?)?.toDouble() ?? 0,
        overallMastery: (json['overallMastery'] as num?)?.toDouble() ?? 0,
        topics: (json['topics'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(AssessmentTopicBaseline.fromJson)
            .toList(),
      );
}

/// ASMT-003 per-topic baseline triplet.
class AssessmentTopicResult {
  const AssessmentTopicResult({
    required this.topicId,
    required this.topicName,
    required this.masteryScore,
    required this.masteryLevel,
    required this.currentDifficulty,
  });

  final String topicId;
  final String topicName;
  final double masteryScore;
  final String masteryLevel;
  final String currentDifficulty;

  factory AssessmentTopicResult.fromJson(Map<String, dynamic> json) =>
      AssessmentTopicResult(
        topicId: uuidOf(json['topicId'], 'AssessmentTopicResult.topicId'),
        topicName: json['topicName'] as String? ?? '',
        masteryScore: (json['masteryScore'] as num?)?.toDouble() ?? 0,
        masteryLevel: json['masteryLevel'] as String? ?? '',
        currentDifficulty: json['currentDifficulty'] as String? ?? '',
      );
}

/// ASMT-003 response. assessed=false is a valid state, never an error.
class AssessmentOutcome {
  const AssessmentOutcome({
    required this.subjectId,
    required this.assessed,
    required this.overallMastery,
    required this.topics,
  });

  final String subjectId;
  final bool assessed;
  final double overallMastery;
  final List<AssessmentTopicResult> topics;

  factory AssessmentOutcome.fromJson(Map<String, dynamic> json) =>
      AssessmentOutcome(
        subjectId: uuidOf(json['subjectId'], 'AssessmentOutcome.subjectId'),
        assessed: json['assessed'] as bool? ?? false,
        overallMastery: (json['overallMastery'] as num?)?.toDouble() ?? 0,
        topics: (json['topics'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(AssessmentTopicResult.fromJson)
            .toList(),
      );
}
