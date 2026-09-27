import 'study_tutor.dart';

/// AI-generated document practice domain (RAG-FE-4 UI foundation).
///
/// FRONTEND product models only. The MlRag backend/API contract does not
/// exist yet: field shapes express what the UI needs, and every content
/// field that a future backend might omit is nullable. Fixture instances
/// live ONLY in tests (clearly marked), never in production paths.
/// This system is a SEPARATE content origin from official CodeTantra /
/// LR / QA banks: nothing here ever flows into quiz or GameContent APIs.

/// Frontend practice preferences for generation. Labels are UI copy;
/// mapping to backend values happens in the real implementation later.
enum PracticeDifficulty { easy, medium, hard }

extension PracticeDifficultyLabel on PracticeDifficulty {
  String get label => switch (this) {
    PracticeDifficulty.easy => 'Easy',
    PracticeDifficulty.medium => 'Medium',
    PracticeDifficulty.hard => 'Hard',
  };
}

/// Setup choices collected before generation. Pure preference state.
class PracticeSetup {
  const PracticeSetup({
    this.questionCount = 5,
    this.difficulty = PracticeDifficulty.medium,
  });

  /// Requested question count. UI offers 5 / 10 / 15 only.
  final int questionCount;
  final PracticeDifficulty difficulty;
}

/// One AI-generated practice question. Only [id], [questionText], and
/// [options] are required; everything a future backend might omit
/// (difficulty, explanation, sources) is nullable and renders
/// conditionally — never invented.
class GeneratedPracticeQuestion {
  const GeneratedPracticeQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    this.difficulty,
    this.explanation,
    this.sources = const <GroundedSource>[],
  });

  final String id;
  final String questionText;
  final List<String> options;
  final String? difficulty;
  final String? explanation;
  final List<GroundedSource> sources;
}

/// A generated practice set. Order is backend order — the UI preserves
/// it and never re-sorts or randomizes client-side.
class GeneratedPracticeSet {
  const GeneratedPracticeSet({
    required this.documentId,
    required this.questions,
    this.id,
  });

  final String? id;
  final String documentId;
  final List<GeneratedPracticeQuestion> questions;

  int get total => questions.length;
}

/// One answered question. Correctness fields stay null until a REAL
/// evaluation result arrives (never client-guessed).
class PracticeAttempt {
  const PracticeAttempt({
    required this.questionId,
    required this.selectedAnswer,
    this.isCorrect,
    this.correctAnswer,
  });

  final String questionId;
  final String selectedAnswer;
  final bool? isCorrect;
  final String? correctAnswer;
}

/// Authoritative evaluation of one submitted answer. Produced ONLY by
/// the repository (real backend); test doubles may script it.
class PracticeEvaluation {
  const PracticeEvaluation({
    required this.isCorrect,
    this.correctAnswer,
    this.explanation,
  });

  final bool isCorrect;
  final String? correctAnswer;
  final String? explanation;
}

/// Local practice outcome: counts computed from recorded attempts.
/// Counts and accuracy ONLY — never XP, mastery, streak, or levels.
class PracticeResult {
  const PracticeResult({required this.attempts, required this.total});

  final List<PracticeAttempt> attempts;
  final int total;

  int get answered => attempts.length;
  int get correct => attempts.where((a) => a.isCorrect == true).length;

  double get accuracy => total == 0 ? 0 : correct / total;
}

/// Explicit generation outcome (RAG-FE-4 backend boundary).
sealed class PracticeGenerationResult {
  const PracticeGenerationResult();
}

/// Real generated set with authoritative questions.
class PracticeSetReady extends PracticeGenerationResult {
  const PracticeSetReady(this.set);

  final GeneratedPracticeSet set;
}

/// No practice service connected (current RAG-FE-4 reality).
class PracticeUnavailable extends PracticeGenerationResult {
  const PracticeUnavailable(this.message);

  final String message;
}

/// Generation attempted but failed (transport/validation/server-side).
class PracticeGenerationFailure extends PracticeGenerationResult {
  const PracticeGenerationFailure(this.message);

  final String message;
}

/// Service answered but produced zero questions.
class PracticeEmpty extends PracticeGenerationResult {
  const PracticeEmpty(this.message);

  final String message;
}

/// Explicit evaluation outcome (RAG-FE-4 backend boundary).
sealed class PracticeEvaluationResult {
  const PracticeEvaluationResult();
}

/// Real evaluation of the submitted answer.
class PracticeEvaluated extends PracticeEvaluationResult {
  const PracticeEvaluated(this.evaluation);

  final PracticeEvaluation evaluation;
}

/// No evaluation service connected.
class PracticeEvaluationUnavailable extends PracticeEvaluationResult {
  const PracticeEvaluationUnavailable(this.message);

  final String message;
}

/// Evaluation attempted but failed.
class PracticeEvaluationFailure extends PracticeEvaluationResult {
  const PracticeEvaluationFailure(this.message);

  final String message;
}
