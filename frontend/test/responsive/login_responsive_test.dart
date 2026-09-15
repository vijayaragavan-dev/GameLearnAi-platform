import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gamelearn_app/core/theme/app_theme.dart';
import 'package:gamelearn_app/features/auth/presentation/login_screen.dart';

import '../helpers/fake_backend.dart';

/// F2 responsive regression: the login screen must render without any
/// overflow/clipping from small phones (320px) through desktop (1440px).
/// A previous production audit observed the "GAMELEARN AI" header and the
/// login headline clipped at ~390px viewport width.
Future<void> _pumpLoginAtSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    fakeScope(
      child: MaterialApp(
        home: const LoginScreen(),
        builder: (context, child) => MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: child!,
        ),
      ),
      handler: (_) => {'status': 404, 'body': {'errorCode': 'NOT_FOUND'}},
    ),
  );
  await tester.pumpAndSettle();
  // Surfaces RenderFlex overflow and other layout asserts.
  expect(
    tester.takeException(),
    isNull,
    reason: 'Login must not overflow at $size',
  );
}

void main() {
  group('Login responsive (F2 regression)', () {
    testWidgets('renders without overflow in dark theme at 390px',
        (tester) async {
      const size = Size(390, 844);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        fakeScope(
          child: MaterialApp(
            theme: buildGameLearnDarkTheme(),
            home: const LoginScreen(),
            builder: (context, child) => MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: child!,
            ),
          ),
          handler: (_) => {'status': 404, 'body': {'errorCode': 'NOT_FOUND'}},
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Login must not overflow in dark theme at $size',
      );
      expect(find.text('GAMELEARN AI'), findsOneWidget);
      expect(find.text('Welcome back, Player'), findsOneWidget);
    });

    for (final size in <Size>[
      const Size(320, 568),
      const Size(360, 740),
      const Size(390, 844),
      const Size(412, 915),
      const Size(768, 1024),
      const Size(1024, 768),
      const Size(1280, 800),
      const Size(1440, 900),
    ]) {
      testWidgets('renders without overflow at ${size.width.toInt()}px',
          (tester) async {
        await _pumpLoginAtSize(tester, size);

        expect(find.text('GAMELEARN AI'), findsOneWidget);
        expect(find.text('Welcome back, Player'), findsOneWidget);
        expect(find.text('Your adventure is waiting.'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        // PrimaryGameButton uppercases its label. The CTA row may sit
        // below the fold inside the vertical scroll view on short screens,
        // so match offstage too: vertical scroll is the intended pattern.
        expect(
          find.text('SIGN IN', skipOffstage: false),
          findsOneWidget,
        );
        // Register CTA is a RichText span tree (find.textContaining does
        // not match RichText); match its flattened text instead.
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is RichText &&
                w.text.toPlainText().contains('Create your player'),
            skipOffstage: false,
          ),
          findsOneWidget,
        );

        // The header row (logo + wordmark) must fit inside the viewport:
        // its right edge may never extend past the screen width.
        final rowRect = tester.getRect(find.text('GAMELEARN AI'));
        expect(
          rowRect.right,
          lessThanOrEqualTo(size.width),
          reason: 'Wordmark clipped at $size',
        );
        final headlineRect = tester.getRect(find.text('Welcome back, Player'));
        expect(
          headlineRect.right,
          lessThanOrEqualTo(size.width),
          reason: 'Headline clipped at $size',
        );
      });
    }
  });
}
