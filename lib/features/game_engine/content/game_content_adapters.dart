import '../../games/concept_builder/models/concept_challenge.dart';
import '../../subjects/domain/canonical_worlds.dart';
import '../models/game_content_models.dart';
import '../models/game_models.dart';
import '../utils/game_content_mapper.dart' show DragItem;
import 'game_content_scope.dart';

/// Backend → engine adapters (Phase 11).
///
/// Each adapter transforms validated [GameContentItem] payloads into the
/// exact shape its existing game engine already consumes. No engine changes,
/// no invented questions, no guessed difficulty.
///
/// Fail-closed contract (applies to every adapter below):
/// - world scope: item subject/topic must agree with [request] (via
///   [WorldContentGate.validateGameContentPayload]);
/// - item `gameType` must equal the target game (never cross-game);
/// - required content fields must be present and non-trivial, otherwise the
///   item is SKIPPED; when too few valid items remain the adapter throws
///   [GameContentScopeMismatch] so callers render honest empty/error states;
/// - backend ordering is preserved (adapters never shuffle; screens keep
///   their existing deterministic presentation);
/// - backend difficulty is mapped strictly (EASY/MEDIUM/HARD only) — malformed
///   difficulty rejects the item, it is never defaulted.
abstract final class GameContentAdapters {
  // ── Memory Match (CONCEPT → term/definition pairs) ──────────────────────

  /// Adapt CONCEPT items to memory pairs shaped exactly like
  /// [GameContentMapper.memoryPairs] output so the screen needs no changes.
  /// Term = authoritative topic name; definition = authoritative backend
  /// definition. Duplicate topic names are de-duplicated (first wins) to
  /// keep pairs unambiguous. Requires at least [minPairs].
  static List<({String term, String definition})> memoryPairsFromItems({
    required List<GameContentItem> items,
    required GameContentRequest request,
    required String gameType,
    int minPairs = 2,
    int maxPairs = 8,
  }) {
    final pairs = <({String term, String definition})>[];
    final seenTerms = <String>{};
    for (final item in items) {
      if (pairs.length >= maxPairs) break;
      if (!_acceptItem(item, request, gameType, GameContentKind.concept)) {
        continue;
      }
      final term = item.topicName?.trim() ?? '';
      final definition = item.definition?.trim() ?? '';
      if (term.isEmpty || definition.isEmpty) continue;
      if (!seenTerms.add(term)) continue;
      pairs.add((term: term, definition: definition));
    }
    if (pairs.length < minPairs) {
      throw GameContentScopeMismatch(
        'Only ${pairs.length} valid CONCEPT items for $gameType; '
        'need at least $minPairs. Rejected.',
      );
    }
    return pairs;
  }

  // ── Drag & Drop (STRUCTURE → difficulty zones + topic items) ────────────

  /// Adapt STRUCTURE items to the [GameContentMapper.dragDropPayload] shape.
  /// Zones are the distinct backend difficulties in canonical EASY/MEDIUM/
  /// HARD order; each item is its authoritative topic name in its own
  /// difficulty zone. Requires at least 2 zones and [minItems] items.
  static ({List<String> zones, List<DragItem> items}) dragPayloadFromItems({
    required List<GameContentItem> items,
    required GameContentRequest request,
    required String gameType,
    int minItems = 3,
  }) {
    const canonicalOrder = ['EASY', 'MEDIUM', 'HARD'];
    final byDifficulty = <String, List<GameContentItem>>{};
    for (final item in items) {
      if (!_acceptItem(item, request, gameType, GameContentKind.structure)) {
        continue;
      }
      final topicName = item.topicName?.trim() ?? '';
      if (topicName.isEmpty) continue;
      final difficulty = _strictDifficulty(item);
      if (difficulty == null) continue;
      byDifficulty.putIfAbsent(difficulty.apiValue, () => []).add(item);
    }
    final zones = canonicalOrder.where(byDifficulty.containsKey).toList();
    final adapted = <DragItem>[];
    for (final zone in zones) {
      for (final item in byDifficulty[zone]!) {
        adapted.add(
          DragItem(
            id: item.id,
            label: item.topicName!.trim(),
            correctZone: zone,
          ),
        );
      }
    }
    if (zones.length < 2 || adapted.length < minItems) {
      throw GameContentScopeMismatch(
        'Only ${zones.length} zones / ${adapted.length} items for $gameType; '
        'need at least 2 zones and $minItems items. Rejected.',
      );
    }
    return (zones: zones, items: adapted);
  }

  // ── Concept Builder (CONCEPT definition → ordered sentence blocks) ──────

