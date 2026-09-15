import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:gamelearn_app/features/games/quiz_battle/presentation/quiz_battle_screen.dart';

import '../helpers/fake_backend.dart';

/// F4 gameplay-reliability regression: answering then immediately tapping
/// the manual Next/Back controls must not double-advance the delayed
/// auto-advance (which previously skipped the next question and auto-filled
/// its answer at submit).
void main() {
  const subjectId = '11111111-1111-1111-1111-111111111101';

  Map<String, dynamic> Function(http.Request) handler(
    List<Map<String, dynamic>> posted,
  ) {
    return (request) {
      final path = request.url.path;
      if (path.endsWith('/api/v1/quiz/t2') && request.method == 'GET') {
        return {'body': Fixtures.quiz()};
      }
      if (path.endsWith('/submit') && request.method == 'POST') {
        return {'body': Fixtures.quizResult()};
      }
      if (path.endsWith('/api/v1/gamification/summary')) {
        return {'body': Fixtures.gamificationSummary()};
      }
      if (path.endsWith('/api/v1/achievements')) {
        return {'body': Fixtures.achievements()};
      }
      if (path.endsWith('/api/v1/me/game-results') &&
          request.method == 'POST') {
        posted.add({'path': path});
        return {
          'body': {
            'requestId': 'r1',
            'xpEarned': 20,
            'previousLevel': 3,
            'currentLevel': 3,
            'previousTotalXp': 325,
            'currentTotalXp': 345,
            'leveledUp': false,
            'levelsGained': 0,
            'playedAt': '2026-08-24T10:15:07Z',
            'nextLevelThresholdXp': 600,
            'xpToNextLevel': 255,
          },
        };
      }
      return {
        'status': 404,
        'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
      };
    };
  }

  Future<void> pumpBattle(
    WidgetTester tester,
    List<Map<String, dynamic>> posted,
  ) async {
    await tester.pumpWidget(
      fakeScope(
        child: const MaterialApp(
          home: QuizBattleScreen(
            topicId: 't2',
            topicName: 'Control Flow',
            subjectId: subjectId,
            subjectName: 'Programming',
          ),
        ),
        handler: handler(posted),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(
      find.text('Which keyword declares a constant?'),
      findsOneWidget,
    );
  }

  group('Quiz Battle advance race (F4)', () {
    testWidgets('manual Next during the auto-advance beat skips nothing',
        (tester) async {
      final posted = <Map<String, dynamic>>[];
      await pumpBattle(tester, posted);

      // Answer Q1, then hammer Next inside the 220ms auto-advance window.
      await tester.tap(find.text('const'));
      await tester.pump();
      await tester.tap(find.text('NEXT'));
      await tester.pump(const Duration(milliseconds: 600));

      // Exactly one advance: Q2 is live, submit has not fired.
      expect(find.text('What does a loop require?'), findsOneWidget);
      expect(find.textContaining('BATTLE 2 / 2'), findsOneWidget);
      expect(posted, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Back during the beat wins; full run still submits once',
        (tester) async {
      final posted = <Map<String, dynamic>>[];
      await pumpBattle(tester, posted);

      await tester.tap(find.text('const'));
      await tester.pump();
      // Next, then immediately Back: the pending auto-advance must stand
      // down instead of re-advancing past the reviewed question.
      await tester.tap(find.text('NEXT'));
      await tester.pump();
      await tester.tap(find.text('BACK'));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Which keyword declares a constant?'), findsOneWidget);
      expect(posted, isEmpty);

      // Continue the run: Q2 answers and auto-submits exactly once.
      // (The AnimatedSwitcher briefly holds both questions; settle it.)
      await tester.tap(find.text('NEXT'));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('What does a loop require?'), findsOneWidget);
      await tester.tap(find.text('condition'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('MISSION COMPLETE'), findsOneWidget);
      expect(posted, hasLength(1));
      expect(tester.takeException(), isNull);
    });
  });
}
