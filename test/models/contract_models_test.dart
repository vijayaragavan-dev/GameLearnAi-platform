import 'package:flutter_test/flutter_test.dart';

import 'package:gamelearn_app/core/models/assessment_models.dart';
import 'package:gamelearn_app/core/models/auth_models.dart';
import 'package:gamelearn_app/core/models/content_models.dart';
import 'package:gamelearn_app/core/models/dashboard_models.dart';
import 'package:gamelearn_app/core/models/gamification_models.dart';
import 'package:gamelearn_app/core/models/quiz_models.dart';
import 'package:gamelearn_app/core/models/tutor_models.dart';

void main() {
  group('AuthSession', () {
    test('parses the contract shape', () {
      final s = AuthSession.fromJson({
        'token': 'jwt-value',
        'tokenType': 'Bearer',
        'expiresInSeconds': 1800,
        'user': {
          'id': '9a111111-1111-1111-1111-111111111101',
          'email': 'a@b.co',
          'displayName': 'Ada',
        },
      });
      expect(s.token, 'jwt-value');
      expect(s.user.displayName, 'Ada');
      expect(s.expiresInSeconds, 1800);
    });

    test('throws on missing token', () {
      expect(
        () => AuthSession.fromJson({
          'user': {'id': 'x', 'email': '', 'displayName': ''},
        }),
        throwsFormatException,
      );
    });
  });

  group('LearningPath', () {
    test('parses PATH-002 generated shape with aiMetadata', () {
      final p = LearningPath.fromJson({
        ...{
          'id': '0b6f',
          'subjectId': 's1',
          'title': 'Sprint',
          'description': 'd',
          'status': 'ACTIVE',
          'generatedBy': 'AI',
          'createdAt': '2026-08-23T12:00:00Z',
          'updatedAt': '2026-08-23T12:00:00Z',
          'nodes': [
            {
              'id': 'n1',
              'topicId': 't1',
              'topicName': 'Variables',
              'sequenceNumber': 1,
              'requiredMastery': 0,
              'status': 'AVAILABLE',
            },
          ],
        },
      });
      expect(p.nodes.single.status, 'AVAILABLE');
      final meta = p.aiMetadataFrom({
        'nodes': [
          {
            'sequenceNumber': 1,
            'objective': 'Declare vars.',
            'rationale': 'Start.',
          },
        ],
      });
      expect(meta[1]!.objective, 'Declare vars.');
    });

    test('aiMetadata absent -> empty map (never fabricated)', () {
      final p = LearningPath.fromJson({
        'id': 'p',
        'subjectId': 's',
        'title': '',
        'description': '',
        'status': 'ACTIVE',
        'generatedBy': 'SYSTEM',
        'nodes': [],
      });
      expect(p.aiMetadataFrom(null), isEmpty);
    });
  });

  group('QuizResult', () {
    test('parses score, review and adaptive block', () {
      final r = QuizResult.fromJson({
        'attemptId': 'a1',
        'quizId': 'q1',
        'status': 'COMPLETED',
        'score': 66.67,
        'correctCount': 2,
        'totalQuestions': 3,
        'durationSeconds': null,
        'results': [
          {
            'questionId': 'qq1',
            'selectedAnswer': 'A',
            'isCorrect': true,
            'correctAnswer': 'A',
            'explanation': 'e',
          },
        ],
        'adaptive': {
          'topicId': 't1',
          'masteryScore': 55.5,
          'previousMasteryScore': null,
          'masteryLevel': 'DEVELOPING',
          'trend': 'STABLE',
          'nextDifficulty': 'MEDIUM',
          'recommendedActivity': 'REVIEW',
          'reasonCode': 'RC',
        },
      });
      expect(r.score, closeTo(66.67, 0.001));
      expect(r.durationSeconds, isNull);
      expect(r.adaptive!.recommendedActivity, 'REVIEW');
      expect(r.results.single.isCorrect, isTrue);
    });
  });

  group('AssessmentOutcome', () {
    test('assessed=false with empty topics is valid', () {
      final o = AssessmentOutcome.fromJson({
        'subjectId': 's1',
        'assessed': false,
        'overallMastery': 12.25,
        'topics': [],
      });
      expect(o.assessed, isFalse);
      expect(o.topics, isEmpty);
    });

    test('delivery never carries correct answers field', () {
      final d = AssessmentDelivery.fromJson({
        'subjectId': 's1',
        'questions': [
          {
            'questionId': 'q',
            'topicId': 't',
            'questionText': '?',
            'options': ['a'],
            'difficulty': 'EASY',
          },
        ],
      });
      expect(d.questions.single.questionId, 'q');
    });
  });

  group('GamificationSummary', () {
    test('max level has null next-level fields', () {
      final g = GamificationSummary.fromJson({
        'totalXp': 999999,
        'currentLevel': 50,
        'maxLevel': 50,
        'nextLevelThresholdXp': null,
        'xpToNextLevel': null,
        'currentStreakDays': 9,
        'longestStreakDays': 9,
        'achievementCount': 6,
      });
      expect(g.atMaxLevel, isTrue);
    });

    test('mid-level values parse', () {
      final g = GamificationSummary.fromJson({
        'totalXp': 325,
        'currentLevel': 3,
        'maxLevel': 50,
        'nextLevelThresholdXp': 600,
        'xpToNextLevel': 276,
        'currentStreakDays': 3,
        'longestStreakDays': 5,
        'achievementCount': 2,
      });
      expect(g.atMaxLevel, isFalse);
      expect(g.unlockedAchievements, 2);
    });
  });

  group('Achievement', () {
    test('unlockedAt null means locked', () {
      final a = Achievement.fromJson({
        'code': 'WEEK_WARRIOR',
        'name': 'Week Warrior',
        'description': 'd',
        'iconKey': 'ach_week_warrior',
        'xpReward': 60,
        'unlockedAt': null,
      });
      expect(a.isUnlocked, isFalse);
    });
  });

  group('Dashboard', () {
    test('zero state parses every section', () {
      final d = Dashboard.fromJson(_zeroState());
      expect(d.learner.displayName, 'Nova Player');
      expect(d.currentSubject, isNull);
      expect(d.mastery.recentTopics, isEmpty);
      expect(d.gamification.totalXp, 0);
      expect(d.gamification.currentLevel, 1);
      expect(d.streak.timezone, 'UTC');
      expect(d.achievements.recentUnlocks, isEmpty);
      expect(d.recommendations, isEmpty);
      expect(d.learningPath, isNull);
      expect(d.assessment.assessedSubjects, isEmpty);
      expect(d.recentActivity.quizzes, isEmpty);
    });

    test('active learner parses recommendations and path card', () {
      final d = Dashboard.fromJson(_activeState());
      expect(d.recommendations.length, 1);
      expect(d.recommendations.first.activityType, 'QUIZ');
      expect(d.learningPath!.subjectName, 'Programming');
      expect(d.learningPath!.nodes.first.status, 'COMPLETED');
      expect(d.currentSubject!.name, 'Programming');
      expect(d.currentSubject!.currentTopic!.topicName, 'Control Flow');
    });
  });

  group('TutorModels', () {
    test('request serializes only provided fields', () {
      final r = const TutorRequest(question: 'What is a subnet?').toJson();
      expect(r.containsKey('conversation'), isFalse);
      expect(r.containsKey('topicId'), isFalse);

      final full = const TutorRequest(
        question: 'q',
        subjectId: 's1',
        topicId: 't1',
        conversation: [TutorMessage(role: 'LEARNER', content: 'hi')],
      ).toJson();
      expect((full['conversation'] as List).length, 1);
    });

    test('response parses refused/degraded flags', () {
      final r = TutorResponse.fromJson({
        'answer': 'template text',
        'refused': true,
        'degraded': false,
        'context': {'subjectId': null, 'topicName': 'Control Flow'},
      });
      expect(r.refused, isTrue);
      expect(r.context!.topicName, 'Control Flow');
      expect(r.context!.subjectId, isNull);
    });
  });
}

