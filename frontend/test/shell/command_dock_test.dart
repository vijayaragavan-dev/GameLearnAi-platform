// F14 — premium navigation command dock: rendering, selection,
// routing behavior, themes, narrow widths, reduced motion.
//
// Semantics are asserted against the semantics owner tree (exactly what
// assistive technology consumes): labels plus selected flags.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gamelearn_app/core/haptics/haptics.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/shell/shell_screen.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          ShellScreen(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Text('HOME PAGE'),
        ),
        GoRoute(
          path: '/subjects',
          builder: (_, _) => const Text('WORLDS PAGE'),
        ),
        GoRoute(
          path: '/progress',
          builder: (_, _) => const Text('STATS PAGE'),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, _) => const Text('PROFILE PAGE'),
        ),
        GoRoute(
          path: '/tutor',
          builder: (_, _) => const Text('TUTOR PAGE'),
        ),
      ],
    ),
  ],
);

Widget _harness(GoRouter router) {
  return ProviderScope(
    overrides: [
      hapticsProvider.overrideWithValue(Haptics()..enabled = false),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _setWidth(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Labeled semantics nodes from the owner tree (assistive-tech view),
/// keyed by the first label line (descendant text merges in).
Map<String, SemanticsData> _labeledNodes() {
  final result = <String, SemanticsData>{};
  final owner = RendererBinding.instance.renderView.debugSemantics;
  void walk(SemanticsNode node) {
    if (node.label.isNotEmpty && !node.isMergedIntoParent) {
      result[node.label.split('\n').first] = node.getSemanticsData();
    }
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  if (owner != null) walk(owner);
  return result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('F14 command dock', () {
    testWidgets('renders four tabs plus tutor orb with semantics',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final semantics = tester.ensureSemantics();
      await _setWidth(tester, 390);
      final router = _router();
      await tester.pumpWidget(_harness(router));
      await tester.pumpAndSettle();

      expect(find.text('HOME PAGE'), findsOneWidget);
      final nodes = _labeledNodes();
      for (final label in [
        'Home tab',
        'Worlds tab',
        'Stats tab',
        'Profile tab',
        'Learn Play Grow — open Nova Tutor',
      ]) {
        expect(nodes, contains(label));
      }
      // Selected state is exposed to assistive tech, not color alone.
      expect(
        nodes['Home tab']!.hasFlag(SemanticsFlag.isSelected),
        isTrue,
      );
      expect(
        nodes['Worlds tab']!.hasFlag(SemanticsFlag.isSelected),
        isFalse,
      );
      semantics.dispose();
      expect(tester.takeException(), isNull);
    });

    testWidgets('selection follows the current route', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final semantics = tester.ensureSemantics();
      await _setWidth(tester, 390);
      final router = _router();
      await tester.pumpWidget(_harness(router));
      await tester.pumpAndSettle();

      router.go('/progress');
      await tester.pumpAndSettle();
      expect(find.text('STATS PAGE'), findsOneWidget);
      final nodes = _labeledNodes();
      expect(
        nodes['Stats tab']!.hasFlag(SemanticsFlag.isSelected),
        isTrue,
      );
      expect(
        nodes['Home tab']!.hasFlag(SemanticsFlag.isSelected),
        isFalse,
      );
      semantics.dispose();
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping a tab navigates to its route', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final semantics = tester.ensureSemantics();
      await _setWidth(tester, 390);
      final router = _router();
      await tester.pumpWidget(_harness(router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('WORLDS'));
      await tester.pumpAndSettle();
      expect(find.text('WORLDS PAGE'), findsOneWidget);
      expect(
        _labeledNodes()['Worlds tab']!.hasFlag(SemanticsFlag.isSelected),
        isTrue,
      );
      semantics.dispose();
      expect(tester.takeException(), isNull);
    });

    testWidgets('center orb opens the tutor route', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final semantics = tester.ensureSemantics();
      await _setWidth(tester, 390);
      final router = _router();
      await tester.pumpWidget(_harness(router));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.sports_esports_rounded));
      await tester.pumpAndSettle();
      expect(find.text('TUTOR PAGE'), findsOneWidget);
      semantics.dispose();
      expect(tester.takeException(), isNull);
    });

    testWidgets('320px narrow renders without overflow', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final semantics = tester.ensureSemantics();
      await _setWidth(tester, 320);
      final router = _router();
      await tester.pumpWidget(_harness(router));
      await tester.pumpAndSettle();

      expect(find.text('HOME PAGE'), findsOneWidget);
      expect(_labeledNodes(), contains('Profile tab'));
      semantics.dispose();
      expect(tester.takeException(), isNull);
    });

    testWidgets('light theme renders without overflow', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final semantics = tester.ensureSemantics();
      await _setWidth(tester, 390);
      final router = _router();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hapticsProvider.overrideWithValue(Haptics()..enabled = false),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.light,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('HOME PAGE'), findsOneWidget);
      expect(_labeledNodes(), contains('Stats tab'));
      semantics.dispose();
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion renders the same destinations',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final semantics = tester.ensureSemantics();
      await _setWidth(tester, 390);
      final router = _router();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _harness(router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HOME PAGE'), findsOneWidget);
      await tester.tap(find.text('PROFILE'));
      await tester.pumpAndSettle();
      expect(find.text('PROFILE PAGE'), findsOneWidget);
      semantics.dispose();
      expect(tester.takeException(), isNull);
    });
  });
}
