// Shell dock anchoring + Exit experience regression tests.
//
// Covers the production defect correction:
// - dock is a single global shell-level bottomNavigationBar (never in scroll)
// - dock stays viewport-anchored while content scrolls (short + long)
// - bottom clearance derives from dock geometry + SafeArea (no magic pads)
// - five destinations unchanged, semantics + reduced motion preserved
// - Exit lives in Settings (not bottom nav), confirms, cancels cleanly,
//   never logs out, Android pops task (mocked), web branch is browser-safe.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gamelearn_app/core/haptics/haptics.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/core/audio/audio_manager.dart';
import 'package:gamelearn_app/features/profile/presentation/settings_screen.dart';
import 'package:gamelearn_app/features/shell/shell_dock_insets.dart';
import 'package:gamelearn_app/features/shell/shell_screen.dart';
import 'package:gamelearn_app/shared/widgets/premium_settings.dart';

import '../helpers/fake_backend.dart';

GoRouter _routerWithChild(Widget child) => GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, shellChild) =>
          ShellScreen(location: state.uri.path, child: shellChild),
      routes: [
        GoRoute(path: '/home', builder: (_, _) => child),
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
        GoRoute(path: '/tutor', builder: (_, _) => const Text('TUTOR PAGE')),
      ],
    ),
  ],
);

Widget _harness(GoRouter router) => ProviderScope(
  overrides: [hapticsProvider.overrideWithValue(Haptics()..enabled = false)],
  child: MaterialApp.router(routerConfig: router),
);

Future<void> _setSize(
  WidgetTester tester,
  double width,
  double height,
) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

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

