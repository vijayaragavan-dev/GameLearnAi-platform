import 'model_ids.dart';

/// QUIZ-001 question (never carries correct answers).
class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.difficulty,
  });

  final String id;
  final String questionText;
  final List<String> options;
  final String difficulty;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
    id: uuidOf(json['id'], 'QuizQuestion.id'),
    questionText: json['questionText'] as String? ?? '',
    options: (json['options'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
    difficulty: json['difficulty'] as String? ?? 'EASY',
  );
}

/// QUIZ-001 response.
class Quiz {
  const Quiz({
    required this.id,
    required this.topicId,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.timeLimitSeconds,
    required this.questionCount,
    required this.questions,
  });

  final String id;
  final String topicId;
  final String title;
  final String description;
  final String difficulty;
  final int? timeLimitSeconds; // nullable per contract
  final int questionCount;
  final List<QuizQuestion> questions;

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
    id: uuidOf(json['id'], 'Quiz.id'),
    topicId: uuidOf(json['topicId'], 'Quiz.topicId'),
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    difficulty: json['difficulty'] as String? ?? 'EASY',
    timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt(),
    questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
    questions: (json['questions'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(QuizQuestion.fromJson)
        .toList(),
  );
}

/// Backend-derived adaptive outcome attached to QUIZ-002 results
/// (Adaptive Engine Spec section 26). Rendered verbatim - never recomputed.
class AdaptiveInsight {
  const AdaptiveInsight({
    required this.topicId,
    required this.masteryScore,
    required this.previousMasteryScore,
    required this.masteryLevel,
    required this.trend,
    required this.nextDifficulty,
    required this.recommendedActivity,
    required this.reasonCode,
  });

  final String topicId;
  final double masteryScore;
  final double? previousMasteryScore;
  final String masteryLevel;
  final String trend;
  final String nextDifficulty;
  final String recommendedActivity;
  final String reasonCode;

  factory AdaptiveInsight.fromJson(Map<String, dynamic> json) =>
      AdaptiveInsight(
        topicId: uuidOf(json['topicId'], 'AdaptiveInsight.topicId'),
        masteryScore: (json['masteryScore'] as num?)?.toDouble() ?? 0,
        previousMasteryScore: (json['previousMasteryScore'] as num?)
            ?.toDouble(),
        masteryLevel: json['masteryLevel'] as String? ?? '',
        trend: json['trend'] as String? ?? '',
        nextDifficulty: json['nextDifficulty'] as String? ?? '',
        recommendedActivity: json['recommendedActivity'] as String? ?? '',
        reasonCode: json['reasonCode'] as String? ?? '',
      );
}

/// QUIZ-002 answer review element (post-submission only).
class AnswerReview {
  const AnswerReview({
    required this.questionId,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.correctAnswer,
    required this.explanation,
  });

  final String questionId;
  final String selectedAnswer;
  final bool isCorrect;
  final String correctAnswer;
  final String explanation;

  factory AnswerReview.fromJson(Map<String, dynamic> json) => AnswerReview(
    questionId: uuidOf(json['questionId'], 'AnswerReview.questionId'),
    selectedAnswer: json['selectedAnswer'] as String? ?? '',
    isCorrect: json['isCorrect'] as bool? ?? false,
    correctAnswer: json['correctAnswer'] as String? ?? '',
    explanation: json['explanation'] as String? ?? '',
  );
}

/// QUIZ-002 response. Score/correctness are server-computed only.
class QuizResult {
  const QuizResult({
    required this.attemptId,
    required this.quizId,
    required this.status,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.durationSeconds,
    required this.results,
    required this.adaptive,
  });

  final String attemptId;
  final String quizId;
  final String status;
  final double score;
  final int correctCount;
  final int totalQuestions;
  final int? durationSeconds;
  final List<AnswerReview> results;
  final AdaptiveInsight? adaptive;

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
    attemptId: uuidOf(json['attemptId'], 'QuizResult.attemptId'),
    quizId: uuidOf(json['quizId'], 'QuizResult.quizId'),
    status: json['status'] as String? ?? 'COMPLETED',
    score: (json['score'] as num?)?.toDouble() ?? 0,
    correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
    totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
    durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
    results: (json['results'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(AnswerReview.fromJson)
        .toList(),
    adaptive: json['adaptive'] is Map<String, dynamic>
        ? AdaptiveInsight.fromJson(json['adaptive'] as Map<String, dynamic>)
        : null,
  );

  Map<String, String> answersById() => {
    for (final r in results) r.questionId: r.selectedAnswer,
  };
}
