import '../../subjects/domain/canonical_worlds.dart';
import '../../../core/models/content_models.dart';
import '../../../core/models/quiz_models.dart';
import '../models/game_content_models.dart';
import '../models/game_models.dart';

/// Game content scope — the data/selection-layer distinction between the
/// WORLD GAME ARENA (strictly isolated to one world) and the GLOBAL GAME
/// ARENA (intentionally mixed core-CS content).
///
/// WORLD ≠ GLOBAL, enforced here — not only in UI labels.
enum GameContentScope {
  /// Single-world play. Content MUST belong to [GameContentRequest.worldId]
  /// (and [GameContentRequest.subjectId] for backend content). Anything else
  /// is REJECTED — never silently substituted.
  world,

  /// Mixed-subject play (dashboard Global Game Arena). Any eligible
  /// core-CS content is allowed.
  global,
}

/// Deterministic content-selection request for one game session.
///
/// Backend ids ([subjectId]/[topicId]) remain authoritative; [worldId] is the
/// stable frontend canonical identity used for static-bank attribution.
/// For [GameContentScope.world], [worldId] is required.
class GameContentRequest {
  const GameContentRequest._({
    required this.scope,
    this.worldId,
    this.subjectId,
    this.subjectName,
    this.topicId,
    this.topicName,
    this.difficulty,
  });

  /// World-scoped request. [worldId] required; [subjectId] required when the
  /// game consumes backend content (quiz/lesson/topic validation).
  factory GameContentRequest.world({
    required WorldId worldId,
    String? subjectId,
    String? subjectName,
    String? topicId,
    String? topicName,
    GameDifficulty? difficulty,
  }) =>
      GameContentRequest._(
        scope: GameContentScope.world,
        worldId: worldId,
        subjectId: subjectId,
        subjectName: subjectName,
        topicId: topicId,
        topicName: topicName,
        difficulty: difficulty,
      );

  /// Global-arena request. Mixed content explicitly allowed.
  factory GameContentRequest.global({
    String? subjectId,
    String? subjectName,
    String? topicId,
    String? topicName,
    GameDifficulty? difficulty,
  }) =>
      GameContentRequest._(
        scope: GameContentScope.global,
        subjectId: subjectId,
        subjectName: subjectName,
        topicId: topicId,
        topicName: topicName,
        difficulty: difficulty,
      );

  /// Derive from route-level widget parameters. World scope applies only
  /// when the subject resolves to a known canonical world; otherwise the
  /// request gracefully degrades to global (never throws, never isolates
  /// into a wrong world).
  factory GameContentRequest.fromRoute({
    String? subjectId,
    String? subjectName,
    String? topicId,
    String? topicName,
    GameDifficulty? difficulty,
  }) {
    final worldId = (subjectName != null && subjectName.trim().isNotEmpty)
        ? WorldCatalog.resolveDisplayName(subjectName)?.id
        : null;
    if (subjectId != null && subjectId.isNotEmpty && worldId != null) {
      return GameContentRequest.world(
        worldId: worldId,
        subjectId: subjectId,
        subjectName: subjectName,
        topicId: topicId,
        topicName: topicName,
        difficulty: difficulty,
      );
    }
    return GameContentRequest.global(
      subjectId: subjectId,
      subjectName: subjectName,
      topicId: topicId,
      topicName: topicName,
      difficulty: difficulty,
    );
  }

  final GameContentScope scope;
  final WorldId? worldId;
  final String? subjectId;
  final String? subjectName;
  final String? topicId;
  final String? topicName;
  final GameDifficulty? difficulty;

  bool get isWorld => scope == GameContentScope.world;
}

/// Strict validation + deterministic selection for game content.
///
/// Rules:
/// - WORLD scope: accept only content belonging to the requested world.
/// - Topic scope (when [GameContentRequest.topicId] present): accept only
///   content for that topic; fallback stays WITHIN the same world, never
///   crosses to another world.
/// - Rejected/missing content → caller renders an honest EmptyState.
///   No fake fallback, no cross-world substitution.
abstract final class WorldContentGate {
  /// Bank-level world defaults for static banks whose items carry
  /// sub-topic labels instead of world names. These classify existing
  /// content by its true domain — they never invent content:
  /// - Debug Arena: language bug-hunts (Java/Dart/Python) → Programming.
  /// - Connectivity Lab: topology/routing/DNS missions → Computer Networks.
  static const Map<GameType, WorldId> bankDefaultWorld = {
    GameType.debugArena: WorldId.programming,
    GameType.connectivityLab: WorldId.computerNetworks,
  };

  /// Resolve a static item's world from its topic label, falling back to
  /// the bank default. Null when the item belongs to no canonical world
  /// (e.g. 'Mathematics', 'Science') — such items are global-arena only.
  static WorldId? worldOfStaticLabel(
    String topicLabel, {
    GameType? gameType,
  }) {
    final resolved = WorldCatalog.resolveDisplayName(topicLabel)?.id;
    if (resolved != null) return resolved;
    if (gameType != null) return bankDefaultWorld[gameType];
    return null;
  }

