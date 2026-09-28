import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/features/gamification/models/game_result_models.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';

void main() {
  group('GameResultSubmission PROG-101 difficulty contract', () {
    test('TEST A: serializes EASY difficulty as apiValue', () {
      const s = GameResultSubmission(
        clientRequestId: '11111111-1111-1111-1111-111111111111',
        gameType: 'quiz_battle',
        difficulty: 'EASY',
        completed: true,
        score: 80,
        durationSeconds: 42,
        bestCombo: 3,
      );
      final json = s.toJson();
      expect(json['difficulty'], 'EASY');
    });

    test('serializes MEDIUM and HARD', () {
      for (final diff in GameDifficulty.values) {
        final s = GameResultSubmission(
          clientRequestId: '11111111-1111-1111-1111-111111111111',
          gameType: 'memory_match',
          difficulty: diff.apiValue,
          completed: true,
          score: 10,
          durationSeconds: 10,
          bestCombo: 1,
        );
        expect(s.toJson()['difficulty'], diff.apiValue);
      }
    });

    test('TEST B: complete payload contains all required backend fields', () {
      const s = GameResultSubmission(
        clientRequestId: '22222222-2222-2222-2222-222222222222',
        gameType: 'speed_run',
        difficulty: 'MEDIUM',
        completed: true,
        score: 100,
        durationSeconds: 60,
        bestCombo: 5,
      );
      final json = s.toJson();
      expect(json.containsKey('clientRequestId'), isTrue);
      expect(json.containsKey('gameType'), isTrue);
      expect(json.containsKey('difficulty'), isTrue);
      expect(json.containsKey('completed'), isTrue);
      expect(json.containsKey('score'), isTrue);
      expect(json.containsKey('durationSeconds'), isTrue);
      expect(json.containsKey('bestCombo'), isTrue);
      expect(json['difficulty'], 'MEDIUM');
      expect(json['gameType'], 'speed_run');
      expect(json['completed'], isTrue);
    });

    test('TEST C: clientRequestId idempotency key preserved', () {
      const id = '33333333-3333-3333-3333-333333333333';
      const s = GameResultSubmission(
        clientRequestId: id,
        gameType: 'drag_drop',
        difficulty: 'HARD',
        completed: true,
        score: 50,
        durationSeconds: 30,
        bestCombo: 2,
      );
      expect(s.clientRequestId, id);
      expect(s.toJson()['clientRequestId'], id);
    });

    test('TEST D: GameConfig difficulty maps to apiValue for submission', () {
      const config = GameConfig(
        topicId: 't1',
        type: GameType.quizBattle,
        difficulty: GameDifficulty.hard,
      );
      final submission = GameResultSubmission(
        clientRequestId: '44444444-4444-4444-4444-444444444444',
        gameType: config.type.id,
        difficulty: config.difficulty.apiValue,
        completed: true,
        score: 90,
        durationSeconds: 45,
        bestCombo: 4,
      );
      expect(submission.difficulty, 'HARD');
      expect(submission.toJson()['difficulty'], 'HARD');
    });

    test('difficulty field is not display label', () {
      // apiValue is uppercase EASY/MEDIUM/HARD, not "Easy"/"Medium"/"Hard"
      const s = GameResultSubmission(
        clientRequestId: '55555555-5555-5555-5555-555555555555',
        gameType: 'snake_and_ladder',
        difficulty: 'EASY',
        completed: true,
        score: 0,
        durationSeconds: 0,
        bestCombo: 0,
      );
      expect(s.difficulty, isNot('Easy'));
      expect(s.difficulty, 'EASY');
    });
  });
}
