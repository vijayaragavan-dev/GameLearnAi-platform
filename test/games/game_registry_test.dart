import 'package:flutter_test/flutter_test.dart';

import 'package:gamelearn_app/app/router.dart';
import 'package:gamelearn_app/core/theme/game_visual_identity.dart';
import 'package:gamelearn_app/features/game_engine/content/game_content_scope.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';
import 'package:gamelearn_app/features/subjects/domain/canonical_worlds.dart';

/// F4 registry regression: exactly the 14 canonical games, each registered
/// once with a stable id, display name, visual identity and route.
void main() {
  group('Game registry (F4)', () {
    test('exactly 14 canonical game types exist', () {
      expect(GameType.values, hasLength(14));
      expect(
        GameType.values.map((t) => t.id).toSet(),
        hasLength(14),
        reason: 'GameType ids must be unique',
      );
    });

    test('every type has a definition with identity exactly once', () {
      expect(GameDefinition.all, hasLength(14));
      for (final type in GameType.values) {
        final def = GameDefinition.of(type);
        expect(def.type, type);
        expect(def.displayName, isNotEmpty);
        expect(def.description, isNotEmpty);
        expect(
          GameDefinition.all.where((d) => d.type == type),
          hasLength(1),
          reason: '${type.id} must be registered exactly once',
        );
      }
    });

    test('every game resolves a visual identity', () {
      final accents = <int>{};
      for (final type in GameType.values) {
        final identity = GameVisualRegistry.of(type);
        accents.add(identity.accent.toARGB32());
      }
      // Identities may share family hues but the registry must resolve
      // every game (no fallback crash) — spot-check distinct coverage.
      expect(accents.length, greaterThan(1));
    });

    test('every game has a distinct route', () {
      final routes = <String, String>{
        GameType.quizBattle.id: Routes.quizBattle('t'),
        GameType.memoryMatch.id: Routes.memoryMatch('t'),
        GameType.dragDrop.id: Routes.dragDrop('t'),
        GameType.speedRun.id: Routes.speedRun('t'),
        GameType.debugArena.id: Routes.debugArena('t'),
        GameType.unlockCode.id: Routes.unlockCode('t'),
        GameType.conceptBuilder.id: Routes.conceptBuilder('t'),
        GameType.sequenceMaster.id: Routes.sequenceMaster('t'),
        GameType.targetChallenge.id: Routes.targetChallenge('t'),
        GameType.mysteryCase.id: Routes.mysteryCase('t'),
        GameType.bossBattle.id: Routes.bossBattle('t'),
        GameType.puzzleArena.id: Routes.puzzleArena('t'),
        GameType.connectivityLab.id: Routes.connectivityLab('t'),
        GameType.snakeAndLadder.id: Routes.snakeAndLadder('t'),
      };
      expect(routes, hasLength(14));
      for (final entry in routes.entries) {
        expect(entry.value, startsWith('/games/t/'),
            reason: '${entry.key} route must nest under its topic');
      }
      expect(routes.values.toSet(), hasLength(14),
          reason: 'game routes must be distinct');
    });

    test('world-scoped games keep their canonical worlds', () {
      // Debug Arena is programming-domain, Connectivity Lab is
      // network-domain (bank defaults enforced by WorldContentGate).
      expect(
        WorldContentGate.bankDefaultWorld[GameType.debugArena],
        WorldId.programming,
      );
      expect(
        WorldContentGate.bankDefaultWorld[GameType.connectivityLab],
        WorldId.computerNetworks,
      );
    });
  });
}
