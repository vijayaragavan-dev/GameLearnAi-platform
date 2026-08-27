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

import '../helpers/fake_backend.dart';

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
  group('Deep-link regression /path/:subjectId?name=', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage()..stored = 'tok',
          ),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              client: MockClient((request) async {
                final path = request.url.path;
                if (path.contains('/learning-path/')) {
                  return http.Response(
                    '[]',
                    200,
                    headers: {'content-type': 'application/json'},
                  );
                }
                if (path.contains('/dashboard')) {
                  return http.Response(
                    '{}',
                    200,
                    headers: {'content-type': 'application/json'},
                  );
                }
                if (path.endsWith('/subjects')) {
                  return http.Response(
                    '[]',
                    200,
                    headers: {'content-type': 'application/json'},
                  );
                }
                return http.Response('', 200);
              }),
            ),
          ),
          audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
        ],
      );
      // Force authenticated session
      container.read(sessionProvider.notifier).state = const SessionState(
        phase: SessionPhase.authenticated,
        user: null,
      );
      // Bind router's redirect listener to provider
      // GoRouter will read sessionProvider via ref.read in redirect.
    });

    tearDown(() => container.dispose());

    test('Routes.path builds correct path and name encoding', () {
      expect(Routes.path('abc-123'), '/path/abc-123');
      final name = Uri.encodeComponent('Java & OOP');
      expect(
        '/${Routes.path('abc-123').substring(1)}?name=$name',
        '/path/abc-123?name=Java%20%26%20OOP',
      );
    });

    testWidgets('valid subject ID resolves to PathMapScreen', (tester) async {
      final widget = _appWithContainer(container);
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Start at /splash, but authenticated should redirect to /home per router.
      // Now navigate to /path/:subjectId?name=
      final router = container.read(routerProvider);
      router.go('/path/11111111-1111-1111-1111-111111111101?name=Programming');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/path/11111111-1111-1111-1111-111111111101',
      );
      expect(
        router.routerDelegate.currentConfiguration.uri.queryParameters['name'],
        'Programming',
      );
      // Find PathMapScreen by checking for header text (subjectName uppercased) or known widget
      expect(find.text('PROGRAMMING'), findsOneWidget);
    });

    testWidgets('optional name query does not break routing - empty name', (
      tester,
    ) async {
      final widget = _appWithContainer(container);
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final router = container.read(routerProvider);
      router.go('/path/22222222-2222-2222-2222-222222222222');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/path/22222222-2222-2222-2222-222222222222',
      );
      expect(
        router.routerDelegate.currentConfiguration.uri.queryParameters['name'],
        isNull,
      );
      // Should still show PathMapScreen (with empty header)
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/path/22222222-2222-2222-2222-222222222222',
      );
    });

    testWidgets('subject ID is authoritative, name is presentation-only', (
      tester,
    ) async {
      String? capturedPathId;
      final testContainer = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage()..stored = 'tok',
          ),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              client: MockClient((request) async {
                if (request.url.path.contains('/learning-path/')) {
                  // Capture the subjectId segment
                  final segments = request.url.pathSegments;
                  // path: api/v1/learning-path/{subjectId}
                  capturedPathId = segments.last;
                  return http.Response(
                    '[]',
                    200,
                    headers: {'content-type': 'application/json'},
                  );
                }
                return http.Response('', 200);
              }),
            ),
          ),
          audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
        ],
      );
      testContainer.read(sessionProvider.notifier).state = const SessionState(
        phase: SessionPhase.authenticated,
      );
      final widget = UncontrolledProviderScope(
        container: testContainer,
        child: MaterialApp.router(
          routerConfig: testContainer.read(routerProvider),
          builder: (context, child) => MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: child!,
          ),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final router = testContainer.read(routerProvider);
      // Navigate with mismatched name (name=FakeName but ID is real ID)
      router.go('/path/33333333-3333-3333-3333-333333333333?name=FakeName');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // Wait for PathMapScreen to trigger load
      await tester.pump(const Duration(milliseconds: 200));
      expect(capturedPathId, '33333333-3333-3333-3333-333333333333');
      expect(
        router.routerDelegate.currentConfiguration.uri.queryParameters['name'],
        'FakeName',
      );
      testContainer.dispose();
    });

    testWidgets('browser refresh/deep-link where supported keeps path', (
      tester,
    ) async {
      // Simulate deep start at /path/:id?name= on authenticated launch
      final prefs = await SharedPreferences.getInstance();
      final deepContainer = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage()..stored = 'tok',
          ),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              client: MockClient(
                (_) async => http.Response(
                  '[]',
                  200,
                  headers: {'content-type': 'application/json'},
                ),
              ),
            ),
          ),
          audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
        ],
      );
      deepContainer.read(sessionProvider.notifier).state = const SessionState(
        phase: SessionPhase.authenticated,
      );
      // Create router already at deep link by navigating before pump
      final router = deepContainer.read(routerProvider);
      // Directly go to deep link before first build mimics browser refresh
      router.go('/path/44444444-4444-4444-4444-444444444444?name=DBMS');
      final widget = UncontrolledProviderScope(
        container: deepContainer,
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: child!,
          ),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/path/44444444-4444-4444-4444-444444444444',
      );
      expect(find.text('DBMS'), findsOneWidget);
      deepContainer.dispose();
    });

    testWidgets('unauthenticated guard redirects deep link to login', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      final unauthContainer = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              client: MockClient((_) async => http.Response('', 401)),
            ),
          ),
          audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
        ],
      );
      unauthContainer.read(sessionProvider.notifier).state = const SessionState(
        phase: SessionPhase.unauthenticated,
      );
      final router = unauthContainer.read(routerProvider);
      final widget = UncontrolledProviderScope(
        container: unauthContainer,
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: child!,
          ),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      router.go('/path/55555555-5555-5555-5555-555555555555?name=OS');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      // Should redirect to /login, not stay on path
      expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
      unauthContainer.dispose();
    });

    test('no per-subject route branching exists (subject-agnostic)', () {
      // Verify Routes helper does not switch on name
      const id1 = '11111111-1111-1111-1111-111111111101';
      const id2 = '22222222-2222-2222-2222-222222222222';
      expect(Routes.path(id1), '/path/$id1');
      expect(Routes.path(id2), '/path/$id2');
      expect(Routes.path(id1) == Routes.path(id2), isFalse);
      // No if(name) logic in Routes.path — it is generic
    });
  });
}
