// Nova floating action vs. viewport-anchored command dock.
//
// Regression coverage for the post-dock-fix overlap: Dashboard's Nova FAB
// lives in its inner Scaffold FAB slot while the global dock occupies real
// viewport space (outer Scaffold.bottomNavigationBar). Nova's bottom must
// sit a deliberate gap above the dock top, derived from ShellDockMetrics
// (never a magic offset), and stay there while content scrolls.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gamelearn_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:gamelearn_app/features/shell/shell_dock_insets.dart';
import 'package:gamelearn_app/features/shell/shell_screen.dart';

import '../helpers/fake_backend.dart';

/// Real DashboardScreen inside the real shell, backed by the fake backend.
/// Zero-state dashboard keeps content short; subjects serve the world grid.
Widget _dashboardShell() {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            ShellScreen(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) => const DashboardScreen(),
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
        ],
      ),
      GoRoute(path: '/tutor', builder: (_, _) => const Text('TUTOR PAGE')),
    ],
  );
  return fakeScope(
    child: MaterialApp.router(routerConfig: router),
    handler: (request) {
      if (request.url.path.contains('/subjects')) {
        return {'body': Fixtures.subjects()};
      }
      return {'body': Fixtures.dashboardZeroState()};
    },
  );
}

Future<void> _setSize(WidgetTester tester, double w, double h) async {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  // Real Dashboard runs continuous atmospheric/stagger animations, so
  // pumpAndSettle never settles — advance the clock with fixed pumps
  // (same pattern as the existing dashboard test suites).
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pump(const Duration(milliseconds: 800));
}

/// The floating Nova action (Dashboard FAB slot). Scoped to the button
/// itself: page content also renders "NOVA" section text.
Finder get _novaFab => find.byType(FloatingActionButton);

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

  group('ShellDockMetrics.novaLift', () {
    testWidgets('zero inset lifts exactly dock + margin + gap − slot margin', (
      tester,
    ) async {
      // 78 + 8 + 0 + 12 − 16 = 82.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(390, 844),
              padding: EdgeInsets.zero,
            ),
            child: _NovaLiftProbe(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('82.0'), findsOneWidget);
    });

    testWidgets('gesture inset is included (Redmi-style 24px)', (
      tester,
    ) async {
      // 78 + 8 + 24 + 12 − 16 = 106. viewPadding carries the true system
      // inset (Scaffold body padding already contains dock occupancy).
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(390, 844),
              viewPadding: EdgeInsets.only(bottom: 24),
            ),
            child: _NovaLiftProbe(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('106.0'), findsOneWidget);
    });

    testWidgets('rail layouts need no lift (no bottom dock)', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(800, 800),
              padding: EdgeInsets.zero,
            ),
            child: _NovaLiftProbe(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('0.0'), findsOneWidget);
    });
  });

  group('Nova above dock (real Dashboard + real shell)', () {
    testWidgets('Nova bottom sits a clear gap above the dock', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(_dashboardShell());
      await _settle(tester);
      expect(tester.takeException(), isNull);

      expect(_novaFab, findsOneWidget);
      expect(find.text('HOME'), findsOneWidget);

      final fabRect = tester.getRect(_novaFab);
      final homeRect = tester.getRect(find.text('HOME'));
      // Nova must not touch or overlap any dock content.
      expect(
        fabRect.bottom,
        lessThan(homeRect.top - 4),
        reason: 'Nova must sit clearly above the command dock',
      );
      // Exact relationship: viewport bottom − dock − gap (tolerance 6px
      // for FAB internal padding/rounding).
      final viewBottom = tester.view.physicalSize.height;
      final expectedBottom =
          viewBottom -
          (ShellDockMetrics.dockHeight +
              ShellDockMetrics.dockBottomMargin +
              ShellDockMetrics.novaGap);
      expect(
        (fabRect.bottom - expectedBottom).abs(),
        lessThan(6.0),
        reason:
            'Nova bottom must derive from dock geometry + gap (expected $expectedBottom)',
      );
    });

    testWidgets('Nova stays above dock while content scrolls', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(_dashboardShell());
      await _settle(tester);

      Rect fab() => tester.getRect(_novaFab);
      Rect home() => tester.getRect(find.text('HOME'));
      final before = fab().bottom;
      expect(before, lessThan(home().top - 4));

      // Scroll from the upper content area (dock overlay absorbs center).
      await tester.dragFrom(const Offset(195, 300), const Offset(0, -800));
      await _settle(tester);
      expect(fab().bottom, lessThan(home().top - 4));
      expect(
        (fab().bottom - before).abs(),
        lessThan(2.0),
        reason: 'Nova must not scroll with page content',
      );

      await tester.dragFrom(const Offset(195, 300), const Offset(0, 800));
      await _settle(tester);
      expect(fab().bottom, lessThan(home().top - 4));
    });

    testWidgets('320px compact keeps Nova above dock without overflow', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await _setSize(tester, 320, 844);
      await tester.pumpWidget(_dashboardShell());
      await _settle(tester);
      expect(tester.takeException(), isNull);
      expect(_novaFab, findsOneWidget);
      expect(find.text('HOME'), findsOneWidget);
      expect(
        tester.getRect(_novaFab).bottom,
        lessThan(tester.getRect(find.text('HOME')).top - 4),
      );
    });

    testWidgets('rail width keeps desktop composition (no bottom dock)', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await _setSize(tester, 800, 800);
      await tester.pumpWidget(_dashboardShell());
      await _settle(tester);
      expect(tester.takeException(), isNull);
      // No bottom-dock labels at rail width; Nova FAB still present.
      expect(find.text('HOME'), findsNothing);
      expect(_novaFab, findsOneWidget);
    });

    testWidgets('Nova action still opens the tutor route', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _setSize(tester, 390, 844);
      await tester.pumpWidget(_dashboardShell());
      await _settle(tester);

      await tester.tap(_novaFab);
      await _settle(tester);
      expect(find.text('TUTOR PAGE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion + semantics intact with lifted Nova', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await _setSize(tester, 390, 844);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _dashboardShell(),
        ),
      );
      await _settle(tester);
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
      expect(_novaFab, findsOneWidget);
      expect(
        tester.getRect(_novaFab).bottom,
        lessThan(tester.getRect(find.text('HOME')).top - 4),
      );
      semantics.dispose();
      expect(tester.takeException(), isNull);
    });
  });
}

class _NovaLiftProbe extends StatelessWidget {
  const _NovaLiftProbe();

  @override
  Widget build(BuildContext context) {
    return Text(ShellDockMetrics.novaLift(context).toString());
  }
}
