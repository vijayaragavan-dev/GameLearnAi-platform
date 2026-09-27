import 'package:flutter/material.dart';

/// AI Study Lab document identity (RAG-FE-1 UI foundation).
///
/// These are FRONTEND presentation models only. There is deliberately NO
/// backend DTO, NO REST path, and NO parsing from server JSON here: the
/// MlRag API contract is audited separately and does not exist yet.
/// Instances in production code paths MUST come from
/// [StudyLabRepository]; only widget tests may construct fixtures
/// directly (clearly marked there as local UI fixtures, never presented
/// as backend data).
enum DocumentFileType {
  pdf,
  docx,
  txt,
  unknown;

  /// File extension label shown on cards. Never a capability claim.
  String get extensionLabel => switch (this) {
    DocumentFileType.pdf => 'PDF',
    DocumentFileType.docx => 'DOCX',
    DocumentFileType.txt => 'TXT',
    DocumentFileType.unknown => 'FILE',
  };

  IconData get icon => switch (this) {
    DocumentFileType.pdf => Icons.picture_as_pdf_rounded,
    DocumentFileType.docx => Icons.description_rounded,
    DocumentFileType.txt => Icons.text_snippet_rounded,
    DocumentFileType.unknown => Icons.insert_drive_file_rounded,
  };
}

/// Lifecycle of a study document as the UI may honestly render it.
enum DocumentStatus {
  /// Indexed and openable for study experiences.
  ready,

  /// Accepted; extraction/indexing still running. No content to show yet.
  processing,

  /// Extraction/indexing reported failure. Retry affordance only.
  failed,

  /// Known reference that cannot be opened (service or source missing).
  unavailable,
}

/// A study document as rendered by the AI Study Lab UI.
///
/// Identity is the stable [id] (future backend key). All content fields
/// are nullable/optional on purpose: the UI renders placeholders and
/// honest unavailable states instead of inventing values.
class StudyDocument {
  const StudyDocument({
    required this.id,
    required this.title,
    required this.fileType,
    required this.status,
    this.topicCount,
    this.lastStudiedLabel,
    this.progressFraction,
    this.failureMessage,
  }) : assert(
         progressFraction == null ||
             (progressFraction >= 0 && progressFraction <= 1),
         'progressFraction must be within 0..1',
       );

  /// Stable document identity (opaque string; never display text).
  final String id;
  final String title;
  final DocumentFileType fileType;
  final DocumentStatus status;

  /// Extracted topic count — present ONLY when the service reported one.
  final int? topicCount;

  /// Pre-formatted recency label supplied by the caller (tests/fixtures).
  /// Production must pass backend-provided values, never compute display
  /// strings from raw timestamps here.
  final String? lastStudiedLabel;

  /// 0..1 learning progress — present ONLY when real progress exists.
  final double? progressFraction;

  /// Service-reported failure reason. Shown verbatim only when present;
  /// otherwise a generic honest message is used.
  final String? failureMessage;

  bool get isReady => status == DocumentStatus.ready;
  bool get isProcessing => status == DocumentStatus.processing;
}

/// Workspace learning actions. Availability is resolved per document by
/// the workspace screen — actions without an implementation behind them
/// render locked and explain honestly instead of navigating.
enum StudyLabAction {
  study,
  askNova,
  practice,
  play;

  String get title => switch (this) {
    StudyLabAction.study => 'Study',
    StudyLabAction.askNova => 'Ask Nova',
    StudyLabAction.practice => 'Practice',
    StudyLabAction.play => 'Play',
  };

  String get blurb => switch (this) {
    StudyLabAction.study => 'Read your document as a guided lesson.',
    StudyLabAction.askNova => 'Ask Nova about this document.',
    StudyLabAction.practice => 'Drills generated from your document.',
    StudyLabAction.play => 'Turn this document into games.',
  };

  IconData get icon => switch (this) {
    StudyLabAction.study => Icons.menu_book_rounded,
    StudyLabAction.askNova => Icons.psychology_rounded,
    StudyLabAction.practice => Icons.fitness_center_rounded,
    StudyLabAction.play => Icons.sports_esports_rounded,
  };
}
