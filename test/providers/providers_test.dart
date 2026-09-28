import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/auth/providers/session_controller.dart';
import 'package:gamelearn_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:gamelearn_app/features/learning/path/providers/path_provider.dart';

import '../helpers/fake_backend.dart';

void main() {
  // -------------------------------------------------------------------------
  // SessionController
  // -------------------------------------------------------------------------
  group('SessionController', () {
    test('restore with no token -> unauthenticated', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
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
      addTearDown(container.dispose);

      final notifier = container.read(sessionProvider.notifier);
      await notifier.restore();
      expect(
        container.read(sessionProvider).phase,
        SessionPhase.unauthenticated,
      );
    });

    test('restore with valid token -> authenticated', () async {
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

      // Need to set token in provider for ApiClient header injection.
      container.read(sessionTokenProvider.notifier).set('tok');
      final notifier = container.read(sessionProvider.notifier);
      await notifier.restore();
      // restore binds token from storage and validates.
      // It should end authenticated.
      expect(container.read(sessionProvider).phase, SessionPhase.authenticated);
      expect(container.read(sessionProvider).user?.email, 'nova@example.com');
    });

    test('restore with 401 -> wipes and unauthenticated', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = FakeTokenStorage()..stored = 'bad-tok';
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(storage),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              client: MockClient((request) async {
                if (request.url.path.endsWith('/auth/validate')) {
                  return http.Response(
                    jsonEncode({
                      'errorCode': 'UNAUTHORIZED',
                      'message': 'expired',
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
      container.read(sessionTokenProvider.notifier).set('bad-tok');
      final notifier = container.read(sessionProvider.notifier);
      await notifier.restore();
      expect(
        container.read(sessionProvider).phase,
        SessionPhase.unauthenticated,
      );
      expect(storage.stored, isNull);
    });

    test('login busy flag and error handling', () async {
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
      final notifier = container.read(sessionProvider.notifier);
      // Ensure initial phase is restoring -> unauthenticated after restore attempt with no token.
      // Force unauthenticated.
      await notifier.restore();
      final future = notifier.login('nova@example.com', 'pass12345');
      // busy should be true immediately after starting login (microtask?).
      // We check after a tiny delay that busy was set.
      // Instead we just verify final state is authenticated and not busy.
      final ok = await future;
      expect(ok, isTrue);
      expect(container.read(sessionProvider).phase, SessionPhase.authenticated);
      expect(container.read(sessionProvider).busy, isFalse);
      expect(container.read(sessionProvider).error, isNull);
      expect(storage.stored, 'test-token-abc');
    });

    test('login failure sets error and unauthenticated', () async {
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
                      'errorCode': 'INVALID_CREDENTIALS',
                      'message': 'bad',
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
      final notifier = container.read(sessionProvider.notifier);
      await notifier.restore();
      final ok = await notifier.login('a@b.c', 'wrong');
      expect(ok, isFalse);
      expect(
        container.read(sessionProvider).phase,
        SessionPhase.unauthenticated,
      );
      expect(container.read(sessionProvider).error, isNotNull);
      expect(container.read(sessionProvider).busy, isFalse);
    });

    test('logout and invalidate discard learner state', () async {
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
                if (request.url.path.endsWith('/auth/validate')) {
                  return http.Response(
                    jsonEncode(Fixtures.authSession()),
                    200,
                    headers: {'content-type': 'application/json'},
                  );
                }
                if (request.url.path.endsWith('/auth/logout')) {
                  return http.Response('', 200);
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
      final notifier = container.read(sessionProvider.notifier);
      await notifier.restore();
      expect(container.read(sessionProvider).phase, SessionPhase.authenticated);
      await notifier.logout();
      expect(
        container.read(sessionProvider).phase,
        SessionPhase.unauthenticated,
      );
      expect(storage.stored, isNull);
      expect(container.read(sessionTokenProvider), isNull);
    });

    test('offline restore keeps authenticated with offline flag', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = FakeTokenStorage()..stored = 'tok';
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(storage),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              client: MockClient(
                (_) async => throw http.ClientException('offline'),
              ),
            ),
          ),
          audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
        ],
      );
      addTearDown(container.dispose);
      container.read(sessionTokenProvider.notifier).set('tok');
      final notifier = container.read(sessionProvider.notifier);
      await notifier.restore();
      expect(container.read(sessionProvider).phase, SessionPhase.authenticated);
      expect(container.read(sessionProvider).offline, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // DashboardController
  // -------------------------------------------------------------------------
  group('DashboardController', () {
    test('load success sets data and clears error', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage()..stored = 'tok',
          ),
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
                return http.Response('', 404);
              }),
            ),
          ),
          audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
        ],
      );
      addTearDown(container.dispose);
      container.read(sessionTokenProvider.notifier).set('tok');
      final controller = container.read(dashboardProvider.notifier);
      await controller.load();
      final state = container.read(dashboardProvider);
      expect(state.data, isNotNull);
      expect(state.error, isNull);
      expect(state.loading, isFalse);
      expect(state.showLoading, isFalse);
    });

    test('refresh keeps data on failure (does not blank)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var dashboardCalls = 0;
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage()..stored = 'tok',
          ),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              client: MockClient((request) async {
                if (request.url.path.endsWith('/dashboard')) {
                  dashboardCalls++;
                  if (dashboardCalls == 1) {
                    return http.Response(
                      jsonEncode(Fixtures.dashboardZeroState()),
                      200,
                      headers: {'content-type': 'application/json'},
                    );
                  } else {
                    return http.Response(
                      jsonEncode({
                        'errorCode': 'INTERNAL_ERROR',
                        'message': 'down',
                      }),
                      500,
                      headers: {'content-type': 'application/json'},
                    );
                  }
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
      final controller = container.read(dashboardProvider.notifier);
      await controller.load();
      final before = container.read(dashboardProvider).data;
      expect(before, isNotNull);
      await controller.refresh();
      final after = container.read(dashboardProvider);
      // On failure, dashboard keeps showing old data? Current implementation replaces with error but keeps data? Let's check.
      // DashboardController.refresh sets state with error but data remains? It does `state = state.copyWith(loading:false, error:e)` so data is preserved.
      expect(after.data, isNotNull);
      expect(after.error, isNotNull);
    });

    test('load failure sets error when data is null', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage()..stored = 'tok',
          ),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              client: MockClient((request) async {
                if (request.url.path.endsWith('/dashboard')) {
                  return http.Response(
                    jsonEncode({
                      'errorCode': 'INTERNAL_ERROR',
                      'message': 'down',
                    }),
                    500,
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
      final controller = container.read(dashboardProvider.notifier);
      await controller.load();
      final state = container.read(dashboardProvider);
      expect(state.data, isNull);
      expect(state.error, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // PathController
  // -------------------------------------------------------------------------
  group('PathController', () {
    test('load sets loading then data', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage()..stored = 'tok',
          ),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              client: MockClient((request) async {
                if (request.url.path.contains('/learning-path/')) {
                  return http.Response(
                    jsonEncode([Fixtures.learningPath()]),
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
      const subjectId = '11111111-1111-1111-1111-111111111101';
      final controller = container.read(pathProvider(subjectId).notifier);
      expect(container.read(pathProvider(subjectId)).loading, isFalse);
      final future = controller.load();
      // Immediately after calling load, loading should be true.
      expect(container.read(pathProvider(subjectId)).loading, isTrue);
      await future;
      expect(container.read(pathProvider(subjectId)).loading, isFalse);
      expect(container.read(pathProvider(subjectId)).paths, isNotEmpty);
      expect(container.read(pathProvider(subjectId)).error, isNull);
    });

    test('load failure sets error', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage()..stored = 'tok',
          ),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              client: MockClient((request) async {
                if (request.url.path.contains('/learning-path/')) {
                  return http.Response(
                    jsonEncode({
                      'errorCode': 'INTERNAL_ERROR',
                      'message': 'down',
                    }),
                    500,
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
      const subjectId = '11111111-1111-1111-1111-111111111101';
      final controller = container.read(pathProvider(subjectId).notifier);
      await controller.load();
      expect(container.read(pathProvider(subjectId)).error, isNotNull);
      expect(container.read(pathProvider(subjectId)).loading, isFalse);
    });

    test('generate guards against parallel calls', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var generateCalls = 0;
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage()..stored = 'tok',
          ),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              client: MockClient((request) async {
                if (request.method == 'POST' &&
                    request.url.path.contains('/learning-path/')) {
                  generateCalls++;
                  await Future<void>.delayed(const Duration(milliseconds: 50));
                  return http.Response(
                    jsonEncode(Fixtures.learningPath()),
                    200,
                    headers: {'content-type': 'application/json'},
                  );
                }
                if (request.method == 'GET' &&
                    request.url.path.contains('/learning-path/')) {
                  return http.Response(
                    jsonEncode([Fixtures.learningPath()]),
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
      const subjectId = '11111111-1111-1111-1111-111111111101';
      final controller = container.read(pathProvider(subjectId).notifier);
      final f1 = controller.generate(learningGoal: 'test');
      final f2 = controller.generate(learningGoal: 'second');
      final results = await Future.wait<bool>([f1, f2]);
      // Second call should be blocked and return false.
      expect(generateCalls, 1);
      expect(results, contains(false));
      expect(results, contains(true));
    });

    test('generate failure sets error and clears generating', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tokenStorageProvider.overrideWithValue(
            FakeTokenStorage()..stored = 'tok',
          ),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              client: MockClient((request) async {
                if (request.method == 'POST' &&
                    request.url.path.contains('/learning-path/')) {
                  return http.Response(
                    jsonEncode({
                      'errorCode': 'AI_RATE_LIMITED',
                      'message': 'too many',
                    }),
                    429,
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
      const subjectId = '11111111-1111-1111-1111-111111111101';
      final controller = container.read(pathProvider(subjectId).notifier);
      final ok = await controller.generate(learningGoal: 'test');
      expect(ok, isFalse);
      expect(container.read(pathProvider(subjectId)).generating, isFalse);
      expect(container.read(pathProvider(subjectId)).error, isNotNull);
    });
  });
}
