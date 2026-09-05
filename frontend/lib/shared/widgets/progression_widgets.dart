import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_typography.dart';

/// GameLearn AI progression visual language.
///
/// Reusable primitives that make learning states immediately readable:
///   COMPLETED  → positive green treatment
///   CURRENT    → strong accent treatment
///   AVAILABLE  → clear action treatment
///   LOCKED     → muted treatment
///   REWARD     → gold warm treatment
///
/// ALL values are passed in from real data — nothing is hardcoded here.
/// Never display placeholder XP, fake levels, or invented progress.

// ─────────────────────────────────────────────────────────────────────────────
// MASTERY ORB — circular mastery state indicator
// ─────────────────────────────────────────────────────────────────────────────

/// Circular mastery display with state-driven color and optional glow.
/// Fraction (0..1) must come from real backend masteryScore.
class MasteryOrb extends StatelessWidget {
  const MasteryOrb({
    super.key,
    required this.fraction, // 0..1 from real masteryScore
    this.size = 56,
    this.label,
    this.animate = true,
  });

  final double fraction;
  final double size;
  final String? label;
  final bool animate;

  Color _colorFor(double f) {
    if (f >= 0.8) return AppColors.success;
    if (f >= 0.5) return AppColors.warning;
    if (f >= 0.25) return AppColors.info;
    return AppColors.locked;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clamped = fraction.clamp(0.0, 1.0);
    final color = _colorFor(clamped);
    final reduce = AppMotion.reducedMotion(context);

    return Semantics(
      label: label ?? '${(clamped * 100).round()} percent mastery',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow ring
            if (isDark && clamped > 0)
              SizedBox(
                width: size,
                height: size,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.28),
                        blurRadius: 14,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
            // Track
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: animate && !reduce
                    ? null // handled by TweenAnimationBuilder below
                    : clamped,
                strokeWidth: size * 0.10,
                backgroundColor: isDark
                    ? AppColors.surfaceHigh
                    : AppLightColors.surfaceHigh,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            // Animated fill
            if (animate && !reduce)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: clamped),
                duration: AppMotion.celebration,
                curve: AppMotion.easeOut,
                builder: (context, v, _) => SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    value: v,
                    strokeWidth: size * 0.10,
                    backgroundColor: isDark
                        ? AppColors.surfaceHigh
                        : AppLightColors.surfaceHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
            // Center label
            Text(
              '${(clamped * 100).round()}%',
              style: TextStyle(
                fontFamily: AppTypography.displayFamily,
                fontSize: size * 0.22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PATH NODE INDICATOR — learning path node visual
// ─────────────────────────────────────────────────────────────────────────────

/// Visual indicator for a learning path node.
/// Status MUST come from the backend PathNode.status field:
/// LOCKED | AVAILABLE | IN_PROGRESS | COMPLETED
class PathNodeIndicator extends StatelessWidget {
  const PathNodeIndicator({
    super.key,
    required this.status, // backend: LOCKED | AVAILABLE | IN_PROGRESS | COMPLETED
    this.sequenceNumber,
    this.size = 44,
    this.onTap,
  });

  final String status;
  final int? sequenceNumber;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = status.toUpperCase();

    final Color color;
    final Color bgColor;
    final IconData icon;
    final bool glowing;

    switch (s) {
      case 'COMPLETED':
        color = AppColors.success;
        bgColor = AppColors.success.withValues(alpha: isDark ? 0.15 : 0.08);
        icon = AppIcons.completed;
        glowing = false;
      case 'IN_PROGRESS':
        color = AppColors.primary;
        bgColor = AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.09);
        icon = AppIcons.inProgress;
        glowing = true;
      case 'AVAILABLE':
        color = AppColors.secondary;
        bgColor = AppColors.secondary.withValues(alpha: isDark ? 0.14 : 0.07);
        icon = AppIcons.available;
        glowing = false;
      default: // LOCKED
        color = isDark ? AppColors.locked : AppLightColors.locked;
        bgColor = isDark
            ? AppColors.lockedSurface
            : AppLightColors.lockedSurface;
        icon = AppIcons.locked;
        glowing = false;
    }

    final inner = Semantics(
      button: onTap != null,
      label: 'Node ${sequenceNumber ?? ''} $s',
      child: GestureDetector(
        onTap: s == 'LOCKED' ? null : onTap,
        child: AnimatedContainer(
          duration: AppMotion.normal,
          curve: AppMotion.easeOut,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: Border.all(
              color: color.withValues(alpha: glowing ? 0.8 : 0.45),
              width: glowing ? 2.0 : 1.5,
            ),
            boxShadow: glowing && isDark
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: sequenceNumber != null && s == 'LOCKED'
              ? Text(
                  '$sequenceNumber',
                  style: TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontSize: size * 0.32,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                )
              : Icon(icon, size: size * 0.45, color: color),
        ),
      ),
    );

    return inner;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// XP EARNED DISPLAY — animated XP reveal
// ─────────────────────────────────────────────────────────────────────────────

/// Animated XP earned display — reveals the XP value with a count-up animation.
/// Pass real xpEarned from [GameResult.xpEarned] — never fabricate.
class XPEarnedDisplay extends StatelessWidget {
  const XPEarnedDisplay({
    super.key,
    required this.xpEarned, // from GameResult.xpEarned
    this.large = false,
    this.animate = true,
  });

  final int xpEarned;
  final bool large;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduce = AppMotion.reducedMotion(context);
    final numberSize = large ? 42.0 : 28.0;
    final labelSize = large ? 14.0 : 11.0;

    Widget numberWidget;
    if (animate && !reduce && xpEarned > 0) {
      numberWidget = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: xpEarned.toDouble()),
        duration: AppMotion.celebration,
        curve: AppMotion.easeOut,
        builder: (context, v, _) => Text(
          '+${v.round()}',
          style: AppTypography.xpNumber(context, size: numberSize),
        ),
      );
    } else {
      numberWidget = Text(
        '+$xpEarned',
        style: AppTypography.xpNumber(context, size: numberSize),
      );
    }

    return Semantics(
      label: '$xpEarned XP earned',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            AppIcons.xp,
            size: numberSize * 0.7,
            color: AppColors.xp,
            shadows: isDark
                ? [
                    Shadow(
                      color: AppColors.xp.withValues(alpha: 0.40),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          const SizedBox(width: 6),
          numberWidget,
          const SizedBox(width: 5),
          Text(
            'XP',
            style: AppTypography.xpLabel(context, size: labelSize),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REWARD BADGE FRAME — achievement/reward display frame
// ─────────────────────────────────────────────────────────────────────────────

/// Premium framing widget for achievement and reward displays.
/// Use in game result screens and achievement unlock presentations.
class RewardBadgeFrame extends StatelessWidget {
  const RewardBadgeFrame({
    super.key,
    required this.child,
    this.glowColor,
    this.size = 80,
    this.unlocked = true,
  });

  final Widget child;
  final Color? glowColor;
  final double size;

  /// Pass the real unlocked state from Achievement.unlockedAt != null.
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = glowColor ?? AppColors.xp;

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: unlocked && isDark
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.45),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: unlocked
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: isDark ? 0.20 : 0.10),
                      isDark ? AppColors.surfaceElevated : AppLightColors.surface,
                    ],
                  )
                : null,
            color: unlocked
                ? null
                : (isDark
                    ? AppColors.lockedSurface
                    : AppLightColors.lockedSurface),
            border: Border.all(
              color: unlocked
                  ? accent.withValues(alpha: isDark ? 0.55 : 0.35)
                  : (isDark ? AppColors.border : AppLightColors.border),
              width: unlocked ? 2.0 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Opacity(
            opacity: unlocked ? 1.0 : 0.40,
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHALLENGE INDICATOR — visual for challenge/quest status
// ─────────────────────────────────────────────────────────────────────────────

/// Visual indicator for challenge status.
/// Status must come from real challenge/quest data.
class ChallengeIndicator extends StatelessWidget {
  const ChallengeIndicator({
    super.key,
    required this.label,
    required this.completed, // real data: challenge.isCompleted
    this.progressFraction, // 0..1 from real data
    this.onTap,
  });

  final String label;
  final bool completed;
  final double? progressFraction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = completed ? AppColors.success : AppColors.primary;

    return Semantics(
      button: onTap != null,
      label: '$label ${completed ? "completed" : "in progress"}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.08 : 0.04),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.35 : 0.22),
            ),
          ),
          child: Row(
            children: [
              Icon(
                completed ? AppIcons.completed : AppIcons.challenge,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.bodySecondary(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (progressFraction != null && !completed) ...[
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 4,
                          color: isDark
                              ? AppColors.surfaceHigh
                              : AppLightColors.surfaceHigh,
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progressFraction!.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (completed)
                const SizedBox(width: 6)
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATE CHIP — compact locked/available/completed/current state chip
// ─────────────────────────────────────────────────────────────────────────────

/// Compact chip communicating a content state.
/// State must come from real data — never assume or invent.
enum ProgressionState {
  locked,
  available,
  inProgress,
  completed,
  current,
  mastered,
}

class StateChip extends StatelessWidget {
  const StateChip({super.key, required this.state, this.compact = false});

  final ProgressionState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (Color color, IconData icon, String text) = switch (state) {
      ProgressionState.locked => (
        isDark ? AppColors.locked : AppLightColors.locked,
        AppIcons.locked,
        'LOCKED',
      ),
      ProgressionState.available => (
        AppColors.secondary,
        AppIcons.available,
        'AVAILABLE',
      ),
      ProgressionState.inProgress => (
        AppColors.warning,
        AppIcons.inProgress,
        'IN PROGRESS',
      ),
      ProgressionState.completed => (
        AppColors.success,
        AppIcons.completed,
        'DONE',
      ),
      ProgressionState.current => (
        AppColors.primary,
        AppIcons.current,
        'CURRENT',
      ),
      ProgressionState.mastered => (
        AppColors.xp,
        AppIcons.mastery,
        'MASTERED',
      ),
    };

    final isLocked = state == ProgressionState.locked;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: isLocked
            ? (isDark ? AppColors.lockedSurface : AppLightColors.lockedSurface)
            : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: color.withValues(alpha: isLocked ? 0.30 : 0.50),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 10 : 12, color: color),
          SizedBox(width: compact ? 3 : 4),
          Text(
            compact && text.length > 6 ? text.substring(0, 4) : text,
            style: TextStyle(
              fontFamily: AppTypography.bodyFamily,
              fontSize: compact ? 9.5 : 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