Map<String, dynamic> _zeroState() => {
  'learner': {
    'displayName': 'Nova Player',
    'overallMastery': 0,
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

Map<String, dynamic> _activeState() => {
  'learner': {
    'displayName': 'Ada Lovelace',
    'overallMastery': 62.50,
    'currentSubjectId': '11111111-1111-1111-1111-111111111101',
    'currentTopicId': '22222222-2222-2222-2222-222222222202',
  },
  'currentSubject': {
    'id': '11111111-1111-1111-1111-111111111101',
    'name': 'Programming',
    'iconKey': 'subject_programming',
    'currentTopic': {
      'topicId': '22222222-2222-2222-2222-222222222202',
      'topicName': 'Control Flow',
      'difficulty': 'MEDIUM',
    },
  },
  'mastery': {
    'topicsAssessed': 4,
    'topicsMastered': 1,
    'recentTopics': [
      {
        'topicId': '22222222-2222-2222-2222-222222222201',
        'topicName': 'Variables & Types',
        'masteryScore': 82.00,
        'masteryLevel': 'PROFICIENT',
        'currentDifficulty': 'MEDIUM',
        'trend': 'IMPROVING',
        'lastAssessedAt': '2026-08-24T09:30:00Z',
      },
    ],
  },
  'gamification': {
    'totalXp': 325,
    'currentLevel': 3,
    'maxLevel': 50,
    'nextLevelThresholdXp': 600,
    'xpToNextLevel': 276,
  },
  'streak': {
    'currentStreakDays': 7,
    'longestStreakDays': 9,
    'lastLearningDate': '2026-08-24',
    'timezone': 'UTC',
  },
  'achievements': {
    'unlockedCount': 2,
    'recentUnlocks': [
      {
        'code': 'FIRST_QUIZ',
        'name': 'First Steps',
        'iconKey': 'ach_first_quiz',
        'unlockedAt': '2026-08-24T10:15:07Z',
      },
    ],
  },
  'recommendations': [
    {
      'topicId': '22222222-2222-2222-2222-222222222202',
      'topicName': 'Control Flow',
      'activityType': 'QUIZ',
      'recommendedDifficulty': 'MEDIUM',
      'priority': 1,
      'reason': 'You are ready for a challenge on this topic.',
      'generatedAt': '2026-08-24T09:30:05Z',
    },
  ],
  'learningPath': {
    'id': '33333333-3333-3333-3333-333333333301',
    'subjectId': '11111111-1111-1111-1111-111111111101',
    'subjectName': 'Programming',
    'title': 'Programming Foundations Sprint',
    'status': 'ACTIVE',
    'generatedBy': 'AI',
    'createdAt': '2026-08-20T08:00:00Z',
    'nodes': [
      {
        'id': 'n1',
        'topicId': '22222222-2222-2222-2222-222222222201',
        'topicName': 'Variables & Types',
        'sequenceNumber': 1,
        'requiredMastery': 0,
        'status': 'COMPLETED',
      },
    ],
  },
  'assessment': {
    'assessedSubjects': [
      {
        'subjectId': '11111111-1111-1111-1111-111111111101',
        'subjectName': 'Programming',
      },
    ],
  },
  'recentActivity': {
    'quizzes': [
      {
        'quizAttemptId': '44444444-4444-4444-4444-444444444401',
        'topicId': '22222222-2222-2222-2222-222222222201',
        'topicName': 'Variables & Types',
        'score': 75.00,
        'correctCount': 3,
        'totalQuestions': 4,
        'submittedAt': '2026-08-24T09:31:00Z',
      },
    ],
  },
};
