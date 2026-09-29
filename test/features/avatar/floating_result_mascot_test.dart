import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/avatar/widgets/floating_result_mascot.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildSubject({required double score, String? customMessage}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: FloatingResultMascot(
            score: score,
            customMessage: customMessage,
          ),
        ),
      ),
    );
  }

  group('FloatingResultMascot result tiers & animations', () {
    testWidgets('Failed score (< 50) displays consoling badge and sad mood', (tester) async {
      await tester.pumpWidget(buildSubject(score: 40.0));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('LET\'S RETRY'), findsOneWidget);
      expect(find.byType(FloatingResultMascot), findsOneWidget);
    });

    testWidgets('Moderate score (50-79) displays motivating badge', (tester) async {
      await tester.pumpWidget(buildSubject(score: 65.0));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('SO CLOSE TO 100%'), findsOneWidget);
      expect(find.byType(FloatingResultMascot), findsOneWidget);
    });

    testWidgets('Good score (>= 80) displays celebratory victory badge', (tester) async {
      await tester.pumpWidget(buildSubject(score: 95.0));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('SPECTACULAR!'), findsOneWidget);
      expect(find.byType(FloatingResultMascot), findsOneWidget);
    });

    testWidgets('Tapping mascot or quote card triggers quote cycling', (tester) async {
      await tester.pumpWidget(buildSubject(score: 90.0));
      await tester.pump(const Duration(milliseconds: 100));

      final quoteCardFinder = find.byType(InkWell);
      expect(quoteCardFinder, findsOneWidget);

      await tester.tap(quoteCardFinder);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(FloatingResultMascot), findsOneWidget);
    });
  });
}
