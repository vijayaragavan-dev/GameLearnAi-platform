import 'model_ids.dart';
import 'content_models.dart' show PathNode;
import 'gamification_models.dart' show StreakState;

/// DASH-001 read model (Dashboard Specification v1.0.0 section 8).
/// All ten top-level sections are ALWAYS present; absence is expressed as
/// null/[]/zeros - never a missing key, never an error.
class Dashboard {
  const Dashboard({
    required this.learner,
    required this.currentSubject,
    required this.mastery,
    required this.gamification,
    required this.streak,
    required this.achievements,
    required this.recommendations,
    required this.learningPath,
    required this.assessment,
    required this.recentActivity,
  });

  final LearnerOverview learner;
  final CurrentSubjectView? currentSubject;
  final MasterySummary mastery;
  final DashGamification gamification;
  final StreakState streak;
  final DashAchievements achievements;
  final List<RecommendationItem> recommendations; // <=3, server-bounded
  final LearningPathCard? learningPath;
  final AssessmentCoverage assessment;
  final RecentActivityView recentActivity;

  factory Dashboard.fromJson(Map<String, dynamic> json) => Dashboard(
    learner: LearnerOverview.fromJson(
      json['learner'] as Map<String, dynamic>? ?? const {},
    ),
    currentSubject: json['currentSubject'] is Map<String, dynamic>
        ? CurrentSubjectView.fromJson(
            json['currentSubject'] as Map<String, dynamic>,
          )
        : null,
    mastery: MasterySummary.fromJson(
      json['mastery'] as Map<String, dynamic>? ?? const {},
    ),
    gamification: DashGamification.fromJson(
      json['gamification'] as Map<String, dynamic>? ?? const {},
    ),
    streak: StreakState.fromJson(
      json['streak'] as Map<String, dynamic>? ?? const {},
    ),
    achievements: DashAchievements.fromJson(
      json['achievements'] as Map<String, dynamic>? ?? const {},
    ),
    recommendations: _list(
      json['recommendations'],
    ).map(RecommendationItem.fromJson).toList(),
    learningPath: json['learningPath'] is Map<String, dynamic>
        ? LearningPathCard.fromJson(
            json['learningPath'] as Map<String, dynamic>,
          )
        : null,
    assessment: AssessmentCoverage.fromJson(
      json['assessment'] as Map<String, dynamic>? ?? const {},
    ),
    recentActivity: RecentActivityView.fromJson(
      json['recentActivity'] as Map<String, dynamic>? ?? const {},
    ),
  );

  static List<Map<String, dynamic>> _list(Object? raw) =>
      raw is List ? raw.whereType<Map<String, dynamic>>().toList() : const [];
}

/// Section 1.
class LearnerOverview {
  const LearnerOverview({
    required this.displayName,
    required this.overallMastery,
    required this.currentSubjectId,
    required this.currentTopicId,
  });

  final String displayName;
  final double overallMastery;
  final String? currentSubjectId;
  final String? currentTopicId;

  factory LearnerOverview.fromJson(Map<String, dynamic> json) =>
      LearnerOverview(
        displayName: json['displayName'] as String? ?? 'Learner',
        overallMastery: (json['overallMastery'] as num?)?.toDouble() ?? 0,
        currentSubjectId: uuidOrNull(json['currentSubjectId']),
        currentTopicId: uuidOrNull(json['currentTopicId']),
      );
}

/// Section 2 inner block.
class DashCurrentTopic {
  const DashCurrentTopic({
    required this.topicId,
    required this.topicName,
    required this.difficulty,
  });

  final String topicId;
  final String topicName;
  final String difficulty;

  factory DashCurrentTopic.fromJson(Map<String, dynamic> json) =>
      DashCurrentTopic(
        topicId: uuidOf(json['topicId'], 'DashCurrentTopic.topicId'),
        topicName: json['topicName'] as String? ?? '',
        difficulty: json['difficulty'] as String? ?? 'EASY',
      );
}

/// Section 2 (nullable at top level).
class CurrentSubjectView {
  const CurrentSubjectView({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.currentTopic,
  });

  final String id;
  final String name;
  final String iconKey;
  final DashCurrentTopic? currentTopic;

  factory CurrentSubjectView.fromJson(Map<String, dynamic> json) =>
      CurrentSubjectView(
        id: uuidOf(json['id'], 'CurrentSubjectView.id'),
        name: json['name'] as String? ?? '',
        iconKey: json['iconKey'] as String? ?? '',
        currentTopic: json['currentTopic'] is Map<String, dynamic>
            ? DashCurrentTopic.fromJson(
                json['currentTopic'] as Map<String, dynamic>,
              )
            : null,
      );
}

