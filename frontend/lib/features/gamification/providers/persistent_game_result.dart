import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../features/dashboard/providers/dashboard_provider.dart';
import '../data/gamification_repository.dart';
import '../models/game_result_models.dart';
import '../providers/game_results_provider.dart';

/// Wraps the existing game-to-result push so that completing a game
/// ALWAYS submits the result to the persistent gamification pipeline
/// (PROG-101) and refreshes the dashboard provider so the player sees
/// real XP/level progression when they return home. The local
/// `GameResultScreen` is shown immediately; the network call runs in
/// parallel and the dashboard provider refetches on success.
///
/// Game screens keep their existing `pushReplacement(GameResultScreen(...))`
/// behaviour unchanged by routing through [pushPersistentResult]. This
/// helper is intentionally additive and never blocks the user on a
/// network blip: failures degrade silently and the dashboard refetches
/// on the next read.
class PersistentGameResult {
  PersistentGameResult(this._ref);
  final Ref _ref;
  final Random _rng = Random();

  Future<void> pushPersistentResult({
    required BuildContext context,
    required Widget resultScreen,
    required String gameType,
    required bool completed,
    required int score,
    required int durationSeconds,
    required int bestCombo,
  }) async {
    // Show the local result screen first (zero blocking).
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => resultScreen),
    );

    // Fire the persistent submission in the background. Failures are
    // intentionally non-fatal: the local result remains the source of
    // truth for this run, and the dashboard provider refetches on its
    // own whenever the player returns home.
    unawaited(_submitInBackground(
      gameType: gameType,
      completed: completed,
      score: score,
      durationSeconds: durationSeconds,
      bestCombo: bestCombo,
    ));
  }

  Future<void> _submitInBackground({
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
      final response =
          await _ref.read(gameResultsProvider.notifier).submit(req);
      // Refresh dashboard + hub providers so the player sees the new XP /
      // level on return-home.
      _ref.invalidate(dashboardProvider);
      // Hub does not currently depend on a separate provider for game
      // results; the next visit to the hub will pick up fresh data via
      // its own fetch paths.
      if (response.leveledUp) {
        // Reserved for a future centered level-up celebration overlay;
        // currently surfaced via the response payload in the result panel.
      }
    } catch (_) {
      // Network blip / backend down: keep the local result, dashboard
      // refetches on next read; never block the player.
    }
  }

  String _newUuid() {
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20, 32)}';
  }
}

final persistentGameResultProvider =
    Provider<PersistentGameResult>((ref) => PersistentGameResult(ref));
