import '../../../game_engine/models/game_models.dart';

enum SequenceMode { arrange, complete }

class SequenceChallenge {
  const SequenceChallenge({
    required this.id,
    required this.title,
    required this.topic,
    required this.difficulty,
    required this.mode,
    required this.learningObjective,
    required this.instruction,
    required this.sequenceBlocks,
    required this.correctOrder,
    this.missingPositions,
    this.candidateBlocks,
    this.correctAnswer,
    required this.explanation,
    this.hint,
    this.conceptSnippet,
  });

  final String id;
  final String title;
  final String topic;
  final GameDifficulty difficulty;
  final SequenceMode mode;
  final String learningObjective;
  final String instruction;
  final List<SequenceBlock> sequenceBlocks; // full correct sequence in order
  final List<String> correctOrder; // list of block ids in correct order (usually same as sequenceBlocks order)
  final List<int>? missingPositions; // for complete mode: indices that are missing (0-based)
  final List<SequenceBlock>? candidateBlocks; // for complete mode: available choices to fill missing
  final String? correctAnswer; // for complete mode: id of correct candidate (when single missing)
  final String explanation;
  final String? hint;
  final String? conceptSnippet;

  bool isArrangeCorrect(List<String> selectedIds) {
    if (selectedIds.length != correctOrder.length) return false;
    for (var i = 0; i < correctOrder.length; i++) {
      if (selectedIds[i] != correctOrder[i]) return false;
    }
    return true;
  }

  bool isCompleteCorrect(String selectedId) {
    if (mode != SequenceMode.complete) return false;
    return selectedId == correctAnswer;
  }

  /// For arrange mode, shuffled candidates are derived from sequenceBlocks shuffled deterministically outside.
  /// For complete mode, sequence with missing slots is built via missingPositions.
}
class SequenceBlock {
  const SequenceBlock({required this.id, required this.label, this.detail});
  final String id;
  final String label;
  final String? detail;
}
