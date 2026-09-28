import '../../../core/models/model_ids.dart';

/// Backend-authoritative game content models (GameContent Batch 2).
///
/// Mirrors the backend DTOs verbatim — no invented fields:
/// - `GameContentResponse{mode, subjectId, items}` from
///   `GET /api/v1/game-content` (mode SUBJECT) and
///   `GET /api/v1/game-content/global` (mode GLOBAL).
/// - `GameContentItem{kind, id, subjectId, subjectName, topicId, topicName,
///   unitId, gameType, difficulty, questionText, options, definition}`.
/// - `SubjectGamesResponse{subjectId, subjectName, games}` from
///   `GET /api/v1/subjects/{subjectId}/games`, with
///   `SubjectGameEntry{gameType, rationale, hasContent, contentCount}`.
///
/// Integrity notes (backend contract):
/// - QUESTION items expose options but never correct answers/explanations.
/// - CONCEPT definitions are server-resolved (lesson summary → lesson
///   content → topic description).
/// - `hasContent` is true only when playable items back the combination.

/// Content strategy per game (backend `GameContentKind` verbatim).
enum GameContentKind {
  question('QUESTION'),
  concept('CONCEPT'),
  structure('STRUCTURE');

  const GameContentKind(this.apiValue);
  final String apiValue;

  static GameContentKind? fromString(String? value) {
    if (value == null) return null;
    final upper = value.trim().toUpperCase();
    for (final kind in GameContentKind.values) {
      if (kind.apiValue == upper) return kind;
    }
    return null;
  }
}

/// One authoritative game content item. Identity fields are verbatim;
/// `kind` is kept as the raw backend string plus a typed nullable view so
/// unknown future kinds never crash parsing.
class GameContentItem {
  const GameContentItem({
    required this.kind,
    required this.id,
    required this.subjectId,
    required this.subjectName,
    this.topicId,
    this.topicName,
    this.unitId,
    required this.gameType,
    required this.difficulty,
    this.questionText,
    this.options = const [],
    this.definition,
  });

  final String kind;
  final String id;
  final String subjectId;
  final String subjectName;
  final String? topicId;
  final String? topicName;
  final String? unitId;
  final String gameType;
  final String difficulty;
  final String? questionText;
  final List<String> options;
  final String? definition;

  GameContentKind? get kindEnum => GameContentKind.fromString(kind);

  static List<String> _options(Object? raw) {
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  factory GameContentItem.fromJson(Map<String, dynamic> json) =>
      GameContentItem(
        kind: json['kind'] as String? ?? '',
        id: uuidOf(json['id'], 'GameContentItem.id'),
        subjectId: uuidOf(json['subjectId'], 'GameContentItem.subjectId'),
        subjectName: json['subjectName'] as String? ?? '',
        topicId: uuidOrNull(json['topicId']),
        topicName: json['topicName'] as String?,
        unitId: uuidOrNull(json['unitId']),
        gameType: json['gameType'] as String? ?? '',
        difficulty: json['difficulty'] as String? ?? '',
        questionText: json['questionText'] as String?,
        options: _options(json['options']),
        definition: json['definition'] as String?,
      );
}

/// Authoritative payload for one game-content request.
/// `mode` is SUBJECT (single world) or GLOBAL (intentionally mixed).
class GameContentPayload {
  const GameContentPayload({
    required this.mode,
    this.subjectId,
    required this.items,
  });

  final String mode;
  final String? subjectId;
  final List<GameContentItem> items;

  bool get isSubjectMode => mode.toUpperCase() == 'SUBJECT';
  bool get isGlobalMode => mode.toUpperCase() == 'GLOBAL';

  factory GameContentPayload.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(GameContentItem.fromJson)
              .toList(growable: false)
        : const <GameContentItem>[];
    return GameContentPayload(
      mode: json['mode'] as String? ?? '',
      subjectId: uuidOrNull(json['subjectId']),
      items: items,
    );
  }
}

/// One supported game for a subject, with truthful availability.
class SubjectGameEntry {
  const SubjectGameEntry({
    required this.gameType,
    required this.rationale,
    required this.hasContent,
    required this.contentCount,
  });

  final String gameType;
  final String rationale;
  final bool hasContent;
  final int contentCount;

  factory SubjectGameEntry.fromJson(Map<String, dynamic> json) =>
      SubjectGameEntry(
        gameType: json['gameType'] as String? ?? '',
        rationale: json['rationale'] as String? ?? '',
        hasContent: json['hasContent'] as bool? ?? false,
        contentCount: (json['contentCount'] as num?)?.toInt() ?? 0,
      );
}

/// Supported games for one subject (compat authority).
class SubjectGames {
  const SubjectGames({
    required this.subjectId,
    required this.subjectName,
    required this.games,
  });

  final String subjectId;
  final String subjectName;
  final List<SubjectGameEntry> games;

  /// Lookup by backend game-type id (e.g. `quiz_battle`). Null when the
  /// backend does not expose the combination (unsupported → never shown).
  SubjectGameEntry? entryFor(String gameTypeId) {
    for (final entry in games) {
      if (entry.gameType == gameTypeId) return entry;
    }
    return null;
  }

  factory SubjectGames.fromJson(Map<String, dynamic> json) {
    final raw = json['games'];
    final games = raw is List
        ? raw
              .whereType<Map<String, dynamic>>()
              .map(SubjectGameEntry.fromJson)
              .toList(growable: false)
        : const <SubjectGameEntry>[];
    return SubjectGames(
      subjectId: uuidOf(json['subjectId'], 'SubjectGames.subjectId'),
      subjectName: json['subjectName'] as String? ?? '',
      games: games,
    );
  }
}

/// Thrown when backend game content violates the requested scope
/// (subject/topic/mode/world mismatch). Callers render honest empty/error
/// states — the content is rejected, never repaired or substituted.
class GameContentScopeMismatch implements Exception {
  const GameContentScopeMismatch(this.message);
  final String message;

  @override
  String toString() => 'GameContentScopeMismatch: $message';
}
