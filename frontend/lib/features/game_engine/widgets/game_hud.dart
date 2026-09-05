import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/game_visual_identity.dart';
import '../../../features/game_engine/models/game_models.dart';
import '../engine/game_combo.dart';

/// Premium HUD for games: score, timer, progress, combo, difficulty.
/// Accent-aware — tints progress and difficulty pill with game identity.
class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.score,
    required this.progress,
    required this.progressLabel,
    required this.timeRemaining,
    required this.combo,
    required this.difficultyLabel,
    this.accent,
    this.gameIcon,
    this.gameTitle,
    this.onPause,
    this.onSoundToggle,
    this.soundEnabled = true,
  });

  final int score;
  final double progress;
  final String progressLabel;
  final String timeRemaining;
  final GameCombo combo;
  final String difficultyLabel;
  final Color? accent;
  final IconData? gameIcon;
  final String? gameTitle;
  final VoidCallback? onPause;
  final VoidCallback? onSoundToggle;
  final bool soundEnabled;

  Color _resolveAccent(BuildContext context) {
    if (accent != null) return accent!;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final a = _resolveAccent(context);
    final showIdentity = gameIcon != null && gameTitle != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [a.withValues(alpha: 0.08), AppColors.surface.withValues(alpha: 0.96)]
              : [a.withValues(alpha: 0.04), AppColors.surface.withValues(alpha: 0.98)],
        ),
        border: Border(
          bottom: BorderSide(color: a.withValues(alpha: isDark ? 0.22 : 0.14)),
          top: BorderSide(color: a.withValues(alpha: 0.10), width: 1),
        ),
        boxShadow: isDark ? [BoxShadow(color: a.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))] : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (showIdentity) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: a.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: a.withValues(alpha: 0.32)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(gameIcon, size: 12, color: a),
                      const SizedBox(width: 4),
                      Text(gameTitle!.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: a)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              _Pill(label: difficultyLabel, color: a),
              const Spacer(),
              Semantics(
                label: 'Score $score',
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 18, color: AppColors.xp),
                    const SizedBox(width: 4),
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.xp,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                label: 'Time remaining $timeRemaining',
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _timerColor(timeRemaining).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: _timerColor(timeRemaining).withValues(alpha: 0.4)),
                    boxShadow: _timerColor(timeRemaining) == AppColors.error ? [BoxShadow(color: AppColors.error.withValues(alpha: 0.18), blurRadius: 10)] : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: _timerColor(timeRemaining)),
                      const SizedBox(width: 5),
                      Text(
                        timeRemaining,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _timerColor(timeRemaining)),
                      ),
                    ],
                  ),
                ),
              ),
              if (onSoundToggle != null) ...[
                const SizedBox(width: 8),
                Semantics(
                  label: soundEnabled ? 'Sound on, tap to mute' : 'Sound off, tap to enable',
                  button: true,
                  child: IconButton(
                    tooltip: soundEnabled ? 'Mute' : 'Unmute',
                    onPressed: onSoundToggle,
                    icon: Icon(soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded, size: 18, color: soundEnabled ? AppColors.textSecondary : AppColors.textTertiary),
                    constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
              if (onPause != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Pause',
                  onPressed: onPause,
                  icon: const Icon(Icons.pause_rounded, size: 18),
                  constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                  padding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: AppMotion.fast,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value.clamp(0, 1),
                minHeight: 6,
                backgroundColor: isDark ? AppColors.surfaceHigh : AppLightColors.surfaceHigh,
                valueColor: AlwaysStoppedAnimation<Color>(a),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(progressLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1)),
              const Spacer(),
              if (combo.current >= 2)
                Semantics(
                  label: combo.label,
                  child: AnimatedSwitcher(
                    duration: AppMotion.fast,
                    child: Container(
                      key: ValueKey(combo.current),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: combo.isOnFire ? AppGradients.streakFire : AppGradients.xpGold,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        boxShadow: combo.isOnFire ? [BoxShadow(color: AppColors.streak.withValues(alpha: 0.28), blurRadius: 10)] : null,
                      ),
                      child: Text(combo.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textOnColor)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _timerColor(String time) {
    final parts = time.split(':');
    int total = 0;
    if (parts.length == 2) total = (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    else total = int.tryParse(time) ?? 99;
    if (total <= 10) return AppColors.error;
    if (total <= 30) return AppColors.warning;
    return AppColors.textSecondary;
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: color.withValues(alpha: 0.45))),
        child: Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: color)),
      );
}
