import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_styles.dart';

/// Visual state wrappers for game feedback — restrained glow/border/scale.
/// No timing-sensitive logic; safe for reusability across games.

enum FeedbackKind {
  correct,
  incorrect,
  warning,
  locked,
  success,
  reward,
  completed,
  info,
}

/// Maps feedback kind to semantic color (dark+light share).
Color _colorFor(FeedbackKind kind) => switch (kind) {
  FeedbackKind.correct => AppColors.success,
  FeedbackKind.success => AppColors.success,
  FeedbackKind.completed => AppColors.success,
  FeedbackKind.incorrect => AppColors.error,
  FeedbackKind.warning => AppColors.warning,
  FeedbackKind.locked => AppColors.locked,
  FeedbackKind.reward => AppColors.xp,
  FeedbackKind.info => AppColors.info,
};

IconData _iconFor(FeedbackKind kind) => switch (kind) {
  FeedbackKind.correct => Icons.check_circle_rounded,
  FeedbackKind.success => Icons.emoji_events_rounded,
  FeedbackKind.completed => Icons.verified_rounded,
  FeedbackKind.incorrect => Icons.cancel_rounded,
  FeedbackKind.warning => Icons.warning_rounded,
  FeedbackKind.locked => Icons.lock_rounded,
  FeedbackKind.reward => Icons.star_rounded,
  FeedbackKind.info => Icons.info_rounded,
};

/// Border + glow wrapper for correct/incorrect etc. Use around QuizOption or game tile.
class FeedbackBorder extends StatelessWidget {
  const FeedbackBorder({
    super.key,
    required this.kind,
    required this.child,
    this.selected = false,
    this.glow = true,
  });

  final FeedbackKind kind;
  final Widget child;
  final bool selected;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _colorFor(kind);
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: selected
              ? color
              : (isDark ? AppColors.border : AppLightColors.border),
          width: selected ? 1.6 : 1,
        ),
        boxShadow: selected && glow
            ? AppShadows.glow(color, alpha: isDark ? 0.22 : 0.12)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          color: selected
              ? color.withValues(alpha: isDark ? 0.08 : 0.05)
              : null,
          child: child,
        ),
      ),
    );
  }
}

/// Icon badge for feedback kind — 28px circle by default.
class FeedbackIcon extends StatelessWidget {
  const FeedbackIcon({
    super.key,
    required this.kind,
    this.size = 28,
    this.showGlow = false,
  });

  final FeedbackKind kind;
  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(kind);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: isDark ? 0.14 : 0.10),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        boxShadow: showGlow
            ? AppShadows.glow(color, alpha: isDark ? 0.28 : 0.14)
            : null,
      ),
      child: Icon(_iconFor(kind), size: size * 0.55, color: color),
    );
  }
}

/// Scale + glow emphasis for reward moments — subtle, one-off.
class FeedbackScale extends StatefulWidget {
  const FeedbackScale({super.key, required this.child, this.trigger = false});

  final Widget child;
  final bool trigger;

  @override
  State<FeedbackScale> createState() => _FeedbackScaleState();
}

class _FeedbackScaleState extends State<FeedbackScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: AppMotion.fast);
    _scale = Tween(
      begin: 1.0,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _c, curve: AppMotion.easeOut));
  }

  @override
  void didUpdateWidget(FeedbackScale old) {
    super.didUpdateWidget(old);
    if (widget.trigger && !old.trigger) {
      _c.forward().then((_) => _c.reverse());
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) return widget.child;
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

/// Full-width state banner for correct/incorrect feedback inside game screens.
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({
    super.key,
    required this.kind,
    required this.message,
    this.icon,
  });

  final FeedbackKind kind;
  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(kind);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(icon ?? _iconFor(kind), size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimary
                    : AppLightColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Locked overlay — dimmed with centered lock icon. Use over locked game cards.
class LockedOverlay extends StatelessWidget {
  const LockedOverlay({super.key, this.label = 'LOCKED'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.scrim,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, size: 22, color: Colors.white70),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
