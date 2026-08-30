import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../models/game_models.dart';
import 'game_hud.dart';
import '../engine/game_combo.dart';

/// Consistent scaffold for all games: HUD + body + optional pause overlay.
class GameScaffold extends StatelessWidget {
  const GameScaffold({
    super.key,
    required this.config,
    required this.score,
    required this.progress,
    required this.progressLabel,
    required this.timeLabel,
    required this.combo,
    required this.child,
    this.onPause,
    this.onSoundToggle,
    this.soundEnabled = true,
    this.paused = false,
    this.onResume,
    this.onExit,
  });

  final GameConfig config;
  final int score;
  final double progress;
  final String progressLabel;
  final String timeLabel;
  final GameCombo combo;
  final Widget child;
  final VoidCallback? onPause;
  final VoidCallback? onSoundToggle;
  final bool soundEnabled;
  final bool paused;
  final VoidCallback? onResume;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                GameHud(
                  score: score,
                  progress: progress,
                  progressLabel: progressLabel,
                  timeRemaining: timeLabel,
                  combo: combo,
                  difficultyLabel: config.difficulty.displayName,
                  onPause: onPause,
                  onSoundToggle: onSoundToggle,
                  soundEnabled: soundEnabled,
                ),
                Expanded(child: child),
              ],
            ),
          ),
          if (paused)
            Positioned.fill(
              child: Container(
                color: AppColors.scrim,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AppColors.border)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pause_circle_rounded, size: 48, color: AppColors.secondary),
                        const SizedBox(height: 12),
                        const Text('PAUSED', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2)),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(onPressed: onResume, icon: const Icon(Icons.play_arrow_rounded), label: const Text('RESUME')),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(onPressed: onExit, icon: const Icon(Icons.exit_to_app_rounded), label: const Text('EXIT GAME')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
