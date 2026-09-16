import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/profile/presentation/settings_screen.dart';
import 'package:gamelearn_app/features/subjects/presentation/subjects_screen.dart';

import '../helpers/fake_backend.dart';

const _subjectsJson =
    '[{"id":"11111111-1111-1111-1111-111111111101","name":"Programming","description":"Learn programming fundamentals","iconKey":"subject_programming","isActive":true,"displayOrder":1},{"id":"11111111-1111-1111-1111-111111111102","name":"Computer Networks","description":"Packets, routing and the web.","iconKey":"subject_networks","isActive":true,"displayOrder":2},{"id":"11111111-1111-1111-1111-111111111103","name":"DBMS","description":null,"iconKey":"subject_dbms","isActive":true,"displayOrder":3}]';

MockClient _subjectsClient() => MockClient((request) async {
  if (request.url.path.endsWith('/subjects')) {
    return http.Response(
      _subjectsJson,
      200,
      headers: {'content-type': 'application/json'},
    );
  }
  return http.Response('', 404);
});

Widget _wrap(
  Widget child, {
  MockClient? client,
  EdgeInsets viewPadding = EdgeInsets.zero,
}) {
  final overrides = [
    tokenStorageProvider.overrideWithValue(FakeTokenStorage()..stored = 'tok'),
    audioManagerProvider.overrideWithValue(SilentAudioManager()),
    if (client != null)
      apiClientProvider.overrideWith((ref) => ApiClient(client: client)),
  ];
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: child,
      builder: (context, c) => MediaQuery(
        data: MediaQueryData(
          disableAnimations: true,
          padding: viewPadding,
        ),
        child: c!,
      ),
    ),
  );
}

Future<void> _pumpAtSize(
  WidgetTester tester,
  Widget child,
  Size size,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(child);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(
    tester.takeException(),
    isNull,
    reason: 'F9 QA surface must not overflow at $size',
  );
}

/// F9 whole-app visual QA: single-title heroes and system-inset safety.
///
/// No behavior changes are asserted — only that cinematic heroes own
/// their titles (no AppBar duplicates) and that AppBar-less tabs clear
/// the status bar/notch via SafeArea.
void main() {
  group('F9 single-title heroes', () {
    testWidgets('subjects hero owns its title exactly once', (tester) async {
      await _pumpAtSize(
        tester,
        _wrap(const SubjectsScreen(), client: _subjectsClient()),
        const Size(390, 844),
      );
      expect(find.text('CHOOSE YOUR WORLD'), findsOneWidget);
    });

    testWidgets('subjects clears a 47px status bar without overflow', (
      tester,
    ) async {
      await _pumpAtSize(
        tester,
        _wrap(
          const SubjectsScreen(),
          client: _subjectsClient(),
          viewPadding: const EdgeInsets.only(top: 47),
        ),
        const Size(390, 844),
      );
      expect(find.text('CHOOSE YOUR WORLD'), findsOneWidget);
    });

    testWidgets('subjects no overflow at 320 and 1280', (tester) async {
      await _pumpAtSize(
        tester,
        _wrap(const SubjectsScreen(), client: _subjectsClient()),
        const Size(320, 844),
      );
      await _pumpAtSize(
        tester,
        _wrap(const SubjectsScreen(), client: _subjectsClient()),
        const Size(1280, 800),
      );
    });

    testWidgets('settings title appears exactly once', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pumpAtSize(
        tester,
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              await SharedPreferences.getInstance(),
            ),
            audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
          ],
          child: MaterialApp(
            home: const SettingsScreen(),
            builder: (context, c) => MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: c!,
            ),
          ),
        ),
        const Size(390, 844),
      );
      // AppBar is title-less; the cinematic hero badge owns the title.
      expect(find.text('SETTINGS'), findsOneWidget);
    });
  });
}
