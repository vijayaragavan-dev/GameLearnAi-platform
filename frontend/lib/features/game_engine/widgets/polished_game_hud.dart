import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../engine/game_combo.dart';

/// Polished, reusable HUD for games that need lives, score, timer, progress, combo.
/// Uses existing theme and is lightweight. Does not replace GameHud, but provides
/// a consistent alternative for future games and can be adopted incrementally.
class PolishedGameHud extends StatelessWidget {
  const PolishedGameHud({
    super.key,
    required this.gameTitle,
    required this.gameColor,
    required this.gameIcon,
    required this.score,
    required this.progress,
    required this.progressLabel,
    required this.timeRemaining,
    required this.combo,
    required this.lives,
    this.onPause,
    this.onHint,
  });

  final String gameTitle;
  final Color gameColor;
  final String gameIcon;
  final int score;
  final double progress;
  final String progressLabel;
  final String timeRemaining;
  final GameCombo combo;
  final int lives;
  final VoidCallback? onPause;
  final VoidCallback? onHint;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$gameTitle HUD, progress $progressLabel, score $score, time $timeRemaining',
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.96),
          border: Border(bottom: BorderSide(color: AppColors.border)),
          boxShadow: [BoxShadow(color: gameColor.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: gameColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: gameColor.withValues(alpha: 0.45))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(gameIcon, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(gameTitle.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: gameColor)),
                    ],
                  ),
                ),
                const Spacer(),
                Semantics(
                  label: 'Score $score',
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 18, color: AppColors.xp),
                      const SizedBox(width: 4),
                      Text('$score', style: const TextStyle(fontFamily: AppTypography.displayFamily, fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.xp)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
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
                        Text(timeRemaining, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _timerColor(timeRemaining))),
                      ],
                    ),
                  ),
                ),
                if (onHint != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Hint',
                    onPressed: onHint,
                    icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                    constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                    padding: EdgeInsets.zero,
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
                  valueColor: AlwaysStoppedAnimation<Color>(gameColor),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(progressLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 1)),
                const Spacer(),
                Semantics(
                  label: 'Lives $lives of 3',
                  child: Row(
                    children: List.generate(3, (i) {
                      final alive = i < lives;
                      return Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                        child: Icon(alive ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 16, color: alive ? AppColors.error : AppColors.textTertiary),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 8),
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
