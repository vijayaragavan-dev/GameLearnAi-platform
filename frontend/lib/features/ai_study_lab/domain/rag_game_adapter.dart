import '../../../core/models/quiz_models.dart';
import 'study_practice.dart';

/// RAG quiz bundle: official-shape questions WITH-provenance wrapper.
///
/// [questions] are verbatim [QuizQuestion] objects (the exact model
/// quiz-like flows consume: text + options + difficulty, never answers
/// — matching the official contract that withholds answers client-side).
/// Provenance travels in the bundle ([documentId]/[documentTitle]),
/// never inside official stores: this adapter performs NO writes to
/// quiz banks, GameContent storage, or any repository. Pure function.
class RagQuizBundle {
  const RagQuizBundle({
    required this.documentId,
    required this.documentTitle,
    required this.questions,
  });

  final String documentId;
  final String documentTitle;
  final List<QuizQuestion> questions;

  int get total => questions.length;
}

/// Thrown when RAG practice content cannot shape into quiz questions.
/// Callers render honest unavailable/empty states — content is
/// rejected, never repaired, padded, or substituted.
class RagIncompatible implements Exception {
  const RagIncompatible(this.message);

  final String message;

  @override
  String toString() => 'RagIncompatible: $message';
}

/// RAG practice → quiz-shape adapter (RAG-FE-5).
///
/// Fail-closed, mirroring the existing Phase-11 adapter discipline:
/// - question text and id must be non-empty, else the item is SKIPPED;
/// - at least 2 options required (same bar as the official gate);
/// - difficulty must be a strict EASY/MEDIUM/HARD (never defaulted);
/// - backend order preserved (never shuffled);
/// - inputs never mutated.
/// Throws [RagIncompatible] when nothing usable remains.
abstract final class RagQuizAdapter {
  static const List<String> _canonicalDifficulties = [
    'EASY',
    'MEDIUM',
    'HARD',
  ];

  static RagQuizBundle toQuizBundle({
    required String documentId,
    required String documentTitle,
    required List<GeneratedPracticeQuestion> questions,
  }) {
    final out = <QuizQuestion>[];
    for (final q in questions) {
      final text = q.questionText.trim();
      if (q.id.isEmpty || text.isEmpty) continue;
      final options = q.options
          .map((o) => o.trim())
          .where((o) => o.isNotEmpty)
          .toList(growable: false);
      if (options.length < 2) continue;
      final difficulty = q.difficulty?.trim().toUpperCase();
      if (difficulty == null ||
          !_canonicalDifficulties.contains(difficulty)) {
        continue;
      }
      out.add(
        QuizQuestion(
          id: q.id,
          questionText: text,
          options: options,
          difficulty: difficulty,
        ),
      );
    }
    if (out.isEmpty) {
      throw const RagIncompatible(
        'No RAG practice question carries usable quiz fields '
        '(text, 2+ options, strict difficulty); rejected.',
      );
    }
    return RagQuizBundle(
      documentId: documentId,
      documentTitle: documentTitle,
      questions: out,
    );
  }
}
