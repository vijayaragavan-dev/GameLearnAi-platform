import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:gamelearn_app/core/network/api_exception.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/auth/data/auth_repository.dart';
import 'package:gamelearn_app/features/learning/data/content_repository.dart';
import 'package:gamelearn_app/features/challenge/data/quiz_repository.dart';
import 'package:gamelearn_app/features/challenge/data/assessment_repository.dart';

import '../helpers/fake_backend.dart';

void main() {
  test('login posts credentials and returns session', () async {
    http.Request? captured;
    final container = testContainer(
      handler: (request) {
        captured = request;
        return {'body': Fixtures.authSession()};
      },
    );
    addTearDown(container.dispose);

    final repo = AuthRepository(container.read(apiClientProvider));
    final session = await repo.login('a@b.co', 'secret123');

    expect(captured!.url.path, '/api/v1/auth/login');
    final sent = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(sent['email'], 'a@b.co');
    expect(sent['password'], 'secret123');
    expect(session.user.displayName, 'Nova Player');
  });

  test('register posts all three fields', () async {
    http.Request? captured;
    final container = testContainer(
      handler: (request) {
        captured = request;
        return {'status': 201, 'body': Fixtures.authSession()};
      },
    );
    addTearDown(container.dispose);

    await AuthRepository(
      container.read(apiClientProvider),
    ).register('a@b.co', 'password1', 'Ada');
    final sent = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(sent['displayName'], 'Ada');
  });

  test('quiz submit sends questionId+selectedAnswer only', () async {
    http.Request? captured;
    final container = testContainer(
      handler: (request) {
        captured = request;
        return {'status': 201, 'body': Fixtures.quizResult()};
      },
    );
    addTearDown(container.dispose);

    final result = await QuizRepository(
      container.read(apiClientProvider),
    ).submit('quiz-1', const [(questionId: 'qq1', selectedAnswer: 'const')]);

    expect(captured!.url.path, '/api/v1/quiz/quiz-1/submit');
    final sent = jsonDecode(captured!.body);
    expect(sent['answers'][0]['questionId'], 'qq1');
    expect(sent['answers'][0]['selectedAnswer'], 'const');
    expect(result.adaptive!.recommendedActivity, 'PRACTICE');
  });

  test('assessment submit surfaces R-GUARD 409 as ConflictException', () async {
    final container = testContainer(
      handler: (request) => {
        'status': 409,
        'body': {
          'status': 409,
          'errorCode': 'DATA_CONFLICT',
          'message': 'assessment baseline already established',
        },
      },
    );
    addTearDown(container.dispose);

    await expectLater(
      AssessmentRepository(
        container.read(apiClientProvider),
      ).submit('s1', const [(questionId: 'aq1', selectedAnswer: 'const')]),
      throwsA(isA<ConflictException>()),
    );
  });

  test('PATH-002 generate returns path + aiMetadata', () async {
    final container = testContainer(
      handler: (request) {
        expect(
          request.url.path,
          '/api/v1/learning-path/11111111-1111-1111-1111-111111111101/generate',
        );
        return {'status': 201, 'body': Fixtures.learningPath()};
      },
    );
    addTearDown(container.dispose);

    final r = await ContentRepository(container.read(apiClientProvider))
        .generatePath(
          subjectId: '11111111-1111-1111-1111-111111111101',
          learningGoal: 'master loops',
        );
    expect(r.path.generatedBy, 'AI');
    expect(r.aiMetadata[2]!.rationale, 'Foundations complete.');
  });

  test('subjects list parses', () async {
    final container = testContainer(
      handler: (request) => {'body': Fixtures.subjects()},
    );
    addTearDown(container.dispose);

    final subjects = await ContentRepository(
      container.read(apiClientProvider),
    ).subjects();
    expect(subjects.length, 2);
    expect(subjects[0].iconKey, 'subject_programming');
  });
}