/// Section 3 element - verbatim Adaptive-owned columns.
class RecentTopicMastery {
  const RecentTopicMastery({
    required this.topicId,
    required this.topicName,
    required this.masteryScore,
    required this.masteryLevel,
    required this.currentDifficulty,
    required this.trend,
    required this.lastAssessedAt,
  });

  static const RecentTopicMastery empty = RecentTopicMastery(
    topicId: '',
    topicName: '',
    masteryScore: 0,
    masteryLevel: '',
    currentDifficulty: '',
    trend: '',
    lastAssessedAt: null,
  );

  final String topicId;
  final String topicName;
  final double masteryScore;
  final String masteryLevel;
  final String currentDifficulty;
  final String trend;
  final DateTime? lastAssessedAt;

  factory RecentTopicMastery.fromJson(Map<String, dynamic> json) =>
      RecentTopicMastery(
        topicId: uuidOf(json['topicId'], 'RecentTopicMastery.topicId'),
        topicName: json['topicName'] as String? ?? '',
        masteryScore: (json['masteryScore'] as num?)?.toDouble() ?? 0,
        masteryLevel: json['masteryLevel'] as String? ?? '',
        currentDifficulty: json['currentDifficulty'] as String? ?? '',
        trend: json['trend'] as String? ?? '',
        lastAssessedAt: json['lastAssessedAt'] is String
            ? DateTime.tryParse(json['lastAssessedAt'] as String)?.toUtc()
            : null,
      );
}

/// Section 3.
class MasterySummary {
  const MasterySummary({
    required this.topicsAssessed,
    required this.topicsMastered,
    required this.recentTopics,
  });

  final int topicsAssessed;
  final int topicsMastered;
  final List<RecentTopicMastery> recentTopics; // <=5

  factory MasterySummary.fromJson(Map<String, dynamic> json) => MasterySummary(
    topicsAssessed: (json['topicsAssessed'] as num?)?.toInt() ?? 0,
    topicsMastered: (json['topicsMastered'] as num?)?.toInt() ?? 0,
    recentTopics: Dashboard._list(
      json['recentTopics'],
    ).map(RecentTopicMastery.fromJson).toList(),
  );
}

/// Section 4 - byte-equivalent to GAM-001 level fields (subset).
class DashGamification {
  const DashGamification({
    required this.totalXp,
    required this.currentLevel,
    required this.maxLevel,
    required this.nextLevelThresholdXp,
    required this.xpToNextLevel,
  });

  final int totalXp;
  final int currentLevel;
  final int maxLevel;
  final int? nextLevelThresholdXp;
  final int? xpToNextLevel;

  bool get atMaxLevel => nextLevelThresholdXp == null || xpToNextLevel == null;

  factory DashGamification.fromJson(Map<String, dynamic> json) =>
      DashGamification(
        totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
        currentLevel: (json['currentLevel'] as num?)?.toInt() ?? 1,
        maxLevel: (json['maxLevel'] as num?)?.toInt() ?? 50,
        nextLevelThresholdXp: (json['nextLevelThresholdXp'] as num?)?.toInt(),
        xpToNextLevel: (json['xpToNextLevel'] as num?)?.toInt(),
      );
}

/// Section 6 element.
class RecentAchievementUnlock {
  const RecentAchievementUnlock({
    required this.code,
    required this.name,
    required this.iconKey,
    required this.unlockedAt,
  });

  final String code;
  final String name;
  final String iconKey;
  final DateTime unlockedAt;

  factory RecentAchievementUnlock.fromJson(Map<String, dynamic> json) =>
      RecentAchievementUnlock(
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        iconKey: json['iconKey'] as String? ?? '',
        unlockedAt: json['unlockedAt'] is String
            ? DateTime.tryParse(json['unlockedAt'] as String)?.toUtc() ??
                  DateTime.utc(1970)
            : DateTime.utc(1970),
      );
}

/// Section 6.
class DashAchievements {
  const DashAchievements({
    required this.unlockedCount,
    required this.recentUnlocks,
  });

  final int unlockedCount;
  final List<RecentAchievementUnlock> recentUnlocks; // <=5

  factory DashAchievements.fromJson(Map<String, dynamic> json) =>
      DashAchievements(
        unlockedCount: (json['unlockedCount'] as num?)?.toInt() ?? 0,
        recentUnlocks: Dashboard._list(
          json['recentUnlocks'],
        ).map(RecentAchievementUnlock.fromJson).toList(),
      );
}

