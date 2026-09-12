import '../../subjects/domain/canonical_worlds.dart';
import '../models/game_models.dart';
import 'game_content_scope.dart';

import '../../games/boss_battle/data/boss_battles.dart';
import '../../games/concept_builder/data/concept_challenges.dart';
import '../../games/connectivity_lab/data/connectivity_missions.dart';
import '../../games/debug_arena/data/debug_challenges.dart';
import '../../games/mystery_case/data/mystery_cases.dart';
import '../../games/puzzle_arena/data/puzzle_puzzles.dart';
import '../../games/sequence_master/data/sequence_challenges.dart';
import '../../games/snake_and_ladder/data/snake_and_ladder_data.dart';
import '../../games/target_challenge/data/target_challenges.dart';
import '../../games/unlock_code/data/unlock_challenges.dart';

/// Static-bank availability per world (Phase 7.4 compatibility).
///
/// Counts how many authored static items are provably attributable to a
/// canonical world, using the same [WorldContentGate] attribution the game
/// screens enforce at launch. Backend-driven games (quiz_battle, speed_run,
/// memory_match, drag_drop — sourced from QUIZ-001/lesson/topic) report -1
/// (unknown statically; their own load validates honestly).
///
/// A static-bank game may be used in a World Arena ONLY when this count is
/// greater than zero for that world. Otherwise the honest SOON state
/// applies — never cross-world substitution.
abstract final class StaticBankAvailability {
  /// Number of static items attributable to [worldId] for [type],
  /// or -1 when the game is backend-driven (not statically countable).
  static int countFor(GameType type, WorldId worldId) {
    final request = GameContentRequest.world(
      worldId: worldId,
      subjectId: '__availability_probe__',
    );
    switch (type) {
      case GameType.quizBattle:
      case GameType.speedRun:
      case GameType.memoryMatch:
      case GameType.dragDrop:
        return -1;
      case GameType.bossBattle:
        return _count(
          BossBattles.all.map((b) => b.topic),
          request,
          GameType.bossBattle,
        );
      case GameType.conceptBuilder:
        return _count(
          ConceptChallenges.all.map((c) => c.topic),
          request,
          GameType.conceptBuilder,
        );
      case GameType.connectivityLab:
        return _count(
          ConnectivityMissions.all.map((m) => m.topic),
          request,
          GameType.connectivityLab,
        );
      case GameType.debugArena:
        return _count(
          DebugChallenges.all.map((c) => c.topic),
          request,
          GameType.debugArena,
        );
      case GameType.mysteryCase:
        return _count(
          MysteryCases.all.map((c) => c.topic),
          request,
          GameType.mysteryCase,
        );
      case GameType.puzzleArena:
        return _count(
          PuzzleArenaPuzzles.all.map((p) => p.topic),
          request,
          GameType.puzzleArena,
        );
      case GameType.sequenceMaster:
        return _count(
          SequenceChallenges.all.map((c) => c.topic),
          request,
          GameType.sequenceMaster,
        );
      case GameType.snakeAndLadder:
        return _count(
          SnakeAndLadderChallenges.all.map((c) => c.topic),
          request,
          GameType.snakeAndLadder,
        );
      case GameType.targetChallenge:
        return _count(
          TargetChallenges.all.map((c) => c.topic),
          request,
          GameType.targetChallenge,
        );
      case GameType.unlockCode:
        return _count(
          UnlockChallenges.all.map((c) => c.topic),
          request,
          GameType.unlockCode,
        );
    }
  }

  static int _count(
    Iterable<String> labels,
    GameContentRequest request,
    GameType gameType,
  ) {
    var count = 0;
    for (final label in labels) {
      if (WorldContentGate.worldOfStaticLabel(label, gameType: gameType) ==
          request.worldId) {
        count++;
      }
    }
    return count;
  }
}
