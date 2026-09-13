import 'package:flutter_test/flutter_test.dart';

import 'package:gamelearn_app/core/network/api_exception.dart';
import 'package:gamelearn_app/features/game_engine/content/game_content_adapters.dart';
import 'package:gamelearn_app/features/game_engine/content/game_content_scope.dart';
import 'package:gamelearn_app/features/game_engine/content/game_content_validation.dart';
import 'package:gamelearn_app/features/game_engine/models/game_content_models.dart';
import 'package:gamelearn_app/features/gamification/models/game_result_models.dart';

/// Phase 11 final integration: cross-game security/isolation audit.
///
/// Uniform fail-closed behavior across all five backend-integrated games'
/// validators/adapters: quiz_battle, speed_run (QUIZ-001 structure),
/// memory_match (CONCEPT), drag_drop (STRUCTURE), concept_builder
/// (CONCEPT). No cross-subject/topic/game leakage, no MCQ fabrication,
/// no malformed acceptance, backend-first precedence everywhere.
void main() {
  const subjectA = '11111111-1111-1111-1111-111111111101';
  const subjectB = '11111111-1111-1111-1111-111111111102';
  const topicA = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01';
  const topicB = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa02';

  GameContentItem item({
    String id = 'item-1',
    String kind = 'QUESTION',
    String subject = subjectA,
    String? topic = topicA,
    String topicName = 'Control Flow',
    String gameType = 'quiz_battle',
    String difficulty = 'MEDIUM',
    String? text = 'Which keyword declares a constant?',
    List<String> options = const ['const', 'let', 'var'],
    String? definition,
  }) =>
      GameContentItem(
        kind: kind,
        id: id,
        subjectId: subject,
        subjectName: 'Subject A',
        topicId: topic,
        topicName: topicName,
        unitId: null,
        gameType: gameType,
        difficulty: difficulty,
        questionText: text,
        options: options,
        definition: definition,
      );

  GameContentItem conceptItem({
    String id = 'c-1',
    String subject = subjectA,
    String? topic = topicA,
    String topicName = 'Transactions',
    String? definition =
        'A transaction is a single unit of work. It follows ACID properties.',
    String gameType = 'memory_match',
    String difficulty = 'MEDIUM',
  }) =>
      item(
        id: id,
        kind: 'CONCEPT',
        subject: subject,
        topic: topic,
        topicName: topicName,
        gameType: gameType,
        difficulty: difficulty,
        text: null,
        options: const [],
        definition: definition,
      );

  GameContentItem structureItem({
    String id = 's-1',
    String subject = subjectA,
    String? topic = topicA,
    String topicName = 'Normalization',
    String difficulty = 'EASY',
  }) =>
      item(
        id: id,
        kind: 'STRUCTURE',
        subject: subject,
        topic: topic,
        topicName: topicName,
        gameType: 'drag_drop',
        difficulty: difficulty,
        text: null,
        options: const [],
      );

  String? Function({
    required GameContentItem item,
    String? expectedSubjectId,
    String? expectedTopicId,
  }) validatorFor(String game) {
    switch (game) {
      case 'quiz_battle':
        return GameContentValidation.validateQuizBattleItem;
      case 'speed_run':
        return GameContentValidation.validateSpeedRunItem;
      case 'memory_match':
        return GameContentValidation.validateMemoryPairItem;
      case 'drag_drop':
        return GameContentValidation.validateDragDropItem;
      case 'concept_builder':
        return GameContentValidation.validateConceptBuilderItem;
      default:
        throw ArgumentError('unknown game $game');
    }
  }

  GameContentItem validFor(String game) {
    switch (game) {
      case 'quiz_battle':
        return item();
      case 'speed_run':
        return item(gameType: 'speed_run');
      case 'memory_match':
        return conceptItem();
      case 'drag_drop':
        return structureItem();
      case 'concept_builder':
        return conceptItem(gameType: 'concept_builder');
      default:
        throw ArgumentError('unknown game $game');
    }
  }

  const games = [
    'quiz_battle',
    'speed_run',
    'memory_match',
    'drag_drop',
    'concept_builder',
  ];

  test('1. same topic name, different subject rejected everywhere', () {
    for (final game in games) {
      final foreign = validFor(game);
      final moved = GameContentItem(
        kind: foreign.kind,
        id: foreign.id,
        subjectId: subjectB,
        subjectName: 'Subject B',
        topicId: topicB,
        topicName: foreign.topicName,
        unitId: null,
        gameType: foreign.gameType,
        difficulty: foreign.difficulty,
        questionText: foreign.questionText,
        options: foreign.options,
        definition: foreign.definition,
      );
      expect(
        validatorFor(game)(
          item: moved,
          expectedSubjectId: subjectA,
          expectedTopicId: topicA,
        ),
        isNotNull,
        reason: game,
      );
    }
  });

  test('2. same concept name, different subject rejected (adapters)', () {
    final req = GameContentRequest.global();
    // Memory: foreign CONCEPT skipped -> shortage throws.
    expect(
      () => GameContentAdapters.memoryPairsFromItems(
        items: [
          conceptItem(subject: subjectB, topic: topicB),
          conceptItem(
              id: 'c-2', subject: subjectB, topic: topicB, topicName: 'Other'),
        ],
        request: req,
        gameType: 'other_game',
      ),
      throwsA(isA<GameContentScopeMismatch>()),
    );
  });

  test('3. valid item with wrong gameType rejected everywhere', () {
    const otherGames = {
      'quiz_battle': 'speed_run',
      'speed_run': 'quiz_battle',
      'memory_match': 'drag_drop',
      'drag_drop': 'memory_match',
      'concept_builder': 'quiz_battle',
    };
    for (final game in games) {
      final mine = validFor(game);
      final crossed = GameContentItem(
        kind: mine.kind,
        id: mine.id,
        subjectId: mine.subjectId,
        subjectName: mine.subjectName,
        topicId: mine.topicId,
        topicName: mine.topicName,
        unitId: null,
        gameType: otherGames[game]!,
        difficulty: mine.difficulty,
        questionText: mine.questionText,
        options: mine.options,
        definition: mine.definition,
      );
      expect(
        validatorFor(game)(
          item: crossed,
          expectedSubjectId: subjectA,
          expectedTopicId: topicA,
        ),
        isNotNull,
        reason: '$game accepted ${otherGames[game]}',
      );
    }
  });

  test('4. valid item with wrong topic rejected everywhere', () {
    for (final game in games) {
      final mine = validFor(game);
      final moved = GameContentItem(
        kind: mine.kind,
        id: mine.id,
        subjectId: mine.subjectId,
        subjectName: mine.subjectName,
        topicId: topicB,
        topicName: mine.topicName,
        unitId: null,
        gameType: mine.gameType,
        difficulty: mine.difficulty,
        questionText: mine.questionText,
        options: mine.options,
        definition: mine.definition,
      );
      expect(
        validatorFor(game)(
          item: moved,
          expectedSubjectId: subjectA,
          expectedTopicId: topicA,
        ),
        isNotNull,
        reason: game,
      );
    }
  });

  test('5. valid item with wrong subject rejected everywhere', () {
    for (final game in games) {
      final mine = validFor(game);
      final moved = GameContentItem(
        kind: mine.kind,
        id: mine.id,
        subjectId: subjectB,
        subjectName: mine.subjectName,
        topicId: mine.topicId,
        topicName: mine.topicName,
        unitId: null,
        gameType: mine.gameType,
        difficulty: mine.difficulty,
        questionText: mine.questionText,
        options: mine.options,
        definition: mine.definition,
      );
      expect(
        validatorFor(game)(
          item: moved,
          expectedSubjectId: subjectA,
          expectedTopicId: topicA,
        ),
        isNotNull,
        reason: game,
      );
    }
  });

  test('6. unknown difficulty rejected everywhere (never EASY)', () {
    for (final game in games) {
      final mine = validFor(game);
      final bad = GameContentItem(
        kind: mine.kind,
        id: mine.id,
        subjectId: mine.subjectId,
        subjectName: mine.subjectName,
        topicId: mine.topicId,
        topicName: mine.topicName,
        unitId: null,
        gameType: mine.gameType,
        difficulty: 'NIGHTMARE',
        questionText: mine.questionText,
        options: mine.options,
        definition: mine.definition,
      );
      expect(
        validatorFor(game)(
          item: bad,
          expectedSubjectId: subjectA,
          expectedTopicId: topicA,
        ),
        isNotNull,
        reason: game,
      );
    }
    expect(GameContentValidation.isValidDifficulty('NIGHTMARE'), isFalse);
  });

  test('7. duplicate content IDs handled without collision', () {
    final req = GameContentRequest.global();
    // Memory dedupes by term (first wins), never crashes.
    final pairs = GameContentAdapters.memoryPairsFromItems(
      items: [
        conceptItem(gameType: 'memory_match'),
        conceptItem(
            id: 'c-1', topicName: 'Transactions', gameType: 'memory_match'),
        conceptItem(
            id: 'c-2', topicName: 'Other', gameType: 'memory_match'),
      ],
      request: req,
      gameType: 'memory_match',
    );
    expect(pairs.length, 2);
    // Drag preserves backend IDs verbatim for placement tracking.
    final payload = GameContentAdapters.dragPayloadFromItems(
      items: [
        structureItem(id: 's-1', topicName: 'A', difficulty: 'EASY'),
        structureItem(id: 's-2', topicName: 'B', difficulty: 'EASY'),
        structureItem(id: 's-3', topicName: 'C', difficulty: 'HARD'),
      ],
      request: req,
      gameType: 'drag_drop',
    );
    final ids = payload.items.map((i) => i.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('8. empty text rejected everywhere', () {
    for (final game in games) {
      final mine = validFor(game);
      final empty = GameContentItem(
        kind: mine.kind,
        id: mine.id,
        subjectId: mine.subjectId,
        subjectName: mine.subjectName,
        topicId: mine.topicId,
        topicName: '',
        unitId: null,
        gameType: mine.gameType,
        difficulty: mine.difficulty,
        questionText: '',
        options: const [],
        definition: '',
      );
      expect(
        validatorFor(game)(
          item: empty,
          expectedSubjectId: subjectA,
          expectedTopicId: topicA,
        ),
        isNotNull,
        reason: game,
      );
    }
  });

  test('9. missing required fields rejected per kind', () {
    // QUESTION without options.
    expect(
      GameContentValidation.validateQuizBattleItem(
        item: item(options: const ['only']),
        expectedSubjectId: subjectA,
      ),
      isNotNull,
    );
    // CONCEPT without definition.
    expect(
      GameContentValidation.validateMemoryPairItem(
        item: conceptItem(definition: null),
        expectedSubjectId: subjectA,
      ),
      isNotNull,
    );
    // STRUCTURE without topicName.
    expect(
      GameContentValidation.validateDragDropItem(
        item: structureItem(topicName: '  '),
        expectedSubjectId: subjectA,
      ),
      isNotNull,
    );
  });

  test('10. malformed JSON/structure fails closed or degrades safe', () {
    // Missing IDs throw at parse (never silent nulls).
    expect(
      () => GameContentItem.fromJson({
        'kind': 'QUESTION',
        'subjectId': subjectA,
        'gameType': 'quiz_battle',
        'difficulty': 'EASY',
      }),
      throwsA(isA<FormatException>()),
    );
    // Non-list items degrade to safe empty (caller renders empty state).
    final payload = GameContentPayload.fromJson({
      'mode': 'SUBJECT',
      'subjectId': subjectA,
      'items': {'not': 'a-list'},
    });
    expect(payload.items, isEmpty);
    expect(
      () => GameContentValidation.validatePayload(
        payload: payload,
        expectedSubjectId: subjectA,
        expectedGameType: 'quiz_battle',
      ),
      returnsNormally,
    );
  });

  test('11. empty backend payload is safe everywhere', () {
    const empty = GameContentPayload(mode: 'SUBJECT', subjectId: subjectA, items: []);
    expect(
      () => GameContentValidation.validatePayload(
        payload: empty,
        expectedSubjectId: subjectA,
        expectedGameType: 'memory_match',
      ),
      returnsNormally,
    );
    expect(GameContentValidation.shouldUseBackend(0), isFalse);
  });

  test('12. backend + fallback simultaneously: backend wins', () {
    expect(GameContentValidation.shouldUseBackend(3), isTrue);
    expect(GameContentValidation.shouldUseBackend(1), isTrue);
    // Valid items validate clean, so screens take the backend branch.
    expect(
      GameContentValidation.validateMemoryPairItem(
        item: conceptItem(),
        expectedSubjectId: subjectA,
      ),
      isNull,
    );
  });

  test('13. transport errors stay distinct from content rejection', () {
    // Policy separation: network failures (ApiException family) route to
    // explicit fallback/error states; content rejection
    // (GameContentScopeMismatch) fails closed. They must never be confused.
    final ApiException transportFailure = const NetworkException();
    expect(transportFailure.errorCode, 'NETWORK');
    expect(
      const GameContentScopeMismatch('x'),
      isNot(isA<ApiException>()),
    );
  });

  test('14. replayed result keeps idempotency contract', () {
    const first = GameResultSubmission(
      clientRequestId: '11111111-2222-4333-8444-555555555555',
      gameType: 'memory_match',
      difficulty: 'MEDIUM',
      completed: true,
      score: 80,
      durationSeconds: 45,
      bestCombo: 2,
    );
    const replay = GameResultSubmission(
      clientRequestId: '11111111-2222-4333-8444-555555555555',
      gameType: 'memory_match',
      difficulty: 'MEDIUM',
      completed: true,
      score: 80,
      durationSeconds: 45,
      bestCombo: 2,
    );
    expect(replay.toJson(), first.toJson());
    expect(first.toJson()['clientRequestId'], isNotEmpty);
  });

  test('15. cross-user scope: other subject content never accepted', () {
    for (final game in games) {
      expect(
        validatorFor(game)(
          item: validFor(game),
          expectedSubjectId: subjectB,
          expectedTopicId: topicA,
        ),
        isNotNull,
        reason: game,
      );
    }
  });

  test('16. no MCQ semantic fabrication in any adapter game', () {
    final mcq = item(
      kind: 'QUESTION',
      gameType: 'memory_match',
      text: 'What is TCP?',
      options: const ['Transmission Control Protocol', 'HTTP'],
      definition: null,
    );
    expect(
      GameContentValidation.validateMemoryPairItem(
        item: mcq,
        expectedSubjectId: subjectA,
      ),
      isNotNull,
    );
    expect(
      GameContentValidation.validateDragDropItem(
        item: mcq,
        expectedSubjectId: subjectA,
      ),
      isNotNull,
    );
    expect(
      GameContentValidation.validateConceptBuilderItem(
        item: mcq,
        expectedSubjectId: subjectA,
      ),
      isNotNull,
    );
  });
}
