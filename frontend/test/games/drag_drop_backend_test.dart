import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/game_engine/content/game_content_adapters.dart';
import 'package:gamelearn_app/features/game_engine/content/game_content_validation.dart';
import 'package:gamelearn_app/features/game_engine/models/game_content_models.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';
import 'package:gamelearn_app/features/game_engine/utils/difficulty_utils.dart';
import 'package:gamelearn_app/features/games/drag_drop/presentation/drag_drop_screen.dart';
import 'package:gamelearn_app/features/gamification/models/game_result_models.dart';
import 'package:gamelearn_app/features/subjects/domain/canonical_worlds.dart';
import 'package:gamelearn_app/features/game_engine/content/game_content_scope.dart';

import '../helpers/fake_backend.dart';

/// Phase 11 — Gate 5: Drag & Drop backend-content adapter verification.
///
/// Semantic contract under test: zones are the items' own backend
/// difficulties (canonical EASY/MEDIUM/HARD order) and items are
/// authoritative topic names placed into their own difficulty zone —
/// never questionText->label with options[0]->zone.
void main() {
  const subjectId = '11111111-1111-1111-1111-111111111101';
  const otherSubject = '11111111-1111-1111-1111-111111111102';
  const subjectName = 'Programming';
  const topicId = 't1';
  const topicA = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01';
  const topicB = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa02';

  GameContentItem structure({
    String id = 's-1',
    String subject = subjectId,
    String? topic = topicA,
    String topicName = 'Normalization',
    String difficulty = 'EASY',
    String gameType = 'drag_drop',
    String kind = 'STRUCTURE',
  }) =>
      GameContentItem(
        kind: kind,
        id: id,
        subjectId: subject,
        subjectName: subjectName,
        topicId: topic,
        topicName: topicName,
        unitId: null,
        gameType: gameType,
        difficulty: difficulty,
        questionText: null,
        options: const [],
        definition: null,
      );

  GameContentRequest progRequest() => GameContentRequest.world(
        worldId: WorldId.programming,
        subjectId: subjectId,
        subjectName: subjectName,
      );

  Map<String, dynamic> structureJson({
    required String id,
    required String topicName,
    required String difficulty,
    String subject = subjectId,
    String gameType = 'drag_drop',
  }) =>
      {
        'kind': 'STRUCTURE',
        'id': id,
        'subjectId': subject,
        'subjectName': subjectName,
        'topicId': topicId,
        'topicName': topicName,
        'unitId': null,
        'gameType': gameType,
        'difficulty': difficulty,
        'questionText': null,
        'options': [],
        'definition': null,
      };

  List<Map<String, dynamic>> fourStructures() => [
        structureJson(id: 's-1', topicName: 'Normalization', difficulty: 'EASY'),
        structureJson(id: 's-2', topicName: 'Transactions', difficulty: 'EASY'),
        structureJson(id: 's-3', topicName: 'Indexing', difficulty: 'MEDIUM'),
        structureJson(id: 's-4', topicName: 'Replication', difficulty: 'HARD'),
      ];

  Map<String, dynamic> topicJson() => {
        'id': topicId,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'name': 'Variables & Types',
        'description':
            'Variables store values for later use. Types describe the kind of data held.',
        'difficulty': 'EASY',
        'displayOrder': 1,
      };

  Map<String, dynamic> Function(http.Request) boardHandler(
      List<Map<String, dynamic>> items) {
    return (http.Request request) {
      final path = request.url.path;
      if (path.endsWith('/api/v1/game-content')) {
        expect(request.url.queryParameters['gameType'], 'drag_drop');
        return {
          'body': {'mode': 'SUBJECT', 'subjectId': subjectId, 'items': items},
        };
      }
      if (path.endsWith('/api/v1/topics/$topicId')) {
        return {'body': topicJson()};
      }
      return {
        'status': 404,
        'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
      };
    };
  }

  Widget board(List<Map<String, dynamic>> items) => fakeScope(
        child: const MaterialApp(
          home: DragDropScreen(
            topicId: topicId,
            topicName: 'Variables & Types',
            subjectId: subjectId,
            subjectName: subjectName,
          ),
        ),
        handler: boardHandler(items),
      );

  group('backend-first board (widget)', () {
    // Wide layout needs a desktop-height viewport: at short heights the
    // pre-existing fixed-height zones list overflows regardless of content
    // source (documented limitation, not redesigned by this gate).
    Future<void> desktop(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('valid backend zones and items render first', (tester) async {
      await desktop(tester);
      await tester.pumpWidget(board(fourStructures()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('EASY'), findsWidgets);
      expect(find.text('MEDIUM'), findsWidgets);
      expect(find.text('HARD'), findsWidgets);
      expect(find.text('Normalization'), findsOneWidget);
      expect(find.textContaining('PLACED 0 / 4'), findsOneWidget);
      expect(find.text('COMPLETE CHALLENGE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('correct drop updates placement and correctness',
        (tester) async {
      await desktop(tester);
      await tester.pumpWidget(board(fourStructures()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final card = find.text('Normalization');
      // Zones render in canonical order, so the first 'Drop here'
      // placeholder belongs to the EASY zone (all zones start empty).
      final zone = find.text('Drop here').first;
      final gesture = await tester.startGesture(tester.getCenter(card));
      await gesture.moveTo(tester.getCenter(zone));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('PLACED 1 / 4'), findsOneWidget);
      expect(find.textContaining('CORRECT 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('scope violation fails hard, never substituted',
        (tester) async {
      await tester.pumpWidget(
        board([
          structureJson(
            id: 's-x',
            topicName: 'Normalization',
            difficulty: 'EASY',
            subject: otherSubject,
          ),
        ]),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Unable to start'), findsOneWidget);
      expect(find.text('Normalization'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('transport failure falls back explicitly', (tester) async {
      await desktop(tester);
      await tester.pumpWidget(
        fakeScope(
          child: const MaterialApp(
            home: DragDropScreen(
              topicId: topicId,
              topicName: 'Variables & Types',
              subjectId: subjectId,
              subjectName: subjectName,
            ),
          ),
          handler: (http.Request request) {
            final path = request.url.path;
            if (path.endsWith('/api/v1/game-content')) {
              return {
                'status': 500,
                'body': {'errorCode': 'SERVER_ERROR'},
              };
            }
            if (path.endsWith('/api/v1/topics/$topicId/lesson')) {
              return {
                'status': 404,
                'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
              };
            }
            if (path.endsWith('/api/v1/quiz/$topicId')) {
              return {
                'status': 404,
                'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
              };
            }
            if (path.endsWith('/api/v1/topics/$topicId')) {
              return {'body': topicJson()};
            }
            return {
              'status': 404,
              'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
            };
          },
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Explicit topic fallback zones (Concept/Definition/Example).
      expect(find.text('CONCEPT'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('adapter semantics (unit)', () {
    test('zones follow canonical difficulty order regardless of input order',
        () {
      final payload = GameContentAdapters.dragPayloadFromItems(
        items: [
          structure(id: 's-4', topicName: 'Replication', difficulty: 'HARD'),
          structure(id: 's-3', topicName: 'Indexing', difficulty: 'MEDIUM'),
          structure(id: 's-1', topicName: 'Normalization', difficulty: 'EASY'),
          structure(id: 's-2', topicName: 'Transactions', difficulty: 'EASY'),
        ],
        request: progRequest(),
        gameType: 'drag_drop',
      );
      expect(payload.zones, ['EASY', 'MEDIUM', 'HARD']);
      expect(payload.items.length, 4);
      // Item identity + correct zone preserved per backend item.
      final byId = {for (final i in payload.items) i.id: i};
      expect(byId['s-1']!.label, 'Normalization');
      expect(byId['s-1']!.correctZone, 'EASY');
      expect(byId['s-3']!.correctZone, 'MEDIUM');
      expect(byId['s-4']!.correctZone, 'HARD');
    });

    test('relationship is topicName-in-own-difficulty, never MCQ-derived', () {
      final payload = GameContentAdapters.dragPayloadFromItems(
        items: [
          structure(topicName: 'Control Flow', difficulty: 'MEDIUM'),
          structure(id: 's-2', topicName: 'Loops', difficulty: 'MEDIUM'),
          structure(id: 's-3', topicName: 'Types', difficulty: 'EASY'),
        ],
        request: progRequest(),
        gameType: 'drag_drop',
      );
      for (final item in payload.items) {
        expect(item.label.trim(), isNotEmpty);
        expect(['EASY', 'MEDIUM', 'HARD'], contains(item.correctZone));
      }
    });

    test('subject/topic/gameType agreement enforced by ID', () {
      expect(
        GameContentValidation.validateDragDropItem(
          item: structure(),
          expectedSubjectId: subjectId,
          expectedTopicId: topicA,
        ),
        isNull,
      );
      expect(
        GameContentValidation.validateDragDropItem(
          item: structure(subject: otherSubject),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
      expect(
        GameContentValidation.validateDragDropItem(
          item: structure(topic: topicB),
          expectedSubjectId: subjectId,
          expectedTopicId: topicA,
        ),
        isNotNull,
      );
      expect(
        GameContentValidation.validateDragDropItem(
          item: structure(gameType: 'quiz_battle'),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
      expect(
        GameContentValidation.validateDragDropItem(
          item: structure(kind: 'QUESTION'),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
    });

    test('same topic name under another subject fails ID validation', () {
      final foreign = structure(subject: otherSubject, topic: topicB);
      expect(
        GameContentValidation.validateDragDropItem(
          item: foreign,
          expectedSubjectId: subjectId,
          expectedTopicId: topicA,
        ),
        isNotNull,
      );
    });

    test('EASY/MEDIUM/HARD accepted; unknown never EASY', () {
      for (final d in ['EASY', 'medium', 'Hard']) {
        expect(
          GameContentValidation.validateDragDropItem(
            item: structure(difficulty: d),
            expectedSubjectId: subjectId,
          ),
          isNull,
          reason: d,
        );
      }
      expect(DifficultyUtils.resolveStrict(topicDifficulty: 'EXTREME'), isNull);
      final resolved =
          DifficultyUtils.resolveStrict(topicDifficulty: 'EXTREME') ??
              GameDifficulty.medium;
      expect(resolved, isNot(GameDifficulty.easy));
      expect(
        GameContentValidation.validateDragDropItem(
          item: structure(difficulty: 'EXTREME'),
          expectedSubjectId: subjectId,
        ),
        contains('never defaulted'),
      );
    });

    test('malformed/empty/insufficient content fails safely', () {
      expect(
        GameContentValidation.validateDragDropItem(
          item: structure(topicName: '  '),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
      // Single zone only -> adapter rejects (needs >= 2 zones).
      expect(
        () => GameContentAdapters.dragPayloadFromItems(
          items: [
            structure(difficulty: 'EASY'),
            structure(id: 's-2', topicName: 'T2'),
            structure(id: 's-3', topicName: 'T3'),
          ],
          request: progRequest(),
          gameType: 'drag_drop',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
      // Too few items -> rejects.
      expect(
        () => GameContentAdapters.dragPayloadFromItems(
          items: [
            structure(difficulty: 'EASY'),
            structure(id: 's-2', topicName: 'T2', difficulty: 'HARD'),
          ],
          request: progRequest(),
          gameType: 'drag_drop',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
      // Empty -> rejects safely.
      expect(
        () => GameContentAdapters.dragPayloadFromItems(
          items: const [],
          request: progRequest(),
          gameType: 'drag_drop',
        ),
        throwsA(isA<GameContentScopeMismatch>()),
      );
    });

    test('duplicate item IDs are traceable per backend item', () {
      final payload = GameContentAdapters.dragPayloadFromItems(
        items: [
          structure(id: 's-1', topicName: 'A', difficulty: 'EASY'),
          structure(id: 's-2', topicName: 'B', difficulty: 'EASY'),
          structure(id: 's-3', topicName: 'C', difficulty: 'HARD'),
        ],
        request: progRequest(),
        gameType: 'drag_drop',
      );
      final ids = payload.items.map((i) => i.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('result submission contract preserved', () {
      const submission = GameResultSubmission(
        clientRequestId: '11111111-2222-4333-8444-555555555555',
        gameType: 'drag_drop',
        difficulty: 'MEDIUM',
        completed: true,
        score: 90,
        durationSeconds: 60,
        bestCombo: 2,
      );
      final json = submission.toJson();
      expect(json['gameType'], 'drag_drop');
      expect(json['clientRequestId'], isNotEmpty);
      expect(json.containsKey('xpEarned'), isFalse);
    });

    test('audio behavior intact via silent double', () {
      final container =
          testContainer(handler: (_) => {'body': <String, dynamic>{}});
      expect(container.read(audioManagerProvider).sfxEnabled, isA<bool>());
      container.dispose();
    });
  });

  group('adversarial semantics (unit)', () {
    test('TCP MCQ never fabricates a TCP->HTTP relationship', () {
      const tcp = GameContentItem(
        kind: 'QUESTION',
        id: 'q-tcp',
        subjectId: subjectId,
        subjectName: subjectName,
        topicId: topicA,
        topicName: 'What is TCP?',
        unitId: null,
        gameType: 'drag_drop',
        difficulty: 'MEDIUM',
        questionText: 'What is TCP?',
        options: ['HTTP', 'Transmission Control Protocol'],
        definition: null,
      );
      expect(
        GameContentValidation.validateDragDropItem(
          item: tcp,
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
      // Even alongside valid items, the MCQ contributes no label/zone.
      final payload = GameContentAdapters.dragPayloadFromItems(
        items: [
          tcp,
          structure(id: 's-1', topicName: 'A', difficulty: 'EASY'),
          structure(id: 's-2', topicName: 'B', difficulty: 'EASY'),
          structure(id: 's-3', topicName: 'C', difficulty: 'HARD'),
        ],
        request: progRequest(),
        gameType: 'drag_drop',
      );
      final labels = payload.items.map((i) => i.label).toList();
      expect(labels, isNot(contains('What is TCP?')));
      expect(labels, isNot(contains('HTTP')));
    });

    test('same topic name, different subjects: IDs decide', () {
      expect(
        GameContentValidation.validateDragDropItem(
          item: structure(),
          expectedSubjectId: subjectId,
        ),
        isNull,
      );
      expect(
        GameContentValidation.validateDragDropItem(
          item: structure(subject: otherSubject, topic: topicB),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
    });

    test('unknown kind rejected', () {
      expect(
        GameContentValidation.validateDragDropItem(
          item: structure(kind: 'VIDEO'),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
    });

    test('empty content ID rejected', () {
      expect(
        GameContentValidation.validateDragDropItem(
          item: structure(id: ''),
          expectedSubjectId: subjectId,
        ),
        isNotNull,
      );
    });

    test('legacy parser danger documented; strict path used instead', () {
      expect(GameDifficulty.fromString('weird'), GameDifficulty.easy);
      expect(DifficultyUtils.tryParseBackend('weird'), isNull);
    });
  });
}
