// Realm backend integration: models, repository, provider, landing,
// game-context honesty, and shared result/XP handling. All HTTP is
// mocked at the verified REALM-001 shapes; no live backend needed.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gamelearn_app/app/router.dart';
import 'package:gamelearn_app/core/models/content_models.dart';
import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/network/api_exception.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/game_engine/models/game_content_models.dart';
import 'package:gamelearn_app/features/gamification/providers/game_result_submitter.dart';
import 'package:gamelearn_app/features/game_engine/models/game_content_models.dart';
import 'package:gamelearn_app/features/gamification/providers/game_result_submitter.dart';
import 'package:gamelearn_app/features/games/quiz_battle/presentation/quiz_battle_screen.dart';
import 'package:gamelearn_app/features/games/speed_run/presentation/speed_run_screen.dart';
import 'package:gamelearn_app/features/realms/data/realm_models.dart';
import 'package:gamelearn_app/features/realms/data/realm_repository.dart';
import 'package:gamelearn_app/features/realms/domain/learning_realm.dart';
import 'package:gamelearn_app/features/realms/presentation/realm_landing_screen.dart';
import 'package:gamelearn_app/shared/widgets/feedback.dart';

import '../helpers/fake_backend.dart';

const _aptitudeSubjectId = '55555555-5555-5555-5555-555555555501';
const _percentagesTopicId = '77777777-7777-7777-7777-777777777701';

Map<String, dynamic> _realmJson(String key, String name, int order) => {
  'id': '0a0a0a0a-0a0a-0a0a-0a0a-0a0a0a0a0a0${order == 1 ? 1 : 2}',
  'realmKey': key,
  'name': name,
  'description': '$name description',
  'iconKey': 'realm_${key.toLowerCase()}',
  'isActive': true,
  'displayOrder': order,
};

Map<String, dynamic> _aptitudeSubjectJson() => {
  'id': _aptitudeSubjectId,
  'name': 'Aptitude',
  'description': 'Quantitative aptitude and logical reasoning.',
  'iconKey': 'aptitude',
  'isActive': true,
  'displayOrder': 100,
  'realmKey': 'APTITUDE',
};

Map<String, dynamic> _compatJson() => {
  'subjectId': _aptitudeSubjectId,
  'subjectName': 'Aptitude',
  'games': [
    {
      'gameType': 'quiz_battle',
      'rationale': 'MCQ skills',
      'hasContent': true,
      'contentCount': 18,
    },
    {
      'gameType': 'speed_run',
      'rationale': 'Timed drills',
      'hasContent': true,
      'contentCount': 18,
    },
  ],
};

Map<String, dynamic> _nodeJson({
  required String topicId,
  required String topicName,
  required int sequence,
  String status = 'AVAILABLE',
}) => {
  'id': 'node-$sequence',
  'topicId': topicId,
  'topicName': topicName,
  'sequenceNumber': sequence,
  'requiredMastery': 0.0,
  'status': status,
};

/// Path payload mirroring PATH-001: original Number Series plus the
/// distinct LR import, proving identities never merge.
Map<String, dynamic> _aptitudePathJson() => {
  'id': 'path-apt-1',
  'subjectId': _aptitudeSubjectId,
  'title': 'Aptitude Adventure',
  'description': 'Forge ahead.',
  'status': 'ACTIVE',
  'generatedBy': 'SYSTEM',
  'nodes': [
    _nodeJson(
      topicId: '22222222-2222-2222-2222-222222222704',
      topicName: 'Number Series',
      sequence: 1,
    ),
    _nodeJson(
      topicId: 'dddddddd-dddd-dddd-dddd-000000000012',
      topicName: 'Number Series (LR)',
      sequence: 2,
    ),
    _nodeJson(
      topicId: 'dddddddd-dddd-dddd-dddd-000000000016',
      topicName: 'Syllogisms',
      sequence: 3,
    ),
  ],
};

