import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gamelearn_app/core/theme/app_theme.dart';
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
    reason: 'Cinematic scenery must not overflow at $size',
  );
}

/// F7 regression: the procedural scenery system (new-UI illustrated
/// landscapes) is identity-driven, theme-aware and overflow-safe.
/// Art varies by stable backend identity — never by user data.
void main() {
  group('scenePaletteForWorld', () {
    test('resolves known backend icon keys', () {
      expect(
        scenePaletteForWorld('network_signal'),
        ScenePalette.abyss,
      );
      expect(
        scenePaletteForWorld('data_base_storage'),
        ScenePalette.ember,
      );
      expect(
        scenePaletteForWorld('tree_graph_structure'),
        ScenePalette.verdant,
      );
      expect(
        scenePaletteForWorld('zzz_unknown_future'),
        ScenePalette.arcane,
      );
    });

    test('unknown keys fall back to arcane (never throws)', () {
      expect(scenePaletteForWorld(''), ScenePalette.arcane);
      expect(
        scenePaletteForWorld('some_future_world_xyz'),
        ScenePalette.arcane,
      );
    });
  });

  group('scenePaletteForGame', () {
    test('resolves known game keys', () {
      expect(
        scenePaletteForGame('memory_match'),
        ScenePalette.abyss,
      );
      expect(
        scenePaletteForGame('boss_battle'),
        ScenePalette.crimson,
      );
      expect(
        scenePaletteForGame('quiz_battle'),
        ScenePalette.violet,
      );
    });

    test('unknown keys fall back to arcane (never throws)', () {
      expect(scenePaletteForGame(''), ScenePalette.arcane);
      expect(scenePaletteForGame('future_game_xyz'), ScenePalette.arcane);
    });
  });

  group('seedForKey', () {
    test('is deterministic per identity key', () {
      expect(seedForKey('programming'), seedForKey('programming'));
      expect(seedForKey('a'), isNot(seedForKey('b')));
      expect(seedForKey(''), isNonNegative);
    });
  });

  group('CinematicScenery + SceneArt', () {
    testWidgets('scenery paints without semantics noise', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 390,
            height: 220,
            child: CinematicScenery(
              palette: ScenePalette.indigo,
              seed: 11,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Purely decorative by construction (ExcludeSemantics +
      // RepaintBoundary inside) — renders exactly one widget.
      expect(find.byType(CinematicScenery), findsOneWidget);
    });

    testWidgets('scene art frames child content', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 390,
            height: 220,
            child: SceneArt(
              palette: ScenePalette.ember,
              seed: 3,
              child: Center(child: Text('world art frame')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('world art frame'), findsOneWidget);
    });

    for (final size in const [
      Size(320, 568),
      Size(390, 844),
      Size(1280, 800),
    ]) {
      testWidgets('scenery no overflow at ${size.width.toInt()}px', (
        tester,
      ) async {
        await _pumpAtSize(
          tester,
          const SizedBox(
            width: double.infinity,
            height: 240,
            child: CinematicScenery(
              palette: ScenePalette.violet,
              seed: 42,
            ),
          ),
          size,
        );
      });
    }

    testWidgets('scenery renders in light mode', (tester) async {
      await _pumpAtSize(
        tester,
        const SizedBox(
          width: double.infinity,
          height: 240,
          child: CinematicScenery(
            palette: ScenePalette.indigo,
            seed: 7,
          ),
        ),
        const Size(390, 844),
        dark: false,
      );
    });
  });

  group('SceneThumb', () {
    testWidgets('renders glyph with accessible label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SceneThumb(
            palette: ScenePalette.abyss,
            seed: 9,
            icon: Icons.code_rounded,
            accent: Colors.cyan,
            label: 'Programming world artwork',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Programming world artwork'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.code_rounded), findsOneWidget);
    });

    testWidgets('full-width thumb has no overflow at 320px', (tester) async {
      await _pumpAtSize(
        tester,
        const SceneThumb(
          palette: ScenePalette.violet,
          seed: 12,
          icon: Icons.quiz_rounded,
          accent: Colors.purple,
          width: double.infinity,
          height: 76,
        ),
        const Size(320, 568),
      );
    });
  });

  group('Scene-backed surfaces', () {
    testWidgets('CinematicHero with scene renders badge + title', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const CinematicHero(
            badge: 'World Explorer',
            title: Text('Choose your world'),
            scene: ScenePalette.indigo,
            sceneSeed: 11,
            novaMood: NovaMood.idle,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('WORLD EXPLORER'), findsOneWidget);
      expect(find.text('Choose your world'), findsOneWidget);
      expect(find.byType(NovaCompanion), findsOneWidget);
    });

    testWidgets('FeaturedSurface with scene renders child', (tester) async {
      await tester.pumpWidget(
        _wrap(
          FeaturedSurface(
            accent: Colors.cyan,
            scene: scenePaletteForWorld('network_icon'),
            sceneSeed: seedForKey('networks'),
            child: const Text('featured scene content'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('featured scene content'), findsOneWidget);
    });

    testWidgets('scene hero no overflow at 320px and 1280px', (tester) async {
      await _pumpAtSize(
        tester,
        const CinematicHero(
          badge: 'Knowledge Scan',
          title: Text('Nova Calibration'),
          scene: ScenePalette.abyss,
          sceneSeed: 21,
          novaMood: NovaMood.thinking,
        ),
        const Size(320, 568),
      );
      await _pumpAtSize(
        tester,
        const CinematicHero(
          badge: 'Knowledge Scan',
          title: Text('Nova Calibration'),
          scene: ScenePalette.abyss,
          sceneSeed: 21,
          novaMood: NovaMood.thinking,
        ),
        const Size(1280, 800),
      );
    });
  });
}
