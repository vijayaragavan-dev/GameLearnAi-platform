import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/game_visual_identity.dart';
import '../../../shared/widgets/app_backgrounds.dart';
import '../models/game_models.dart';
import 'game_hud.dart';
import '../engine/game_combo.dart';

/// Premium gameplay scaffold — the shared shell for all 14 games.
/// Provides: atmospheric game world, identity-aware header, HUD,
/// challenge area, pause overlay. Keeps mechanics untouched.
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
    final identity = GameVisualRegistry.of(config.type);
    final hasSubject = config.subjectId != null && config.subjectId!.isNotEmpty;
    final subjectLabel = hasSubject ? (config.subjectName?.isNotEmpty == true ? config.subjectName! : 'World') : 'GAME ZONE';
    final topicLabel = config.topicName ?? (config.topicId.length > 8 ? config.topicId.substring(0, 8) : config.topicId);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Atmospheric game world — subtle per-game identity
          Positioned.fill(
            child: AtmosphericBackground(
              primaryGlow: identity.accent,
              secondaryGlow: AppColors.secondary,
              intensity: isDark ? 0.72 : 0.0,
              showStarField: true,
            ),
          ),
          if (isDark) ...[
            Positioned(top: -40, right: -30, child: GlowOrb(color: identity.accent, size: 260, opacity: 0.10)),
            Positioned(bottom: 80, left: -60, child: GlowOrb(color: AppColors.secondary, size: 220, opacity: 0.07)),
          ],
          SafeArea(
            child: Column(
              children: [
                // Premium subject-aware identity banner
                Semantics(
                  label: hasSubject
                      ? 'Subject $subjectLabel, topic $topicLabel, game ${config.type.displayName}'
                      : 'General game ${config.type.displayName}, topic $topicLabel',
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: hasSubject
                            ? [identity.accent.withValues(alpha: isDark ? 0.16 : 0.07), Theme.of(context).colorScheme.surface]
                            : [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surface],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: hasSubject ? identity.accent.withValues(alpha: isDark ? 0.32 : 0.22) : (isDark ? AppColors.border : AppLightColors.border)),
                      boxShadow: hasSubject && isDark ? [BoxShadow(color: identity.accent.withValues(alpha: 0.10), blurRadius: 14, offset: const Offset(0, 4))] : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: hasSubject ? identity.accent.withValues(alpha: 0.14) : AppColors.textTertiary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: hasSubject ? identity.accent.withValues(alpha: 0.28) : AppColors.textTertiary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(identity.icon, size: 11, color: hasSubject ? identity.accent : AppColors.textTertiary),
                              const SizedBox(width: 4),
                              Text(
                                hasSubject ? subjectLabel.toUpperCase() : 'GENERAL',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: hasSubject ? identity.accent : AppColors.textTertiary),
                              ),
                            ],
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceHigh : AppLightColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: isDark ? AppColors.border : AppLightColors.border),
                          ),
                          child: Text(config.difficulty.displayName.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: isDark ? AppColors.textTertiary : AppLightColors.textTertiary)),
                        ),
                      ],
                    ),
                  ),
                ),
                // Premium identity HUD bar — accent-aware
                GameHud(
                  score: score,
                  progress: progress,
                  progressLabel: progressLabel,
                  timeRemaining: timeLabel,
                  combo: combo,
                  difficultyLabel: config.difficulty.displayName,
                  accent: identity.accent,
                  gameIcon: identity.icon,
                  gameTitle: config.type.displayName,
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
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [identity.accent.withValues(alpha: 0.14), AppColors.surface]
                            : [identity.accent.withValues(alpha: 0.06), AppLightColors.surface],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(color: identity.accent.withValues(alpha: 0.32)),
                      boxShadow: [BoxShadow(color: identity.accent.withValues(alpha: 0.18), blurRadius: 22, offset: const Offset(0, 8))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [identity.accent, identity.accent.withValues(alpha: 0.8)])),
                          child: const Icon(Icons.pause_rounded, size: 28, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        const Text('PAUSED', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2)),
                        const SizedBox(height: 6),
                        Text(config.type.displayName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: identity.accent)),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(onPressed: onResume, icon: const Icon(Icons.play_arrow_rounded), label: const Text('RESUME'), style: FilledButton.styleFrom(backgroundColor: identity.accent)),
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
