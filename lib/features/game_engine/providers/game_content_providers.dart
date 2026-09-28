import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../models/game_content_models.dart';

/// Scoped providers for backend-authoritative game content.
///
/// Family keys carry the backend ids, so switching worlds (DBMS → OS →
/// DBMS) addresses distinct cache entries — scoped state reloads instead of
/// showing stale content. All are invalidated on logout/session expiry via
/// the session controller's learner-state discard.
///
/// Ownership validation (subject/topic agreement) runs inside
/// [validatedSubjectContentProvider]; full mode/world agreement runs where
/// the caller's [GameContentRequest] is known via
/// `WorldContentGate.validateGameContentPayload`.
final subjectGamesProvider =
    FutureProvider.family<SubjectGames, String>((ref, subjectId) async {
  return ref.watch(gameContentRepoProvider).subjectGames(subjectId);
});

/// Route-level key for one world-scoped content fetch.
class GameContentQuery {
  const GameContentQuery({
    required this.subjectId,
    this.topicId,
    required this.gameType,
    this.difficulty,
    this.limit,
  });

  final String subjectId;
  final String? topicId;
  final String gameType;
  final String? difficulty;
  final int? limit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameContentQuery &&
          subjectId == other.subjectId &&
          topicId == other.topicId &&
          gameType == other.gameType &&
          difficulty == other.difficulty &&
          limit == other.limit;

  @override
  int get hashCode =>
      Object.hash(subjectId, topicId, gameType, difficulty, limit);
}

/// Subject-scoped payload with ownership validation: every item must carry
/// the requested subjectId, and (when a topic is requested) a matching
/// topicId. Violations throw [GameContentScopeMismatch] — rejected, never
/// repaired or substituted.
final validatedSubjectContentProvider =
    FutureProvider.family<GameContentPayload, GameContentQuery>(
        (ref, query) async {
  final payload =
      await ref.watch(gameContentRepoProvider).subjectContent(
            subjectId: query.subjectId,
            topicId: query.topicId,
            gameType: query.gameType,
            difficulty: query.difficulty,
            limit: query.limit,
          );
  for (final item in payload.items) {
    if (item.subjectId.isEmpty || item.subjectId != query.subjectId) {
      throw GameContentScopeMismatch(
        'Content item ${item.id} does not belong to subject '
        '${query.subjectId}; rejected.',
      );
    }
    if (query.topicId != null &&
        query.topicId!.isNotEmpty &&
        item.topicId != null &&
        item.topicId!.isNotEmpty &&
        item.topicId != query.topicId) {
      throw GameContentScopeMismatch(
        'Content item ${item.id} does not belong to topic '
        '${query.topicId}; rejected.',
      );
    }
  }
  return payload;
});

/// Intentionally mixed global-arena payload (no isolation applied — every
/// item keeps its subject identity for display).
final globalGameContentProvider =
    FutureProvider.family<GameContentPayload, GameContentQuery>(
        (ref, query) async {
  return ref.watch(gameContentRepoProvider).globalContent(
        gameType: query.gameType,
        difficulty: query.difficulty,
        limit: query.limit,
      );
});