/// Section 7 element. topicId/topicName defensively nullable per contract.
class RecommendationItem {
  const RecommendationItem({
    required this.topicId,
    required this.topicName,
    required this.activityType,
    required this.recommendedDifficulty,
    required this.priority,
    required this.reason,
    required this.generatedAt,
  });

  final String? topicId;
  final String? topicName;
  final String
  activityType; // CONTINUE_LESSON|PRACTICE|REVIEW|QUIZ|REMEDIATION|ADVANCE
  final String recommendedDifficulty;
  final int priority;
  final String reason;
  final DateTime? generatedAt;

  factory RecommendationItem.fromJson(Map<String, dynamic> json) =>
      RecommendationItem(
        topicId: uuidOrNull(json['topicId']),
        topicName: json['topicName'] as String?,
        activityType: json['activityType'] as String? ?? '',
        recommendedDifficulty: json['recommendedDifficulty'] as String? ?? '',
        priority: (json['priority'] as num?)?.toInt() ?? 0,
        reason: json['reason'] as String? ?? '',
        generatedAt: json['generatedAt'] is String
            ? DateTime.tryParse(json['generatedAt'] as String)?.toUtc()
            : null,
      );
}

/// Section 8 (nullable). Nodes mirror PATH-001 node shape.
class LearningPathCard {
  const LearningPathCard({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.title,
    required this.status,
    required this.generatedBy,
    required this.createdAt,
    required this.nodes,
  });

  final String id;
  final String subjectId;
  final String subjectName;
  final String title;
  final String status;
  final String generatedBy;
  final DateTime? createdAt;
  final List<PathNode> nodes;

  factory LearningPathCard.fromJson(Map<String, dynamic> json) =>
      LearningPathCard(
        id: uuidOf(json['id'], 'LearningPathCard.id'),
        subjectId: uuidOf(json['subjectId'], 'LearningPathCard.subjectId'),
        subjectName: json['subjectName'] as String? ?? '',
        title: json['title'] as String? ?? '',
        status: json['status'] as String? ?? 'ACTIVE',
        generatedBy: json['generatedBy'] as String? ?? 'SYSTEM',
        createdAt: json['createdAt'] is String
            ? DateTime.tryParse(json['createdAt'] as String)?.toUtc()
            : null,
        nodes: Dashboard._list(json['nodes']).map(PathNode.fromJson).toList(),
      );
}

/// Section 9 element.
class AssessedSubjectRef {
  const AssessedSubjectRef({
    required this.subjectId,
    required this.subjectName,
  });

  final String subjectId;
  final String subjectName;

  factory AssessedSubjectRef.fromJson(Map<String, dynamic> json) =>
      AssessedSubjectRef(
        subjectId: uuidOf(json['subjectId'], 'AssessedSubjectRef.subjectId'),
        subjectName: json['subjectName'] as String? ?? '',
      );
}

/// Section 9.
class AssessmentCoverage {
  const AssessmentCoverage({required this.assessedSubjects});

  final List<AssessedSubjectRef> assessedSubjects;

  factory AssessmentCoverage.fromJson(Map<String, dynamic> json) =>
      AssessmentCoverage(
        assessedSubjects: Dashboard._list(
          json['assessedSubjects'],
        ).map(AssessedSubjectRef.fromJson).toList(),
      );
}

/// Section 10 element - COMPLETED quiz attempts only.
class RecentQuizRun {
  const RecentQuizRun({
    required this.quizAttemptId,
    required this.topicId,
    required this.topicName,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.submittedAt,
  });

  final String quizAttemptId;
  final String topicId;
  final String topicName;
  final double score;
  final int correctCount;
  final int totalQuestions;
  final DateTime submittedAt;

  factory RecentQuizRun.fromJson(Map<String, dynamic> json) => RecentQuizRun(
    quizAttemptId: uuidOf(json['quizAttemptId'], 'RecentQuizRun.quizAttemptId'),
    topicId: uuidOf(json['topicId'], 'RecentQuizRun.topicId'),
    topicName: json['topicName'] as String? ?? '',
    score: (json['score'] as num?)?.toDouble() ?? 0,
    correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
    totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
    submittedAt: json['submittedAt'] is String
        ? DateTime.tryParse(json['submittedAt'] as String)?.toUtc() ??
              DateTime.utc(1970)
        : DateTime.utc(1970),
  );
}

/// Section 10.
class RecentActivityView {
  const RecentActivityView({required this.quizzes});

  final List<RecentQuizRun> quizzes; // <=5

  factory RecentActivityView.fromJson(Map<String, dynamic> json) =>
      RecentActivityView(
        quizzes: Dashboard._list(
          json['quizzes'],
        ).map(RecentQuizRun.fromJson).toList(),
      );
}