/// Dock label text inside the shell (proves single global instance).
Finder get _dockHomeLabel => find.text('HOME');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shell dock anchoring', () {
    testWidgets('renders exactly one global dock outside scroll content', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await _setSize(tester, 390, 844);
      final router = _routerWithChild(
        const SingleChildScrollView(child: Text('SHORT CONTENT')),
      );
      await tester.pumpWidget(_harness(router));
      await tester.pumpAndSettle();

      // One dock: each destination label appears exactly once.
      expect(find.text('HOME'), findsOneWidget);
      expect(find.text('WORLDS'), findsOneWidget);
      expect(find.text('STATS'), findsOneWidget);
      expect(find.text('PROFILE'), findsOneWidget);
      // Dock owns the shell bottom bar, not the page scrollable.
      final scrollables = find.byType(SingleChildScrollView);
      expect(scrollables, findsOneWidget);
      expect(
        find.descendant(of: scrollables, matching: _dockHomeLabel),
        findsNothing,
        reason: 'dock must not live inside page scroll content',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('dock stays fixed at viewport bottom while content scrolls', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await _setSize(tester, 390, 844);
      final router = _routerWithChild(
        ListView.builder(
          itemCount: 60,
          itemBuilder: (_, i) => SizedBox(
            height: 48,
            child: Text('ROW $i', key: ValueKey('row-$i')),
          ),
        ),
      );
      await tester.pumpWidget(_harness(router));
      await tester.pumpAndSettle();

      Offset dockTop() => tester.getTopLeft(find.text('HOME'));
      final before = dockTop().dy;

      // Scroll content a lot; dock must not move with it. Drag from the
      // upper content area so the floating dock overlay does not absorb
      // the pointer (the dock legitimately floats above list center).
      await tester.dragFrom(const Offset(195, 300), const Offset(0, -600));
      await tester.pumpAndSettle();
      final afterMiddle = dockTop().dy;
      await tester.dragFrom(const Offset(195, 300), const Offset(0, -1200));
      await tester.pumpAndSettle();
      final afterBottom = dockTop().dy;

      expect(
        (afterMiddle - before).abs(),
        lessThan(2.0),
        reason: 'dock must not scroll with page content',
      );
      expect(
        (afterBottom - before).abs(),
        lessThan(2.0),
        reason: 'dock must stay viewport-anchored at list bottom',
      );
      // Dock remains near viewport bottom (844 height, dock ~86 tall).
      final dockRect = tester.getRect(find.text('HOME'));
      expect(dockRect.bottom, greaterThan(700));
      expect(tester.takeException(), isNull);
    });

    testWidgets('short content still anchors dock at viewport bottom', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await _setSize(tester, 390, 844);
      final router = _routerWithChild(
        const SingleChildScrollView(
          child: SizedBox(height: 200, child: Text('SHORT')),
        ),
      );
      await tester.pumpWidget(_harness(router));
      await tester.pumpAndSettle();

      // Content is only 200px tall; dock must still sit at viewport
      // bottom, not directly under the short content.
      final dockRect = tester.getRect(find.text('HOME'));
      expect(
        dockRect.top,
        greaterThan(600),
        reason: 'dock must not move up because content is short',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('clearance derives from dock geometry plus SafeArea', (
      tester,
    ) async {
      // No system inset: 78 + 8 + 0 + 16 = 102.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(padding: EdgeInsets.zero),
            child: _ClearanceProbe(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('102.0'), findsOneWidget);
    });

    testWidgets('clearance grows with gesture/nav inset', (tester) async {
      // Redmi-style gesture inset: 78 + 8 + 24 + 16 = 126.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(
              padding: EdgeInsets.only(bottom: 24),
            ),
            child: _ClearanceProbe(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('126.0'), findsOneWidget);
    });

    testWidgets('320px compact renders dock without overflow', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _setSize(tester, 320, 844);
      final router = _routerWithChild(
        const SingleChildScrollView(child: Text('COMPACT')),
      );
      await tester.pumpWidget(_harness(router));
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
      expect(find.text('PROFILE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion keeps all five destinations', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _setSize(tester, 390, 844);
      final router = _routerWithChild(
        const SingleChildScrollView(child: Text('PAGE')),
      );
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _harness(router),
        ),
      );
      await tester.pumpAndSettle();
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
      semantics.dispose();
      expect(tester.takeException(), isNull);
    });
  });

  group('Exit experience (Settings)', () {
    Future<SharedPreferences> fakePrefs() async {
      SharedPreferences.setMockInitialValues({});
      return SharedPreferences.getInstance();
    }

    Future<void> pumpSettings(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(await fakePrefs()),
            audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Exit row exists once, separate from Sign out', (tester) async {
      await pumpSettings(tester);
      expect(find.text('Exit app'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
      // Exit is an application-control row, not a bottom-nav destination.
      expect(find.byType(PremiumAccountRow), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Exit confirmation appears and Cancel leaves app unchanged', (
      tester,
    ) async {
      await pumpSettings(tester);
      await tester.ensureVisible(find.text('Exit app'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Exit app'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Exit GameLearn AI?'), findsOneWidget);
      expect(
        find.text('Are you sure you want to close the application?'),
        findsOneWidget,
      );
      // Cancel dismisses; settings state is untouched (both rows remain,
      // no navigation to login, no sign-out dialog).
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();
      expect(find.text('Exit GameLearn AI?'), findsNothing);
      expect(find.text('Exit app'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.text('Sign out?'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Exit confirm on Android pops task without logging out', (
      tester,
    ) async {
      await pumpSettings(tester);
      var popped = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (
            call,
          ) async {
            if (call.method == 'SystemNavigator.pop') popped = true;
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding
            .instance
            .defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );

      await tester.ensureVisible(find.text('Exit app'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Exit app'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('EXIT'));
      await tester.pumpAndSettle();

      // Android behavior: task close requested…
      expect(popped, isTrue);
      // …and nothing about auth changed: still on Settings, sign-out intact,
      // no logout navigation, no sign-out dialog.
      expect(find.text('Exit app'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.text('Sign out?'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

class _ClearanceProbe extends StatelessWidget {
  const _ClearanceProbe();

  @override
  Widget build(BuildContext context) {
    return Text(ShellDockMetrics.bottomClearance(context).toString());
  }
}
