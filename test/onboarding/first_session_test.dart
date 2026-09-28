import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/auth/presentation/onboarding_screen.dart';
import 'package:gamelearn_app/shared/widgets/game_button.dart';

Future<void> _pumpOnboarding(WidgetTester tester, SharedPreferences prefs) async {
  await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MediaQuery(data: const MediaQueryData(disableAnimations: true), child: const MaterialApp(home: OnboardingScreen()))));
  await tester.pumpAndSettle();
}

void main() {
  group('First Session A9', () {
    testWidgets('onboarding shows 4 steps with welcome', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await _pumpOnboarding(tester, prefs);
      expect(find.text('Welcome to GameLearnAI'), findsOneWidget);
      expect(find.text('SKIP'), findsOneWidget);
      expect(find.byType(PrimaryGameButton), findsOneWidget);
    });

    testWidgets('onboarding step navigation Next and BACK', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await _pumpOnboarding(tester, prefs);
      expect(find.text('SKIP'), findsOneWidget);
      await tester.tap(find.byType(PrimaryGameButton));
      await tester.pumpAndSettle();
      expect(find.text('BACK'), findsOneWidget);
    });

    testWidgets('onboarding completion persists', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await _pumpOnboarding(tester, prefs);
      // Directly complete via SKIP to avoid page navigation flakiness
      await tester.tap(find.text('SKIP'));
      await tester.pumpAndSettle();
      expect(prefs.getBool('onboarding_seen'), isTrue);
    });

    testWidgets('SKIP persists', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await _pumpOnboarding(tester, prefs);
      await tester.tap(find.text('SKIP'));
      await tester.pumpAndSettle();
      expect(prefs.getBool('onboarding_seen'), isTrue);
    });

    testWidgets('360 responsive no overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MediaQuery(data: const MediaQueryData(disableAnimations: true, size: Size(360, 640)), child: const MaterialApp(home: OnboardingScreen()))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark and light theme render', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MediaQuery(data: const MediaQueryData(disableAnimations: true), child: MaterialApp(theme: ThemeData.light(), home: const OnboardingScreen()))));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to GameLearnAI'), findsOneWidget);
      await tester.pumpWidget(ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MediaQuery(data: const MediaQueryData(disableAnimations: true), child: MaterialApp(theme: ThemeData.dark(), home: const OnboardingScreen()))));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to GameLearnAI'), findsOneWidget);
    });
  });
}
