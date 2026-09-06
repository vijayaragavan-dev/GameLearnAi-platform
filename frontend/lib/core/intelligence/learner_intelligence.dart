import '../../core/models/dashboard_models.dart';
import '../theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Learner intelligence derived from real Dashboard data — no fake analytics.
class LearnerIntelligence {
  const LearnerIntelligence({
    required this.overallMastery,
    required this.topicsAssessed,
    required this.topicsMastered,
    required this.recentTopics,
    required this.weakTopics,
    required this.strongTopics,
    required this.trend,
    required this.insufficientData,
    required this.revisionQueue,
    required this.nextDifficulty,
    required this.recommendedGames,
    required this.mistakes,
  });

  final double overallMastery;
  final int topicsAssessed;
  final int topicsMastered;
  final List<RecentTopicMastery> recentTopics;
  final List<RecentTopicMastery> weakTopics;
  final List<RecentTopicMastery> strongTopics;
  final String trend; // overall trend derived
  final bool insufficientData;
  final List<RecentTopicMastery> revisionQueue;
  final String nextDifficulty;
  final List<RecommendedGameRef> recommendedGames;
  final List<MistakeInsight> mistakes;

  static LearnerIntelligence empty() => const LearnerIntelligence(
        overallMastery: 0,
        topicsAssessed: 0,
        topicsMastered: 0,
        recentTopics: [],
        weakTopics: [],
        strongTopics: [],
        trend: 'INSUFFICIENT_DATA',
        insufficientData: true,
        revisionQueue: [],
        nextDifficulty: 'EASY',
        recommendedGames: [],
        mistakes: [],
      );
}

class RecommendedGameRef {
  const RecommendedGameRef({
    required this.topicId,
    required this.topicName,
    required this.gameType,
    required this.reason,
    required this.priority,
  });
  final String topicId;
  final String topicName;
  final String gameType;
  final String reason;
  final int priority;
}

class MistakeInsight {
  const MistakeInsight({
    required this.topicName,
    required this.detail,
    required this.count,
  });
  final String topicName;
  final String detail;
  final int count;
}

class AdaptiveRecommendation {
  const AdaptiveRecommendation({
    required this.title,
    required this.reason,
    required this.actionLabel,
    required this.topicId,
    required this.topicName,
    required this.gameType,
    required this.difficulty,
    required this.priority,
  });
  final String title;
  final String reason;
  final String actionLabel;
  final String? topicId;
  final String? topicName;
  final String? gameType;
  final String difficulty;
  final int priority;
}

/// Deterministic adaptive engine — pure functions, no API calls.
abstract final class AdaptiveEngine {
  static const double masteredThreshold = 80;
  static const double proficientThreshold = 60;
  static const double developingThreshold = 40;

  static LearnerIntelligence fromDashboard(Dashboard d) {
    final overall = (d.learner.overallMastery.clamp(0, 100) as num).toDouble();
    final assessed = d.mastery.topicsAssessed;
    final mastered = d.mastery.topicsMastered;
    final recent = d.mastery.recentTopics;
    final insufficient = assessed == 0 && recent.isEmpty;

    if (insufficient) return LearnerIntelligence.empty().copyWithOverall(overall);

    // Weak: mastery < developingThreshold or trend DECLINING with mastery < proficient
    final weak = recent.where((t) {
      if (t.masteryScore < developingThreshold) return true;
      if (t.trend == 'DECLINING' && t.masteryScore < proficientThreshold) return true;
      return false;
    }).toList()
      ..sort((a, b) => a.masteryScore.compareTo(b.masteryScore));

    // Strong: mastered or proficient with STABLE/IMPROVING
    final strong = recent.where((t) {
      if (t.masteryScore >= masteredThreshold) return true;
      if (t.masteryScore >= proficientThreshold && (t.trend == 'IMPROVING' || t.trend == 'STABLE')) return true;
      return false;
    }).toList()
      ..sort((a, b) => b.masteryScore.compareTo(a.masteryScore));

    // Overall trend: majority of recent trends
    final trend = _overallTrend(recent);
    final revisionQueue = [...weak];
    // Add declining not yet weak
    for (final t in recent) {
      if (t.trend == 'DECLINING' && !revisionQueue.any((w) => w.topicId == t.topicId)) {
        revisionQueue.add(t);
      }
    }

    final nextDifficulty = _nextDifficulty(weak, strong, recent);
    final mistakes = _mistakes(recent, d.recentActivity.quizzes);
    final recommendedGames = _recommendedGames(weak, strong, recent);

    return LearnerIntelligence(
      overallMastery: overall,
      topicsAssessed: assessed,
      topicsMastered: mastered,
      recentTopics: recent,
      weakTopics: weak,
      strongTopics: strong,
      trend: trend,
      insufficientData: false,
      revisionQueue: revisionQueue.take(3).toList(),
      nextDifficulty: nextDifficulty,
      recommendedGames: recommendedGames,
      mistakes: mistakes,
    );
  }

