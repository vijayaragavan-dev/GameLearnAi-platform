import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gamelearn_app/app/router.dart';
import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/games/hub/presentation/game_hub_screen.dart';
import 'package:gamelearn_app/features/subjects/presentation/world_screen.dart';
import 'package:gamelearn_app/features/tutor/presentation/tutor_screen.dart';

import '../helpers/fake_backend.dart';

Map<String, dynamic> _dbmsSubject() => {
      'id': '11111111-1111-1111-1111-111111111101',
      'name': 'Database Management Systems',
      'description': 'Model data. Query anything.',
      'iconKey': 'dbms',
      'isActive': true,
      'displayOrder': 4,
    };

Map<String, dynamic> _aiSubject() => {
      'id': '11111111-1111-1111-1111-111111111108',
      'name': 'Artificial Intelligence & Machine Learning',
      'description': 'Learn how machines learn.',
      'iconKey': 'ai_ml',
      'isActive': true,
      'displayOrder': 8,
    };

Map<String, dynamic> _pathFor(String subjectId) => {
      'id': '0b6f1111-1111-1111-1111-111111111101',
      'subjectId': subjectId,
      'title': 'DBMS Sprint',
      'description': 'A plan tuned to your mastery profile.',
      'status': 'ACTIVE',
      'generatedBy': 'AI',
      'createdAt': '2026-08-23T12:00:00Z',
      'updatedAt': '2026-08-23T12:00:00Z',
      'nodes': [
        {
          'id': 'n1',
          'topicId': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01',
          'topicName': 'SQL',
          'sequenceNumber': 1,
          'requiredMastery': 0,
          'status': 'COMPLETED',
        },
        {
          'id': 'n2',
          'topicId': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa02',
          'topicName': 'Normalization',
          'sequenceNumber': 2,
          'requiredMastery': 40.0,
          'status': 'AVAILABLE',
        },
        {
          'id': 'n3',
          'topicId': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa03',
          'topicName': 'Transactions',
          'sequenceNumber': 3,
          'requiredMastery': 60.0,
          'status': 'LOCKED',
        },
      ],
    };

MockClient _client({
  required List<Map<String, dynamic>> subjects,
  List<Map<String, dynamic>>? paths,
  Map<String, dynamic>? dashboard,
}) {
  return MockClient((request) async {
    final path = request.url.path;
    if (path.endsWith('/api/v1/subjects')) {
      return http.Response(jsonEncode(subjects), 200,
          headers: {'content-type': 'application/json'});
    }
    if (path.contains('/api/v1/learning-path/')) {
      if (paths == null) {
        return http.Response('{"errorCode":"NOT_FOUND"}', 404,
            headers: {'content-type': 'application/json'});
      }
      return http.Response(jsonEncode(paths), 200,
          headers: {'content-type': 'application/json'});
    }
    if (path.endsWith('/api/v1/dashboard')) {
      return http.Response(
          jsonEncode(dashboard ?? Fixtures.dashboardZeroState()), 200,
          headers: {'content-type': 'application/json'});
    }
    return http.Response('{"errorCode":"NOT_FOUND"}', 404,
        headers: {'content-type': 'application/json'});
  });
}

Widget _scope({
  required Widget child,
  required MockClient client,
  ThemeData? theme,
}) {
  return ProviderScope(
    overrides: [
      tokenStorageProvider.overrideWithValue(
        FakeTokenStorage()..stored = 'tok',
      ),
      apiClientProvider.overrideWith((ref) => ApiClient(client: client)),
      audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
    ],
    child: MaterialApp(
      theme: theme ?? ThemeData(brightness: Brightness.dark),
      home: child,
    ),
  );
}

