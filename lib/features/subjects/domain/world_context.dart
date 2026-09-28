import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/content_models.dart';
import '../../../core/providers.dart';
import 'canonical_worlds.dart';

/// World context — a lightweight, first-class frontend concept binding a
/// navigation/game/tutor entry point to its learning world.
///
/// Identity rules (never violated):
/// - [WorldId] is the stable frontend canonical identity (presentation +
///   scoping). It NEVER replaces backend ids.
/// - [subjectId] is backend-authoritative (UUID from SUBJ-001).
/// - [topicId] is backend-authoritative (UUID from TOPIC-001).
/// All three coexist. Context travels via route parameters and widget
/// constructors — never via a global mutable singleton.
///
/// Resolution: backend [Subject] → [WorldCatalog] → [WorldDefinition] →
/// [WorldId]. Unknown subjects yield a context with null [worldId] and
/// callers MUST use generic fallback behavior (never throw).
class WorldContext {
  const WorldContext({
    this.worldId,
    this.subjectId,
    this.subjectName,
    this.topicId,
    this.topicName,
  });

  /// Canonical world, or null when the backend subject is unmapped/unknown.
  final WorldId? worldId;

  /// Backend-authoritative subject UUID (may be null in global contexts).
  final String? subjectId;
  final String? subjectName;
  final String? topicId;
  final String? topicName;

  WorldDefinition? get definition => WorldCatalog.byId(worldId);

  /// True when this context carries a known world + backend subject.
  bool get isWorldScoped =>
      worldId != null && subjectId != null && subjectId!.isNotEmpty;

  /// The gameplay scope implied by this context: isolated world play only
  /// when fully scoped, otherwise the mixed Global Game Arena.
  WorldScope get scope =>
      isWorldScoped ? WorldScope.subjectIsolated : WorldScope.globalArena;

  WorldContext copyWith({
    WorldId? worldId,
    String? subjectId,
    String? subjectName,
    String? topicId,
    String? topicName,
  }) =>
      WorldContext(
        worldId: worldId ?? this.worldId,
        subjectId: subjectId ?? this.subjectId,
        subjectName: subjectName ?? this.subjectName,
        topicId: topicId ?? this.topicId,
        topicName: topicName ?? this.topicName,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldContext &&
          worldId == other.worldId &&
          subjectId == other.subjectId &&
          subjectName == other.subjectName &&
          topicId == other.topicId &&
          topicName == other.topicName;

  @override
  int get hashCode =>
      Object.hash(worldId, subjectId, subjectName, topicId, topicName);
}

/// Resolve a world context from backend data. Never throws: unmapped
/// subjects produce a context with null [WorldContext.worldId].
WorldContext resolveWorldContext({
  Subject? subject,
  String? subjectId,
  String? subjectName,
  String? topicId,
  String? topicName,
}) {
  final effectiveSubjectId = subject?.id ?? subjectId;
  final effectiveSubjectName = subject?.name ?? subjectName;
  WorldDefinition? definition;
  if (subject != null) {
    definition = WorldCatalog.resolveSubject(subject);
  } else if (effectiveSubjectName != null &&
      effectiveSubjectName.trim().isNotEmpty) {
    definition = WorldCatalog.resolveDisplayName(effectiveSubjectName);
  }
  return WorldContext(
    worldId: definition?.id,
    subjectId: effectiveSubjectId,
    subjectName: effectiveSubjectName,
    topicId: topicId,
    topicName: topicName,
  );
}

// ── Shared cached subject catalog ──────────────────────────────────────────
// Screens resolve route subjectIds through this single provider instead of
// issuing duplicate `contentRepo.subjects()` FutureBuilders (dashboard,
// champions arena, subjects, tutor, world landing share one cached fetch).
// Backend remains authoritative; this is a read-through cache only.

/// All backend subjects, cached while watched. Never fabricated.
final subjectsProvider = FutureProvider<List<Subject>>((ref) async {
  return ref.watch(contentRepoProvider).subjects();
});

/// Look up one backend subject by id from the shared catalog.
/// Null while loading, on error, or when the id is unknown.
final subjectByIdProvider = Provider.family<Subject?, String?>((ref, id) {
  if (id == null || id.isEmpty) return null;
  final async = ref.watch(subjectsProvider);
  final subjects = async.asData?.value;
  if (subjects == null) return null;
  for (final s in subjects) {
    if (s.id == id) return s;
  }
  return null;
});

/// Canonical world for a backend subject id (null when unmapped/unknown).
final worldForSubjectIdProvider =
    Provider.family<WorldDefinition?, String?>((ref, subjectId) {
  final subject = ref.watch(subjectByIdProvider(subjectId));
  if (subject == null) return null;
  return WorldCatalog.resolveSubject(subject);
});

/// World context for a (subjectId, topicId) route pair. Rebuilt from route
/// parameters — switching DBMS → OS → DBMS yields a fresh context per id, so
/// scoped family providers (path, assessment, leaderboard) reload instead of
/// showing stale content.
final worldContextProvider = Provider.family<WorldContext, WorldContextArgs>(
  (ref, args) {
    final subject = ref.watch(subjectByIdProvider(args.subjectId));
    return resolveWorldContext(
      subject: subject,
      subjectId: args.subjectId,
      subjectName: args.subjectName,
      topicId: args.topicId,
      topicName: args.topicName,
    );
  },
);

/// Route-pair key for [worldContextProvider].
class WorldContextArgs {
  const WorldContextArgs({
    this.subjectId,
    this.subjectName,
    this.topicId,
    this.topicName,
  });

  final String? subjectId;
  final String? subjectName;
  final String? topicId;
  final String? topicName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldContextArgs &&
          subjectId == other.subjectId &&
          subjectName == other.subjectName &&
          topicId == other.topicId &&
          topicName == other.topicName;

  @override
  int get hashCode =>
      Object.hash(subjectId, subjectName, topicId, topicName);
}
