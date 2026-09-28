import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gamelearn_app/core/audio/audio_manager.dart';
import 'package:gamelearn_app/core/network/api_client.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/core/storage/token_storage.dart';

/// Deterministic contract fixtures mirroring GameLearn_AI_API_Contract v1.4.0.
abstract final class Fixtures {
  static Map<String, dynamic> authSession({
    String email = 'nova@example.com',
    String displayName = 'Nova Player',
  }) => {
    'token': 'test-token-abc',
    'tokenType': 'Bearer',
    'expiresInSeconds': 3600,
    'user': {
      'id': '9a111111-1111-1111-1111-111111111101',
      'email': email,
      'displayName': displayName,
    },
  };

  static List<Map<String, dynamic>> subjects() => [
    {
      'id': '11111111-1111-1111-1111-111111111101',
      'name': 'Programming',
      'description': null,
      'iconKey': 'subject_programming',
      'isActive': true,
      'displayOrder': 1,
    },
    {
      'id': '11111111-1111-1111-1111-111111111102',
      'name': 'Computer Networks',
      'description': 'Packets, routing and the web.',
      'iconKey': 'subject_networks',
      'isActive': true,
      'displayOrder': 2,
    },
  ];

  static Map<String, dynamic> learningPath() => {
    'id': '0b6f1111-1111-1111-1111-111111111101',
    'subjectId': '11111111-1111-1111-1111-111111111101',
    'title': 'Programming Foundations Sprint',
    'description': 'A plan tuned to your mastery profile.',
    'status': 'ACTIVE',
    'generatedBy': 'AI',
    'createdAt': '2026-08-23T12:00:00Z',
    'updatedAt': '2026-08-23T12:00:00Z',
    'nodes': [
      {
        'id': 'n1',
        'topicId': 't1',
        'topicName': 'Variables & Types',
        'sequenceNumber': 1,
        'requiredMastery': 0,
        'status': 'COMPLETED',
      },
      {
        'id': 'n2',
        'topicId': 't2',
        'topicName': 'Control Flow',
        'sequenceNumber': 2,
        'requiredMastery': 40.0,
        'status': 'AVAILABLE',
      },
      {
        'id': 'n3',
        'topicId': 't3',
        'topicName': 'Functions',
        'sequenceNumber': 3,
        'requiredMastery': 60.0,
        'status': 'LOCKED',
      },
    ],
    'aiMetadata': {
      'nodes': [
        {
          'sequenceNumber': 2,
          'objective': 'Apply branching logic.',
          'rationale': 'Foundations complete.',
        },
      ],
    },
  };

  static Map<String, dynamic> quiz() => {
    'id': 'q1111111-1111-1111-1111-111111111101',
    'topicId': 't2',
    'title': 'Control Flow Challenge',
    'description': 'Prove your branching knowledge',
    'difficulty': 'MEDIUM',
    'timeLimitSeconds': null,
    'questionCount': 2,
    'questions': [
      {
        'id': 'qq1',
        'questionText': 'Which keyword declares a constant?',
        'options': ['const', 'let', 'var'],
        'difficulty': 'EASY',
      },
      {
        'id': 'qq2',
        'questionText': 'What does a loop require?',
        'options': ['condition', 'magic'],
        'difficulty': 'EASY',
      },
    ],
  };

  static Map<String, dynamic> quizResult() => {
    'attemptId': 'aaaa1111-1111-1111-1111-111111111101',
    'quizId': 'q1111111-1111-1111-1111-111111111101',
    'status': 'COMPLETED',
    'score': 50.00,
    'correctCount': 1,
    'totalQuestions': 2,
    'durationSeconds': 42,
    'results': [
      {
        'questionId': 'qq1',
        'selectedAnswer': 'const',
        'isCorrect': true,
        'correctAnswer': 'const',
        'explanation': 'const declares an immutable binding.',
      },
      {
        'questionId': 'qq2',
        'selectedAnswer': 'magic',
        'isCorrect': false,
        'correctAnswer': 'condition',
        'explanation': 'Loops repeat while their condition holds.',
      },
    ],
    'adaptive': {
      'topicId': 't2',
      'masteryScore': 45.50,
      'previousMasteryScore': 40.00,
      'masteryLevel': 'DEVELOPING',
      'trend': 'IMPROVING',
      'nextDifficulty': 'MEDIUM',
      'recommendedActivity': 'PRACTICE',
      'reasonCode': 'MASTERY_GAP',
    },
  };

  static Map<String, dynamic> gamificationSummary({
    int totalXp = 325,
    int level = 3,
    int? xpToNext = 276,
  }) => {
    'totalXp': totalXp,
    'currentLevel': level,
    'maxLevel': 50,
    'nextLevelThresholdXp': xpToNext == null ? null : totalXp + xpToNext,
    'xpToNextLevel': xpToNext,
    'currentStreakDays': 3,
    'longestStreakDays': 5,
    'achievementCount': 2,
  };

