import '../../../core/models/quiz_models.dart';
import '../models/game_content_models.dart';

/// Shared backend-content validation boundary (Phase 11 — Gate 1).
///
/// Fail-closed gate between [GameContentPayload]/[GameContentItem] (backend
/// authority) and the existing game engines. It validates identity and shape
/// but never repairs, substitutes, or invents content:
///
/// - IDs are matched as UUID strings, never display names (the same topic
///   name may exist under different subjects).
/// - Backend difficulty is authoritative: only `EASY`/`MEDIUM`/`HARD`
///   (case-insensitive input, canonical upper-case comparison). Anything else
///   is rejected — never defaulted. (Do NOT use `GameDifficulty.fromString`
///   for backend content: it silently defaults unknown values to EASY.)
/// - `QUESTION` items carry options but never correct answers (contract).
///   Local grading therefore requires an explicit answer supplied alongside
///   the item ("where applicable"); server-graded flows (quiz_battle,
///   speed_run via QUIZ-002) do not use this gate for grading.
/// - Empty payloads are SAFE (return normally; callers render an honest empty
///   state). Everything else that fails validation throws
///   [GameContentScopeMismatch] so callers render honest error states.
/// - Backend-first precedence: when valid backend items exist they win;
///   static banks are explicit fallback only and never silently override
///   valid backend content (see [shouldUseBackend]).
abstract final class GameContentValidation {
  /// Authoritative difficulties. Anything else is malformed.
  static const Set<String> validDifficulties = {'EASY', 'MEDIUM', 'HARD'};

  static bool isValidDifficulty(String? value) {
    if (value == null) return false;
    return validDifficulties.contains(value.trim().toUpperCase());
  }

  /// Validate one item. Returns `null` when valid, otherwise a human-readable
  /// reason (callers throw [GameContentScopeMismatch] with it).
  ///
  /// - [subjectMode]: true = subject isolation enforced ([expectedSubjectId]
  ///   required and must match); false = global arena, mixed subjects allowed
  ///   but every item must still carry subject identity.
  /// - Topic/gameType expectations are enforced by ID (exact match), never by
  ///   display name. A topic expectation only rejects topic-bound items that
  ///   disagree (items with an empty `topicId` are topic-agnostic and pass the
  ///   topic check — same semantics as `WorldContentGate`).
  static String? validateItem({
    required GameContentItem item,
    String? expectedSubjectId,
    String? expectedTopicId,
    String? expectedGameType,
    bool subjectMode = true,
  }) {
    if (item.id.trim().isEmpty) {
      return 'Content item carries no id; rejected.';
    }
    if (item.subjectId.trim().isEmpty) {
      return 'Content item ${item.id} carries no subject identity; rejected.';
    }
    if (item.kindEnum == null) {
      return 'Content item ${item.id} has unknown kind '
          "'${item.kind}'; rejected.";
    }
    if (item.gameType.trim().isEmpty) {
      return 'Content item ${item.id} carries no gameType; rejected.';
    }
    if (expectedGameType != null &&
        expectedGameType.isNotEmpty &&
        item.gameType != expectedGameType) {
      return 'Content item ${item.id} targets ${item.gameType}, not '
          '$expectedGameType; rejected (never cross-game).';
    }
    if (!isValidDifficulty(item.difficulty)) {
      return 'Content item ${item.id} has malformed difficulty '
          "'${item.difficulty}'; rejected (never defaulted).";
    }
    if (subjectMode) {
      if (expectedSubjectId == null || expectedSubjectId.isEmpty) {
        return 'Subject-mode request carries no subjectId; rejected.';
      }
      if (item.subjectId != expectedSubjectId) {
        return 'Content item ${item.id} does not belong to subject '
            '$expectedSubjectId; rejected.';
      }
    }
    if (expectedTopicId != null &&
        expectedTopicId.isNotEmpty &&
        item.topicId != null &&
        item.topicId!.isNotEmpty &&
        item.topicId != expectedTopicId) {
      return 'Content item ${item.id} does not belong to topic '
          '$expectedTopicId; rejected.';
    }

    switch (item.kindEnum!) {
      case GameContentKind.concept:
        if ((item.topicName ?? '').trim().isEmpty) {
          return 'CONCEPT item ${item.id} has no topicName; rejected.';
        }
        if ((item.definition ?? '').trim().isEmpty) {
          return 'CONCEPT item ${item.id} has no definition; rejected.';
        }
      case GameContentKind.structure:
        if ((item.topicName ?? '').trim().isEmpty) {
          return 'STRUCTURE item ${item.id} has no topicName; rejected.';
        }
      case GameContentKind.question:
        if ((item.questionText ?? '').trim().isEmpty) {
          return 'QUESTION item ${item.id} has no questionText; rejected.';
        }
        final options = item.options.where((o) => o.trim().isNotEmpty).toList();
        if (options.length < 2) {
          return 'QUESTION item ${item.id} has fewer than 2 usable options; '
              'rejected.';
        }
    }
    return null;
  }

