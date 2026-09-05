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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasSubject = config.subjectId != null && config.subjectId!.isNotEmpty;
    final subjectLabel = hasSubject ? (config.subjectName?.isNotEmpty == true ? config.subjectName! : 'World') : 'GAME ZONE';
    final topicLabel = config.topicName ?? (config.topicId.length > 8 ? config.topicId.substring(0, 8) : config.topicId);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Subject-aware context banner — UI-6
                Semantics(
                  label: hasSubject
                      ? 'Subject $subjectLabel, topic $topicLabel, game ${config.type.displayName}'
                      : 'General game ${config.type.displayName}, topic $topicLabel',
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: isDark ? AppColors.border : AppLightColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: hasSubject ? AppColors.primary.withValues(alpha: 0.12) : AppColors.textTertiary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: hasSubject ? AppColors.primary.withValues(alpha: 0.22) : AppColors.textTertiary.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            hasSubject ? subjectLabel.toUpperCase() : 'GENERAL',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: hasSubject ? AppColors.primary : AppColors.textTertiary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(hasSubject ? Icons.topic_rounded : Icons.sports_esports_rounded, size: 12, color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hasSubject ? '$topicLabel • ${config.type.displayName}' : '${config.type.displayName} • $topicLabel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(config.difficulty.displayName.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary)),
                      ],
                    ),
                  ),
                ),
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
