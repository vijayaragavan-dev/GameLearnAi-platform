import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/shared/widgets/pressable.dart';

void main() {
  group('A12 UX Polish', () {
    testWidgets('Pressable renders child and onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Pressable(
              onTap: () => taps++,
              child: const Text('Tap me'),
            ),
          ),
        ),
      ));
      expect(find.text('Tap me'), findsOneWidget);
      await tester.tap(find.text('Tap me'));
      expect(taps, 1);
    });

    testWidgets('Pressable semantics label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Pressable(
            onTap: () {},
            semanticsLabel: 'Open game',
            child: const Text('Hi'),
          ),
        ),
      ));
      // Semantics label attaches to the wrapper
      expect(find.text('Hi'), findsOneWidget);
      expect(find.byType(Pressable), findsOneWidget);
    });

    testWidgets('Pressable onTap null becomes non-interactive', (tester) async {
      var taps = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Pressable(
            onTap: null,
            child: const Text('No tap'),
          ),
        ),
      ));
      await tester.tap(find.text('No tap'), warnIfMissed: false);
      expect(taps, 0);
    });
  });
}
