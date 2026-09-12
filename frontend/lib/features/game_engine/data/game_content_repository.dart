import '../../../core/network/api_client.dart';
import '../models/game_content_models.dart';

/// Backend-authoritative game content repository (GameContent Batch 2).
///
/// Endpoints (verbatim backend contracts — nothing invented):
/// - `GET /api/v1/subjects/{subjectId}/games` → supported games per subject
///   with truthful availability (`hasContent` + `contentCount`).
/// - `GET /api/v1/game-content?subjectId&topicId&gameType&difficulty&limit`
///   → subject-scoped items (`subjectId` + `gameType` required server-side;
///   cross-subject topics rejected server-side; empty → 404
///   RESOURCE_NOT_FOUND).
/// - `GET /api/v1/game-content/global?gameType&difficulty&limit` →
///   intentionally mixed items, deterministic round-robin, every item
///   carrying its subject identity.
///
/// Ownership is verified client-side too (defense in depth): see
/// [WorldContentGate.validateGameContentPayload]. Rejected content is
/// never repaired or substituted.
class GameContentRepository {
  GameContentRepository(this._client);

  final ApiClient _client;

  /// Supported games for one backend subject.
  Future<SubjectGames> subjectGames(String subjectId) async {
    if (subjectId.isEmpty) {
      throw ArgumentError('subjectId must not be empty');
    }
    final json = await _client.getJson('/api/v1/subjects/$subjectId/games');
    return SubjectGames.fromJson(json);
  }

  /// Subject-scoped playable items for one game (optionally narrowed by
  /// topic and difficulty). `limit` is clamped server-side to 1..50.
  Future<GameContentPayload> subjectContent({
    required String subjectId,
    String? topicId,
    required String gameType,
    String? difficulty,
    int? limit,
  }) async {
    if (subjectId.isEmpty) {
      throw ArgumentError('subjectId must not be empty');
    }
    if (gameType.isEmpty) {
      throw ArgumentError('gameType must not be empty');
    }
    final json = await _client.getJson(
      '/api/v1/game-content',
      query: {
        'subjectId': subjectId,
        if (topicId != null && topicId.isNotEmpty) 'topicId': topicId,
        'gameType': gameType,
        if (difficulty != null && difficulty.isNotEmpty)
          'difficulty': difficulty,
        if (limit != null) 'limit': '$limit',
      },
    );
    return GameContentPayload.fromJson(json);
  }

  /// Intentionally mixed global-arena items for one game.
  Future<GameContentPayload> globalContent({
    required String gameType,
    String? difficulty,
    int? limit,
  }) async {
    if (gameType.isEmpty) {
      throw ArgumentError('gameType must not be empty');
    }
    final json = await _client.getJson(
      '/api/v1/game-content/global',
      query: {
        'gameType': gameType,
        if (difficulty != null && difficulty.isNotEmpty)
          'difficulty': difficulty,
        if (limit != null) 'limit': '$limit',
      },
    );
    return GameContentPayload.fromJson(json);
  }
}
