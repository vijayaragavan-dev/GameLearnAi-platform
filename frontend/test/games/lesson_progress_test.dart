import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:gamelearn_app/features/learning/lesson/presentation/lesson_screen.dart';

import '../helpers/fake_backend.dart';

/// Generic lesson completion (Phase QA-6C): explicit Mark Complete only.
/// No auto-completion, exactly one PUT, backend-authoritative state, no
/// XP/mastery/streak involvement. Generic topicIds only — no QA/LR/CS names.
void main() {
  const topicId = 't-lesson-1';
  const qaTopicId = 'b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b201';

  Map<String, dynamic> lessonJson() => {
    'id': 'l1',
    'topicId': topicId,
    'title': 'Training Module',
    'content': 'First paragraph.\nSecond paragraph.',
    'summary': 'Key takeaway.',
    'difficulty': 'MEDIUM',
    'sourceType': 'CURATED',
  };

  Map<String, dynamic> completedProgressJson(String tid) => {
    'id': 'p1',
    'topicId': tid,
    'learningPathNodeId': null,
    'completionPercentage': 100,
    'status': 'COMPLETED',
    'lastActivityAt': '2026-09-26T10:00:00Z',
    'completedAt': '2026-09-26T10:00:00Z',
  };

  final List<String> puts = [];
  final List<String> posts = [];
  bool progressIsComplete = false;
  bool putFails = false;

  Map<String, dynamic> Function(http.Request) handler =
      (http.Request request) {
        final path = request.url.path;
        if (request.method == 'PUT' && path.contains('/api/v1/progress/')) {
          puts.add(path);
          if (putFails) {
            return {
              'status': 500,
              'body': {'errorCode': 'INTERNAL_ERROR'},
            };
          }
          progressIsComplete = true;
          final tid = path.split('/').last;
          return {'status': 200, 'body': completedProgressJson(tid)};
        }
        if (request.method == 'POST') {
          posts.add(path);
        }
        if (path.contains('/api/v1/topics/') && path.endsWith('/lesson')) {
          return {'status': 200, 'body': lessonJson()};
        }
        if (path.contains('/api/v1/progress/')) {
          if (progressIsComplete) {
            final tid = path.split('/').last;
            return {'status': 200, 'body': completedProgressJson(tid)};
          }
          return {
            'status': 404,
            'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
          };
        }
        return {
          'status': 404,
          'body': {'errorCode': 'RESOURCE_NOT_FOUND'},
        };
      };

  Widget wrap(String tid) => fakeScope(
    child: MaterialApp(home: LessonScreen(topicId: tid)),
    handler: handler,
  );

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  setUp(() {
    puts.clear();
    posts.clear();
    progressIsComplete = false;
    putFails = false;
  });

  testWidgets('TEST 1 — CTA visible for incomplete topic', (tester) async {
    await tester.pumpWidget(wrap(topicId));
    await settle(tester);
    expect(find.text('Training Module'), findsOneWidget);
    expect(find.text('MARK COMPLETE'), findsOneWidget);
  });

  testWidgets('TEST 2 — completed topic renders Completed state', (
    tester,
  ) async {
    progressIsComplete = true;
    await tester.pumpWidget(wrap(topicId));
    await settle(tester);
    expect(find.text('COMPLETED'), findsOneWidget);
    expect(find.text('MARK COMPLETE'), findsNothing);
    expect(puts, isEmpty);
  });

  testWidgets('TEST 3 — Mark Complete sends exactly one PUT', (tester) async {
    await tester.pumpWidget(wrap(topicId));
    await settle(tester);
    await tester.tap(find.text('MARK COMPLETE'));
    await settle(tester);
    final putCalls = puts
        .where((p) => p.endsWith('/api/v1/progress/$topicId'))
        .toList();
    expect(putCalls, hasLength(1));
  });

  testWidgets('TEST 4 — success refreshes to Completed', (tester) async {
    await tester.pumpWidget(wrap(topicId));
    await settle(tester);
    await tester.tap(find.text('MARK COMPLETE'));
    await settle(tester);
    expect(find.text('COMPLETED'), findsOneWidget);
    expect(find.text('MARK COMPLETE'), findsNothing);
  });

  testWidgets('TEST 5 — failed PUT keeps incomplete state', (tester) async {
    putFails = true;
    await tester.pumpWidget(wrap(topicId));
    await settle(tester);
    await tester.tap(find.text('MARK COMPLETE'));
    await settle(tester);
    expect(find.text('MARK COMPLETE'), findsOneWidget);
    expect(find.text('COMPLETED'), findsNothing);
  });

  testWidgets('TEST 6 — duplicate taps send a single PUT', (tester) async {
    await tester.pumpWidget(wrap(topicId));
    await settle(tester);
    await tester.tap(find.text('MARK COMPLETE'));
    await settle(tester);
    expect(find.text('COMPLETED'), findsOneWidget);
    // The completed control is disabled: further taps are no-ops.
    await tester.tap(find.text('COMPLETED'));
    await settle(tester);
    final putCalls = puts
        .where((p) => p.endsWith('/api/v1/progress/$topicId'))
        .toList();
    expect(putCalls, hasLength(1));
  });

  testWidgets('TEST 7 — QA lesson completes without any quiz', (tester) async {
    await tester.pumpWidget(wrap(qaTopicId));
    await settle(tester);
    expect(find.text('MARK COMPLETE'), findsOneWidget);
    await tester.tap(find.text('MARK COMPLETE'));
    await settle(tester);
    expect(find.text('COMPLETED'), findsOneWidget);
    expect(puts.single.endsWith('/api/v1/progress/$qaTopicId'), isTrue);
  });

  testWidgets('TEST 8 — completion launches no quiz and posts nothing', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(topicId));
    await settle(tester);
    await tester.tap(find.text('MARK COMPLETE'));
    await settle(tester);
    // Still on the lesson; no quiz, submit, or game-result traffic.
    expect(find.text('Training Module'), findsOneWidget);
    expect(posts, isEmpty);
  });

  testWidgets('TEST 9 — no XP/mastery/streak traffic occurs', (tester) async {
    await tester.pumpWidget(wrap(topicId));
    await settle(tester);
    await tester.tap(find.text('MARK COMPLETE'));
    await settle(tester);
    expect(
      puts.every(
        (p) =>
            !p.contains('gamification') &&
            !p.contains('mastery') &&
            !p.contains('streak'),
      ),
      isTrue,
    );
    expect(posts, isEmpty);
  });

  testWidgets('TEST 10 — lesson content behavior intact', (tester) async {
    await tester.pumpWidget(wrap(topicId));
    await settle(tester);
    expect(find.textContaining('First paragraph.'), findsOneWidget);
    expect(find.text('KEY TAKEAWAYS'), findsOneWidget);
    expect(find.text('TAKE THE CHALLENGE'), findsOneWidget);
  });
}