/// Full mock backend for the aptitude vertical slice.
MockClient _aptitudeClient() => MockClient((request) async {
  final path = request.url.path;
  if (path == '/api/v1/realms') {
    return http.Response(
      jsonEncode([
        _realmJson('COMPUTER_SCIENCE', 'Computer Science', 1),
        _realmJson('APTITUDE', 'Aptitude', 2),
      ]),
      200,
    );
  }
  if (path == '/api/v1/realms/APTITUDE') {
    return http.Response(jsonEncode(_realmJson('APTITUDE', 'Aptitude', 2)), 200);
  }
  if (path == '/api/v1/realms/APTITUDE/subjects') {
    return http.Response(jsonEncode([_aptitudeSubjectJson()]), 200);
  }
  if (path == '/api/v1/subjects/$_aptitudeSubjectId/games') {
    return http.Response(jsonEncode(_compatJson()), 200);
  }
  if (path == '/api/v1/learning-path/$_aptitudeSubjectId') {
    return http.Response(jsonEncode([_aptitudePathJson()]), 200);
  }
  if (path == '/api/v1/quiz/$_percentagesTopicId') {
    // No Quiz rows exist for aptitude topics: honest 404, exactly as
    // the verified backend behaves (QUIZ-001 requires Quiz rows).
    return http.Response(
      jsonEncode({'errorCode': 'RESOURCE_NOT_FOUND', 'message': 'Quiz not found'}),
      404,
    );
  }
  if (path == '/api/v1/me/game-results' && request.method == 'POST') {
    return http.Response(
      jsonEncode({
        'requestId': 'r1',
        'xpEarned': 24,
        'previousLevel': 1,
        'currentLevel': 1,
        'previousTotalXp': 480,
        'currentTotalXp': 504,
        'leveledUp': false,
        'levelsGained': 0,
        'playedAt': '2026-09-25T00:00:00Z',
      }),
      200,
    );
  }
  return http.Response(
    jsonEncode({'errorCode': 'RESOURCE_NOT_FOUND', 'message': 'Not found'}),
    404,
  );
});

