import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/auth/presentation/onboarding_screen.dart';

import '../helpers/fake_backend.dart';

/// Onboarding must not clip at 320px (found via browser QA: the panel
/// title/body extended past the right edge on small phones).
void main() {
  group('Onboarding compact (320px regression)', () {
    for (final size in const [Size(320, 844), Size(390, 844)]) {
      testWidgets('renders without overflow at ${size.width.toInt()}px',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
            ],
            child: MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: const OnboardingScreen(),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          tester.takeException(),
          isNull,
          reason: 'Onboarding overflowed at $size',
        );
        expect(find.text('Welcome to GameLearnAI'), findsOneWidget);

        // Panel title and body must end inside the viewport.
        for (final finder in [
          find.text('Welcome to GameLearnAI'),
          find.textContaining('Your personal game-powered learning adventure'),
        ]) {
          final rect = tester.getRect(finder);
          expect(
            rect.right,
            lessThanOrEqualTo(size.width),
            reason: 'Clipped panel text at $size',
          );
        }
      });
    }
  });
}
