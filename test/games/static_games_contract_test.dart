import 'package:flutter_test/flutter_test.dart';

import 'package:gamelearn_app/features/game_engine/content/game_content_scope.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';
import 'package:gamelearn_app/features/games/boss_battle/data/boss_battles.dart';
import 'package:gamelearn_app/features/games/connectivity_lab/data/connectivity_missions.dart';
import 'package:gamelearn_app/features/games/connectivity_lab/models/connectivity_lab.dart';
import 'package:gamelearn_app/features/games/debug_arena/data/debug_challenges.dart';
import 'package:gamelearn_app/features/games/mystery_case/data/mystery_cases.dart';
import 'package:gamelearn_app/features/games/puzzle_arena/data/puzzle_puzzles.dart';
import 'package:gamelearn_app/features/games/sequence_master/data/sequence_challenges.dart';
import 'package:gamelearn_app/features/games/snake_and_ladder/data/snake_and_ladder_data.dart';
import 'package:gamelearn_app/features/games/target_challenge/data/target_challenges.dart';
import 'package:gamelearn_app/features/games/unlock_code/data/unlock_challenges.dart';
import 'package:gamelearn_app/features/subjects/domain/canonical_worlds.dart';

/// Phase 11 — Gates 7-15: static-only contract verification.
///
/// These 9 mechanic-heavy games stay static BY CONTRACT: the backend does
/// not expose the authored answers/mechanics they require, and no fake
/// adapter exists (verified: no game-content imports in these features).
/// These tests lock that posture: bank integrity, world isolation,
/// determinism, and answer-binding — so no silent backend conversion or
/// cross-world contamination can regress in.
void main() {
  GameContentRequest worldReq(WorldId world) => GameContentRequest.world(
        worldId: world,
        subjectId: '__static_audit__',
      );

  List<T> selected<T>(
    List<T> items,
    String Function(T) labelOf,
    WorldId world, {
    GameType? gameType,
  }) =>
      WorldContentGate.selectStatic(
        items: items,
        topicLabelOf: labelOf,
        request: worldReq(world),
        gameType: gameType,
      );

  void expectBankIntegrity({
    required String game,
    required List<String> ids,
    required List<String> topics,
  }) {
    expect(ids, isNotEmpty, reason: '$game bank empty');
    expect(ids.toSet().length, ids.length,
        reason: '$game duplicate ids');
    for (final t in topics) {
      expect(t.trim(), isNotEmpty, reason: '$game empty topic label');
    }
  }

  void expectWorldDiscipline<T>({
    required String game,
    required List<T> items,
    required String Function(T) labelOf,
    GameType? gameType,
  }) {
    final prog = selected(items, labelOf, WorldId.programming,
        gameType: gameType);
    final nets = selected(items, labelOf, WorldId.computerNetworks,
        gameType: gameType);
    // Deterministic + order-preserving.
    expect(
      selected(items, labelOf, WorldId.programming, gameType: gameType),
      prog,
      reason: '$game non-deterministic selection',
    );
    final bankOrder = items.map(labelOf).toList();
    var cursor = -1;
    for (final kept in prog.map(labelOf)) {
      final next = bankOrder.indexWhere((l) => l == kept, cursor + 1);
      expect(next, greaterThan(cursor), reason: '$game order not preserved');
      cursor = next;
    }
    // No cross-world leakage between the two worlds.
    final progLabels = prog.map(labelOf).toSet();
    final netsLabels = nets.map(labelOf).toSet();
    expect(progLabels.intersection(netsLabels), isEmpty,
        reason: '$game cross-world leakage');
  }

  group('target_challenge (Gate 7) static-only', () {
    test('bank integrity: actions, targets, authored solutions', () {
      final all = TargetChallenges.all;
      expectBankIntegrity(
        game: 'target_challenge',
        ids: all.map((c) => c.id).toList(),
        topics: all.map((c) => c.topic).toList(),
      );
      for (final c in all) {
        expect(c.availableActions, isNotEmpty);
        expect(c.explanation.trim(), isNotEmpty);
        expect(c.mode, isNotNull);
      }
    });

    test('world isolation + determinism', () {
      expectWorldDiscipline(
        game: 'target_challenge',
        items: TargetChallenges.all,
        labelOf: (c) => c.topic,
        gameType: GameType.targetChallenge,
      );
    });
  });

  group('debug_arena (Gate 8) static-only', () {
    test('bank integrity: diagnosis bound to choices', () {
      final all = DebugChallenges.all;
      expectBankIntegrity(
        game: 'debug_arena',
        ids: all.map((c) => c.id).toList(),
        topics: all.map((c) => c.topic).toList(),
      );
      for (final c in all) {
        expect(c.buggyCode.trim(), isNotEmpty);
        expect(c.choices.length, greaterThanOrEqualTo(2));
        expect(c.choices, contains(c.correctDiagnosis),
            reason: 'diagnosis must be answerable from choices');
        expect(c.explanation.trim(), isNotEmpty);
      }
    });

    test('world isolation + determinism (programming bank default)', () {
      expectWorldDiscipline(
        game: 'debug_arena',
        items: DebugChallenges.all,
        labelOf: (c) => c.topic,
        gameType: GameType.debugArena,
      );
    });
  });

  group('unlock_code (Gate 9) static-only', () {
    test('bank integrity: answer bound to choices + code reward', () {
      final all = UnlockChallenges.all;
      expectBankIntegrity(
        game: 'unlock_code',
        ids: all.map((c) => c.id).toList(),
        topics: all.map((c) => c.topic).toList(),
      );
      for (final c in all) {
        expect(c.choices, contains(c.correctAnswer));
        expect(c.codeReward.trim(), isNotEmpty);
        expect(c.explanation.trim(), isNotEmpty);
      }
    });

    test('world isolation + determinism', () {
      expectWorldDiscipline(
        game: 'unlock_code',
        items: UnlockChallenges.all,
        labelOf: (c) => c.topic,
        gameType: GameType.unlockCode,
      );
    });
  });

  group('sequence_master (Gate 10) static-only', () {
    test('bank integrity: authored order, no inferred sequence', () {
      final all = SequenceChallenges.all;
      expectBankIntegrity(
        game: 'sequence_master',
        ids: all.map((c) => c.id).toList(),
        topics: all.map((c) => c.topic).toList(),
      );
      for (final c in all) {
        expect(c.sequenceBlocks.length, greaterThanOrEqualTo(2));
        expect(c.correctOrder, isNotEmpty);
        final ids = c.sequenceBlocks.map((b) => b.id).toSet();
        for (final o in c.correctOrder) {
          expect(ids, contains(o));
        }
      }
    });

    test('world isolation + determinism', () {
      expectWorldDiscipline(
        game: 'sequence_master',
        items: SequenceChallenges.all,
        labelOf: (c) => c.topic,
        gameType: GameType.sequenceMaster,
      );
    });
  });

  group('mystery_case (Gate 11) static-only', () {
    test('bank integrity: clues + resolvable solution', () {
      final all = MysteryCases.all;
      expectBankIntegrity(
        game: 'mystery_case',
        ids: all.map((c) => c.id).toList(),
        topics: all.map((c) => c.topic).toList(),
      );
      for (final c in all) {
        expect(c.clues, isNotEmpty);
        expect(c.solutions, isNotEmpty);
        expect(c.isCorrectSolution(c.correctSolutionId), isTrue);
        expect(c.correctSolution.id, c.correctSolutionId);
      }
    });

    test('world isolation + determinism', () {
      expectWorldDiscipline(
        game: 'mystery_case',
        items: MysteryCases.all,
        labelOf: (c) => c.topic,
        gameType: GameType.mysteryCase,
      );
    });
  });

  group('boss_battle (Gate 12) static-only', () {
    test('bank integrity: phases valid', () {
      final all = BossBattles.all;
      expectBankIntegrity(
        game: 'boss_battle',
        ids: all.map((c) => c.id).toList(),
        topics: all.map((c) => c.topic).toList(),
      );
      for (final b in all) {
        expect(b.phases, isNotEmpty);
        for (final p in b.phases) {
          expect(p.isValid, isTrue, reason: 'phase ${p.id} invalid');
        }
      }
    });

    test('world isolation + determinism', () {
      expectWorldDiscipline(
        game: 'boss_battle',
        items: BossBattles.all,
        labelOf: (c) => c.topic,
        gameType: GameType.bossBattle,
      );
    });
  });

  group('puzzle_arena (Gate 13) static-only', () {
    test('bank integrity: puzzles valid per type', () {
      final all = PuzzleArenaPuzzles.all;
      expectBankIntegrity(
        game: 'puzzle_arena',
        ids: all.map((c) => c.id).toList(),
        topics: all.map((c) => c.topic).toList(),
      );
      for (final p in all) {
        expect(p.isValid, isTrue, reason: 'puzzle ${p.id} invalid');
      }
    });

    test('world isolation + determinism', () {
      expectWorldDiscipline(
        game: 'puzzle_arena',
        items: PuzzleArenaPuzzles.all,
        labelOf: (c) => c.topic,
        gameType: GameType.puzzleArena,
      );
    });
  });

  group('connectivity_lab (Gate 14) static-only', () {
    test('bank integrity: topology graph present, no duplicates', () {
      final all = ConnectivityMissions.all;
      expectBankIntegrity(
        game: 'connectivity_lab',
        ids: all.map((c) => c.id).toList(),
        topics: all.map((c) => c.topic).toList(),
      );
      expect(ConnectivityValidator.hasNoDuplicateIds(all), isTrue);
      for (final m in all) {
        expect(m.devices, isNotEmpty);
        final deviceIds = m.devices.map((d) => d.id).toSet();
        expect(deviceIds.length, m.devices.length);
        for (final conn in [
          ...m.initialConnections,
          ...?m.correctConnections,
        ]) {
          expect(deviceIds, contains(conn.sourceId));
          expect(deviceIds, contains(conn.targetId));
        }
      }
    });

    test('world isolation + determinism (networks bank default)', () {
      expectWorldDiscipline(
        game: 'connectivity_lab',
        items: ConnectivityMissions.all,
        labelOf: (c) => c.topic,
        gameType: GameType.connectivityLab,
      );
    });
  });

  group('snake_and_ladder (Gate 15) static-only', () {
    test('bank integrity: challenges valid', () {
      final all = SnakeAndLadderChallenges.all;
      expectBankIntegrity(
        game: 'snake_and_ladder',
        ids: all.map((c) => c.id).toList(),
        topics: all.map((c) => c.topic).toList(),
      );
      for (final c in all) {
        expect(c.isValid, isTrue, reason: 'challenge ${c.id} invalid');
      }
    });

    test('world isolation + determinism', () {
      expectWorldDiscipline(
        game: 'snake_and_ladder',
        items: SnakeAndLadderChallenges.all,
        labelOf: (c) => c.topic,
        gameType: GameType.snakeAndLadder,
      );
    });
  });
}