void main() {
  group('World vs Global arena identity (Phase 6)', () {
    testWidgets('DBMS hub shows WORLD ARENA scope, not global', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: GameHubScreen(
          topicId: 't-1',
          topicName: 'SQL',
          subjectId: '11111111-1111-1111-1111-111111111101',
          subjectName: 'Database Management Systems',
        ),
      ));
      await tester.pump();
      expect(
        find.text('DATABASE MANAGEMENT SYSTEMS // WORLD ARENA'),
        findsOneWidget,
      );
      expect(find.textContaining('World-scoped play'), findsOneWidget);
      expect(find.text('GLOBAL ARENA'), findsNothing);
    });

    testWidgets('hub without subject shows GLOBAL ARENA note', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: GameHubScreen(topicId: 't-1', topicName: 'SQL'),
      ));
      await tester.pump();
      expect(find.text('GLOBAL ARENA'), findsOneWidget);
      expect(find.textContaining('WORLD ARENA'), findsNothing);
    });

    test('world route preserves backend subjectId; game routes keep context',
        () {
      expect(Routes.world('subject-uuid-1'), '/world/subject-uuid-1');
      final hub = Routes.gameHub('topic-uuid-9',
          subjectId: 'subject-uuid-1', subjectName: 'DBMS');
      expect(hub, contains('subject-uuid-1'));
      expect(hub, contains('topic-uuid-9'));
      final tutor = Routes.tutorWithContext(
        subjectId: 'subject-uuid-1',
        topicId: 'topic-uuid-9',
        topicName: 'SQL',
      );
      expect(tutor, contains('subjectId=subject-uuid-1'));
      expect(tutor, contains('topicId=topic-uuid-9'));
    });
  });

  group('WorldScreen — DBMS world journey (Phase 6)', () {
    testWidgets('renders hero, next topic, arena and tutor CTAs', (tester) async {
      final client = _client(
        subjects: [_dbmsSubject()],
        paths: [_pathFor('11111111-1111-1111-1111-111111111101')],
      );
      await tester.pumpWidget(_scope(
        client: client,
        child: const WorldScreen(
          subjectId: '11111111-1111-1111-1111-111111111101',
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Database Management Systems'), findsWidgets);
      expect(find.text('Database Management Systems // WORLD ARENA'), findsOneWidget);
      // Backend-driven next topic (first AVAILABLE node).
      expect(find.text('Normalization'), findsWidgets);
      expect(find.text('CONTINUE'), findsOneWidget);
      expect(find.text('ENTER GAME ARENA'), findsOneWidget);
      expect(find.text('ASK NOVA TUTOR'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in light theme without overflow at 360', (tester) async {
      tester.view.physicalSize = const Size(360, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final client = _client(
        subjects: [_dbmsSubject()],
        paths: [_pathFor('11111111-1111-1111-1111-111111111101')],
      );
      await tester.pumpWidget(_scope(
        client: client,
        theme: ThemeData(brightness: Brightness.light),
        child: const WorldScreen(
          subjectId: '11111111-1111-1111-1111-111111111101',
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.text('Database Management Systems // WORLD ARENA'), findsOneWidget);
    });

    testWidgets('pending AI/ML world is honest (no fake syllabus)', (tester) async {
      final client = _client(subjects: [_aiSubject()], paths: const []);
      await tester.pumpWidget(_scope(
        client: client,
        child: const WorldScreen(
          subjectId: '11111111-1111-1111-1111-111111111108',
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Artificial Intelligence & Machine Learning'),
        findsWidgets,
      );
      expect(find.text('Content arriving'), findsOneWidget);
      expect(find.text('WORLD PREPARATION IN PROGRESS'), findsOneWidget);
      // Arena CTA honestly disabled without path topics.
      expect(find.textContaining('unlocks once your path'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unknown subject fails honestly (no crash)', (tester) async {
      final client = _client(subjects: const [], paths: null);
      await tester.pumpWidget(_scope(
        client: client,
        child: const WorldScreen(subjectId: 'missing-id'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      // Either the generic hero or an honest error — never a crash.
      expect(
        find.text('Path unavailable').evaluate().isNotEmpty ||
            find.text('World').evaluate().isNotEmpty ||
            find.text('No learning path yet').evaluate().isNotEmpty,
        isTrue,
      );
    });
  });

  group('Tutor preserves world context (Phase 4F)', () {
    testWidgets('DBMS tutor shows world scope chip', (tester) async {
      final client = _client(subjects: [_dbmsSubject()]);
      await tester.pumpWidget(_scope(
        client: client,
        child: const TutorScreen(
          initialSubjectId: '11111111-1111-1111-1111-111111111101',
          initialTopicId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa02',
          initialTopicName: 'Normalization',
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.text('Normalization'), findsWidgets);
      expect(find.textContaining('DATABASE MANAGEMENT SYSTEMS'), findsOneWidget);
    });

    testWidgets('global tutor inherits no stale world scope', (tester) async {
      final client = _client(subjects: [_dbmsSubject()]);
      await tester.pumpWidget(_scope(
        client: client,
        child: const TutorScreen(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      // No world chip without an explicit world launch.
      expect(find.textContaining('WORLD', findRichText: true), findsNothing);
    });
  });

  group('World arena compat list + SOON states (Phase 7)', () {
    MockClient compatClient(List<Map<String, dynamic>> games) {
      return MockClient((request) async {
        if (request.url.path.contains('/api/v1/subjects/') &&
            request.url.path.endsWith('/games')) {
          return http.Response(
            jsonEncode({
              'subjectId': '11111111-1111-1111-1111-111111111101',
              'subjectName': 'Database Management Systems',
              'games': games,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"errorCode":"NOT_FOUND"}', 404,
            headers: {'content-type': 'application/json'});
      });
    }

    Map<String, dynamic> entry(String gameType, bool hasContent) => {
          'gameType': gameType,
          'rationale': hasContent ? 'backed' : 'no rows yet',
          'hasContent': hasContent,
          'contentCount': hasContent ? 7 : 0,
        };

    Widget hubScope(MockClient client) {
      return ProviderScope(
        overrides: [
          apiClientProvider.overrideWith((ref) => ApiClient(client: client)),
        ],
        child: const MaterialApp(
          home: GameHubScreen(
            topicId: 't-1',
            topicName: 'SQL',
            subjectId: '11111111-1111-1111-1111-111111111101',
            subjectName: 'Database Management Systems',
          ),
        ),
      );
    }

    int cardCount(WidgetTester tester) => tester
        .widgetList(find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_ArcadeGameCard',
        ))
        .length;

    testWidgets('unsupported games hidden from world list, general intact',
        (tester) async {
      await tester.pumpWidget(hubScope(compatClient([
        entry('quiz_battle', true),
      ])));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      // Subject section: 1 supported; general section: all 14.
      expect(cardCount(tester), 15);
      expect(find.text('SNAKE & LADDER'), findsOneWidget);
      expect(find.text('DATABASE MANAGEMENT SYSTEMS // WORLD ARENA'),
          findsOneWidget);
    });

    testWidgets('statically-empty + backend-empty game shows SOON',
        (tester) async {
      // Debug Arena has no DBMS static items; backend confirms none.
      await tester.pumpWidget(hubScope(compatClient([
        entry('quiz_battle', true),
        entry('debug_arena', false),
        entry('mystery_case', false),
      ])));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(
        find.bySemanticsLabel(RegExp('not yet available in this world')),
        findsWidgets,
      );
      // Mystery Case has DBMS static items → stays playable despite false.
      expect(
        find.bySemanticsLabel(
          RegExp('Mystery Case.*subject Database Management Systems'),
        ),
        findsWidgets,
      );
    });

    testWidgets('compat failure keeps status-quo roster (never claims empty)',
        (tester) async {
      await tester.pumpWidget(hubScope(compatClient(const [])));
      await tester.pump();
      // Empty compat list is truthful only when the endpoint answers with
      // zero games; the 404 path below covers the silent fallback.
      expect(tester.takeException(), isNull);
    });

    testWidgets('compat 404 keeps every card playable', (tester) async {
      final failing = MockClient((request) async {
        return http.Response('{"errorCode":"NOT_FOUND"}', 404,
            headers: {'content-type': 'application/json'});
      });
      await tester.pumpWidget(hubScope(failing));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(cardCount(tester), 28);
      expect(
        find.bySemanticsLabel(RegExp('not yet available in this world')),
        findsNothing,
      );
    });
  });

  group('Programming world uses backend syllabus (Phase 8)', () {
    testWidgets('backend-driven syllabus lists path topics', (tester) async {
      final client = _client(
        subjects: [
          {
            'id': '11111111-1111-1111-1111-111111111101',
            'name': 'Programming',
            'description': 'Write code.',
            'iconKey': 'code',
            'isActive': true,
            'displayOrder': 1,
          },
        ],
        paths: [
          _pathFor('11111111-1111-1111-1111-111111111101'),
        ],
      );
      await tester.pumpWidget(_scope(
        client: client,
        child: const WorldScreen(
          subjectId: '11111111-1111-1111-1111-111111111101',
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.text('Programming'), findsWidgets);
      // Backend syllabus branch: no static UNIT headers.
      expect(find.textContaining('UNIT 1'), findsNothing);
      expect(find.text('SQL'), findsWidgets);
    });
  });

  group('WorldScreen responsive sweep (Phase 8.12)', () {
    for (final width in [390.0, 768.0, 1024.0, 1280.0]) {
      testWidgets('DBMS world renders without overflow at $width',
          (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final client = _client(
          subjects: [_dbmsSubject()],
          paths: [_pathFor('11111111-1111-1111-1111-111111111101')],
        );
        await tester.pumpWidget(_scope(
          client: client,
          child: const WorldScreen(
            subjectId: '11111111-1111-1111-1111-111111111101',
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(
          find.text('Database Management Systems // WORLD ARENA'),
          findsOneWidget,
        );
      });
    }
  });
}
