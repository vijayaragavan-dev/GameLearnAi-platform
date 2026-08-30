import '../../../game_engine/models/game_models.dart';

/// Clue category determines icon and content rendering.
enum ClueCategory {
  document('Document'),
  log('System Log'),
  diagram('Diagram'),
  database('Database Record'),
  network('Network Trace'),
  codeSnippet('Code Snippet'),
  observation('Observation'),
  timeline('Timeline'),
  scientific('Scientific Data');

  const ClueCategory(this.displayName);
  final String displayName;
}

/// Single clue that must be inspected. Some clues are key evidence, others are distractors.
class MysteryClue {
  const MysteryClue({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    this.detail,
    this.isKeyEvidence = true,
    this.revealsHint,
  });

  final String id;
  final String title;
  final ClueCategory category;
  final String content; // main clue text / log / diagram description
  final String? detail; // optional secondary
  final bool isKeyEvidence;
  final String? revealsHint;
}

/// Entity / suspect / system involved in the case.
class MysteryEntity {
  const MysteryEntity({
    required this.id,
    required this.name,
    required this.role,
    required this.description,
    this.alibi,
    this.isDistractor = false,
  });

  final String id;
  final String name;
  final String role;
  final String description;
  final String? alibi;
  final bool isDistractor;
}

/// Possible conclusion / deduction option.
class MysterySolutionOption {
  const MysterySolutionOption({
    required this.id,
    required this.label,
    required this.description,
    this.isCorrect = false,
  });

  final String id;
  final String label;
  final String description;
  final bool isCorrect;
}

/// Core Mystery Case model — pure Dart, no widget dependency.
class MysteryCase {
  const MysteryCase({
    required this.id,
    required this.title,
    required this.topic,
    required this.difficulty,
    required this.caseBriefing,
    required this.learningObjective,
    required this.background,
    required this.investigationQuestion,
    required this.clues,
    required this.entities,
    required this.solutions,
    required this.correctSolutionId,
    required this.explanation,
    required this.conceptExplanation,
    required this.hint,
    this.requiredEvidenceCount,
    this.optimalDeductionIds,
  });

  final String id;
  final String title;
  final String topic;
  final GameDifficulty difficulty;
  final String caseBriefing;
  final String learningObjective;
  final String background;
  final String investigationQuestion;
  final List<MysteryClue> clues;
  final List<MysteryEntity> entities;
  final List<MysterySolutionOption> solutions;
  final String correctSolutionId;
  final String explanation;
  final String conceptExplanation;
  final String hint;
  final int? requiredEvidenceCount;
  final List<String>? optimalDeductionIds;

  /// Minimum evidence required before solving is allowed. Defaults to number of key clues (capped).
  int get requiredEvidence {
    if (requiredEvidenceCount != null) return requiredEvidenceCount!;
    final keys = clues.where((c) => c.isKeyEvidence).length;
    // Require at least 2, at most all keys, default to keys count but allow leniency for hard cases
    if (keys <= 2) return keys;
    // For medium/hard require majority
    if (difficulty == GameDifficulty.hard) return keys;
    if (difficulty == GameDifficulty.medium) return (keys * 0.75).ceil();
    return (keys * 0.6).ceil().clamp(2, keys);
  }

  bool isCorrectSolution(String solutionId) => solutionId == correctSolutionId;

  MysterySolutionOption get correctSolution =>
      solutions.firstWhere((s) => s.id == correctSolutionId);

  List<MysteryClue> get keyClues => clues.where((c) => c.isKeyEvidence).toList();

  /// Validate case invariants for testing determinism.
  bool get isValid {
    if (id.isEmpty) return false;
    if (title.isEmpty) return false;
    if (clues.length < 3) return false;
    if (solutions.length < 2) return false;
    if (!solutions.any((s) => s.id == correctSolutionId)) return false;
    if (explanation.isEmpty) return false;
    if (conceptExplanation.isEmpty) return false;
    if (hint.isEmpty) return false;
    // At least one key clue
    if (keyClues.isEmpty) return false;
    // Duplicate clue ids check outside but ensure solutions ids unique
    final sIds = solutions.map((s) => s.id).toSet();
    if (sIds.length != solutions.length) return false;
    final cIds = clues.map((c) => c.id).toSet();
    if (cIds.length != clues.length) return false;
    return true;
  }

  /// Check if enough evidence collected to allow solving.
  bool canSolve(Set<String> collectedEvidenceIds) {
    return collectedEvidenceIds.length >= requiredEvidence;
  }

  /// Validate clue discovery (exists).
  bool hasClue(String clueId) => clues.any((c) => c.id == clueId);

  /// Validate solution exists.
  bool hasSolution(String solutionId) => solutions.any((s) => s.id == solutionId);

  /// Get evidence ids that are considered key.
  Set<String> get keyEvidenceIds => keyClues.map((c) => c.id).toSet();
}

/// Lightweight session state for deterministic simulation & testing without widgets.
class MysteryCaseState {
  MysteryCaseState({required this.mysteryCase});

  final MysteryCase mysteryCase;
  final Set<String> discoveredClueIds = {};
  final Set<String> collectedEvidenceIds = {};
  String? selectedSolutionId;
  bool solved = false;
  bool failed = false;
  int lives = 3;

  /// Discover a clue. Returns true if newly discovered, false if already or invalid.
  bool discoverClue(String clueId) {
    if (!mysteryCase.hasClue(clueId)) return false;
    if (discoveredClueIds.contains(clueId)) return false;
    discoveredClueIds.add(clueId);
    return true;
  }

  /// Collect evidence from a discovered clue. Returns true if newly collected.
  bool collectEvidence(String clueId) {
    if (!discoveredClueIds.contains(clueId)) return false; // must discover first
    if (collectedEvidenceIds.contains(clueId)) return false; // duplicate protection
    if (!mysteryCase.hasClue(clueId)) return false;
    collectedEvidenceIds.add(clueId);
    return true;
  }

  /// Attempt deduction with a solution. Must have enough evidence.
  /// Returns null if not enough evidence or invalid solution; true/false for correctness.
  bool? attemptDeduction(String solutionId) {
    if (!mysteryCase.hasSolution(solutionId)) return null;
    if (!mysteryCase.canSolve(collectedEvidenceIds)) return null;
    selectedSolutionId = solutionId;
    final correct = mysteryCase.isCorrectSolution(solutionId);
    if (correct) {
      solved = true;
    } else {
      failed = true;
      lives--;
    }
    return correct;
  }

  bool get isGameOver => lives <= 0;

  void reset() {
    discoveredClueIds.clear();
    collectedEvidenceIds.clear();
    selectedSolutionId = null;
    solved = false;
    failed = false;
    lives = 3;
  }

  /// Number of key evidence still missing.
  int get remainingKeyEvidence {
    final needed = mysteryCase.requiredEvidence - collectedEvidenceIds.length;
    return needed > 0 ? needed : 0;
  }
}

/// Helper for catalog-level validation.
abstract final class MysteryCaseValidator {
  static bool hasNoDuplicateIds(List<MysteryCase> cases) {
    final ids = cases.map((c) => c.id).toSet();
    return ids.length == cases.length;
  }

  static Set<String> topicsOf(List<MysteryCase> cases) => cases.map((c) => c.topic).toSet();

  static Set<GameDifficulty> difficultiesOf(List<MysteryCase> cases) =>
      cases.map((c) => c.difficulty).toSet();
}
