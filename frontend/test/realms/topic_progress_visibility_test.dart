// QA-8 — Learning progress visibility: the shared topic-progress map
// (ONE progressAll fetch, topicId-keyed) drives completion badges on
// realm topic rows. Backend-driven, generic, never name-based.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gamelearn_app/app/router.dart';
import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/gamification/providers/topic_progress_provider.dart';
import 'package:gamelearn_app/features/realms/presentation/realm_landing_screen.dart';
import 'package:gamelearn_app/shared/widgets/pressable.dart';

const _subjectId = '55555555-5555-5555-5555-555555555501';
const _nsId = '22222222-2222-2222-2222-222222222704';
const _nslrId = 'dddddddd-dddd-dddd-dddd-000000000012';
const _sylId = 'dddddddd-dddd-dddd-dddd-000000000016';

Map<String, dynamic> _realmJson() => {
  'id': '0a0a0a0a-0a0a-0a0a-0a0a-0a0a0a0a0a02',
  'realmKey': 'APTITUDE',
  'name': 'Aptitude',
  'description': 'Quantitative aptitude and logical reasoning.',
  'iconKey': 'realm_aptitude',
  'isActive': true,
  'displayOrder': 2,
};

Map<String, dynamic> _subjectJson() => {
  'id': _subjectId,
  'name': 'Aptitude',
  'description': 'Quantitative aptitude and logical reasoning.',
  'iconKey': 'aptitude',
  'isActive': true,
  'displayOrder': 100,
  'realmKey': 'APTITUDE',
};

Map<String, dynamic> _nodeJson({
  required String topicId,
  required String topicName,
  required int sequence,
}) => {
  'id': 'node-$sequence',
  'topicId': topicId,
  'topicName': topicName,
  'sequenceNumber': sequence,
  'requiredMastery': 0.0,
  'status': 'AVAILABLE',
};

Map<String, dynamic> _pathJson() => {
  'id': 'path-apt-1',
  'subjectId': _subjectId,
  'title': 'Aptitude Adventure',
  'description': 'Forge ahead.',
  'status': 'ACTIVE',
  'generatedBy': 'SYSTEM',
  'nodes': [
    _nodeJson(topicId: _nsId, topicName: 'Number Series', sequence: 1),
    _nodeJson(topicId: _nslrId, topicName: 'Number Series (LR)', sequence: 2),
    _nodeJson(topicId: _sylId, topicName: 'Syllogisms', sequence: 3),
  ],
};

Map<String, dynamic> _progressJson(String tid, String status, num pct) => {
  'id': 'prog-$tid',
  'topicId': tid,
  'learningPathNodeId': null,
  'completionPercentage': pct,
  'status': status,
  'lastActivityAt': '2026-09-26T10:00:00Z',
  'completedAt': status == 'COMPLETED' ? '2026-09-26T10:00:00Z' : null,
};

/// Controllable backend: stateful progress list, counted collection GETs,
/// counted PUTs, recorded POSTs (must stay empty — no gamification calls).
class _ProgressHarness {
  final progressGets = <String>[];
  final puts = <String>[];
  final posts = <String>[];
  final completed = <String>{};
  bool progressFails = false;
  Completer<void>? progressGate;

  MockClient get client => MockClient((request) async {
    final path = request.url.path;
    if (path == '/api/v1/realms/APTITUDE') {
      return http.Response(jsonEncode(_realmJson()), 200);
    }
    if (path == '/api/v1/realms/APTITUDE/subjects') {
      return http.Response(jsonEncode([_subjectJson()]), 200);
    }
    if (path == '/api/v1/subjects/$_subjectId/games') {
      // Zero playable games: honest empty compat, and no competing
      // check icons, so row badges are unambiguous in these tests.
      return http.Response(
        jsonEncode({
          'subjectId': _subjectId,
          'subjectName': 'Aptitude',
          'games': const [],
        }),
        200,
      );
    }
    if (path == '/api/v1/learning-path/$_subjectId') {
      return http.Response(jsonEncode([_pathJson()]), 200);
    }
    if (request.method == 'PUT' && path.startsWith('/api/v1/progress/')) {
      puts.add(path);
      completed.add(path.split('/').last);
      return http.Response(
        jsonEncode(
          _progressJson(path.split('/').last, 'COMPLETED', 100),
        ),
        200,
      );
    }
    if (request.method == 'POST') {
      posts.add(path);
    }
    if (path == '/api/v1/progress') {
      progressGets.add(path);
      final gate = progressGate;
      if (gate != null) await gate.future;
      if (progressFails) return http.Response('Server exploded', 500);
      return http.Response(
        jsonEncode([
          for (final tid in completed) _progressJson(tid, 'COMPLETED', 100),
        ]),
        200,
      );
    }
    return http.Response(
      jsonEncode({'errorCode': 'RESOURCE_NOT_FOUND', 'message': 'Not found'}),
      404,
    );
  });
}