  /// Deterministic world/global filter for static banks. Preserves bank
  /// order; world scope keeps only items attributed to the requested world.
  static List<T> selectStatic<T>({
    required List<T> items,
    required String Function(T) topicLabelOf,
    required GameContentRequest request,
    GameType? gameType,
  }) {
    if (!request.isWorld) return [...items];
    final worldId = request.worldId;
    if (worldId == null) return const [];
    return items
        .where(
          (item) =>
              worldOfStaticLabel(topicLabelOf(item), gameType: gameType) ==
              worldId,
        )
        .toList();
  }

  /// Validate a backend topic against the request. WORLD scope requires
  /// `topic.subjectId == request.subjectId` (both non-empty). When the
  /// request also carries a topicId, it must match exactly.
  static bool acceptBackendTopic({
    required Topic topic,
    required GameContentRequest request,
  }) {
    if (!request.isWorld) return true;
    final wantSubject = request.subjectId;
    if (wantSubject == null ||
        wantSubject.isEmpty ||
        topic.subjectId.isEmpty ||
        topic.subjectId != wantSubject) {
      return false;
    }
    final wantTopic = request.topicId;
    if (wantTopic != null &&
        wantTopic.isNotEmpty &&
        topic.id.isNotEmpty &&
        topic.id != wantTopic) {
      return false;
    }
    return true;
  }

  /// Validate a backend quiz against the request (QUIZ-001 carries topicId).
  static bool acceptBackendQuiz({
    required Quiz quiz,
    required GameContentRequest request,
  }) {
    if (!request.isWorld) return true;
    final wantTopic = request.topicId;
    if (wantTopic == null || wantTopic.isEmpty) return true;
    if (quiz.topicId.isEmpty) return false;
    return quiz.topicId == wantTopic;
  }

  /// Honest rejection message for backend content that fails scope
  /// validation, or null when accepted. Callers surface this via their
  /// existing ErrorState — never silent, never cross-world fallback.
  static String? rejectionMessage({
    Topic? topic,
    Quiz? quiz,
    required GameContentRequest request,
  }) {
    if (!request.isWorld) return null;
    if (topic != null && !acceptBackendTopic(topic: topic, request: request)) {
      final where = (request.subjectName != null &&
              request.subjectName!.trim().isNotEmpty)
          ? request.subjectName!
          : 'this world';
      return 'This content does not belong to $where. '
          'Nothing from another world is substituted.';
    }
    if (quiz != null && !acceptBackendQuiz(quiz: quiz, request: request)) {
      return 'This quiz does not belong to the requested topic. '
          'Nothing from another topic is substituted.';
    }
    return null;
  }

  /// Full ownership validation for a backend game-content payload against
  /// a world-scoped request (Phase 7.2 pipeline):
  /// - every item's subjectId must equal the requested subjectId;
  /// - when a topic is requested, topic-bound items must match it;
  /// - the payload mode must be SUBJECT (GLOBAL payloads never satisfy a
  ///   world request);
  /// - when the backend supplies a world-agreeing identity (subjectName
  ///   resolving to a canonical world), it must equal the requested world.
  ///
  /// Global requests accept any payload whose items carry subject identity.
  /// Violations throw [GameContentScopeMismatch] — rejected, never repaired.
  static void validateGameContentPayload({
    required GameContentPayload payload,
    required GameContentRequest request,
  }) {
    if (!request.isWorld) {
      for (final item in payload.items) {
        if (item.subjectId.isEmpty) {
          throw GameContentScopeMismatch(
            'Global item ${item.id} carries no subject identity; rejected.',
          );
        }
      }
      return;
    }
    final wantSubject = request.subjectId;
    if (wantSubject == null || wantSubject.isEmpty) {
      throw const GameContentScopeMismatch(
        'World request carries no backend subjectId; rejected.',
      );
    }
    if (!payload.isSubjectMode) {
      throw GameContentScopeMismatch(
        'World request requires a SUBJECT payload but received '
        "'${payload.mode}'; rejected.",
      );
    }
    if (payload.subjectId != null &&
        payload.subjectId!.isNotEmpty &&
        payload.subjectId != wantSubject) {
      throw GameContentScopeMismatch(
        'Payload subject ${payload.subjectId} does not match requested '
        'subject $wantSubject; rejected.',
      );
    }
    for (final item in payload.items) {
      if (item.subjectId.isEmpty || item.subjectId != wantSubject) {
        throw GameContentScopeMismatch(
          'Content item ${item.id} does not belong to subject '
          '$wantSubject; rejected.',
        );
      }
      final wantTopic = request.topicId;
      if (wantTopic != null &&
          wantTopic.isNotEmpty &&
          item.topicId != null &&
          item.topicId!.isNotEmpty &&
          item.topicId != wantTopic) {
        throw GameContentScopeMismatch(
          'Content item ${item.id} does not belong to topic '
          '$wantTopic; rejected.',
        );
      }
    }
    final wantWorld = request.worldId;
    if (wantWorld != null) {
      for (final item in payload.items) {
        final itemWorld = item.subjectName.isNotEmpty
            ? WorldCatalog.resolveDisplayName(item.subjectName)?.id
            : null;
        if (itemWorld != null && itemWorld != wantWorld) {
          throw GameContentScopeMismatch(
            'Content item ${item.id} maps to $itemWorld, not the requested '
            '$wantWorld; rejected.',
          );
        }
      }
    }
  }
}
