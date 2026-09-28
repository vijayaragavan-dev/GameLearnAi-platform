import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/core/theme/app_theme.dart';
import 'package:gamelearn_app/features/avatar/widgets/avatar_visual.dart';

void main() {
  group('AvatarVisual', () {
    Future<void> pumpVisual(WidgetTester tester, {required double size, required String rarity}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildGameLearnDarkTheme(),
          home: Scaffold(body: Center(child: AvatarVisual(assetKey: 'characters/nova_spark', displayName: 'Test', rarity: rarity, size: size))),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('L8-04 renders actual asset', (tester) async {
      await pumpVisual(tester, size: 80, rarity: 'COMMON');
      expect(find.byType(AvatarVisual), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('L8-05 missing asset does not crash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: buildGameLearnDarkTheme(), home: Scaffold(body: Center(child: AvatarVisual(assetKey: 'characters/unknown_xyz', displayName: 'Unknown', rarity: 'COMMON', size: 80)))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AvatarVisual), findsOneWidget);
    });

    testWidgets('L8-06 rarity presentation', (tester) async {
      for (final rarity in ['INITIATE', 'COMMON', 'RARE', 'EPIC', 'LEGENDARY']) {
        await pumpVisual(tester, size: 80, rarity: rarity);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('L8-07 small 32dp rendering', (tester) async {
      await pumpVisual(tester, size: 32, rarity: 'COMMON');
      expect(tester.takeException(), isNull);
    });

    testWidgets('L8-08 40dp rendering', (tester) async {
      await pumpVisual(tester, size: 40, rarity: 'RARE');
      expect(tester.takeException(), isNull);
    });

    testWidgets('L6-UI-09 56dp rendering', (tester) async {
      await pumpVisual(tester, size: 56, rarity: 'EPIC');
      expect(tester.takeException(), isNull);
    });

    testWidgets('L8-10 92dp rendering', (tester) async {
      await pumpVisual(tester, size: 92, rarity: 'LEGENDARY');
      expect(tester.takeException(), isNull);
    });

    testWidgets('L8-11 120dp rendering', (tester) async {
      await pumpVisual(tester, size: 120, rarity: 'LEGENDARY');
      expect(tester.takeException(), isNull);
    });

    testWidgets('L8-12 large rendering', (tester) async {
      await pumpVisual(tester, size: 160, rarity: 'LEGENDARY');
      expect(tester.takeException(), isNull);
    });

    testWidgets('L8-18 dark theme', (tester) async {
      await tester.pumpWidget(MaterialApp(theme: buildGameLearnDarkTheme(), home: Scaffold(body: AvatarVisual(assetKey: 'characters/nova_spark', displayName: 'Test', rarity: 'LEGENDARY', size: 80))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('L8-19 light theme', (tester) async {
      await tester.pumpWidget(MaterialApp(theme: buildGameLearnLightTheme(), home: Scaffold(body: AvatarVisual(assetKey: 'characters/nova_spark', displayName: 'Test', rarity: 'LEGENDARY', size: 80))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('L8-20 reduced motion', (tester) async {
      await tester.pumpWidget(MediaQuery(data: const MediaQueryData(disableAnimations: true), child: MaterialApp(theme: buildGameLearnDarkTheme(), home: Scaffold(body: AvatarVisual(assetKey: 'characters/nova_spark', displayName: 'Test', rarity: 'COMMON', size: 80)))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('L8-21 semantics', (tester) async {
      await tester.pumpWidget(MaterialApp(theme: buildGameLearnDarkTheme(), home: Scaffold(body: AvatarVisual(assetKey: 'characters/nova_spark', displayName: 'Nova Spark', rarity: 'INITIATE', size: 80))));
      await tester.pumpAndSettle();
      expect(find.byType(Semantics), findsWidgets);
    });
  });
}
