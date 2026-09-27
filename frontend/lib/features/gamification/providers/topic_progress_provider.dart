import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/gamification_models.dart';
import '../../../core/providers.dart';

/// Session-scoped topic learning-progress map, keyed by backend topicId.
///
/// Single collection fetch (`GET /api/v1/progress` via
/// [GamificationRepository.progressAll]); every consumer resolves rows by
/// [TopicProgress.topicId] — never by name, order, or display text, so
/// similarly named topics (QA `Percentage` vs original `Percentages`)
/// can never cross-match.
///
/// Backend remains authoritative: refresh by invalidating this provider.
/// [LessonScreen] does so after a successful explicit completion; the
/// session controller discards it on logout/session expiry so progress
/// never leaks across learners. Load failure surfaces as [AsyncError];
/// consumers must degrade to progress-unaware rendering and MUST NOT
/// claim completion that could not be verified.
final topicProgressProvider =
    FutureProvider<Map<String, TopicProgress>>((ref) async {
  final all = await ref.watch(gamificationRepoProvider).progressAll();
  return {for (final p in all) p.topicId: p};
});