  /// Validate a locally-graded answer against a QUESTION item ("where
  /// applicable"). Backend items never embed the correct answer, so the
  /// answer must be supplied explicitly alongside the item:
  /// - missing/empty answer → rejected (returned as an error string);
  /// - answer not present in options → rejected;
  /// - otherwise `null` (valid).
  ///
  /// Server-graded flows (QUIZ-002) never call this — grading stays
  /// backend-authoritative there.
  static String? validateAnswerInOptions({
    required String? answer,
    required GameContentItem item,
  }) {
    if (answer == null || answer.trim().isEmpty) {
      return 'QUESTION item ${item.id} has no answer supplied; rejected '
          '(local grading requires an explicit answer).';
    }
    final options = item.options.map((o) => o.trim()).toList();
    if (!options.contains(answer.trim())) {
      return 'Answer for QUESTION item ${item.id} is not present in '
          'options; rejected.';
    }
    return null;
  }

  /// Validate a whole payload. Empty payloads are SAFE (returns normally).
  /// Any scope/shape violation throws [GameContentScopeMismatch].
  static void validatePayload({
    required GameContentPayload payload,
    String? expectedSubjectId,
    String? expectedTopicId,
    String? expectedGameType,
    bool subjectMode = true,
  }) {
    if (payload.items.isEmpty) return;
    if (subjectMode) {
      if (!payload.isSubjectMode) {
        throw GameContentScopeMismatch(
          'Subject request requires a SUBJECT payload but received '
          "'${payload.mode}'; rejected.",
        );
      }
      if (expectedSubjectId == null || expectedSubjectId.isEmpty) {
        throw const GameContentScopeMismatch(
          'Subject request carries no backend subjectId; rejected.',
        );
      }
      if (payload.subjectId != null &&
          payload.subjectId!.isNotEmpty &&
          payload.subjectId != expectedSubjectId) {
        throw GameContentScopeMismatch(
          'Payload subject ${payload.subjectId} does not match requested '
          'subject $expectedSubjectId; rejected.',
        );
      }
    }
    for (final item in payload.items) {
      final reason = validateItem(
        item: item,
        expectedSubjectId: expectedSubjectId,
        expectedTopicId: expectedTopicId,
        expectedGameType: expectedGameType,
        subjectMode: subjectMode,
      );
      if (reason != null) throw GameContentScopeMismatch(reason);
    }
  }

  /// Backend-first precedence: valid backend items win over static banks.
  /// Static fallback is permitted only when there is nothing valid to show.
  /// This helper makes the rule explicit and testable at the boundary.
  static bool shouldUseBackend(int validBackendItemCount) =>
      validBackendItemCount > 0;

  /// (A) Client-renderable question-structure validation for Quiz Battle
  /// (Phase 11 — Gate 2).
  ///
  /// QUIZ-001 questions intentionally carry NO correct answer (grading is
  /// server-side via QUIZ-002), so answer absence is EXPECTED here and never
  /// a rejection reason. This validates only what the client renders:
  /// id, questionText, ≥2 usable options, and strict difficulty.
  /// Returns `null` when valid, otherwise the rejection reason.
  static String? validateQuizQuestion({required QuizQuestion question}) {
    if (question.id.trim().isEmpty) {
      return 'Quiz question carries no id; rejected.';
    }
    if (question.questionText.trim().isEmpty) {
      return 'Quiz question ${question.id} has no questionText; rejected.';
    }
    final options = question.options.where((o) => o.trim().isNotEmpty).toList();
    if (options.length < 2) {
      return 'Quiz question ${question.id} has fewer than 2 usable options; '
          'rejected.';
    }
    if (!isValidDifficulty(question.difficulty)) {
      return 'Quiz question ${question.id} has malformed difficulty '
          "'${question.difficulty}'; rejected (never defaulted).";
    }
    return null;
  }

  /// (A) Game-content-item view of the Quiz Battle contract: the item must be
  /// a `QUESTION` for exactly `quiz_battle`. Answer absence is expected
  /// (server-graded); use [validateAnswerInOptions] only for locally-graded
  /// flows (B), never for Quiz Battle.
  static String? validateQuizBattleItem({
    required GameContentItem item,
    String? expectedSubjectId,
    String? expectedTopicId,
  }) {
    if (item.kindEnum != GameContentKind.question) {
      return 'Content item ${item.id} is ${item.kind}, not QUESTION; '
          'rejected for quiz_battle.';
    }
    return validateItem(
      item: item,
      expectedSubjectId: expectedSubjectId,
      expectedTopicId: expectedTopicId,
      expectedGameType: 'quiz_battle',
      subjectMode: expectedSubjectId != null && expectedSubjectId.isNotEmpty,
    );
  }

