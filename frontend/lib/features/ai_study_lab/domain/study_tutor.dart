/// Document-grounded tutor domain (RAG-FE-3 UI foundation).
///
/// FRONTEND product models only. The MlRag backend/API contract does not
/// exist yet, so NOTHING here parses server JSON or assumes REST paths,
/// streaming, scores, or history shapes. Fixture instances live ONLY in
/// tests (clearly marked), never in production paths.
library;

/// Who sent a chat message. Nova is the ONE assistant (no RAG alter ego).
enum ChatRole { learner, nova }

/// A source backing a grounded answer. EVERY field except [documentId]
/// is optional: the UI renders only fields that actually exist — page
/// numbers, sections, and snippets are never invented. Without any
/// metadata the answer must not claim grounding.
class GroundedSource {
  const GroundedSource({
    required this.documentId,
    this.documentTitle,
    this.page,
    this.section,
    this.snippet,
  });

  /// Stable owning-document identity (opaque string, never display text).
  final String documentId;

  /// Display title supplied by the caller (test fixture or future API).
  final String? documentTitle;

  /// 1-based page reference. Null means "no page information".
  final int? page;

  /// Section/heading reference. Null means "no section information".
  final String? section;

  /// Quoted source excerpt. Null means "no excerpt available".
  final String? snippet;

  /// True only when at least one concrete reference exists.
  bool get hasReference => page != null || section != null;
}

/// One conversation message. Local state only; maps onto the existing
/// [TutorMessage] shape (role/content) when a real backend arrives.
class DocumentChatMessage {
  const DocumentChatMessage({
    required this.role,
    required this.text,
    this.sources = const <GroundedSource>[],
    this.grounded = false,
  });

  final ChatRole role;
  final String text;

  /// Sources backing THIS answer. Empty for learner messages and for
  /// answers without grounding metadata.
  final List<GroundedSource> sources;

  /// True only when the backend supplied grounding metadata. The UI
  /// shows the grounded indicator exclusively from this flag — never
  /// assumed, never per-message guessed.
  final bool grounded;

  bool get isLearner => role == ChatRole.learner;
}

/// Explicit ask-document outcome (RAG-FE-3 backend boundary).
///
/// The repository returns one of these instead of throwing for expected
/// service states. Only a REAL backend-backed implementation may ever
/// return [TutorAnswer]; placeholder/test doubles must use
/// [TutorUnavailable]/[TutorFailure] ([TutorNoAnswer] likewise only
/// from a real retrieval pass that found nothing).
sealed class TutorAskResult {
  const TutorAskResult();
}

/// Real grounded answer with authoritative text + sources.
class TutorAnswer extends TutorAskResult {
  const TutorAnswer({
    required this.text,
    this.sources = const [],
    this.grounded = false,
  });

  final String text;
  final List<GroundedSource> sources;

  /// True only when the backend supplied grounding metadata. The UI
  /// shows the grounded indicator exclusively from this flag.
  final bool grounded;
}

/// Retrieval ran but found nothing usable in the document.
class TutorNoAnswer extends TutorAskResult {
  const TutorNoAnswer(this.message);

  final String message;
}

/// No document-AI service connected (current RAG-FE-3 reality).
class TutorUnavailable extends TutorAskResult {
  const TutorUnavailable(this.message);

  final String message;
}

/// Ask attempted but failed (transport/validation/server-side).
class TutorFailure extends TutorAskResult {
  const TutorFailure(this.message);

  final String message;
}

/// Suggestion prompts for the empty conversation. Prompts ONLY —
/// tapping one populates the composer; responses come exclusively
/// from a real backend implementation.
const List<String> documentTutorSuggestions = <String>[
  'Summarize this document',
  'Explain the main concepts',
  'What should I study first?',
  'Create practice questions',
];
