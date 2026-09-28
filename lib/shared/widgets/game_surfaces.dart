import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/neo_brutalism.dart';
import 'cinematic_scenery.dart';

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
              : NeoBrutalColors.ink,
          width: isDark ? 1.0 : 2.5,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : NeoBrutalShadows.hard,
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
        boxShadow: isDark
            ? (glowColor != null
                ? [
                    BoxShadow(
                      color: glowColor!.withValues(alpha: 0.22),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : AppShadows.drop())
            : NeoBrutalShadows.hard,
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: highlight ? AppGradients.sheen(context) : null,
          color: highlight ? null : (isDark ? scheme.surface : Colors.white),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isDark
                ? (glowColor?.withValues(alpha: 0.35) ?? AppColors.border)
                : NeoBrutalColors.ink,
            width: isDark ? 1.0 : 2.5,
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
            AppColors.xp.withValues(alpha: isDark ? intensity : 0.16),
            isDark ? AppColors.surfaceElevated : NeoBrutalColors.cardWarmCream,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.xp.withValues(alpha: 0.35) : NeoBrutalColors.ink,
          width: isDark ? 1.0 : 2.5,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: AppColors.xp.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : NeoBrutalShadows.hard,
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
            color: isDark ? AppColors.border : NeoBrutalColors.ink,
            width: isDark ? 1.0 : 2.0,
          ),
        ),
        child: child,
      );
    }
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.primary.withValues(alpha: 0.3) : NeoBrutalColors.ink,
          width: isDark ? 1.0 : 2.5,
        ),
        boxShadow: isDark
            ? AppShadows.glow(
                AppColors.primary,
                alpha: 0.22,
              )
            : NeoBrutalShadows.hard,
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
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark
              ? (tint ?? AppColors.border).withValues(alpha: tint != null ? 0.35 : 1)
              : NeoBrutalColors.ink,
          width: isDark ? 1.0 : 2.0,
        ),
        boxShadow: isDark ? null : NeoBrutalShadows.hardSm,
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
        boxShadow: isDark
            ? AppShadows.glow(color, alpha: 0.22)
            : NeoBrutalShadows.hardLg,
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    color.withValues(alpha: 0.14),
                    Theme.of(context).colorScheme.surface,
                  ]
                : [
                    color.withValues(alpha: 0.12),
                    Colors.white,
                  ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isDark ? color.withValues(alpha: 0.45) : NeoBrutalColors.ink,
            width: isDark ? 1.0 : 2.5,
          ),
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
        (isDark ? AppColors.borderStrong : NeoBrutalColors.ink);
    final idleBorder =
        widget.borderColor ??
        (isDark ? AppColors.border : NeoBrutalColors.ink);
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          transform: isDark
              ? null
              : Matrix4.translationValues(_pressed ? 2.0 : 0.0, _pressed ? 2.0 : 0.0, 0.0),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: isDark ? scheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isDark ? (_hovered ? hoverBorder : idleBorder) : NeoBrutalColors.ink,
              width: isDark ? 1.0 : 2.5,
            ),
            boxShadow: isDark
                ? (_hovered && widget.enableHoverGlow
                    ? AppShadows.interactive(AppColors.primary, alpha: 0.14)
                    : AppShadows.drop())
                : (_pressed ? NeoBrutalShadows.hardPressed : NeoBrutalShadows.hard),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Featured surface — premium highlighted card for hero/spotlight content.
/// Use for "Current Path Node", "Today's Challenge", "Recommended Game".
/// One per screen max — use sparingly.
///
/// [scene] paints a procedural cinematic landscape ([CinematicScenery],
/// keyed by world/game identity) behind the content. When set, the flat
/// gradient wash is softened so the artwork carries the hero, and a bottom
/// scrim keeps text legible. Null (default) preserves the legacy gradient
/// treatment exactly — existing call sites are unaffected.
class FeaturedSurface extends StatelessWidget {
  const FeaturedSurface({
    super.key,
    required this.child,
    this.accent = AppColors.primary,
    this.padding = const EdgeInsets.all(20),
    this.scene,
    this.sceneSeed = 7,
  });

  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry padding;
  final ScenePalette? scene;
  final int sceneSeed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasScene = scene != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.28),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ]
            : NeoBrutalShadows.hardLg,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    accent.withValues(alpha: hasScene ? 0.10 : 0.18),
                    AppColors.surfaceElevated,
                    AppColors.surfaceElevated.withValues(alpha: 0.95),
                  ]
                : [
                    accent.withValues(alpha: hasScene ? 0.04 : 0.08),
                    AppLightColors.surface,
                  ],
            stops: isDark ? const [0.0, 0.55, 1.0] : const [0.0, 1.0],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isDark
                ? accent.withValues(alpha: 0.45)
                : NeoBrutalColors.ink,
            width: isDark ? 1.5 : 2.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl - 1.5),
          child: Stack(
            children: [
              if (hasScene)
                Positioned.fill(
                  child: CinematicScenery(
                    palette: scene!,
                    seed: sceneSeed,
                    intensity: isDark ? 1.0 : 0.55,
                  ),
                ),
              if (hasScene)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(
                              alpha: isDark ? 0.45 : 0.18,
                            ),
                          ],
                          stops: const [0.3, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
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
        boxShadow: isDark
            ? (showGlow
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ]
                : null)
            : NeoBrutalShadows.hard,
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: isDark ? 0.12 : 0.08),
              isDark ? scheme.surface : Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isDark ? accent.withValues(alpha: 0.30) : NeoBrutalColors.ink,
            width: isDark ? 1.0 : 2.5,
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
        boxShadow: isDark
            ? [
                BoxShadow(color: accent.withValues(alpha: 0.14), blurRadius: 20, offset: const Offset(0, 8)),
                if (isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 6)),
              ]
            : NeoBrutalShadows.hard,
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [accent.withValues(alpha: 0.10), AppColors.surfaceElevated, AppColors.surfaceElevated.withValues(alpha: 0.98)]
                : [accent.withValues(alpha: 0.08), Colors.white],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isDark ? accent.withValues(alpha: 0.28) : NeoBrutalColors.ink,
            width: isDark ? 1.2 : 2.5,
          ),
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
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                        border: isDark ? null : Border.all(color: NeoBrutalColors.ink, width: 2),
                      ),
                      child: Icon(icon, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title!,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: isDark ? accent : NeoBrutalColors.ink,
                      ),
                    ),
                  ),
                  if (subtitle != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceHigh : NeoBrutalColors.pastelYellow,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isDark ? AppColors.border : NeoBrutalColors.ink,
                          width: isDark ? 1.0 : 1.5,
                        ),
                      ),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textSecondary : NeoBrutalColors.ink,
                        ),
                      ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.10)
            : (isCorrect ? NeoBrutalColors.pastelGreen : const Color(0xFFFFEAEA)),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? color.withValues(alpha: 0.38) : NeoBrutalColors.ink,
          width: isDark ? 1.2 : 2.5,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(color: color.withValues(alpha: 0.14), blurRadius: 14, offset: const Offset(0, 4)),
              ]
            : NeoBrutalShadows.hardSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCorrect ? AppColors.success : AppColors.error,
              border: isDark ? null : Border.all(color: NeoBrutalColors.ink, width: 2),
            ),
            child: Icon(
              isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}