RealmRepository _repo() =>
    RealmRepository(ApiClient(client: _aptitudeClient()));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Realm API models', () {
    test('BackendRealm parses the verified REALM-001 shape', () {
      final realm = BackendRealm.fromJson(
        _realmJson('APTITUDE', 'Aptitude', 2),
      );
      expect(realm.realmKey, 'APTITUDE');
      expect(realm.name, 'Aptitude');
      expect(realm.isActive, isTrue);
      expect(realm.displayOrder, 2);
    });

    test('BackendRealm is defensive against sparse JSON', () {
      final realm = BackendRealm.fromJson(const {});
      expect(realm.realmKey, '');
      expect(realm.name, '');
      expect(realm.isActive, isTrue);
      expect(realm.displayOrder, 0);
    });

    test('ResolvedRealm inherits known visuals and structure', () {
      final resolved = ResolvedRealm.resolve(
        BackendRealm.fromJson(_realmJson('APTITUDE', 'Aptitude', 2)),
      );
      expect(resolved.visual?.id, RealmId.aptitude);
      expect(resolved.structure, RealmLearningStructure.skillBased);
      expect(resolved.isWorldBased, isFalse);
    });

    test('ResolvedRealm falls back generically for unknown keys', () {
      final resolved = ResolvedRealm.resolve(
        BackendRealm.fromJson(_realmJson('CHESS', 'Chess', 9)),
      );
      expect(resolved.visual, isNull);
      expect(resolved.isWorldBased, isFalse);
      expect(resolved.backend.name, 'Chess');
    });

    test('Subject parses additive realmKey, null for legacy payloads', () {
      final withRealm = Subject.fromJson(_aptitudeSubjectJson());
      expect(withRealm.realmKey, 'APTITUDE');
      final legacy = Subject.fromJson({
        'id': '11111111-1111-1111-1111-111111111101',
        'name': 'Programming',
      });
      expect(legacy.realmKey, isNull);
    });
  });

  group('RealmRepository', () {
    test('realm() returns the backend realm', () async {
      final realm = await _repo().realm('APTITUDE');
      expect(realm.name, 'Aptitude');
      expect(realm.realmKey, 'APTITUDE');
    });

    test('subjectsForRealm() returns realm subjects with keys', () async {
      final subjects = await _repo().subjectsForRealm('APTITUDE');
      expect(subjects, hasLength(1));
      expect(subjects.first.name, 'Aptitude');
      expect(subjects.first.realmKey, 'APTITUDE');
    });

    test('unknown realm surfaces NotFoundException', () async {
      expect(
        () => _repo().realm('NOPE'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('401 surfaces UnauthorizedException (existing auth handling)',
        () async {
      final repo = RealmRepository(
        ApiClient(
          client: MockClient((_) async => http.Response('', 401)),
        ),
      );
      expect(() => repo.realms(), throwsA(isA<UnauthorizedException>()));
    });

    test('network failure surfaces NetworkException', () async {
      final repo = RealmRepository(
        ApiClient(
          client: MockClient(
            (_) async => throw http.ClientException('down'),
          ),
        ),
      );
      expect(() => repo.realms(), throwsA(isA<NetworkException>()));
    });

    test('realmRepoProvider exposes the repository', () async {
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => ApiClient(client: _aptitudeClient()),
          ),
        ],
      );
      addTearDown(container.dispose);
      final repo = container.read(realmRepoProvider);
      expect(repo, isA<RealmRepository>());
      expect((await repo.realms()).length, greaterThanOrEqualTo(1));
    });
  });

  group('RealmLandingScreen (APTITUDE)', () {
    GoRouter router() => GoRouter(
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
          builder: (_, s) =>
              Text('TOPIC:${s.pathParameters['topicId']}'),
        ),
        GoRoute(
          path: '/path/:subjectId',
          builder: (_, _) => const Text('PATH MAP'),
        ),
      ],
    );

    Future<void> pumpLanding(WidgetTester tester, Widget app) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
    }

    Widget scoped(GoRouter r) => ProviderScope(
      overrides: [
        apiClientProvider.overrideWith(
          (ref) => ApiClient(client: _aptitudeClient()),
        ),
      ],
      child: MaterialApp.router(routerConfig: r),
    );

    testWidgets('renders real subject, compat games and path CTA',
        (tester) async {
      await pumpLanding(tester, scoped(router()));
      // Hero title plus uppercased badge both render the realm name.
      expect(find.text('APTITUDE'), findsWidgets);
      expect(
        find.textContaining('Quantitative aptitude', skipOffstage: false),
        findsOneWidget,
      );
      // Backend compat strip with real content counts.
      expect(find.textContaining('quiz_battle', skipOffstage: false), findsOneWidget);
      expect(find.textContaining('speed_run', skipOffstage: false), findsOneWidget);
      expect(find.text('OPEN LEARNING PATH'), findsOneWidget);
      expect(find.text('ASK NOVA TUTOR'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('topics list preserves distinct LR identities',
        (tester) async {
      await pumpLanding(tester, scoped(router()));
      // Original and LR import render side by side, never merged.
      expect(find.text('Number Series', skipOffstage: false), findsOneWidget);
      expect(
        find.text('Number Series (LR)', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Syllogisms', skipOffstage: false), findsOneWidget);
      // Tapping the LR node navigates by its backend topicId.
      await tester.ensureVisible(
        find.text('Number Series (LR)', skipOffstage: false),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(
        find.text('Number Series (LR)', skipOffstage: false),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.text('TOPIC:dddddddd-dddd-dddd-dddd-000000000012'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty path offers honest forge entry', (tester) async {
      final client = MockClient((request) async {
        final path = request.url.path;
        if (path == '/api/v1/realms/APTITUDE') {
          return http.Response(
            jsonEncode(_realmJson('APTITUDE', 'Aptitude', 2)),
            200,
          );
        }
        if (path == '/api/v1/realms/APTITUDE/subjects') {
          return http.Response(
            jsonEncode([_aptitudeSubjectJson()]),
            200,
          );
        }
        if (path ==
            '/api/v1/subjects/$_aptitudeSubjectId/games') {
          return http.Response(jsonEncode(_compatJson()), 200);
        }
        if (path == '/api/v1/learning-path/$_aptitudeSubjectId') {
          return http.Response(jsonEncode([]), 200);
        }
        return http.Response(
          jsonEncode(
              {'errorCode': 'RESOURCE_NOT_FOUND', 'message': 'Not found'}),
          404,
        );
      });
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(client: client),
            ),
          ],
          child: MaterialApp.router(routerConfig: router()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(
        find.textContaining('No learning path forged yet', skipOffstage: false),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.text('FORGE LEARNING PATH', skipOffstage: false),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(
        find.text('FORGE LEARNING PATH', skipOffstage: false),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      // Forge entry reuses the existing path map route.
      expect(find.text('PATH MAP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('topics error renders honest retryable state',
        (tester) async {
      final client = MockClient((request) async {
        final path = request.url.path;
        if (path == '/api/v1/realms/APTITUDE') {
          return http.Response(
            jsonEncode(_realmJson('APTITUDE', 'Aptitude', 2)),
            200,
          );
        }
        if (path == '/api/v1/realms/APTITUDE/subjects') {
          return http.Response(
            jsonEncode([_aptitudeSubjectJson()]),
            200,
          );
        }
        if (path ==
            '/api/v1/subjects/$_aptitudeSubjectId/games') {
          return http.Response(jsonEncode(_compatJson()), 200);
        }
        return http.Response('Server exploded', 500);
      });
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(client: client),
            ),
          ],
          child: MaterialApp.router(routerConfig: router()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      // Topics section degrades honestly; the rest stays usable.
      expect(
        find.textContaining('Topics are unavailable', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('APTITUDE'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unknown realm key renders honest error with retry',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final r = router();
      await tester.pumpWidget(scoped(r));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      r.go('/realm/NOPE');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      // Honest error state (ErrorState retry affordance present).
      expect(find.text('TRY AGAIN', skipOffstage: false), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Computer Science key redirects to worlds', (tester) async {
      final client = MockClient((request) async {
        final path = request.url.path;
        if (path == '/api/v1/realms/COMPUTER_SCIENCE') {
          return http.Response(
            jsonEncode(_realmJson('COMPUTER_SCIENCE', 'Computer Science', 1)),
            200,
          );
        }
        if (path == '/api/v1/realms/COMPUTER_SCIENCE/subjects') {
          return http.Response(jsonEncode([]), 200);
        }
        return http.Response('{}', 404);
      });
      await pumpLanding(
        tester,
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(client: client),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/realm/COMPUTER_SCIENCE',
              routes: [
                GoRoute(
                  path: '/realm/:realmKey',
                  builder: (_, s) => RealmLandingScreen(
                    realmKey: s.pathParameters['realmKey']!,
                  ),
                ),
                GoRoute(
                  path: Routes.subjects,
                  builder: (_, _) => const Text('WORLDS CATALOG'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('WORLDS CATALOG'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320px renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(scoped(router()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('APTITUDE'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1280px renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(scoped(router()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('APTITUDE'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('light theme renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(client: _aptitudeClient()),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router(),
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.light,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('APTITUDE'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion renders the same truth', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(client: _aptitudeClient()),
            ),
          ],
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MaterialApp.router(routerConfig: router()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('APTITUDE'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('Aptitude game context honesty', () {
    testWidgets('Quiz Battle shows honest empty state without Quiz rows',
        (tester) async {
      // Aptitude topics carry Questions (game-content API) but no Quiz
      // rows (QUIZ-001): the game must render its honest empty state,
      // never fabricated or substituted content. Backend Quiz seed rows
      // are the documented missing piece — no frontend workaround.
      await tester.pumpWidget(
        fakeScope(
          child: const MaterialApp(
            home: QuizBattleScreen(
              topicId: _percentagesTopicId,
              topicName: 'Percentages',
              subjectId: _aptitudeSubjectId,
              subjectName: 'Aptitude',
            ),
          ),
          handler: (request) {
            final path = request.url.path;
            if (path.endsWith('/api/v1/quiz/$_percentagesTopicId')) {
              return {
                'status': 404,
                'body': {
                  'errorCode': 'RESOURCE_NOT_FOUND',
                  'message': 'Quiz not found',
                },
              };
            }
            if (path.endsWith('/api/v1/gamification/summary')) {
              return {
                'body': Fixtures.gamificationSummary(),
              };
            }
            if (path.endsWith('/api/v1/achievements')) {
              return {
                'body': Fixtures.achievements(),
              };
            }
            return {
              'status': 404,
              'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
            };
          },
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      // 404 Quiz rows → honest ErrorState (ErrorState, never game
      // content, never a crash). EmptyState covers the zero-question
      // case; both are honest by construction.
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('No questions'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Speed Run shows honest empty state without Quiz rows',
        (tester) async {
      await tester.pumpWidget(
        fakeScope(
          child: MaterialApp(
            home: const SpeedRunScreen(
              topicId: _percentagesTopicId,
              topicName: 'Percentages',
              subjectId: _aptitudeSubjectId,
              subjectName: 'Aptitude',
            ),
          ),
          handler: (request) {
            final path = request.url.path;
            if (path.endsWith('/api/v1/quiz/$_percentagesTopicId')) {
              return {
                'status': 404,
                'body': {
                  'errorCode': 'RESOURCE_NOT_FOUND',
                  'message': 'Quiz not found',
                },
              };
            }
            if (path.endsWith('/api/v1/gamification/summary')) {
              return {
                'body': Fixtures.gamificationSummary(),
              };
            }
            if (path.endsWith('/api/v1/achievements')) {
              return {
                'body': Fixtures.achievements(),
              };
            }
            return {
              'status': 404,
              'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
            };
          },
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('No questions'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Shared result and XP handling', () {
    testWidgets('result submission parses XP through the common contract',
        (tester) async {
      // The submission carries no subject: identical path for every
      // realm, proving shared progression without per-realm variants.
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(client: _aptitudeClient()),
            ),
          ],
          child: Builder(
            builder: (context) {
              container = ProviderScope.containerOf(context);
              return const SizedBox();
            },
          ),
        ),
      );
      final submitter = container.read(gameResultSubmitterProvider);
      final response = await submitter.submit(
        gameType: 'quiz_battle',
        difficulty: 'EASY',
        completed: true,
        score: 100,
        durationSeconds: 60,
        bestCombo: 3,
      );
      expect(response, isNotNull);
      expect(response!.xpEarned, 24);
      expect(response.currentTotalXp, 504);
    });

    test('SubjectGames entry lookup stays backend-driven', () {
      const games = SubjectGames(
        subjectId: _aptitudeSubjectId,
        subjectName: 'Aptitude',
        games: [
          SubjectGameEntry(
            gameType: 'quiz_battle',
            rationale: 'MCQ skills',
            hasContent: true,
            contentCount: 18,
          ),
        ],
      );
      expect(games.entryFor('quiz_battle')?.hasContent, isTrue);
      expect(games.entryFor('memory_match'), isNull);
    });
  });
}
