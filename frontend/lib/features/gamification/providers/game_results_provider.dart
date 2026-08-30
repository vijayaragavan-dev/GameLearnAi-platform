import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/gamification_repository.dart';
import '../models/game_result_models.dart';
import '../../../core/providers.dart';

/// Holds the outcome of the most recent game-result submission so screens
/// can render the real XP / level-up. Backend remains the source of truth;
/// the dashboard / hub providers re-fetch after a successful submit.
class GameResultsNotifier extends StateNotifier<GameResultsState> {
  GameResultsNotifier(this._repo) : super(GameResultsState());

  final GamificationRepository _repo;

  Future<GameResultSubmissionResponse> submit(
      GameResultSubmission submission) async {
    final response = await _repo.submitGameResult(submission);
    state = state.copyWith(latestResponse: response);
    return response;
  }

  void clear() {
    state = const GameResultsState();
  }
}

class GameResultsState {
  const GameResultsState({this.latestResponse, this.error});
  final GameResultSubmissionResponse? latestResponse;
  final Object? error;

  GameResultsState copyWith({
    GameResultSubmissionResponse? latestResponse,
    Object? error,
    bool clearError = false,
  }) =>
      GameResultsState(
        latestResponse: latestResponse ?? this.latestResponse,
        error: clearError ? null : (error ?? this.error),
      );
}

final gameResultsProvider =
    StateNotifierProvider<GameResultsNotifier, GameResultsState>((ref) {
  return GameResultsNotifier(ref.watch(gamificationRepoProvider));
});
