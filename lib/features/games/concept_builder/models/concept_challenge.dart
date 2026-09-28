import '../../../game_engine/models/game_models.dart';

/// Single Concept Builder challenge.
class ConceptChallenge {
  const ConceptChallenge({
    required this.id,
    required this.title,
    required this.topic,
    required this.difficulty,
    required this.learningObjective,
    required this.instruction,
    required this.blocks,
    required this.correctOrder,
    required this.explanation,
    this.hint,
    this.conceptSnippet,
  });

  final String id;
  final String title;
  final String topic; // Programming / DBMS / OS / Networks / DS / Mathematics
  final GameDifficulty difficulty;
  final String learningObjective;
  final String instruction; // e.g., "Build a correct FOR loop"
  final List<ConceptBlock> blocks; // available blocks (shuffled)
  final List<String> correctOrder; // ordered list of block ids that is correct
  final String explanation;
  final String? hint;
  final String? conceptSnippet; // optional code/concept preview

  bool isCorrect(List<String> selectedIds) {
    if (selectedIds.length != correctOrder.length) return false;
    for (var i = 0; i < correctOrder.length; i++) {
      if (selectedIds[i] != correctOrder[i]) return false;
    }
    return true;
  }

  List<ConceptBlock> get correctBlocks =>
      correctOrder.map((id) => blocks.firstWhere((b) => b.id == id)).toList();
}

class ConceptBlock {
  const ConceptBlock({required this.id, required this.label, this.detail});
  final String id;
  final String label; // short, e.g., "initialize i = 0"
  final String? detail; // optional longer
}