  static String _overallTrend(List<RecentTopicMastery> recent) {
    if (recent.isEmpty) return 'INSUFFICIENT_DATA';
    final counts = <String, int>{};
    for (final t in recent) {
      counts[t.trend] = (counts[t.trend] ?? 0) + 1;
    }
    // Prefer DECLINING if any, then IMPROVING, then STABLE
    if ((counts['DECLINING'] ?? 0) >= 2) return 'DECLINING';
    if ((counts['IMPROVING'] ?? 0) >= 2) return 'IMPROVING';
    if ((counts['STABLE'] ?? 0) >= (recent.length / 2)) return 'STABLE';
    return recent.first.trend.isEmpty ? 'INSUFFICIENT_DATA' : recent.first.trend;
  }

  static String _nextDifficulty(List<RecentTopicMastery> weak, List<RecentTopicMastery> strong, List<RecentTopicMastery> recent) {
    if (weak.isNotEmpty) return 'EASY'; // remediation
    if (strong.length >= 2) return 'HARD'; // ready for harder
    if (recent.any((t) => t.masteryScore >= 85 && t.trend == 'IMPROVING')) return 'HARD';
    if (recent.any((t) => t.masteryScore < 55)) return 'MEDIUM';
    return 'MEDIUM';
  }

  static List<MistakeInsight> _mistakes(List<RecentTopicMastery> recent, List<RecentQuizRun> quizzes) {
    final insights = <MistakeInsight>[];
    for (final t in recent.where((x) => x.masteryScore < developingThreshold).take(3)) {
      insights.add(MistakeInsight(
        topicName: t.topicName,
        detail: 'Mastery ${t.masteryScore.round()}% • ${t.trend.isEmpty ? 'needs practice' : t.trend.toLowerCase()}',
        count: 1,
      ));
    }
    // Add low accuracy recent quizzes as mistakes if not already covered
    for (final q in quizzes.where((x) => x.totalQuestions > 0 && (x.correctCount / x.totalQuestions) < 0.6).take(2)) {
      if (insights.any((m) => m.topicName == q.topicName)) continue;
      insights.add(MistakeInsight(
        topicName: q.topicName,
        detail: 'Recent accuracy ${(q.correctCount / q.totalQuestions * 100).round()}% • ${q.correctCount}/${q.totalQuestions} correct',
        count: 1,
      ));
    }
    return insights.take(3).toList();
  }

  static List<RecommendedGameRef> _recommendedGames(List<RecentTopicMastery> weak, List<RecentTopicMastery> strong, List<RecentTopicMastery> recent) {
    final refs = <RecommendedGameRef>[];
    // Weak -> Concept Builder / Quiz Battle for foundations
    for (final w in weak.take(2)) {
      refs.add(RecommendedGameRef(
        topicId: w.topicId,
        topicName: w.topicName,
        gameType: w.masteryScore < 30 ? 'quiz_battle' : 'concept_builder',
        reason: 'Foundations for ${w.topicName} need reinforcement',
        priority: 1,
      ));
    }
    // Declining -> Sequence Master / Puzzle
    for (final d in recent.where((t) => t.trend == 'DECLINING').take(1)) {
      if (refs.any((r) => r.topicId == d.topicId)) continue;
      refs.add(RecommendedGameRef(
        topicId: d.topicId,
        topicName: d.topicName,
        gameType: 'sequence_master',
        reason: 'Declining trend — practice ordering for ${d.topicName}',
        priority: 2,
      ));
    }
    // Strong -> Boss Battle / Debug Arena for challenge
    for (final s in strong.take(1)) {
      if (refs.length >= 3) break;
      if (refs.any((r) => r.topicId == s.topicId)) continue;
      refs.add(RecommendedGameRef(
        topicId: s.topicId,
        topicName: s.topicName,
        gameType: 'boss_battle',
        reason: 'Strong mastery — challenge yourself with ${s.topicName}',
        priority: 3,
      ));
    }
    return refs.take(3).toList();
  }

