import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/content_models.dart';
import '../../../../core/providers.dart';

/// Learning-path state for one subject: existing paths (PATH-001), optional
/// AI metadata from a fresh generation (PATH-002), and generation progress.
class PathState {
  const PathState({
    required this.paths,
    this.aiMetadata = const {},
    this.generating = false,
    this.error,
  });

  final List<LearningPath> paths;
  final Map<int, ({String objective, String rationale})> aiMetadata;
  final bool generating;
  final String? error;

  LearningPath? get activePath {
    for (final p in paths) {
      if (p.status == 'ACTIVE') return p;
    }
    return null;
  }

  PathState copyWith({
    List<LearningPath>? paths,
    Map<int, ({String objective, String rationale})>? aiMetadata,
    bool? generating,
    String? error,
    bool clearError = false,
  }) => PathState(
    paths: paths ?? this.paths,
    aiMetadata: aiMetadata ?? this.aiMetadata,
    generating: generating ?? this.generating,
    error: clearError ? null : (error ?? this.error),
  );
}

final pathProvider = NotifierProvider.family<PathController, PathState, String>(
  PathController.new,
);

class PathController extends Notifier<PathState> {
  PathController(this.subjectId);

  final String subjectId;

  @override
  PathState build() => const PathState(paths: []);

  Future<void> load() async {
    state = state.copyWith(generating: false);
    try {
      final paths = await ref
          .read(contentRepoProvider)
          .pathsForSubject(subjectId);
      state = state.copyWith(paths: paths, clearError: true);
    } catch (_) {
      state = state.copyWith(error: 'Could not load your path');
    }
  }

  /// PATH-002. regenerate=false is an idempotent return when a path exists.
  Future<bool> generate({bool regenerate = false, String? learningGoal}) async {
    if (state.generating) return false;
    state = state.copyWith(generating: true, clearError: true);
    try {
      final result = await ref
          .read(contentRepoProvider)
          .generatePath(
            subjectId: subjectId,
            regenerate: regenerate,
            learningGoal: learningGoal,
          );
      // Refresh authoritative list from PATH-001 after creation.
      final paths = await ref
          .read(contentRepoProvider)
          .pathsForSubject(subjectId);
      state = PathState(
        paths: paths,
        aiMetadata: result.aiMetadata,
        generating: false,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        generating: false,
        error: 'Generation failed. Try again soon.',
      );
      return false;
    }
  }
}
