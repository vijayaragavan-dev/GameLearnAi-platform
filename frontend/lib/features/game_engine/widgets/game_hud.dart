import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../engine/game_combo.dart';

/// Reusable HUD for games: score, timer, progress, combo, difficulty.
class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.score,
    required this.progress,
    required this.progressLabel,
    required this.timeRemaining,
    required this.combo,
    required this.difficultyLabel,
    this.onPause,
    this.onSoundToggle,
    this.soundEnabled = true,
  });

  final int score;
  final double progress; // 0..1
  final String progressLabel;
  final String timeRemaining; // formatted mm:ss
  final GameCombo combo;
  final String difficultyLabel;
  final VoidCallback? onPause;
  final VoidCallback? onSoundToggle;
  final bool soundEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _Pill(label: difficultyLabel, color: AppColors.secondary),
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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _timerColor(timeRemaining).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: _timerColor(timeRemaining).withValues(alpha: 0.4)),
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
                backgroundColor: AppColors.surfaceHigh,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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
    // Parse mm:ss or plain seconds string
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
