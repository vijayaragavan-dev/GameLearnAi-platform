import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gamelearn_app/app/router.dart';
import 'package:gamelearn_app/core/models/auth_models.dart';
import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/auth/providers/session_controller.dart';
import 'package:gamelearn_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:gamelearn_app/features/learning/path/providers/path_provider.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AUTH regression — Phase 3B stabilization', () {
    testWidgets('unauthenticated Create Player navigates to Register', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'onboarding_seen': true});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              client: MockClient((_) async => http.Response('', 200)),
            ),
          ),
          audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
        ],
      );
      addTearDown(container.dispose);
      container.read(sessionProvider.notifier).state = const SessionState(
        phase: SessionPhase.unauthenticated,
      );
      final widget = _appWithContainer(container);
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 300));
      final router = container.read(routerProvider);
      // Should already be at login via splash restore (onboarding_seen true)
      expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
      // Find "Create your player" tap target (RichText inside TextButton)
      // Use textContaining with findRichText:true because it's a RichText TextSpan
      expect(
        find.textContaining('Create your player', findRichText: true),
        findsOneWidget,
      );
      await tester.tap(
        find.textContaining('Create your player', findRichText: true),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(router.routerDelegate.currentConfiguration.uri.path, '/register');
      expect(tester.takeException(), isNull);
    });

    testWidgets('authenticated register is redirected to home', (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_seen': true});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage()..stored = 'tok',
          ),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              client: MockClient((_) async => http.Response('', 200)),
            ),
          ),
          audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
        ],
      );
      addTearDown(container.dispose);
      container.read(sessionProvider.notifier).state = const SessionState(
        phase: SessionPhase.authenticated,
        user: null,
      );
      // Authenticated should not be able to visit register
      final router = container.read(routerProvider);
      final widget = _appWithContainer(container);
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      // Already at /home via redirect from splash + authenticated
      router.go(Routes.register);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
    });

    testWidgets(
      'Create Player after logout opens Register not previous dashboard',
      (tester) async {
        SharedPreferences.setMockInitialValues({'onboarding_seen': true});
        final prefs = await SharedPreferences.getInstance();
        final storage = FakeTokenStorage()..stored = 'tok';
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tokenStorageProvider.overrideWithValue(storage),
            apiClientProvider.overrideWith(
              (ref) => ApiClient(
                client: MockClient((request) async {
                  if (request.url.path.endsWith('/auth/logout')) {
                    return http.Response('', 204);
                  }
                  return http.Response('', 200);
                }),
              ),
            ),
            audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
          ],
        );
        addTearDown(container.dispose);
        // Authenticated initially
        container.read(sessionProvider.notifier).state = const SessionState(
          phase: SessionPhase.authenticated,
          user: null,
        );
        container.read(sessionTokenProvider.notifier).set('tok');
        final router = container.read(routerProvider);
        final widget = _appWithContainer(container);
        await tester.pumpWidget(widget);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));
        expect(router.routerDelegate.currentConfiguration.uri.path, '/home');

        // Logout via controller (mirrors SettingsScreen)
        await container.read(sessionProvider.notifier).logout();
        // After logout explicit go to login (as SettingsScreen does)
        router.go(Routes.login);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          container.read(sessionProvider).phase,
          SessionPhase.unauthenticated,
        );
        expect(container.read(sessionTokenProvider), isNull);
        expect(storage.stored, isNull);
        expect(router.routerDelegate.currentConfiguration.uri.path, '/login');

        // Now Create your player must go to register, not home
        expect(
          find.textContaining('Create your player', findRichText: true),
          findsOneWidget,
        );
        await tester.tap(
          find.textContaining('Create your player', findRichText: true),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          '/register',
        );
      },
    );

    test(
      'successful registration creates correct authenticated state',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = FakeTokenStorage();
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tokenStorageProvider.overrideWithValue(storage),
            apiClientProvider.overrideWith(
              (ref) => ApiClient(
                client: MockClient((request) async {
                  if (request.url.path.endsWith('/auth/register')) {
                    return http.Response(
                      jsonEncode(
                        Fixtures.authSession(
                          email: 'new@example.com',
                          displayName: 'New Player',
                        ),
                      ),
                      201,
                      headers: {'content-type': 'application/json'},
                    );
                  }
                  return http.Response('', 404);
                }),
              ),
            ),
            audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
          ],
        );
        addTearDown(container.dispose);
        // Start unauthenticated
        container.read(sessionProvider.notifier).state = const SessionState(
          phase: SessionPhase.unauthenticated,
        );
        final notifier = container.read(sessionProvider.notifier);
        final ok = await notifier.register(
          'new@example.com',
          'password123',
          'New Player',
        );
        expect(ok, isTrue);
        final state = container.read(sessionProvider);
        expect(state.phase, SessionPhase.authenticated);
        expect(state.user!.email, 'new@example.com');
        expect(state.user!.displayName, 'New Player');
        expect(storage.stored, 'test-token-abc');
        expect(container.read(sessionTokenProvider), 'test-token-abc');
        expect(state.busy, isFalse);
        expect(state.error, isNull);
      },
    );

    test(
      'duplicate registration shows error and stays unauthenticated',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = FakeTokenStorage();
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tokenStorageProvider.overrideWithValue(storage),
            apiClientProvider.overrideWith(
              (ref) => ApiClient(
                client: MockClient((request) async {
                  if (request.url.path.endsWith('/auth/register')) {
                    return http.Response(
                      jsonEncode({
                        'errorCode': 'DATA_CONFLICT',
                        'message': 'An account with this email already exists',
                      }),
                      409,
                      headers: {'content-type': 'application/json'},
                    );
                  }
                  return http.Response('', 404);
                }),
              ),
            ),
            audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
          ],
        );
        addTearDown(container.dispose);
        container.read(sessionProvider.notifier).state = const SessionState(
          phase: SessionPhase.unauthenticated,
        );
        final notifier = container.read(sessionProvider.notifier);
        final ok = await notifier.register(
          'dup@example.com',
          'password123',
          'Dup',
        );
        expect(ok, isFalse);
        final state = container.read(sessionProvider);
        expect(state.phase, SessionPhase.unauthenticated);
        expect(state.error, isNotNull);
        expect(state.error!.message, contains('already exists'));
        expect(storage.stored, isNull);
        expect(state.busy, isFalse);
      },
    );

    test(
      'failed registration while authenticated does not corrupt session',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = FakeTokenStorage()..stored = 'tok-A';
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            tokenStorageProvider.overrideWithValue(storage),
            apiClientProvider.overrideWith(
              (ref) => ApiClient(
                client: MockClient((request) async {
                  if (request.url.path.endsWith('/auth/register')) {
                    return http.Response(
                      jsonEncode({
                        'errorCode': 'DATA_CONFLICT',
                        'message': 'An account with this email already exists',
                      }),
                      409,
                      headers: {'content-type': 'application/json'},
                    );
                  }
                  return http.Response('', 404);
                }),
              ),
            ),
            audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
          ],
        );
        addTearDown(container.dispose);
        // Authenticated as User A
        const userA = SessionUser(
          id: '11111111-1111-1111-1111-111111111111',
          email: 'a@example.com',
          displayName: 'User A',
        );
        container.read(sessionProvider.notifier).state = const SessionState(
          phase: SessionPhase.authenticated,
          user: userA,
        );
        container.read(sessionTokenProvider.notifier).set('tok-A');

        final notifier = container.read(sessionProvider.notifier);
        final ok = await notifier.register(
          'a@example.com',
          'password123',
          'User A',
        );
        expect(ok, isFalse);
        final state = container.read(sessionProvider);
        // Must remain authenticated as User A, not wiped
        expect(state.phase, SessionPhase.authenticated);
        expect(state.user!.email, 'a@example.com');
        expect(container.read(sessionTokenProvider), 'tok-A');
        expect(storage.stored, 'tok-A');
        expect(state.error, isNotNull);
      },
    );

    test('logout clears learner-specific state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = FakeTokenStorage()..stored = 'tok';
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(storage),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              client: MockClient((request) async {
                if (request.url.path.endsWith('/dashboard')) {
                  return http.Response(
                    jsonEncode(Fixtures.dashboardZeroState()),
                    200,
                    headers: {'content-type': 'application/json'},
                  );
                }
                if (request.url.path.contains('/learning-path/')) {
                  return http.Response(
                    jsonEncode([Fixtures.learningPath()]),
                    200,
                    headers: {'content-type': 'application/json'},
                  );
                }
                if (request.url.path.endsWith('/auth/logout')) {
                  return http.Response('', 204);
                }
                if (request.url.path.endsWith('/auth/validate')) {
                  return http.Response(
                    jsonEncode(Fixtures.authSession()),
                    200,
                    headers: {'content-type': 'application/json'},
                  );
                }
                return http.Response('', 404);
              }),
            ),
          ),
          audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
        ],
      );
      addTearDown(container.dispose);
      container.read(sessionTokenProvider.notifier).set('tok');
      await container.read(sessionProvider.notifier).restore();
      expect(container.read(sessionProvider).phase, SessionPhase.authenticated);
      // Prime learner state
      await container.read(dashboardProvider.notifier).load();
      expect(container.read(dashboardProvider).data, isNotNull);
      const subjectId = '11111111-1111-1111-1111-111111111101';
      await container.read(pathProvider(subjectId).notifier).load();
      expect(container.read(pathProvider(subjectId)).paths, isNotEmpty);

      await container.read(sessionProvider.notifier).logout();
      expect(
        container.read(sessionProvider).phase,
        SessionPhase.unauthenticated,
      );
      expect(storage.stored, isNull);
      expect(container.read(sessionTokenProvider), isNull);
      // Providers should be invalidated (fresh state)
      // After invalidate, reading them yields fresh empty state
      expect(container.read(dashboardProvider).data, isNull);
      expect(container.read(pathProvider(subjectId)).paths, isEmpty);
    });

    test('user switching does not leak state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = FakeTokenStorage();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(storage),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              client: MockClient((request) async {
                if (request.url.path.endsWith('/auth/login')) {
                  final body = jsonDecode(request.body);
                  final email = body['email'] as String;
                  if (email == 'a@example.com') {
                    return http.Response(
                      jsonEncode(
                        Fixtures.authSession(
                          email: 'a@example.com',
                          displayName: 'User A',
                        ),
                      ),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  } else {
                    return http.Response(
                      jsonEncode(
                        Fixtures.authSession(
                          email: 'b@example.com',
                          displayName: 'User B',
                        ),
                      ),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  }
                }
                if (request.url.path.endsWith('/dashboard')) {
                  // Differentiate via session user email
                  final sessionUser = ref.read(sessionProvider).user;
                  if (sessionUser?.email == 'a@example.com') {
                    return http.Response(
                      jsonEncode({
                        ...Fixtures.dashboardZeroState(),
                        'learner': {
                          'displayName': 'User A',
                          'overallMastery': 77,
                          'currentSubjectId': null,
                          'currentTopicId': null,
                        },
                      }),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  } else if (sessionUser?.email == 'b@example.com') {
                    return http.Response(
                      jsonEncode({
                        ...Fixtures.dashboardZeroState(),
                        'learner': {
                          'displayName': 'User B',
                          'overallMastery': 33,
                          'currentSubjectId': null,
                          'currentTopicId': null,
                        },
                      }),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  }
                  return http.Response(
                    jsonEncode(Fixtures.dashboardZeroState()),
                    200,
                    headers: {'content-type': 'application/json'},
                  );
                }
                if (request.url.path.endsWith('/auth/logout')) {
                  return http.Response('', 204);
                }
                return http.Response('', 404);
              }),
            ),
          ),
          audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
        ],
      );
      addTearDown(container.dispose);
      container.read(sessionProvider.notifier).state = const SessionState(
        phase: SessionPhase.unauthenticated,
      );

      // User A login
      var ok = await container
          .read(sessionProvider.notifier)
          .login('a@example.com', 'pass12345');
      expect(ok, isTrue);
      expect(container.read(sessionProvider).user!.email, 'a@example.com');
      await container.read(dashboardProvider.notifier).load();
      final dashA = container.read(dashboardProvider).data!;
      expect(dashA.learner.displayName, 'User A');
      expect(dashA.learner.overallMastery, 77);

      // Logout
      await container.read(sessionProvider.notifier).logout();
      expect(
        container.read(sessionProvider).phase,
        SessionPhase.unauthenticated,
      );
      expect(container.read(dashboardProvider).data, isNull);

      // User B login
      ok = await container
          .read(sessionProvider.notifier)
          .login('b@example.com', 'pass12345');
      expect(ok, isTrue);
      expect(container.read(sessionProvider).user!.email, 'b@example.com');
      await container.read(dashboardProvider.notifier).load();
      final dashB = container.read(dashboardProvider).data!;
      expect(dashB.learner.displayName, 'User B');
      expect(dashB.learner.overallMastery, 33);
      // Ensure B's dashboard is not A's
      expect(dashB.learner.displayName, isNot('User A'));
      expect(dashB.learner.overallMastery, isNot(77));
    });

    test('restore with validate null token preserves user and token', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = FakeTokenStorage()..stored = 'persisted-token';
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(storage),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              client: MockClient((request) async {
                if (request.url.path.endsWith('/auth/validate')) {
                  // Real backend shape: token null, but user present
                  return http.Response(
                    jsonEncode({
                      'token': null,
                      'tokenType': null,
                      'expiresInSeconds': 0,
                      'user': {
                        'id': 'c3193b6c-064f-455e-b183-ef7ffb570cfc',
                        'email': 'real@example.com',
                        'displayName': 'Real User',
                      },
                    }),
                    200,
                    headers: {'content-type': 'application/json'},
                  );
                }
                return http.Response('', 404);
              }),
            ),
          ),
          audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
        ],
      );
      addTearDown(container.dispose);
      // Phase restoring is initial
      final notifier = container.read(sessionProvider.notifier);
      await notifier.restore();
      final state = container.read(sessionProvider);
      expect(state.phase, SessionPhase.authenticated);
      expect(state.user!.email, 'real@example.com');
      // Token must remain the stored one, not nulled
      expect(container.read(sessionTokenProvider), 'persisted-token');
      expect(storage.stored, 'persisted-token');
      expect(state.offline, isFalse);
    });

    test('invalid login remains on login with error', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = FakeTokenStorage();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(storage),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              client: MockClient((request) async {
                if (request.url.path.endsWith('/auth/login')) {
                  return http.Response(
                    jsonEncode({
                      'errorCode': 'UNAUTHORIZED',
                      'message': 'Invalid email or password',
                    }),
                    401,
                    headers: {'content-type': 'application/json'},
                  );
                }
                return http.Response('', 404);
              }),
            ),
          ),
          audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
        ],
      );
      addTearDown(container.dispose);
      container.read(sessionProvider.notifier).state = const SessionState(
        phase: SessionPhase.unauthenticated,
      );
      final ok = await container
          .read(sessionProvider.notifier)
          .login('unknown@example.com', 'wrong');
      expect(ok, isFalse);
      final state = container.read(sessionProvider);
      expect(state.phase, SessionPhase.unauthenticated);
      expect(state.error, isNotNull);
      expect(container.read(sessionTokenProvider), isNull);
    });
  });
}
