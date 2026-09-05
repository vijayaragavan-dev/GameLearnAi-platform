import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';

/// Premium reusable surfaces — single language for all future game screens.
///
/// All surfaces are theme-aware (dark/light), use [AppColors]/[AppLightColors]
/// tokens, respect [AppRadius.lg] geometry, and provide restrained depth
/// (no excessive glow). Prefer these over per-screen Decoration copies.

/// Glass-like translucent panel — the only glass primitive. Use max once per screen.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppRadius.xl,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.03),
                ]
              : [
                  (tint ?? AppColors.primary).withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.6),
                ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.14)
              : AppLightColors.border,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : AppShadows.elevated(alpha: 0.06),
      ),
      child: child,
    );
  }
}

/// Elevated game panel — premium card with subtle highlight sheen and restrained glow.
/// Use for game HUD containers, reward headers, highlighted sections.
class ElevatedGamePanel extends StatelessWidget {
  const ElevatedGamePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.glowColor,
    this.highlight = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? glowColor;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor!.withValues(alpha: isDark ? 0.22 : 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ]
            : (isDark ? AppShadows.drop() : AppShadows.elevated(alpha: 0.07)),
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: highlight ? AppGradients.sheen(context) : null,
          color: highlight ? null : scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color:
                glowColor?.withValues(alpha: 0.35) ??
                (isDark ? AppColors.border : AppLightColors.border),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Reward surface — warm gold wash for XP/reward cards. Data-driven value is outside.
class RewardSurface extends StatelessWidget {
  const RewardSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.intensity = 0.08,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.xp.withValues(alpha: intensity),
            isDark ? AppColors.surfaceElevated : AppLightColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.xp.withValues(alpha: isDark ? 0.35 : 0.22),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: AppColors.xp.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// Achievement surface — locked vs unlocked. Pass [unlocked] from real Achievement.unlockedAt != null.
class AchievementSurface extends StatelessWidget {
  const AchievementSurface({
    super.key,
    required this.child,
    required this.unlocked,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final bool unlocked;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!unlocked) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.lockedSurface
              : AppLightColors.lockedSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isDark ? AppColors.border : AppLightColors.border,
          ),
        ),
        child: child,
      );
    }
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: AppShadows.glow(
          AppColors.primary,
          alpha: isDark ? 0.22 : 0.10,
        ),
      ),
      child: child,
    );
  }
}

/// Statistic surface — quiet, consistent for StatCard and KPI tiles.
/// Uses tint only for the top accent border.
class StatisticSurface extends StatelessWidget {
  const StatisticSurface({
    super.key,
    required this.child,
    this.tint,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color? tint;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: (tint ?? (isDark ? AppColors.border : AppLightColors.border))
              .withValues(alpha: tint != null ? 0.35 : 1),
        ),
      ),
      child: child,
    );
  }
}

/// Highlighted surface — featured/selected game card backing.
/// Controlled glow — one per section max.
class HighlightedSurface extends StatelessWidget {
  const HighlightedSurface({
    super.key,
    required this.child,
    this.color = AppColors.primary,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.glow(color, alpha: isDark ? 0.22 : 0.10),
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: isDark ? 0.14 : 0.07),
              Theme.of(context).colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: child,
      ),
    );
  }
}

