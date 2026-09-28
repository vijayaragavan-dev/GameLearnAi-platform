import 'model_ids.dart';

/// GAM-001 response. Next-level fields are null at max level.
class GamificationSummary {
  const GamificationSummary({
    required this.totalXp,
    required this.currentLevel,
    required this.maxLevel,
    required this.nextLevelThresholdXp,
    required this.xpToNextLevel,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.unlockedAchievements,
  });

  final int totalXp;
  final int currentLevel;
  final int maxLevel;
  final int? nextLevelThresholdXp;
  final int? xpToNextLevel;
  final int currentStreakDays;
  final int longestStreakDays;
  final int unlockedAchievements;

  bool get atMaxLevel => nextLevelThresholdXp == null || xpToNextLevel == null;

  /// Progress toward the next level, derived ONLY from server fields
  /// (currentXp within level is not exposed; we render xpToNextLevel as the
  /// remaining distance and animate on change instead of fabricating a ratio).
  factory GamificationSummary.fromJson(Map<String, dynamic> json) =>
      GamificationSummary(
        totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
        currentLevel: (json['currentLevel'] as num?)?.toInt() ?? 1,
        maxLevel: (json['maxLevel'] as num?)?.toInt() ?? 50,
        nextLevelThresholdXp: (json['nextLevelThresholdXp'] as num?)?.toInt(),
        xpToNextLevel: (json['xpToNextLevel'] as num?)?.toInt(),
        currentStreakDays: (json['currentStreakDays'] as num?)?.toInt() ?? 0,
        longestStreakDays: (json['longestStreakDays'] as num?)?.toInt() ?? 0,
        unlockedAchievements: (json['achievementCount'] as num?)?.toInt() ?? 0,
      );
}

/// GAM-002 element. unlockedAt == null means locked.
class Achievement {
  const Achievement({
    required this.code,
    required this.name,
    required this.description,
    required this.iconKey,
    required this.xpReward,
    required this.unlockedAt,
  });

  final String code;
  final String name;
  final String description;
  final String iconKey;
  final int xpReward;
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    code: json['code'] as String? ?? '',
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    iconKey: json['iconKey'] as String? ?? '',
    xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
    unlockedAt: json['unlockedAt'] is String
        ? DateTime.tryParse(json['unlockedAt'] as String)?.toUtc()
        : null,
  );
}

/// GAM-003 response. lastLearningDate is a local-date string (YYYY-MM-DD).
class StreakState {
  const StreakState({
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.lastLearningDate,
    required this.timezone,
  });

  final int currentStreakDays;
  final int longestStreakDays;
  final DateTime? lastLearningDate; // date-only semantics
  final String timezone;

  factory StreakState.fromJson(Map<String, dynamic> json) => StreakState(
    currentStreakDays: (json['currentStreakDays'] as num?)?.toInt() ?? 0,
    longestStreakDays: (json['longestStreakDays'] as num?)?.toInt() ?? 0,
    lastLearningDate: json['lastLearningDate'] is String
        ? DateTime.tryParse(json['lastLearningDate'] as String)
        : null,
    timezone: json['timezone'] as String? ?? 'UTC',
  );
}

/// USER-001 profile response.
class LearnerProfile {
  const LearnerProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.currentLevel,
    required this.totalXp,
    required this.overallMastery,
    required this.currentSubjectId,
    required this.currentTopicId,
  });

  final String id;
  final String email;
  final String displayName;
  final int currentLevel;
  final int totalXp;
  final double overallMastery;
  final String? currentSubjectId;
  final String? currentTopicId;

  factory LearnerProfile.fromJson(Map<String, dynamic> json) => LearnerProfile(
    id: uuidOf(json['id'], 'LearnerProfile.id'),
    email: json['email'] as String? ?? '',
    displayName: json['displayName'] as String? ?? 'Learner',
    currentLevel: (json['currentLevel'] as num?)?.toInt() ?? 1,
    totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
    overallMastery: (json['overallMastery'] as num?)?.toDouble() ?? 0,
    currentSubjectId: json['currentSubjectId'] is String
        ? json['currentSubjectId'] as String
        : null,
    currentTopicId: json['currentTopicId'] is String
        ? json['currentTopicId'] as String
        : null,
  );
}

/// PROG-001/002 element.
class TopicProgress {
  const TopicProgress({
    required this.id,
    required this.topicId,
    required this.learningPathNodeId,
    required this.completionPercentage,
    required this.status,
    required this.lastActivityAt,
    required this.completedAt,
  });

  final String id;
  final String topicId;
  final String? learningPathNodeId;
  final double completionPercentage;
  final String status;
  final DateTime? lastActivityAt;
  final DateTime? completedAt;

  factory TopicProgress.fromJson(Map<String, dynamic> json) => TopicProgress(
    id: uuidOf(json['id'], 'TopicProgress.id'),
    topicId: uuidOf(json['topicId'], 'TopicProgress.topicId'),
    learningPathNodeId: json['learningPathNodeId'] is String
        ? json['learningPathNodeId'] as String
        : null,
    completionPercentage:
        (json['completionPercentage'] as num?)?.toDouble() ?? 0,
    status: json['status'] as String? ?? 'NOT_STARTED',
    lastActivityAt: json['lastActivityAt'] is String
        ? DateTime.tryParse(json['lastActivityAt'] as String)?.toUtc()
        : null,
    completedAt: json['completedAt'] is String
        ? DateTime.tryParse(json['completedAt'] as String)?.toUtc()
        : null,
  );
}