  /// Adapt one CONCEPT item into a [ConceptChallenge] by splitting its
  /// authoritative definition into sentence blocks; the correct order is the
  /// definition's own sentence order (backend content order, not invented).
  /// Items with fewer than [minBlocks] sentences are rejected (impossible
  /// ordering). Presentational chrome (instruction/objective) is generic and
  /// documented — the educational content stays verbatim.
  static ConceptChallenge conceptChallengeFromItem({
    required GameContentItem item,
    required GameContentRequest request,
    required String gameType,
    int minBlocks = 2,
    int maxBlocks = 6,
  }) {
    if (!_acceptItem(item, request, gameType, GameContentKind.concept)) {
      throw GameContentScopeMismatch(
        'Item ${item.id} failed scope/kind/gameType validation for '
        '$gameType; rejected.',
      );
    }
    final topicName = item.topicName?.trim() ?? '';
    final definition = item.definition?.trim() ?? '';
    if (topicName.isEmpty || definition.isEmpty) {
      throw GameContentScopeMismatch(
        'Item ${item.id} has empty topic/definitions for $gameType; '
        'rejected.',
      );
    }
    final difficulty = _strictDifficulty(item);
    if (difficulty == null) {
      throw GameContentScopeMismatch(
        'Item ${item.id} has malformed difficulty '
        "'${item.difficulty}' for $gameType; rejected (never defaulted).",
      );
    }
    final sentences = definition
        .split(RegExp(r'[\.\n]+'))
        .map((s) => s.trim())
        .where((s) => s.length > 12)
        .take(maxBlocks)
        .toList();
    if (sentences.length < minBlocks) {
      throw GameContentScopeMismatch(
        'Item ${item.id} yields only ${sentences.length} blocks for '
        '$gameType; need at least $minBlocks. Rejected.',
      );
    }
    final blocks = <ConceptBlock>[];
    final order = <String>[];
    for (var i = 0; i < sentences.length; i++) {
      final id = '${item.id}_b$i';
      blocks.add(ConceptBlock(id: id, label: sentences[i]));
      order.add(id);
    }
    final worldLabel = request.subjectName?.trim().isNotEmpty == true
        ? request.subjectName!.trim()
        : item.subjectName;
    return ConceptChallenge(
      id: item.id,
      title: topicName,
      topic: worldLabel,
      difficulty: difficulty,
      learningObjective: 'Understand $topicName',
      instruction: 'Arrange the concept in the correct order',
      blocks: blocks,
      correctOrder: order,
      explanation: definition,
    );
  }

  /// Adapt a batch, skipping invalid items; throws when fewer than
  /// [minChallenges] survive.
  static List<ConceptChallenge> conceptChallengesFromItems({
    required List<GameContentItem> items,
    required GameContentRequest request,
    required String gameType,
    int minChallenges = 1,
    int maxChallenges = 4,
  }) {
    final out = <ConceptChallenge>[];
    for (final item in items) {
      if (out.length >= maxChallenges) break;
      try {
        out.add(
          conceptChallengeFromItem(
            item: item,
            request: request,
            gameType: gameType,
          ),
        );
      } on GameContentScopeMismatch {
        continue;
      }
    }
    if (out.length < minChallenges) {
      throw GameContentScopeMismatch(
        'Only ${out.length} valid CONCEPT challenges for $gameType; '
        'need at least $minChallenges. Rejected.',
      );
    }
    return out;
  }

  // ── Shared validation ───────────────────────────────────────────────────

  /// Scope + kind + gameType agreement for a single item. Game-type check is
  /// exact (Game A content never enters Game B). Unknown future kinds are
  /// rejected (fail closed) — callers only accept the kinds they declare.
  static bool _acceptItem(
    GameContentItem item,
    GameContentRequest request,
    String gameType,
    GameContentKind kind,
  ) {
    if (item.id.isEmpty || item.gameType != gameType) return false;
    if (item.kindEnum != kind) return false;
    if (item.subjectId.isEmpty) return false;
    if (request.isWorld) {
      final wantSubject = request.subjectId;
      if (wantSubject == null ||
          wantSubject.isEmpty ||
          item.subjectId != wantSubject) {
        return false;
      }
      final wantTopic = request.topicId;
      if (wantTopic != null &&
          wantTopic.isNotEmpty &&
          item.topicId != null &&
          item.topicId!.isNotEmpty &&
          item.topicId != wantTopic) {
        return false;
      }
      final wantWorld = request.worldId;
      if (wantWorld != null && item.subjectName.isNotEmpty) {
        final itemWorld =
            WorldCatalog.resolveDisplayName(item.subjectName)?.id;
        if (itemWorld != null && itemWorld != wantWorld) return false;
      }
    }
    return true;
  }

  /// Strict EASY/MEDIUM/HARD mapping. Returns null for anything else —
  /// difficulty is never guessed or defaulted (Rule 13).
  static GameDifficulty? _strictDifficulty(GameContentItem item) {
    final upper = item.difficulty.trim().toUpperCase();
    for (final d in GameDifficulty.values) {
      if (d.apiValue == upper) return d;
    }
    return null;
  }
}
