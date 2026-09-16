import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gamelearn_app/core/models/dashboard_models.dart';
import 'package:gamelearn_app/core/theme/app_colors.dart';
import 'package:gamelearn_app/core/theme/app_theme.dart';
import 'package:gamelearn_app/core/utils/formatters.dart';
import 'package:gamelearn_app/features/progress/presentation/progress_screen.dart';
import 'package:gamelearn_app/shared/widgets/cinematic_scenery.dart';
import 'package:gamelearn_app/shared/widgets/cinematic_surfaces.dart';
import 'package:gamelearn_app/shared/widgets/game_surfaces.dart';
import 'package:gamelearn_app/shared/widgets/nova_companion.dart';

Widget _wrap(Widget child, {bool dark = true}) => ProviderScope(
  child: MaterialApp(
    theme: buildGameLearnDarkTheme(),
    darkTheme: buildGameLearnDarkTheme(),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    home: Scaffold(body: SingleChildScrollView(child: child)),
    builder: (context, c) => MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: c!,
    ),
  ),
);

Future<void> _pumpAtSize(
  WidgetTester tester,
  Widget child,
  Size size, {
  bool dark = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(_wrap(child, dark: dark));
  await tester.pumpAndSettle();
  expect(
    tester.takeException(),
    isNull,
    reason: 'F8 refinement must not overflow at $size',
  );
}

RecentQuizRun _run(String topic, double score, DateTime at) => RecentQuizRun(
  quizAttemptId: 'q-$topic',
  topicId: 't-$topic',
  topicName: topic,
  score: score,
  correctCount: (score / 25).round(),
  totalQuestions: 4,
  submittedAt: at,
);

/// F8 regression: Nova character art, tutor header composition and stats
/// refinements. All values are real reads — no fabricated data.
void main() {
  group('NovaAvatar', () {
    testWidgets('renders Nova art with accessible identity', (tester) async {
      await tester.pumpWidget(_wrap(const NovaAvatar(size: 72)));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Nova, AI learning companion'),
        findsOneWidget,
      );
    });

    testWidgets('static at all sizes, dark and light', (tester) async {
      await _pumpAtSize(
        tester,
        const NovaAvatar(size: 92),
        const Size(320, 568),
      );
      await _pumpAtSize(
        tester,
        const NovaAvatar(size: 64, showHalo: false),
        const Size(390, 844),
        dark: false,
      );
    });

    testWidgets('hero with leading Nova avatar renders title', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const CinematicHero(
            badge: 'Nova · Calibration',
            title: Text('KNOWLEDGE SCAN'),
            leading: NovaAvatar(size: 88),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('KNOWLEDGE SCAN'), findsOneWidget);
      // The hero's Semantics container groups descendants, so Nova's
      // label merges with the title (announced together); the avatar
      // itself must be present in the leading slot.
      expect(find.byType(NovaAvatar), findsOneWidget);
    });
  });

  group('Tutor cinematic header composition', () {
    testWidgets('scene header with Nova + identity has no overflow', (
      tester,
    ) async {
      await _pumpAtSize(
        tester,
        FeaturedSurface(
          accent: AppColors.secondary,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          scene: ScenePalette.abyss,
          sceneSeed: 8,
          child: Row(
            children: [
              const NovaAvatar(size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('NOVA TUTOR'),
                    Text('Your AI learning companion'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Size(320, 568),
      );
      expect(find.text('NOVA TUTOR'), findsOneWidget);
    });
  });

  group('AccuracyBars value + date labels', () {
    final runs = [
      _run('Control Flow', 100, DateTime(2026, 9, 4)),
      _run('Control Flow', 25, DateTime(2026, 9, 3)),
      _run('Networking Fundamentals', 75, DateTime(2026, 8, 29)),
    ];

    testWidgets('each bar shows its real score and date', (tester) async {
      await tester.pumpWidget(
        _wrap(SizedBox(height: 152, child: AccuracyBars(quizzes: runs))),
      );
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(
        find.text(Formatters.shortDate(DateTime(2026, 9, 4))),
        findsOneWidget,
      );
      expect(
        find.text(Formatters.shortDate(DateTime(2026, 8, 29))),
        findsOneWidget,
      );
    });

    testWidgets('no overflow at 320px and 1280px', (tester) async {
      await _pumpAtSize(
        tester,
        SizedBox(height: 152, child: AccuracyBars(quizzes: runs)),
        const Size(320, 568),
      );
      await _pumpAtSize(
        tester,
        SizedBox(height: 152, child: AccuracyBars(quizzes: runs)),
        const Size(1280, 800),
      );
    });
  });
}
