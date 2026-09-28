import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/models/leaderboard_models.dart';
import '../../../core/providers.dart';

class LeaderboardState {
  const LeaderboardState({this.data, this.error, this.loading = false});

  final LeaderboardResponse? data;
  final Object? error;
  final bool loading;

  bool get showLoading => loading && data == null;

  LeaderboardState copyWith({
    LeaderboardResponse? data,
    bool clearData = false,
    Object? error,
    bool clearError = false,
    bool? loading,
  }) =>
      LeaderboardState(
        data: clearData ? null : (data ?? this.data),
        error: clearError ? null : (error ?? this.error),
        loading: loading ?? this.loading,
      );
}

class OverallLeaderboardController extends Notifier<LeaderboardState> {
  @override
  LeaderboardState build() {
    Future<void>.microtask(() => load());
    return const LeaderboardState(loading: true);
  }

  Future<void> load({int page = 1, int size = 20, bool includeTop = true}) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final repo = ref.read(leaderboardRepoProvider);
      final data = await repo.overall(page: page, size: size, includeTop: includeTop);
      if (!ref.mounted) return;
      state = LeaderboardState(data: data);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(loading: false, error: e);
    }
  }

  Future<void> refresh({int page = 1, int size = 20, bool includeTop = true}) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final repo = ref.read(leaderboardRepoProvider);
      final fresh = await repo.overall(page: page, size: size, includeTop: includeTop);
      if (!ref.mounted) return;
      state = LeaderboardState(data: fresh);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(loading: false, error: e);
    }
  }
}

final overallLeaderboardProvider =
    NotifierProvider<OverallLeaderboardController, LeaderboardState>(OverallLeaderboardController.new);

final selectedSubjectIdProvider = StateProvider<String?>((ref) => null);

final subjectLeaderboardProvider = FutureProvider<LeaderboardResponse>((ref) async {
  final subjectId = ref.watch(selectedSubjectIdProvider);
  if (subjectId == null || subjectId!.isEmpty) throw ArgumentError('subjectId required');
  final repo = ref.watch(leaderboardRepoProvider);
  return repo.subject(subjectId);
});

// My position
class MyPositionState {
  const MyPositionState({this.data, this.error, this.loading = false});
  final LeaderboardPosition? data;
  final Object? error;
  final bool loading;
  bool get showLoading => loading && data == null;
}

class MyPositionController extends Notifier<MyPositionState> {
  @override
  MyPositionState build() {
    Future<void>.microtask(() => loadOverall());
    return const MyPositionState(loading: true);
  }

  Future<void> loadOverall() async {
    state = const MyPositionState(loading: true);
    try {
      final repo = ref.read(leaderboardRepoProvider);
      final data = await repo.myPosition(segment: 'OVERALL');
      if (!ref.mounted) return;
      state = MyPositionState(data: data);
    } catch (e) {
      if (!ref.mounted) return;
      state = MyPositionState(error: e);
    }
  }

  Future<void> loadSubject(String subjectId) async {
    if (subjectId.isEmpty) {
      state = const MyPositionState(error: 'subjectId required');
      return;
    }
    state = const MyPositionState(loading: true);
    try {
      final repo = ref.read(leaderboardRepoProvider);
      final data = await repo.myPosition(segment: 'SUBJECT', subjectId: subjectId);
      if (!ref.mounted) return;
      state = MyPositionState(data: data);
    } catch (e) {
      if (!ref.mounted) return;
      state = MyPositionState(error: e);
    }
  }

  Future<void> refreshOverall() => loadOverall();
  Future<void> refreshSubject(String subjectId) => loadSubject(subjectId);
}

final myPositionProvider = NotifierProvider<MyPositionController, MyPositionState>(MyPositionController.new);

// Dashboard lightweight provider uses myPosition overall
final dashboardLeaderboardProvider = NotifierProvider<MyPositionController, MyPositionState>(MyPositionController.new);
