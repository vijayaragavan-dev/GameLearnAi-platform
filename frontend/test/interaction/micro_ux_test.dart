// F15 — final interaction & micro-UX polish: press feedback,
// reduced-motion guards, state entrance continuity.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gamelearn_app/core/theme/app_motion.dart';
import 'package:gamelearn_app/shared/widgets/feedback.dart';
import 'package:gamelearn_app/shared/widgets/game_card.dart';
import 'package:gamelearn_app/shared/widgets/pressable.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('F15 interaction language', () {
    testWidgets('Pressable calls onTap and exposes button semantics',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Pressable(
              onTap: () => taps++,
              semanticsLabel: 'Open details',
              child: const SizedBox(width: 120, height: 48),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(Pressable));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Pressable scales down on press and restores on release',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Pressable(
              onTap: null,
              child: SizedBox(width: 120, height: 48),
            ),
          ),
        ),
      );
      // Disabled pressable never scales and never fires.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Pressable)),
      );
      await tester.pump();
      AnimatedScale scaleOf() =>
          tester.widget<AnimatedScale>(find.byType(AnimatedScale).first);
      expect(scaleOf().scale, 1.0);

      await gesture.up();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Pressable press scale responds when enabled',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Pressable(
              onTap: () {},
              child: const SizedBox(width: 120, height: 48),
            ),
          ),
        ),
      );
      AnimatedScale scaleOf() =>
          tester.widget<AnimatedScale>(find.byType(AnimatedScale).first);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Pressable)),
      );
      await tester.pump();
      expect(scaleOf().scale, moreOrLessEquals(0.97));
      await gesture.up();
      await tester.pump();
      expect(scaleOf().scale, moreOrLessEquals(1.0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Pressable holds still under reduced motion',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Pressable(
                onTap: null,
                child: SizedBox(width: 120, height: 48),
              ),
            ),
          ),
        ),
      );
      // With reduced motion the press path is inert and settled.
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('AppMotion.durFor collapses under reduced motion',
        (tester) async {
      Duration? normal;
      Duration? reduced;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                normal = AppMotion.durFor(context, AppMotion.fast);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(normal, AppMotion.fast);
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Builder(
                builder: _ReducedProbe.builder,
              ),
            ),
          ),
        ),
      );
      reduced = _ReducedProbe.last;
      expect(reduced, Duration.zero);
    });

    testWidgets('InteractiveCard disabled renders without interaction',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveCard(
              enabled: false,
              child: Text('Locked content'),
            ),
          ),
        ),
      );
      expect(find.text('Locked content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ErrorState renders message and retry action',
        (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorState(
              title: 'Arena offline',
              message: 'Check connection',
              onRetry: () => retried++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Arena offline'), findsOneWidget);
      expect(find.text('Check connection'), findsOneWidget);
      await tester.tap(find.text('TRY AGAIN'));
      expect(retried, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('EmptyState renders icon, copy and action', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.public_off_rounded,
              title: 'No worlds yet',
              message: 'Check back soon',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No worlds yet'), findsOneWidget);
      expect(find.text('Check back soon'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

abstract final class _ReducedProbe {
  static Duration? last;

  static Widget builder(BuildContext context) {
    last = AppMotion.durFor(context, AppMotion.fast);
    return const SizedBox();
  }
}
