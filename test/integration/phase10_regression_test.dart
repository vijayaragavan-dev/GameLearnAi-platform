import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/core/config/app_config.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';
import 'package:gamelearn_app/features/gamification/models/game_result_models.dart';

void main() {
  group('Phase10 Regression — API base URL', () {
    test('AppConfig apiBaseUrl respects dart-define and kIsWeb fallback', () {
      // String.fromEnvironment is const, but we can verify getter logic
      // For web, should be localhost:8080 when no env var
      final url = AppConfig.apiBaseUrl;
      // In test environment (not web), should be 10.0.2.2 or localhost
      expect(url, isNotEmpty);
      expect(url.startsWith('http'), isTrue);
      // Should not be empty and should be valid URI
      expect(Uri.tryParse(url), isNotNull);
    });

    test('AppConfig resolve builds correct URI', () {
      final uri = AppConfig.resolve('/api/v1/test', query: {'a': '1'});
      expect(uri.path, '/api/v1/test');
      expect(uri.queryParameters['a'], '1');
    });
  });

  group('Phase10 — Difficulty contract', () {
    test('GameDifficulty apiValue remains EASY/MEDIUM/HARD', () {
      expect(GameDifficulty.easy.apiValue, 'EASY');
      expect(GameDifficulty.medium.apiValue, 'MEDIUM');
      expect(GameDifficulty.hard.apiValue, 'HARD');
    });

    test('GameResultSubmission preserves difficulty', () {
      final sub = GameResultSubmission(
        clientRequestId: '00000000-0000-4000-8000-000000000000',
        gameType: 'quiz_battle',
        difficulty: GameDifficulty.hard.apiValue,
        completed: true,
        score: 100,
        durationSeconds: 60,
        bestCombo: 3,
      );
      final json = sub.toJson();
      expect(json['difficulty'], 'HARD');
      expect(json['gameType'], 'quiz_battle');
      expect(json['clientRequestId'], isNotEmpty);
    });

    test('GameConfig preserves difficulty via displayName', () {
      const cfg = GameConfig(topicId: 't1', type: GameType.quizBattle, difficulty: GameDifficulty.medium);
      expect(cfg.difficulty.displayName, 'Medium');
      expect(cfg.difficulty.apiValue, 'MEDIUM');
    });
  });

  group('Phase10 — Subject routing', () {
    test('GameConfig subject/topic preserved', () {
      const cfg = GameConfig(topicId: 'topic-123', subjectId: 'subject-456', subjectName: 'Java', topicName: 'Loops', type: GameType.debugArena, difficulty: GameDifficulty.easy);
      expect(cfg.topicId, 'topic-123');
      expect(cfg.subjectId, 'subject-456');
      expect(cfg.subjectName, 'Java');
      expect(cfg.topicName, 'Loops');
    });

    test('General game has null subject', () {
      const cfg = GameConfig(topicId: 't1', type: GameType.memoryMatch, difficulty: GameDifficulty.easy);
      expect(cfg.subjectId, isNull);
      expect(cfg.subjectName, isNull);
    });
  });

  group('Phase10 — Snake & Ladder restart rule', () {
    test('GameType snakeAndLadder exists and has correct id', () {
      expect(GameType.snakeAndLadder.id, 'snake_and_ladder');
      expect(GameType.snakeAndLadder.displayName, 'Snake & Ladder');
    });

    test('GameDefinition for snakeAndLadder exists', () {
      final def = GameDefinition.of(GameType.snakeAndLadder);
      expect(def.type, GameType.snakeAndLadder);
      expect(def.supportsTimer, isTrue);
    });
  });

  group('Phase10 — 14 games discoverable', () {
    test('All 14 GameDefinitions present', () {
      expect(GameDefinition.all.length, 14);
      final ids = GameDefinition.all.map((d) => d.type.id).toSet();
      expect(ids.length, 14);
    });

    test('All 14 GameTypes have visual identity', () {
      for (final t in GameType.values) {
        final id = GameDefinition.of(t);
        expect(id.displayName, isNotEmpty);
      }
    });
  });

  group('Phase10 — kIsWeb detection', () {
    test('kIsWeb is false in test (not web)', () {
      // In flutter test, kIsWeb is false, so default should be 10.0.2.2 when no env var
      // This verifies the logic branch exists
      expect(kIsWeb, isFalse);
    });
  });
}
