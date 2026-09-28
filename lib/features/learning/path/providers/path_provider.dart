import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/user_facing_error.dart';
import '../../../../core/models/content_models.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/providers.dart';

/// Learning-path state for one subject: existing paths (PATH-001), optional
/// AI metadata from a fresh generation (PATH-002), and generation progress.
class PathState {
  const PathState({
    required this.paths,
    this.aiMetadata = const {},
    this.generating = false,
    this.loading = false,
    this.error,
  });

  final List<LearningPath> paths;
  final Map<int, ({String objective, String rationale})> aiMetadata;
  final bool generating;
  final bool loading;
  final String? error;

  LearningPath? get activePath {
    for (final p in paths) {
      if (p.status == 'ACTIVE') return p;
    }
    return null;
  }

  bool get showLoading => loading && paths.isEmpty && !generating;

  PathState copyWith({
    List<LearningPath>? paths,
    Map<int, ({String objective, String rationale})>? aiMetadata,
    bool? generating,
    bool? loading,
    String? error,
    bool clearError = false,
  }) => PathState(
    paths: paths ?? this.paths,
    aiMetadata: aiMetadata ?? this.aiMetadata,
    generating: generating ?? this.generating,
    loading: loading ?? this.loading,
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
    if (state.loading) return;
    state = state.copyWith(loading: true, generating: false, clearError: true);
    try {
      final paths = await ref
          .read(contentRepoProvider)
          .pathsForSubject(subjectId);
      if (!ref.mounted) return;
      try {
        state = state.copyWith(paths: paths, loading: false, clearError: true);
      } catch (_) {}
    } on ApiException catch (e) {
      if (!ref.mounted) return;
      try {
        state = state.copyWith(loading: false, error: describeError(e).message);
      } catch (_) {}
    } catch (_) {
      if (!ref.mounted) return;
      try {
        state = state.copyWith(
          loading: false,
          error: 'Could not load your path. Check your connection.',
        );
      } catch (_) {}
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
      if (!ref.mounted) return false;
      try {
        state = PathState(
          paths: paths,
          aiMetadata: result.aiMetadata,
          generating: false,
        );
      } catch (_) {}
      return true;
    } on ApiException catch (e) {
      if (!ref.mounted) return false;
      try {
        state = state.copyWith(
          generating: false,
          error: describeError(e).message,
        );
      } catch (_) {}
      return false;
    } catch (_) {
      if (!ref.mounted) return false;
      try {
        state = state.copyWith(
          generating: false,
          error: 'Generation failed. Check your connection and try again.',
        );
      } catch (_) {}
      return false;
    }
  }
}