GoRouter _router() => GoRouter(
  initialLocation: '/realm/APTITUDE',
  routes: [
    GoRoute(
      path: '/realm/:realmKey',
      builder: (_, s) =>
          RealmLandingScreen(realmKey: s.pathParameters['realmKey']!),
    ),
    GoRoute(
      path: Routes.subjects,
      builder: (_, _) => const Text('WORLDS CATALOG'),
    ),
    GoRoute(
      path: '/topic/:topicId',
      builder: (_, s) => Text('TOPIC:${s.pathParameters['topicId']}'),
    ),
    GoRoute(
      path: '/path/:subjectId',
      builder: (_, _) => const Text('PATH MAP'),
    ),
  ],
);

Future<void> _settleLanding(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
}

/// The topic row for [name]: Pressable ancestor of the topic label.
Finder _rowFor(String name) => find.ancestor(
  of: find.text(name, skipOffstage: false),
  matching: find.byType(Pressable),
);

Finder _rowCheck(String name) => find.descendant(
  of: _rowFor(name),
  matching: find.byIcon(Icons.check_circle_rounded),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('completed topic shows badge; others do not (ID-keyed)',
      (tester) async {
    final h = _ProgressHarness()..completed.add(_nslrId);
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWith((ref) => ApiClient(client: h.client)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: _router()),
      ),
    );
    await _settleLanding(tester);

    // All three backend-ordered topics render.
    expect(find.text('Number Series', skipOffstage: false), findsOneWidget);
    expect(
      find.text('Number Series (LR)', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Syllogisms', skipOffstage: false), findsOneWidget);
    // Only the completed backend id carries the badge…
    expect(_rowCheck('Number Series (LR)'), findsOneWidget);
    // …and the similarly named plain topic does NOT cross-match.
    expect(_rowCheck('Number Series'), findsNothing);
    expect(_rowCheck('Syllogisms'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ONE progress collection fetch for the whole list (no N+1)',
      (tester) async {
    final h = _ProgressHarness()..completed.add(_nslrId);
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWith((ref) => ApiClient(client: h.client)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: _router()),
      ),
    );
    await _settleLanding(tester);

    expect(find.text('Syllogisms', skipOffstage: false), findsOneWidget);
    expect(h.progressGets, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('progress loading degrades gracefully (no claimed badge)',
      (tester) async {
    final h = _ProgressHarness()
      ..completed.add(_nslrId)
      ..progressGate = Completer<void>();
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWith((ref) => ApiClient(client: h.client)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: _router()),
      ),
    );
    await _settleLanding(tester);

    // Path rows render while progress is still in flight…
    expect(find.text('Syllogisms', skipOffstage: false), findsOneWidget);
    // …but nothing claims completion before verification.
    expect(
      find.byIcon(Icons.check_circle_rounded, skipOffstage: false),
      findsNothing,
    );
    h.progressGate!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(_rowCheck('Number Series (LR)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('progress API failure keeps usable content, claims nothing',
      (tester) async {
    final h = _ProgressHarness()..progressFails = true;
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWith((ref) => ApiClient(client: h.client)),
      ],
    );
    var disposed = false;
    void disposeContainer() {
      if (!disposed) {
        disposed = true;
        container.dispose();
      }
    }

    addTearDown(disposeContainer);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: _router()),
      ),
    );
    await _settleLanding(tester);

    // Learning content stays usable…
    expect(find.text('Number Series', skipOffstage: false), findsOneWidget);
    expect(find.text('Syllogisms', skipOffstage: false), findsOneWidget);
    // …with zero fabricated completion.
    expect(
      find.byIcon(Icons.check_circle_rounded, skipOffstage: false),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
    // The failing provider schedules background retries: dispose the
    // container before the test ends so no retry timer outlives the tree.
    disposeContainer();
  });

  testWidgets('invalidation after completion refreshes the row',
      (tester) async {
    final h = _ProgressHarness();
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWith((ref) => ApiClient(client: h.client)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: _router()),
      ),
    );
    await _settleLanding(tester);
    expect(_rowCheck('Number Series'), findsNothing);

    // Exactly one explicit PUT (the LessonScreen path), then the shared
    // map refreshes — the surrounding list reflects the new state.
    await container.read(gamificationRepoProvider).markTopicComplete(_nsId);
    container.invalidate(topicProgressProvider);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(_rowCheck('Number Series'), findsOneWidget);
    expect(
      h.puts.where((p) => p.endsWith('/api/v1/progress/$_nsId')),
      hasLength(1),
    );
    expect(h.posts, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('320px renders without overflow', (tester) async {
    final h = _ProgressHarness()..completed.addAll([_nslrId, _sylId]);
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWith((ref) => ApiClient(client: h.client)),
      ],
    );
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: _router()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('APTITUDE', skipOffstage: false), findsWidgets);
    expect(_rowCheck('Number Series (LR)'), findsOneWidget);
    expect(_rowCheck('Syllogisms'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet and desktop widths render badges without overflow',
      (tester) async {
    for (final size in [const Size(768, 1024), const Size(1440, 900)]) {
      final h = _ProgressHarness()..completed.addAll([_nslrId, _sylId]);
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith((ref) => ApiClient(client: h.client)),
        ],
      );
      addTearDown(container.dispose);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: _router()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('APTITUDE', skipOffstage: false), findsWidgets);
      expect(_rowCheck('Number Series (LR)'), findsOneWidget);
      expect(_rowCheck('Syllogisms'), findsOneWidget);
      expect(_rowCheck('Number Series'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
}
