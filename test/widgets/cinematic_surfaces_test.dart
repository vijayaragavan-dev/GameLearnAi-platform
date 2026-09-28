import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gamelearn_app/core/theme/app_theme.dart';
import 'package:gamelearn_app/shared/widgets/cinematic_surfaces.dart';
import 'package:gamelearn_app/shared/widgets/nova_companion.dart';

Widget _wrap(Widget child, {bool dark = true}) => ProviderScope(
  child: MaterialApp(
    theme: buildGameLearnDarkTheme(),
    darkTheme: buildGameLearnDarkTheme(),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    home: Scaffold(body: SingleChildScrollView(child: child)),
    // Nova's ambient animation honors reduced motion; disable it so
    // pumpAndSettle terminates (same pattern as login responsive tests).
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
    reason: 'Cinematic surface must not overflow at $size',
  );
}

/// Visual regression for the cinematic surface system (new-UI language).
/// All components render real content — no fake data, no hardcoded XP.
void main() {
  group('CinematicHero', () {
    testWidgets('renders badge, title and Nova', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CinematicHero(
            badge: 'Current Mission',
            title: Text('Programming'),
            subtitle: Text('Control Flow'),
            novaMood: NovaMood.encouraging,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('CURRENT MISSION'), findsOneWidget);
      expect(find.text('Programming'), findsOneWidget);
      expect(find.byType(NovaCompanion), findsOneWidget);
    });

    for (final size in const [
      Size(320, 568),
      Size(390, 844),
      Size(1280, 800),
    ]) {
      testWidgets('no overflow at ${size.width.toInt()}px', (tester) async {
        await _pumpAtSize(
          tester,
          const CinematicHero(
            badge: 'Featured World',
            title: Text('Programming'),
            subtitle: Text('Enter the Programming world and forge your path.'),
            tagline: 'CODE\nBUILD\nSOLVE\nGROW',
            novaMood: NovaMood.idle,
            bottom: null,
          ),
          size,
        );
      });
    }
  });

  group('GlassPanel + GlowCTA', () {
    testWidgets('glass panel renders child with glow border', (tester) async {
      await tester.pumpWidget(
        _wrap(const GlassPanel(child: Text('panel content'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('panel content'), findsOneWidget);
    });

    testWidgets('glow CTA uppercases label and honors disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              GlowCTA(label: 'Begin scan', onPressed: () {}),
              const GlowCTA(label: 'Locked action', onPressed: null),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('BEGIN SCAN'), findsOneWidget);
      expect(find.text('LOCKED ACTION'), findsOneWidget);
    });

    testWidgets('no overflow at 320px and 1280px', (tester) async {
      await _pumpAtSize(
        tester,
        GlowCTA(label: 'Continue world', onPressed: () {}),
        const Size(320, 568),
      );
      await _pumpAtSize(
        tester,
        GlowCTA(label: 'Continue world', onPressed: () {}),
        const Size(1280, 800),
      );
    });
  });

  group('NeonSectionHeader', () {
    testWidgets('renders title and View All action', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          NeonSectionHeader(
            icon: Icons.sports_esports_rounded,
            title: 'Game Zone',
            subtitle: 'Play, practice and master',
            onViewAll: () => tapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('GAME ZONE'), findsOneWidget);
      await tester.tap(find.text('View All'));
      expect(tapped, isTrue);
    });
  });

  group('WorldStatusBadge', () {
    testWidgets('state is text + icon, never color alone', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Column(
            children: [
              WorldStatusBadge(status: WorldStatus.live),
              WorldStatusBadge(status: WorldStatus.fresh),
              WorldStatusBadge(status: WorldStatus.scan),
              WorldStatusBadge(status: WorldStatus.comingSoon),
              WorldStatusBadge(status: WorldStatus.locked),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('NEW'), findsOneWidget);
      expect(find.text('SCAN'), findsOneWidget);
      expect(find.text('COMING SOON'), findsOneWidget);
      expect(find.text('LOCKED'), findsOneWidget);
    });
  });

  group('BrandWordmark + JourneyTimeline', () {
    testWidgets('wordmark renders canonical identity', (tester) async {
      await tester.pumpWidget(_wrap(const BrandWordmark()));
      await tester.pumpAndSettle();
      expect(find.text('GAMELEARN AI'), findsOneWidget);
    });

    testWidgets('journey timeline announces stage accessibly', (tester) async {
      await tester.pumpWidget(_wrap(const JourneyTimeline(stage: 1)));
      await tester.pumpAndSettle();
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);
      expect(find.text('Challenge'), findsOneWidget);
      expect(find.text('Master'), findsOneWidget);
    });

    testWidgets('timeline no overflow at 320px', (tester) async {
      await _pumpAtSize(
        tester,
        const JourneyTimeline(stage: 0),
        const Size(320, 568),
      );
    });
  });

  group('Light theme', () {
    testWidgets('cinematic surfaces stay readable in light mode', (
      tester,
    ) async {
      await _pumpAtSize(
        tester,
        const Column(
          children: [
            BrandWordmark(),
            SizedBox(height: 12),
            CinematicHero(
              badge: 'Knowledge Scan',
              title: Text('Nova Tutor'),
            ),
            SizedBox(height: 12),
            GlassPanel(child: Text('light panel')),
          ],
        ),
        const Size(390, 844),
        dark: false,
      );
      expect(find.text('GAMELEARN AI'), findsOneWidget);
      expect(find.text('light panel'), findsOneWidget);
    });
  });
}
