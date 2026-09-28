import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gamelearn_app/core/connectivity/connectivity_probe.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/shared/widgets/feedback.dart';

Future<void> _pumpWithOffline(WidgetTester tester, Widget child) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(home: Scaffold(body: child)),
  ));
  await tester.pump();
}

void main() {
  group('Reliability A10', () {
    testWidgets('OfflineState mark and clear', (tester) async {
      final o = OfflineState();
      expect(o.offline, false);
      o.mark();
      expect(o.offline, true);
      o.mark(); // no-op
      expect(o.offline, true);
      o.clear();
      expect(o.offline, false);
    });

    testWidgets('OfflineState notifies listeners', (tester) async {
      final o = OfflineState();
      var notifs = 0;
      o.addListener(() => notifs++);
      o.mark();
      o.clear();
      expect(notifs, 2);
    });

    testWidgets('ErrorState renders with retry', (tester) async {
      var retried = 0;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ErrorState(title: 'Loading failed', message: 'Try again later', onRetry: () => retried++))));
      expect(find.text('Loading failed'), findsOneWidget);
      expect(find.text('Try again later'), findsOneWidget);
      await tester.tap(find.text('TRY AGAIN'));
      expect(retried, 1);
    });

    testWidgets('EmptyState renders with action', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: EmptyState(icon: Icons.lightbulb, title: 'Nothing here', message: 'Start learning'))));
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Start learning'), findsOneWidget);
    });

    testWidgets('OfflineBanner renders and tap calls onRetry', (tester) async {
      var retried = 0;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: OfflineBanner(onRetry: () => retried++))));
      expect(find.textContaining('offline'), findsOneWidget);
      expect(find.text('RETRY'), findsOneWidget);
      await tester.tap(find.text('RETRY'));
      expect(retried, 1);
    });

    testWidgets('EmptyMiniCard renders', (tester) async {
      await _pumpWithOffline(tester, const EmptyMiniCard(text: 'No data'));
      expect(find.text('No data'), findsOneWidget);
    });

    testWidgets('Skeletons render without overflow', (tester) async {
      await _pumpWithOffline(tester, const SkeletonCard());
      expect(find.byType(SkeletonCard), findsOneWidget);
    });
  });
}
