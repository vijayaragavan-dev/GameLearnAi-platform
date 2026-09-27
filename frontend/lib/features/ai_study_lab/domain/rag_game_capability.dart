import '../../game_engine/models/game_models.dart';

/// RAG content requirement of one game (RAG-FE-5 audit result).
///
/// Derived from how each existing screen actually loads content:
/// backend quiz rows (QUESTION + server grading), backend GameContent
/// kinds (CONCEPT/STRUCTURE via the Phase-11 adapters), or bundled
/// custom/static mechanics. Never assumed — see the per-game reason.
enum RagContentNeed {
  /// MCQ-like items with options (quiz_battle, speed_run shape).
  question,

  /// Term/definition items (memory_match, concept_builder shape).
  concept,

  /// Topic/difficulty-zone items (drag_drop shape).
  structure,

  /// Custom/static mechanics with no RAG-mappable source
  /// (sequences, targets, cases, code, networks, board rules).
  custom,
}

/// Capability verdict for one game.
///
/// Two independent flags (both false until a real backend serves RAG
/// content — nothing is playable today):
/// - [contentMappable]: the game's input shape is provable from RAG
///   practice fields alone (question text + options).
/// - [playable]: actually launchable with RAG content (always false
///   until backend RAG content + grading exist).
class RagGameCapability {
  const RagGameCapability({
    required this.gameType,
    required this.needs,
    required this.contentMappable,
    required this.playable,
    required this.reason,
    this.specialRules,
  });

  final GameType gameType;
  final RagContentNeed needs;

  /// Shape-verified against RAG practice fields (no backend needed to
  /// prove the mapping). Only quiz-like games qualify.
  final bool contentMappable;

  /// Launchable today with RAG content. False for all 14 until the
  /// backend serves RAG content (quiz rows, game-content rows) and
  /// grading for it.
  final bool playable;
  final String reason;
  final String? specialRules;
}

/// Audited 14-game registry. Static metadata only — no backend calls,
/// no content loading. Screens render availability from here; the day
/// backend RAG content lands, [playable] flips per game with no UI
/// restructuring.
abstract final class RagGameCapabilityRegistry {
  static const List<RagGameCapability> all = [
    RagGameCapability(
      gameType: GameType.quizBattle,
      needs: RagContentNeed.question,
      contentMappable: true,
      playable: false,
      reason:
          'Needs backend RAG quiz rows and server grading for the '
          'document topic.',
    ),
    RagGameCapability(
      gameType: GameType.speedRun,
      needs: RagContentNeed.question,
      contentMappable: true,
      playable: false,
      reason:
          'Needs backend RAG quiz rows and server grading for the '
          'document topic.',
    ),
    RagGameCapability(
      gameType: GameType.memoryMatch,
      needs: RagContentNeed.concept,
      contentMappable: false,
      playable: false,
      reason:
          'Needs term/definition pairs the document does not provide.',
    ),
    RagGameCapability(
      gameType: GameType.dragDrop,
      needs: RagContentNeed.structure,
      contentMappable: false,
      playable: false,
      reason:
          'Needs difficulty-zoned topic structures the document does '
          'not provide.',
    ),
    RagGameCapability(
      gameType: GameType.conceptBuilder,
      needs: RagContentNeed.concept,
      contentMappable: false,
      playable: false,
      reason:
          'Needs definition-grade source text the document does not '
          'provide.',
    ),
    RagGameCapability(
      gameType: GameType.sequenceMaster,
      needs: RagContentNeed.custom,
      contentMappable: false,
      playable: false,
      reason: 'Static sequence mechanics have no document source.',
    ),
    RagGameCapability(
      gameType: GameType.targetChallenge,
      needs: RagContentNeed.custom,
      contentMappable: false,
      playable: false,
      reason: 'Target-state mechanics have no document source.',
    ),
    RagGameCapability(
      gameType: GameType.mysteryCase,
      needs: RagContentNeed.custom,
      contentMappable: false,
      playable: false,
      reason: 'Case/clue mechanics have no document source.',
    ),
    RagGameCapability(
      gameType: GameType.bossBattle,
      needs: RagContentNeed.custom,
      contentMappable: false,
      playable: false,
      reason: 'Boss mechanics have no document source.',
    ),
    RagGameCapability(
      gameType: GameType.puzzleArena,
      needs: RagContentNeed.custom,
      contentMappable: false,
      playable: false,
      reason: 'Puzzle structures have no document source.',
    ),
    RagGameCapability(
      gameType: GameType.unlockCode,
      needs: RagContentNeed.custom,
      contentMappable: false,
      playable: false,
      reason: 'Vault-code mechanics have no document source.',
    ),
    RagGameCapability(
      gameType: GameType.debugArena,
      needs: RagContentNeed.custom,
      contentMappable: false,
      playable: false,
      reason: 'Programming-only debugging content.',
      specialRules: 'Reserved for programming topics.',
    ),
    RagGameCapability(
      gameType: GameType.connectivityLab,
      needs: RagContentNeed.custom,
      contentMappable: false,
      playable: false,
      reason: 'Network-only lab mechanics.',
      specialRules: 'Reserved for computer-network topics.',
    ),
    RagGameCapability(
      gameType: GameType.snakeAndLadder,
      needs: RagContentNeed.custom,
      contentMappable: false,
      playable: false,
      reason: 'Board rules with special failure/restart behavior.',
      specialRules: 'Failure restarts from the starting level.',
    ),
  ];

  static RagGameCapability forGame(GameType type) =>
      all.firstWhere((c) => c.gameType == type);

  /// Games whose input shape is provable from RAG fields today.
  static List<RagGameCapability> get mappable =>
      all.where((c) => c.contentMappable).toList(growable: false);

  /// Games launchable with RAG content today (none until backend).
  static List<RagGameCapability> get playable =>
      all.where((c) => c.playable).toList(growable: false);
}