/// Interactive surface — provides hover/pressed/focus feedback without duplicating logic.
/// Wraps any child; handles hover on desktop/web via MouseRegion and pressed via GestureDetector.
class InteractiveSurface extends StatefulWidget {
  const InteractiveSurface({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.enableHoverGlow = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final bool enableHoverGlow;

  @override
  State<InteractiveSurface> createState() => _InteractiveSurfaceState();
}

class _InteractiveSurfaceState extends State<InteractiveSurface> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final hoverBorder =
        widget.borderColor ??
        (isDark ? AppColors.borderStrong : AppLightColors.borderStrong);
    final idleBorder =
        widget.borderColor ??
        (isDark ? AppColors.border : AppLightColors.border);
    return MouseRegion(
      onEnter: widget.onTap == null
          ? null
          : (_) => setState(() => _hovered = true),
      onExit: widget.onTap == null
          ? null
          : (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? AppStates.pressedScale : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: _hovered ? hoverBorder : idleBorder),
              boxShadow: _hovered && widget.enableHoverGlow
                  ? AppShadows.interactive(AppColors.primary, alpha: 0.14)
                  : (isDark ? AppShadows.drop() : null),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Featured surface — premium highlighted card for hero/spotlight content.
/// Use for "Current Path Node", "Today's Challenge", "Recommended Game".
/// One per screen max — use sparingly.
class FeaturedSurface extends StatelessWidget {
  const FeaturedSurface({
    super.key,
    required this.child,
    this.accent = AppColors.primary,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.28 : 0.12),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          if (isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    accent.withValues(alpha: 0.18),
                    AppColors.surfaceElevated,
                    AppColors.surfaceElevated.withValues(alpha: 0.95),
                  ]
                : [
                    accent.withValues(alpha: 0.08),
                    AppLightColors.surface,
                  ],
            stops: isDark ? const [0.0, 0.55, 1.0] : const [0.0, 1.0],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.45 : 0.28),
            width: 1.5,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Game identity surface — tints a card with the game's visual accent.
/// Pass [accent] from [GameVisualIdentity.accent] for the current game.
class GameIdentitySurface extends StatelessWidget {
  const GameIdentitySurface({
    super.key,
    required this.child,
    required this.accent,
    this.padding = const EdgeInsets.all(16),
    this.showGlow = false,
    this.radius = AppRadius.lg,
  });

  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry padding;
  final bool showGlow;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: showGlow && isDark
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: isDark ? 0.12 : 0.05),
              scheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.30 : 0.18),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Premium challenge surface — the focal point for every game's challenge area.
/// Provides accent-aware depth, subtle gradient, and clear hierarchy.
class GameChallengeSurface extends StatelessWidget {
  const GameChallengeSurface({
    super.key,
    required this.child,
    required this.accent,
    this.title,
    this.icon,
    this.subtitle,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final Color accent;
  final String? title;
  final IconData? icon;
  final String? subtitle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: isDark ? 0.14 : 0.07), blurRadius: 20, offset: const Offset(0, 8)),
          if (isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [accent.withValues(alpha: 0.10), AppColors.surfaceElevated, AppColors.surfaceElevated.withValues(alpha: 0.98)]
                : [accent.withValues(alpha: 0.06), AppLightColors.surface],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: accent.withValues(alpha: isDark ? 0.28 : 0.18), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.78)])),
                      child: Icon(icon, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(title!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: accent)),
                  ),
                  if (subtitle != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: isDark ? AppColors.surfaceHigh : AppLightColors.surfaceHigh, borderRadius: BorderRadius.circular(999), border: Border.all(color: isDark ? AppColors.border : AppLightColors.border)),
                      child: Text(subtitle!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Premium feedback surface for correct/incorrect states.
/// Success: subtle success glow + check; Error: red glow + shake support externally.
class GameFeedbackSurface extends StatelessWidget {
  const GameFeedbackSurface({
    super.key,
    required this.child,
    required this.isCorrect,
    this.accent,
  });

  final Widget child;
  final bool isCorrect;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isCorrect ? AppColors.success : AppColors.error;
    final useAccent = accent ?? color;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isCorrect ? AppColors.success : AppColors.error).withValues(alpha: isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: (isCorrect ? AppColors.success : AppColors.error).withValues(alpha: isDark ? 0.38 : 0.28), width: 1.2),
        boxShadow: [
          BoxShadow(color: (isCorrect ? AppColors.success : AppColors.error).withValues(alpha: isDark ? 0.14 : 0.06), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(shape: BoxShape.circle, color: (isCorrect ? AppColors.success : AppColors.error).withValues(alpha: 0.16), border: Border.all(color: (isCorrect ? AppColors.success : AppColors.error).withValues(alpha: 0.45))),
            child: Icon(isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 16, color: isCorrect ? AppColors.success : AppColors.error),
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}
