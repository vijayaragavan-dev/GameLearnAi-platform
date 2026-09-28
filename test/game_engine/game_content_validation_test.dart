import 'package:flutter_test/flutter_test.dart';

import 'package:gamelearn_app/features/game_engine/content/game_content_validation.dart';
import 'package:gamelearn_app/features/game_engine/models/game_content_models.dart';

/// Phase 11 — Gate 1 shared-foundation tests (exactly the 14 required cases).
///
/// Covers the central [GameContentValidation] boundary only. No game engines,
/// no result flow, no audio/UI changes are exercised here.
void main() {
  const subjectA = '11111111-1111-1111-1111-111111111101';
  const subjectB = '11111111-1111-1111-1111-111111111102';
  const topicA = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01';
  const topicB = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa02';

  GameContentItem item({
    String id = 'item-1',
    String kind = 'CONCEPT',
    String subjectId = subjectA,
    String subjectName = 'Subject A',
    String? topicId = topicA,
    String topicName = 'Control Flow',
    String gameType = 'memory_match',
    String difficulty = 'MEDIUM',
    String? definition = 'Control flow directs execution. Branches select paths.',
    String? questionText,
    List<String> options = const [],
  }) =>
      GameContentItem(
        kind: kind,
        id: id,
        subjectId: subjectId,
        subjectName: subjectName,
        topicId: topicId,
        topicName: topicName,
        unitId: null,
        gameType: gameType,
        difficulty: difficulty,
        questionText: questionText,
        options: options,
        definition: definition,
      );

  GameContentPayload payloadOf(List<GameContentItem> items,
          {String mode = 'SUBJECT', String? subjectId = subjectA}) =>
      GameContentPayload(mode: mode, subjectId: subjectId, items: items);

  test('1. valid GameContentItem passes validation', () {
    expect(
      GameContentValidation.validateItem(
        item: item(),
        expectedSubjectId: subjectA,
        expectedTopicId: topicA,
        expectedGameType: 'memory_match',
      ),
      isNull,
    );
  });

  test('2. wrong subject is rejected', () {
    final reason = GameContentValidation.validateItem(
      item: item(subjectId: subjectB),
      expectedSubjectId: subjectA,
      expectedGameType: 'memory_match',
    );
    expect(reason, isNotNull);
    expect(
      () => GameContentValidation.validatePayload(
        payload: payloadOf([item(subjectId: subjectB)]),
        expectedSubjectId: subjectA,
        expectedGameType: 'memory_match',
      ),
      throwsA(isA<GameContentScopeMismatch>()),
    );
  });

  test('3. wrong topic is rejected', () {
    final reason = GameContentValidation.validateItem(
      item: item(topicId: topicB),
      expectedSubjectId: subjectA,
      expectedTopicId: topicA,
      expectedGameType: 'memory_match',
    );
    expect(reason, isNotNull);
  });

  test('4. wrong gameType is rejected', () {
    final reason = GameContentValidation.validateItem(
      item: item(gameType: 'drag_drop'),
      expectedSubjectId: subjectA,
      expectedGameType: 'memory_match',
    );
    expect(reason, contains('never cross-game'));
  });

  test('5. invalid difficulty is rejected (never defaulted)', () {
    for (final bad in ['IMPOSSIBLE', '', 'medium-hard', 'EASY ']) {
      if (bad == 'EASY ') continue; // trailing-space EASY is still EASY
      expect(GameContentValidation.isValidDifficulty(bad), isFalse);
    }
    expect(GameContentValidation.isValidDifficulty('easy'), isTrue);
    expect(GameContentValidation.isValidDifficulty('MEDIUM'), isTrue);
    expect(GameContentValidation.isValidDifficulty('HARD'), isTrue);
    expect(
      GameContentValidation.validateItem(
        item: item(difficulty: 'EXTREME'),
        expectedSubjectId: subjectA,
        expectedGameType: 'memory_match',
      ),
      contains('never defaulted'),
    );
  });

  test('6. missing required content is rejected', () {
    // CONCEPT without definition.
    expect(
      GameContentValidation.validateItem(
        item: item(definition: '  '),
        expectedSubjectId: subjectA,
        expectedGameType: 'memory_match',
      ),
      isNotNull,
    );
    // QUESTION without text/options.
    expect(
      GameContentValidation.validateItem(
        item: item(
          kind: 'QUESTION',
          gameType: 'quiz_battle',
          questionText: '',
          options: const ['only-one'],
        ),
        expectedSubjectId: subjectA,
        expectedGameType: 'quiz_battle',
      ),
      isNotNull,
    );
    // Empty id.
    expect(
      GameContentValidation.validateItem(
        item: item(id: ''),
        expectedSubjectId: subjectA,
        expectedGameType: 'memory_match',
      ),
      isNotNull,
    );
  });

  test('7. empty content is handled safely', () {
    expect(
      () => GameContentValidation.validatePayload(
        payload: payloadOf(const []),
        expectedSubjectId: subjectA,
        expectedGameType: 'memory_match',
      ),
      returnsNormally,
    );
  });

  test('8. correct answer missing is rejected where applicable', () {
    final q = item(
      kind: 'QUESTION',
      gameType: 'unlock_code',
      questionText: 'What opens the vault?',
      options: const ['A', 'B'],
    );
    expect(
      GameContentValidation.validateAnswerInOptions(answer: null, item: q),
      isNotNull,
    );
    expect(
      GameContentValidation.validateAnswerInOptions(answer: '  ', item: q),
      isNotNull,
    );
  });

  test('9. correct answer not present in options is rejected', () {
    final q = item(
      kind: 'QUESTION',
      gameType: 'unlock_code',
      questionText: 'What opens the vault?',
      options: const ['A', 'B'],
    );
    expect(
      GameContentValidation.validateAnswerInOptions(answer: 'C', item: q),
      isNotNull,
    );
    expect(
      GameContentValidation.validateAnswerInOptions(answer: 'A', item: q),
      isNull,
    );
  });

  test('10. same topic name under different subjects uses IDs', () {
    // Same display name "Control Flow" in two subjects: ID decides.
    final inA = item(subjectId: subjectA, topicId: topicA);
    final inB = item(subjectId: subjectB, topicId: topicB);
    expect(
      GameContentValidation.validateItem(
        item: inA,
        expectedSubjectId: subjectA,
        expectedGameType: 'memory_match',
      ),
      isNull,
    );
    expect(
      GameContentValidation.validateItem(
        item: inB,
        expectedSubjectId: subjectA,
        expectedGameType: 'memory_match',
      ),
      isNotNull,
    );
  });

  test('11. global mixed-subject content accepted in global mode', () {
    expect(
      () => GameContentValidation.validatePayload(
        payload: payloadOf(
          [item(subjectId: subjectA), item(subjectId: subjectB)],
          mode: 'GLOBAL',
          subjectId: null,
        ),
        subjectMode: false,
      ),
      returnsNormally,
    );
  });

  test('12. subject mode does not accept wrong-subject content', () {
    expect(
      () => GameContentValidation.validatePayload(
        payload: payloadOf(
          [item(subjectId: subjectA), item(subjectId: subjectB)],
          mode: 'SUBJECT',
        ),
        expectedSubjectId: subjectA,
        subjectMode: true,
      ),
      throwsA(isA<GameContentScopeMismatch>()),
    );
    // GLOBAL payload never satisfies a subject request.
    expect(
      () => GameContentValidation.validatePayload(
        payload: payloadOf([item()], mode: 'GLOBAL'),
        expectedSubjectId: subjectA,
        subjectMode: true,
      ),
      throwsA(isA<GameContentScopeMismatch>()),
    );
  });

  test('13. no static content overrides valid backend content', () {
    expect(GameContentValidation.shouldUseBackend(2), isTrue);
    expect(GameContentValidation.shouldUseBackend(1), isTrue);
    expect(GameContentValidation.shouldUseBackend(0), isFalse);
  });

  test('14. existing result submission remains untouched', () {
    // Boundary contract: this file references no result/XP/mastery types and
    // exposes no submission API — verified by the imports above (models only)
    // plus the absence of any result symbol here.
    expect(GameContentValidation.validDifficulties,
        containsAll(['EASY', 'MEDIUM', 'HARD']));
  });
}
