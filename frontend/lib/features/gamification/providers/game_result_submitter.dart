import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/gamification_repository.dart';
import '../models/game_result_models.dart';
import '../providers/game_results_provider.dart';

/// Helper used by existing game screens to submit a completed run
/// without breaking their public surface. A fresh client UUID is
/// generated on every call so the backend's idempotency key is unique
/// per attempt. A network blip is non-fatal — the player keeps the local
/// result screen and the dashboard / hub providers re-fetch on the next
/// read so a retry recovers.
class GameResultSubmitter {
  GameResultSubmitter(this._ref);
  final Ref _ref;
  final Random _rng = Random();

  Future<GameResultSubmissionResponse?> submit({
    required String gameType,
    required bool completed,
    required int score,
    required int durationSeconds,
    required int bestCombo,
  }) async {
    final req = GameResultSubmission(
      clientRequestId: _newUuid(),
      gameType: gameType,
      completed: completed,
      score: score,
      durationSeconds: durationSeconds,
      bestCombo: bestCombo,
    );
    try {
      final GameResultsNotifier notifier = _ref.read(gameResultsProvider.notifier);
      return await notifier.submit(req);
    } catch (_) {
      return null;
    }
  }

  String _newUuid() {
    // RFC4122 v4 layout using platform random; sufficient for an idempotency
    // key (server only requires uniqueness, not cryptographic security).
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 1
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20, 32)}';
  }
}

final gameResultSubmitterProvider =
    Provider<GameResultSubmitter>((ref) => GameResultSubmitter(ref));
