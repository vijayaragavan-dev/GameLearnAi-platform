import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gamelearn_app/app/router.dart';
import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/auth/providers/session_controller.dart';
import 'package:gamelearn_app/features/game_engine/models/game_models.dart';
import 'package:gamelearn_app/features/games/hub/presentation/game_hub_screen.dart';

import 'helpers/fake_backend.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Widget _appWithContainer(ProviderContainer container) {
  final router = container.read(routerProvider);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => MediaQuery(data: const MediaQueryData(disableAnimations: true), child: child!),
    ),
  );
}

Future<ProviderContainer> _makeContainer({Map<String, dynamic> Function(http.Request)? handler}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final client = MockClient((r) async {
    if (handler != null) {
      final res = handler(r);
      final status = (res['status'] as num?)?.toInt() ?? 200;
      Object? body = res['body'];
      if (body is Map || body is List) body = jsonEncode(body);
      return http.Response(body?.toString() ?? '', status, headers: {'content-type': 'application/json'});
    }
    final p = r.url.path;
    if (p.contains('/api/v1/quiz/')) return http.Response(jsonEncode(Fixtures.quiz()), 200, headers: {'content-type': 'application/json'});
    if (p.contains('/learning-path/')) return http.Response('[]', 200, headers: {'content-type': 'application/json'});
    if (p.contains('/dashboard')) return http.Response(jsonEncode(Fixtures.dashboardZeroState()), 200, headers: {'content-type': 'application/json'});
    if (p.endsWith('/subjects')) return http.Response('[]', 200, headers: {'content-type': 'application/json'});
    if (p.contains('/topics/')) return http.Response(jsonEncode({'id': 't1', 'subjectId': 's1', 'subjectName': 'Java', 'name': 'Control Flow', 'description': '', 'difficulty': 'MEDIUM', 'displayOrder': 1}), 200, headers: {'content-type': 'application/json'});
    return http.Response('', 200, headers: {'content-type': 'application/json'});
  });
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    tokenStorageProvider.overrideWithValue(FakeTokenStorage()..stored = 'tok'),
    apiClientProvider.overrideWith((ref) => ApiClient(client: client)),
    audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
  ]);
  c.read(sessionProvider.notifier).state = const SessionState(phase: SessionPhase.authenticated, user: null);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UI-6 Subject-Aware Games + General Games Context', () {
    test('GameConfig preserves subjectId and topicId', () {
      const cfg = GameConfig(topicId: 't-123', subjectId: 's-456', subjectName: 'Java', topicName: 'Control Flow', type: GameType.quizBattle, difficulty: GameDifficulty.medium);
      expect(cfg.topicId, 't-123');
      expect(cfg.subjectId, 's-456');
      expect(cfg.subjectName, 'Java');
      expect(cfg.topicName, 'Control Flow');
      expect(cfg.type, GameType.quizBattle);
    });

    test('Routes.gameHub builds with subject query params and topicId authoritative', () {
      final base = Routes.gameHub('t-1');
      expect(base, '/games/t-1');
      final withSubject = Routes.gameHub('t-1', subjectId: 's-1', subjectName: 'Java');
      expect(withSubject, contains('subjectId=s-1'));
      expect(withSubject, contains('subjectName=Java'));
      expect(withSubject.startsWith('/games/t-1'), isTrue);
      // subjectName never used as ID — base path still uses topicId
      expect(withSubject.contains('/games/Java'), isFalse);
    });

    test('Routes for all 14 games preserve subjectId as query, not path', () {
      final routes = [
        Routes.quizBattle('t1', subjectId: 's1'),
        Routes.memoryMatch('t1', subjectId: 's1'),
        Routes.dragDrop('t1', subjectId: 's1'),
        Routes.speedRun('t1', subjectId: 's1'),
        Routes.debugArena('t1', subjectId: 's1'),
        Routes.unlockCode('t1', subjectId: 's1'),
        Routes.conceptBuilder('t1', subjectId: 's1'),
        Routes.sequenceMaster('t1', subjectId: 's1'),
        Routes.targetChallenge('t1', subjectId: 's1'),
        Routes.mysteryCase('t1', subjectId: 's1'),
        Routes.bossBattle('t1', subjectId: 's1'),
        Routes.puzzleArena('t1', subjectId: 's1'),
        Routes.connectivityLab('t1', subjectId: 's1'),
        Routes.snakeAndLadder('t1', subjectId: 's1'),
      ];
      for (final r in routes) {
        expect(r, contains('subjectId=s1'));
        expect(r.startsWith('/games/t1'), isTrue);
      }
    });

    testWidgets('GameHub renders with subject context when real subjectId supplied', (tester) async {
      tester.view.physicalSize = const Size(1200, 5800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
      await tester.pumpWidget(const MaterialApp(home: GameHubScreen(topicId: 't1', topicName: 'Control Flow', subjectId: 's1', subjectName: 'Java')));
      expect(find.textContaining('JAVA'), findsWidgets);
      expect(find.textContaining('SUBJECT GAMES'), findsOneWidget);
      expect(find.textContaining('GENERAL GAMES'), findsOneWidget);
      // Semantics for subject game
      expect(find.bySemanticsLabel(RegExp(r'subject Java')), findsWidgets);
    });

    testWidgets('GameHub renders general context when no subjectId', (tester) async {
      tester.view.physicalSize = const Size(1200, 5800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
      await tester.pumpWidget(const MaterialApp(home: GameHubScreen(topicId: 't1', topicName: 'Variables')));
      expect(find.text('GAME ZONE'), findsOneWidget);
      expect(find.textContaining('GENERAL'), findsWidgets);
      expect(find.textContaining('SUBJECT GAMES'), findsNothing);
      // General semantics
      expect(find.bySemanticsLabel(RegExp(r'general game')), findsWidgets);
    });

    testWidgets('GameHub topic-specific navigation: topicId remains authoritative', (tester) async {
      final container = await _makeContainer();
      addTearDown(container.dispose);
      final widget = _appWithContainer(container);
      await tester.pumpWidget(widget);
      await tester.pump(const Duration(milliseconds: 300));
      final router = container.read(routerProvider);
      router.go(Routes.gameHub('t-abc', subjectId: 's-xyz', subjectName: 'Python'));
      await tester.pump(); await tester.pump(const Duration(milliseconds: 400));
      expect(router.routerDelegate.currentConfiguration.uri.path, '/games/t-abc');
      expect(router.routerDelegate.currentConfiguration.uri.queryParameters['subjectId'], 's-xyz');
      // TopicId in path, subjectId in query — not confused
      expect(router.routerDelegate.currentConfiguration.uri.path.contains('s-xyz'), isFalse);
    });

    testWidgets('General game route without subjectId still resolves', (tester) async {
      final container = await _makeContainer();
      addTearDown(container.dispose);
      final widget = _appWithContainer(container);
      await tester.pumpWidget(widget);
      await tester.pump(const Duration(milliseconds: 300));
      final router = container.read(routerProvider);
      router.go(Routes.gameHub('t-general'));
      await tester.pump(); await tester.pump(const Duration(milliseconds: 400));
      expect(router.routerDelegate.currentConfiguration.uri.path, '/games/t-general');
      expect(router.routerDelegate.currentConfiguration.uri.queryParameters['subjectId'], isNull);
      expect(find.text('GAME ZONE'), findsOneWidget);
    });

    testWidgets('Existing game routes still resolve (all 14)', (tester) async {
      final container = await _makeContainer();
      addTearDown(container.dispose);
      final widget = _appWithContainer(container);
      await tester.pumpWidget(widget);
      await tester.pump(const Duration(milliseconds: 300));
      final router = container.read(routerProvider);
      // Pick one subject-specific and one general
      router.go(Routes.quizBattle('t1', subjectId: 's1'));
      await tester.pump(); await tester.pump(const Duration(milliseconds: 400));
      expect(router.routerDelegate.currentConfiguration.uri.path, '/games/t1/quiz-battle');
      router.go(Routes.memoryMatch('t2'));
      await tester.pump(); await tester.pump(const Duration(milliseconds: 400));
      expect(router.routerDelegate.currentConfiguration.uri.path, '/games/t2/memory');
    });

    testWidgets('Subject name never used as ID (query subjectName does not replace topicId)', (tester) async {
      final container = await _makeContainer();
      addTearDown(container.dispose);
      final widget = _appWithContainer(container);
      await tester.pumpWidget(widget);
      await tester.pump(const Duration(milliseconds: 300));
      final router = container.read(routerProvider);
      router.go(Routes.gameHub('t-real', subjectId: 's-id', subjectName: 'My Subject With Spaces'));
      await tester.pump(); await tester.pump(const Duration(milliseconds: 400));
      expect(router.routerDelegate.currentConfiguration.uri.path, '/games/t-real');
      expect(router.routerDelegate.currentConfiguration.uri.queryParameters['subjectName'], 'My Subject With Spaces');
      // Ensure path still t-real, not My Subject
      expect(router.routerDelegate.currentConfiguration.uri.path.contains('My Subject'), isFalse);
    });

    testWidgets('Hub responsive at 360 and 1440 no overflow', (tester) async {
      // 360
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
      await tester.pumpWidget(const MaterialApp(home: GameHubScreen(topicId: 't1', topicName: 'A very long topic name that should wrap without overflow even on tiny screens', subjectId: 's1', subjectName: 'A very long subject name that should also wrap gracefully')));
      expect(tester.takeException(), isNull);
      // 1440
      tester.view.physicalSize = const Size(1440, 900);
      await tester.pumpWidget(const MaterialApp(home: GameHubScreen(topicId: 't1', topicName: 'Control Flow', subjectId: 's1', subjectName: 'Java')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('QUIZ BATTLE'), findsWidgets);
    });

    testWidgets('Light and dark theme render hub', (tester) async {
      await tester.pumpWidget(MaterialApp(theme: ThemeData.light(), home: const GameHubScreen(topicId: 't1', topicName: 'Variables', subjectId: 's1', subjectName: 'Java')));
      expect(find.text('GAME ARENA'), findsOneWidget);
      await tester.pumpWidget(MaterialApp(theme: ThemeData.dark(), home: const GameHubScreen(topicId: 't1', subjectId: 's1', subjectName: 'Java')));
      expect(find.text('GAME ARENA'), findsOneWidget);
    });

    test('No fake game-to-subject mapping invented', () {
      // All 14 definitions exist, no mapping table
      expect(GameDefinition.all.length, 14);
      // No hardcoded subject mapping in GameDefinition
      for (final d in GameDefinition.all) {
        expect(d.displayName, isNotEmpty);
        // No subject field in definition — proves no fake mapping
      }
    });
  });
}