  /// (A) Game-content-item view of the Memory Match contract (Phase 11 —
  /// Gate 4): the item must be a `CONCEPT` for exactly `memory_match`.
  ///
  /// Semantic note: pairs are term↔definition (topicName↔definition), a
  /// legitimate educational relationship from the backend payload — never
  /// question↔options[0]. `QUESTION` items (which withhold answers) can never
  /// enter Memory Match through this gate, so no fabricated pair like
  /// "What is TCP?"↔options[0] is possible here.
  static String? validateMemoryPairItem({
    required GameContentItem item,
    String? expectedSubjectId,
    String? expectedTopicId,
  }) {
    if (item.kindEnum != GameContentKind.concept) {
      return 'Content item ${item.id} is ${item.kind}, not CONCEPT; '
          'rejected for memory_match (no MCQ options[0] pairing).';
    }
    return validateItem(
      item: item,
      expectedSubjectId: expectedSubjectId,
      expectedTopicId: expectedTopicId,
      expectedGameType: 'memory_match',
      subjectMode: expectedSubjectId != null && expectedSubjectId.isNotEmpty,
    );
  }

  /// (A) Game-content-item view of the Drag & Drop contract (Phase 11 —
  /// Gate 5): the item must be a `STRUCTURE` item for exactly `drag_drop`.
  ///
  /// Semantic note: zones are the item's own backend difficulty and items
  /// are authoritative topic names placed into their own difficulty zone —
  /// never questionText->label with options[0]->zone. `QUESTION` items
  /// (which withhold answers) can never enter Drag & Drop through this gate.
  static String? validateDragDropItem({
    required GameContentItem item,
    String? expectedSubjectId,
    String? expectedTopicId,
  }) {
    if (item.kindEnum != GameContentKind.structure) {
      return 'Content item ${item.id} is ${item.kind}, not STRUCTURE; '
          'rejected for drag_drop (no MCQ fabrication).';
    }
    return validateItem(
      item: item,
      expectedSubjectId: expectedSubjectId,
      expectedTopicId: expectedTopicId,
      expectedGameType: 'drag_drop',
      subjectMode: expectedSubjectId != null && expectedSubjectId.isNotEmpty,
    );
  }

  /// (A) Game-content-item view of the Concept Builder contract (Phase 11 —
  /// Gate 6): the item must be a `CONCEPT` item for exactly
  /// `concept_builder`.
  ///
  /// Semantic note: blocks are the backend definition's own sentences in
  /// the definition's own order (correctOrder = definition order) — never
  /// MCQ options or question text repurposed as blocks. `QUESTION` items
  /// can never enter Concept Builder through this gate.
  static String? validateConceptBuilderItem({
    required GameContentItem item,
    String? expectedSubjectId,
    String? expectedTopicId,
  }) {
    if (item.kindEnum != GameContentKind.concept) {
      return 'Content item ${item.id} is ${item.kind}, not CONCEPT; '
          'rejected for concept_builder (no MCQ conversion).';
    }
    return validateItem(
      item: item,
      expectedSubjectId: expectedSubjectId,
      expectedTopicId: expectedTopicId,
      expectedGameType: 'concept_builder',
      subjectMode: expectedSubjectId != null && expectedSubjectId.isNotEmpty,
    );
  }

  /// (A) Game-content-item view of the Speed Run contract (Phase 11 —
  /// Gate 3): the item must be a `QUESTION` for exactly `speed_run`.
  /// Answer absence is expected (server-graded via QUIZ-002); use
  /// [validateAnswerInOptions] only for locally-graded flows (B), never
  /// for Speed Run.
  ///
  /// Contract note: QUIZ-001 itself is game-agnostic (no gameType field) —
  /// Quiz Battle and Speed Run share it by design, and the route determines
  /// the game. This validator applies at the GameContentItem layer, where
  /// gameType IS authoritative: `quiz_battle` items never enter Speed Run.
  static String? validateSpeedRunItem({
    required GameContentItem item,
    String? expectedSubjectId,
    String? expectedTopicId,
  }) {
    if (item.kindEnum != GameContentKind.question) {
      return 'Content item ${item.id} is ${item.kind}, not QUESTION; '
          'rejected for speed_run.';
    }
    return validateItem(
      item: item,
      expectedSubjectId: expectedSubjectId,
      expectedTopicId: expectedTopicId,
      expectedGameType: 'speed_run',
      subjectMode: expectedSubjectId != null && expectedSubjectId.isNotEmpty,
    );
  }
}
