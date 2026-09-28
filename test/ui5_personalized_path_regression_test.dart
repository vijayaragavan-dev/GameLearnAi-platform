import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gamelearn_app/app/router.dart';
import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/auth/providers/session_controller.dart';
import 'package:gamelearn_app/shared/widgets/game_button.dart';

import 'helpers/fake_backend.dart';

Widget _appWithContainer(ProviderContainer container) {
  final router = container.read(routerProvider);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: child!,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UI-5 Personalized Path — Assessment Result → View My Path regression', () {
    const testSubjectId = '11111111-1111-1111-1111-111111111101';
    const otherSubjectId = '99999999-9999-9999-9999-999999999999';

    late ProviderContainer container;

    Future<ProviderContainer> makeContainer({
      required Map<String, dynamic> Function(http.Request) handler,
    }) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage()..stored = 'tok',
          ),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              client: MockClient((r) async {
                final result = handler(r);
                final status = (result['status'] as num?)?.toInt() ?? 200;
                Object? body = result['body'];
                if (body is Map || body is List) body = jsonEncode(body);
                return http.Response(
                  body?.toString() ?? '',
                  status,
                  headers: {'content-type': 'application/json'},
                );
              }),
            ),
          ),
          audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
        ],
      );
      c.read(sessionProvider.notifier).state = const SessionState(
        phase: SessionPhase.authenticated,
        user: null,
      );
      return c;
    }

    tearDown(() {
      try {
        container.dispose();
      } catch (_) {}
    });

    testWidgets('Assessment result renders View My Path CTA', (tester) async {
      container = await makeContainer(
        handler: (req) {
          final p = req.url.path;
          if (p.contains('/assessment/$testSubjectId/result')) {
            return {
              'body': {
                'subjectId': testSubjectId,
                'assessed': true,
                'overallMastery': 42.0,
                'topics': [
                  {
                    'topicId': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1',
                    'topicName': 'Variables',
                    'masteryScore': 60,
                    'masteryLevel': 'DEVELOPING',
                    'currentDifficulty': 'MEDIUM',
                  },
                ],
              },
            };
          }
          if (p.contains('/learning-path/')) return {'body': []};
          if (p.contains('/dashboard'))
            return {'body': Fixtures.dashboardZeroState()};
          if (p.endsWith('/subjects')) return {'body': Fixtures.subjects()};
          return {'body': {}};
        },
      );

      final widget = _appWithContainer(container);
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final router = container.read(routerProvider);
      router.go(Routes.assessmentResult(testSubjectId));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('VIEW MY PATH'), findsOneWidget);
      expect(find.text('BACK TO HOME'), findsOneWidget);
    });

    testWidgets('View My Path navigates to correct subject path (not Home)', (
      tester,
    ) async {
      container = await makeContainer(
        handler: (req) {
          final p = req.url.path;
          if (p.contains('/assessment/$testSubjectId/result')) {
            return {
              'body': {
                'subjectId': testSubjectId,
                'assessed': true,
                'overallMastery': 55.0,
                'topics': [
                  {
                    'topicId': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1',
                    'topicName': 'Control Flow',
                    'masteryScore': 70,
                    'masteryLevel': 'PROFICIENT',
                    'currentDifficulty': 'MEDIUM',
                  },
                ],
              },
            };
          }
          if (p.contains('/learning-path/$testSubjectId')) {
            return {
              'body': [Fixtures.learningPath()],
            };
          }
          if (p.contains('/learning-path/')) return {'body': []};
          if (p.contains('/dashboard'))
            return {'body': Fixtures.dashboardZeroState()};
          if (p.endsWith('/subjects')) return {'body': Fixtures.subjects()};
          return {'body': {}};
        },
      );

      final widget = _appWithContainer(container);
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final router = container.read(routerProvider);
      router.go(Routes.assessmentResult(testSubjectId));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('VIEW MY PATH'), findsOneWidget);
      await tester.ensureVisible(find.text('VIEW MY PATH'));
      await tester.pumpAndSettle();
      // Directly invoke the button's onTap to avoid hit-test flakiness from confetti overlay
      final btn = tester.widget<PrimaryGameButton>(
        find.widgetWithText(PrimaryGameButton, 'VIEW MY PATH'),
      );
      expect(
        btn.onTap,
        isNotNull,
        reason: 'View My Path button must have onTap',
      );
      btn.onTap!.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      // Extra settle for GoRouter transition
      await tester.pump(const Duration(milliseconds: 800));

      // Must NOT be /home — must be /path/<subjectId>
      final loc = router.routerDelegate.currentConfiguration.uri;
      expect(
        loc.path,
        Routes.path(testSubjectId),
        reason: 'View My Path must navigate to subject-specific path, not Home',
      );
      expect(loc.path, isNot(Routes.home));
      // Ensure correct subject ID is passed, not other subject
      expect(loc.path.contains(testSubjectId), isTrue);
      expect(loc.path.contains(otherSubjectId), isFalse);
    });

    testWidgets('View My Path uses actual widget.subjectId (no ID confusion)', (
      tester,
    ) async {
      // Use a second subjectId to ensure ID is taken from route param, not a hardcoded value.
      const secondId = '22222222-2222-2222-2222-222222222222';
      container = await makeContainer(
        handler: (req) {
          final p = req.url.path;
          if (p.contains('/assessment/$secondId/result')) {
            return {
              'body': {
                'subjectId': secondId,
                'assessed': true,
                'overallMastery': 80,
                'topics': [],
              },
            };
          }
          if (p.contains('/learning-path/$secondId')) return {'body': []};
          if (p.contains('/learning-path/')) return {'body': []};
          if (p.contains('/dashboard'))
            return {'body': Fixtures.dashboardZeroState()};
          if (p.endsWith('/subjects')) return {'body': Fixtures.subjects()};
          return {'body': {}};
        },
      );

      final widget = _appWithContainer(container);
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final router = container.read(routerProvider);
      router.go(Routes.assessmentResult(secondId));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('VIEW MY PATH'), findsOneWidget);
      await tester.ensureVisible(find.text('VIEW MY PATH'));
      await tester.pumpAndSettle();
      final tBtn = tester.widget<PrimaryGameButton>(
        find.widgetWithText(PrimaryGameButton, 'VIEW MY PATH'),
      );
      expect(tBtn.onTap, isNotNull);
      tBtn.onTap!.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        Routes.path(secondId),
      );
    });

    testWidgets(
      'Existing Subjects → Path navigation still works (no regression)',
      (tester) async {
        container = await makeContainer(
          handler: (req) {
            final p = req.url.path;
            if (p.contains('/learning-path/')) return {'body': []};
            if (p.contains('/dashboard'))
              return {'body': Fixtures.dashboardZeroState()};
            if (p.endsWith('/subjects')) return {'body': Fixtures.subjects()};
            return {'body': {}};
          },
        );

        final widget = _appWithContainer(container);
        await tester.pumpWidget(widget);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final router = container.read(routerProvider);
        // Simulate Subjects → Path via direct go (same as SubjectsScreen._enter)
        final name = Uri.encodeComponent('Programming');
        router.go('/${Routes.path(testSubjectId).substring(1)}?name=$name');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          Routes.path(testSubjectId),
        );
        expect(
          router
              .routerDelegate
              .currentConfiguration
              .uri
              .queryParameters['name'],
          'Programming',
        );
      },
    );

    testWidgets(
      'Path screen renders real node states (COMPLETED/AVAILABLE/LOCKED)',
      (tester) async {
        container = await makeContainer(
          handler: (req) {
            final p = req.url.path;
            if (p.contains('/learning-path/$testSubjectId')) {
              return {
                'body': [Fixtures.learningPath()],
              };
            }
            if (p.contains('/learning-path/')) return {'body': []};
            if (p.contains('/dashboard'))
              return {'body': Fixtures.dashboardZeroState()};
            if (p.endsWith('/subjects')) return {'body': Fixtures.subjects()};
            return {'body': {}};
          },
        );

        final widget = _appWithContainer(container);
        await tester.pumpWidget(widget);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final router = container.read(routerProvider);
        router.go(Routes.path(testSubjectId));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));
        await tester.pump(const Duration(milliseconds: 800));
        await tester.pump(const Duration(milliseconds: 400));

        // Header shows subject title from fixture
        expect(
          find.textContaining('Programming Foundations Sprint'),
          findsOneWidget,
        );
        // Progress derived from real nodes
        expect(find.textContaining('1 of 3 topics completed'), findsOneWidget);
        // Continue/Next derived from real AVAILABLE node
        expect(find.textContaining('Control Flow'), findsWidgets);
        final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').toList();
        // Node statuses truthful — check both raw and capitalized (trail uses capitalized, list uses raw)
        expect(texts.any((s) => s == 'COMPLETED' || s == 'Completed'), isTrue);
        expect(texts.any((s) => s == 'AVAILABLE' || s == 'Available'), isTrue);
        expect(texts.any((s) => s == 'LOCKED' || s == 'Locked'), isTrue);
        // Current topic CTA (upcased)
        expect(find.text('START NEXT TOPIC'), findsOneWidget);
      },
    );

    testWidgets('Path empty state when no ACTIVE path', (tester) async {
      container = await makeContainer(
        handler: (req) {
          final p = req.url.path;
          if (p.contains('/learning-path/')) return {'body': []};
          if (p.contains('/dashboard'))
            return {'body': Fixtures.dashboardZeroState()};
          if (p.endsWith('/subjects')) return {'body': Fixtures.subjects()};
          return {'body': {}};
        },
      );

      final widget = _appWithContainer(container);
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final router = container.read(routerProvider);
      router.go(Routes.path(testSubjectId));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Forge your path'), findsOneWidget);
      expect(find.text('GENERATE PATH'), findsOneWidget);
    });
  });
}