  static List<AdaptiveRecommendation> recommendations(LearnerIntelligence intel, List<RecommendationItem> serverRecs) {
    // Server recs are real and bounded <=3; use them first if present, else derive locally
    if (serverRecs.isNotEmpty) {
      return serverRecs.map((r) => AdaptiveRecommendation(
        title: r.topicName ?? r.activityType.replaceAll('_', ' '),
        reason: r.reason.isEmpty ? 'Recommended for you' : r.reason,
        actionLabel: _actionLabel(r.activityType),
        topicId: r.topicId,
        topicName: r.topicName,
        gameType: _gameForActivity(r.activityType),
        difficulty: r.recommendedDifficulty.isEmpty ? intel.nextDifficulty : r.recommendedDifficulty,
        priority: r.priority,
      )).toList();
    }
    // Fallback deterministic local recommendations from intelligence
    final out = <AdaptiveRecommendation>[];
    for (final w in intel.weakTopics.take(1)) {
      out.add(AdaptiveRecommendation(
        title: 'Revise ${w.topicName}',
        reason: 'Mastery ${w.masteryScore.round()}% • ${w.trend.isEmpty ? 'needs practice' : w.trend}',
        actionLabel: 'Revise',
        topicId: w.topicId,
        topicName: w.topicName,
        gameType: 'quiz_battle',
        difficulty: 'EASY',
        priority: 1,
      ));
    }
    for (final r in intel.revisionQueue.where((x) => !out.any((o) => o.topicId == x.topicId)).take(1)) {
      out.add(AdaptiveRecommendation(
        title: 'Practice ${r.topicName}',
        reason: 'Declining trend — quick reinforcement',
        actionLabel: 'Practice',
        topicId: r.topicId,
        topicName: r.topicName,
        gameType: 'concept_builder',
        difficulty: 'MEDIUM',
        priority: 2,
      ));
    }
    for (final s in intel.strongTopics.take(1)) {
      if (out.length >= 3) break;
      if (out.any((o) => o.topicId == s.topicId)) continue;
      out.add(AdaptiveRecommendation(
        title: 'Challenge ${s.topicName}',
        reason: 'Strong mastery ${s.masteryScore.round()}% • try HARD',
        actionLabel: 'Challenge',
        topicId: s.topicId,
        topicName: s.topicName,
        gameType: 'boss_battle',
        difficulty: 'HARD',
        priority: 3,
      ));
    }
    if (out.isEmpty && !intel.insufficientData) {
      out.add(const AdaptiveRecommendation(
        title: 'Continue Learning',
        reason: 'Keep exploring your learning path',
        actionLabel: 'Continue',
        topicId: null,
        topicName: null,
        gameType: null,
        difficulty: 'MEDIUM',
        priority: 10,
      ));
    }
    return out.take(3).toList();
  }

  static String _actionLabel(String activityType) {
    return switch (activityType) {
      'QUIZ' => 'Start Quiz',
      'PRACTICE' => 'Practice',
      'REVIEW' => 'Review',
      'REMEDIATION' => 'Revise',
      'ADVANCE' => 'Challenge',
      'CONTINUE_LESSON' => 'Continue',
      _ => 'Start',
    };
  }

  static String? _gameForActivity(String activityType) {
    return switch (activityType) {
      'QUIZ' => 'quiz_battle',
      'PRACTICE' => 'concept_builder',
      'REVIEW' => 'memory_match',
      'REMEDIATION' => 'quiz_battle',
      'ADVANCE' => 'boss_battle',
      _ => null,
    };
  }

  static Color masteryColor(double score, bool isDark) {
    if (score >= masteredThreshold) return const Color(0xFF34D399);
    if (score >= proficientThreshold) return const Color(0xFF22D3EE);
    if (score >= developingThreshold) return const Color(0xFFFBBF24);
    return const Color(0xFFF87171);
  }

  // For linter: ensure double conversion helper
  static double _toDouble(num v) => v.toDouble();
}

extension _LearnerIntelligenceX on LearnerIntelligence {
  LearnerIntelligence copyWithOverall(double overall) => LearnerIntelligence(
        overallMastery: overall,
        topicsAssessed: topicsAssessed,
        topicsMastered: topicsMastered,
        recentTopics: recentTopics,
        weakTopics: weakTopics,
        strongTopics: strongTopics,
        trend: trend,
        insufficientData: insufficientData,
        revisionQueue: revisionQueue,
        nextDifficulty: nextDifficulty,
        recommendedGames: recommendedGames,
        mistakes: mistakes,
      );
}
