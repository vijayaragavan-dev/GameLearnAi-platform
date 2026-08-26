import 'models/gamification_models.dart';

/// Immutable GAM-001/GAM-002 snapshot used to compute honest, backend-derived
/// deltas across a quiz submission. No reward values are invented here.
class GamificationSnapshot {
  const GamificationSnapshot({
    required this.totalXp,
    required this.currentLevel,
    required this.unlocked,
  });

  final int totalXp;
  final int currentLevel;
  final List<Achievement> unlocked; // isUnlocked == true only
}

class GamificationDelta {
  const GamificationDelta({
    this.xpGained = 0,
    this.leveledUpTo,
    this.newAchievements = const <Achievement>[],
  });

  final int xpGained;
  final int? leveledUpTo;
  final List<Achievement> newAchievements;
}

/// Reads the current gamification state via injected GAM readers so it works
/// with both `Ref` and `WidgetRef` call sites.
Future<GamificationSnapshot?> captureGamificationSnapshot({
  required Future<GamificationSummary> Function() readSummary,
  required Future<List<Achievement>> Function() readAchievements,
}) async {
  try {
    final summary = await readSummary();
    final achievements = await readAchievements();
    return GamificationSnapshot(
      totalXp: summary.totalXp,
      currentLevel: summary.currentLevel,
      unlocked: achievements.where((a) => a.isUnlocked).toList(),
    );
  } catch (_) {
    // Snapshot is best-effort; result screens degrade gracefully without it.
    return null;
  }
}

/// Compares two backend reads. Every output field traces to GAM data.
GamificationDelta compareSnapshots(
  GamificationSnapshot? pre,
  GamificationSnapshot? post,
) {
  if (pre == null || post == null) return const GamificationDelta();
  final preCodes = pre.unlocked.map((a) => a.code).toSet();
  return GamificationDelta(
    xpGained: post.totalXp > pre.totalXp ? post.totalXp - pre.totalXp : 0,
    leveledUpTo: post.currentLevel > pre.currentLevel
        ? post.currentLevel
        : null,
    newAchievements: post.unlocked
        .where((a) => !preCodes.contains(a.code))
        .toList(growable: false),
  );
}
