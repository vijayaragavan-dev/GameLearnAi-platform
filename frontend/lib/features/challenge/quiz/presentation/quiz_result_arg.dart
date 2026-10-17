import '../../../../core/models/gamification_models.dart';
import '../../../../core/models/quiz_models.dart';

/// Payload passed to the result screen via router `extra`.
class QuizResultArg {
  const QuizResultArg({
    required this.result,
    required this.topicName,
    this.topicId,
    this.subjectId,
    this.xpGained = 0,
    this.leveledUpTo,
    this.newAchievements = const <Achievement>[],
  });

  final QuizResult result;
  final String topicName;

  /// Route context so the result screen can offer "practice again" and
  /// subject-scoped navigation without a second backend read.
  final String? topicId;
  final String? subjectId;

  /// Backend-derived deltas between two GAM-001 reads (pre/post submission).
  /// Zero when the reads could not be compared.
  final int xpGained;
  final int? leveledUpTo;
  final List<Achievement> newAchievements;
}