  static List<Map<String, dynamic>> achievements() => [
    {
      'code': 'FIRST_QUIZ',
      'name': 'First Steps',
      'description': 'Complete your first quiz.',
      'iconKey': 'ach_first_quiz',
      'xpReward': 20,
      'unlockedAt': '2026-08-24T10:15:07Z',
    },
    {
      'code': 'WEEK_WARRIOR',
      'name': 'Week Warrior',
      'description': 'Maintain a 7-day learning streak.',
      'iconKey': 'ach_week_warrior',
      'xpReward': 60,
      'unlockedAt': null,
    },
  ];

  static Map<String, dynamic> streak() => {
    'currentStreakDays': 3,
    'longestStreakDays': 5,
    'lastLearningDate': '2026-08-24',
    'timezone': 'UTC',
  };

  /// Full DASH-001 zero-state per Dashboard Specification section 23.1.
  static Map<String, dynamic> dashboardZeroState() => {
    'learner': {
      'displayName': 'Nova Player',
      'overallMastery': 0.00,
      'currentSubjectId': null,
      'currentTopicId': null,
    },
    'currentSubject': null,
    'mastery': {'topicsAssessed': 0, 'topicsMastered': 0, 'recentTopics': []},
    'gamification': {
      'totalXp': 0,
      'currentLevel': 1,
      'maxLevel': 50,
      'nextLevelThresholdXp': 100,
      'xpToNextLevel': 100,
    },
    'streak': {
      'currentStreakDays': 0,
      'longestStreakDays': 0,
      'lastLearningDate': null,
      'timezone': 'UTC',
    },
    'achievements': {'unlockedCount': 0, 'recentUnlocks': []},
    'recommendations': [],
    'learningPath': null,
    'assessment': {'assessedSubjects': []},
    'recentActivity': {'quizzes': []},
  };

  static Map<String, dynamic> assessmentDelivery() => {
    'subjectId': '11111111-1111-1111-1111-111111111101',
    'questions': [
      {
        'questionId': 'aq1',
        'topicId': 't1',
        'questionText': 'Which keyword declares a constant?',
        'options': ['const', 'let', 'var'],
        'difficulty': 'EASY',
      },
      {
        'questionId': 'aq2',
        'topicId': 't2',
        'questionText': 'Pick the loop keyword',
        'options': ['for', 'forever'],
        'difficulty': 'EASY',
      },
    ],
  };
}

class FakeTokenStorage implements TokenStorage {
  String? stored;

  @override
  Future<void> clear() async => stored = null;

  @override
  Future<String?> read() async => stored;

  @override
  Future<void> write(String token) async => stored = token;
}

/// Builds a route-table driven fake backend speaking the real contract.
ProviderContainer testContainer({
  required Map<String, dynamic> Function(http.Request request) handler,
}) {
  final client = MockClient((request) async {
    final result = handler(request);
    final status = (result['status'] as num?)?.toInt() ?? 200;
    Object? body = result['body'];
    if (body is Map && !body.containsKey('errorCode')) {
      body = jsonEncode(body);
    } else if (body is List) {
      body = jsonEncode(body);
    }
    return http.Response(
      body?.toString() ?? '',
      status,
      headers: {'content-type': 'application/json'},
    );
  });

  return ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
      apiClientProvider.overrideWith((ref) => ApiClient(client: client)),
      audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
    ],
  );
}

/// Builds a ProviderScope wired to the fake backend for pumping real screens.
Widget fakeScope({
  required Widget child,
  required Map<String, dynamic> Function(http.Request request) handler,
}) {
  final client = MockClient((request) async {
    final result = handler(request);
    final status = (result['status'] as num?)?.toInt() ?? 200;
    Object? body = result['body'];
    if (body is Map || body is List) body = jsonEncode(body);
    return http.Response(
      body?.toString() ?? '',
      status,
      headers: {'content-type': 'application/json'},
    );
  });
  return ProviderScope(
    overrides: [
      tokenStorageProvider.overrideWithValue(
        FakeTokenStorage()..stored = 'tok',
      ),
      apiClientProvider.overrideWith((ref) => ApiClient(client: client)),
      audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
    ],
    child: child,
  );
}

/// Test double: exercises UI flows without touching audio plugins.
class SilentAudioManager extends AudioManager {
  @override
  Future<void> play(Sfx sfx) async {}

  @override
  Future<void> playContext(MusicContext context) async {}

  @override
  Future<void> stopMusic() async {}
}
