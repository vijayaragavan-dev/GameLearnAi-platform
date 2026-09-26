import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:gamelearn_app/features/challenge/quiz/presentation/quiz_screen.dart';
import 'package:gamelearn_app/features/games/quiz_battle/presentation/quiz_battle_screen.dart';
import 'package:gamelearn_app/features/games/speed_run/presentation/speed_run_screen.dart';

import '../helpers/fake_backend.dart';

/// Practice-unavailable boundary: topics that serve lessons but have no
/// playable quiz (backend QUIZ-001 404) must render a truthful, polished
/// unavailable state — never a generic error, never fabricated content.
///
/// Generic by construction: no subject/topic names are referenced; any
/// topicId without a quiz triggers the same state.
void main() {
  const missingTopic = 't-noquiz';
  const okTopic = 't-ok';

  Map<String, dynamic> okQuiz() => {
    'id': 'q1111111-1111-1111-1111-111111111101',
    'topicId': okTopic,
    'title': 'Control Flow Challenge',
    'description': 'Prove your branching knowledge',
    'difficulty': 'MEDIUM',
    'timeLimitSeconds': null,
    'questionCount': 1,
    'questions': [
      {
        'id': 'qq1',
        'questionText': 'Which keyword declares a constant?',
        'options': ['const', 'let', 'var'],
        'difficulty': 'EASY',
      },
    ],
  };

  final List<String> posts = [];

  Map<String, dynamic> Function(http.Request) handler = (http.Request request) {
    final path = request.url.path;
    if (request.method != 'GET' &&
        (path.contains('/quiz/') || path.contains('/game-results'))) {
      posts.add('${request.method} $path');
    }
    if (path.endsWith('/api/v1/quiz/$missingTopic') && request.method == 'GET') {
      return {
        'status': 404,
        'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
      };
    }
    if (path.endsWith('/api/v1/quiz/$okTopic') && request.method == 'GET') {
      return {'status': 200, 'body': okQuiz()};
    }
    if (path.endsWith('/api/v1/gamification/summary')) {
      return {'body': Fixtures.gamificationSummary()};
    }
    if (path.endsWith('/api/v1/achievements')) {
      return {'body': Fixtures.achievements()};
    }
    return {
      'status': 404,
      'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
    };
  };

  Widget wrap(Widget child) => fakeScope(
    child: MaterialApp(home: child),
    handler: handler,
  );

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('QuizScreen 404 renders practice-unavailable, not generic error', (
    tester,
  ) async {
    posts.clear();
    await tester.pumpWidget(wrap(const QuizScreen(topicId: missingTopic)));
    await settle(tester);
    expect(find.text('Practice unavailable'), findsOneWidget);
    expect(find.text('RETURN TO LESSON'), findsOneWidget);
    expect(find.text('ASK NOVA'), findsOneWidget);
    expect(find.text('Nothing here'), findsNothing);
    expect(posts, isEmpty);
  });

  testWidgets('QuizBattleScreen 404 renders practice-unavailable', (tester) async {
    posts.clear();
    await tester.pumpWidget(
      wrap(
        const QuizBattleScreen(
          topicId: missingTopic,
          topicName: 'Some Topic',
          subjectId: 's1',
          subjectName: 'Some Subject',
        ),
      ),
    );
    await settle(tester);
    expect(find.text('Practice unavailable'), findsOneWidget);
    expect(find.text('RETURN TO LESSON'), findsOneWidget);
    expect(find.text('ASK NOVA'), findsOneWidget);
    expect(find.text('Nothing here'), findsNothing);
    expect(posts, isEmpty);
  });

  testWidgets('SpeedRunScreen 404 renders practice-unavailable', (tester) async {
    posts.clear();
    await tester.pumpWidget(
      wrap(
        const SpeedRunScreen(
          topicId: missingTopic,
          topicName: 'Some Topic',
          subjectId: 's1',
          subjectName: 'Some Subject',
        ),
      ),
    );
    await settle(tester);
    expect(find.text('Practice unavailable'), findsOneWidget);
    expect(find.text('RETURN TO LESSON'), findsOneWidget);
    expect(find.text('ASK NOVA'), findsOneWidget);
    expect(posts, isEmpty);
  });

  testWidgets('QuizScreen with playable quiz still renders questions', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const QuizScreen(topicId: okTopic)));
    await settle(tester);
    expect(find.text('Which keyword declares a constant?'), findsOneWidget);
    expect(find.text('Practice unavailable'), findsNothing);
  });
}
