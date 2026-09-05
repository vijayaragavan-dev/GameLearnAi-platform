import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_styles.dart';

/// GameLearn AI visual depth hierarchy.
///
/// 6-level system ensures consistent perceived depth across all screens.
/// Every shadow, elevation, and z-ordering decision should reference this system.
///
/// ┌─────────────────────────────────────────────────────────────────┐
/// │ Level 5 │ Critical reward / achievement overlay  (top)          │
/// │ Level 4 │ Modal / dialog / bottom sheet                         │
/// │ Level 3 │ Featured / highlighted card                           │
/// │ Level 2 │ Standard card / panel                                 │
/// │ Level 1 │ Base content / subtle tile                            │
/// │ Level 0 │ Background (scaffold, atmospheric layers)  (bottom)   │
/// └─────────────────────────────────────────────────────────────────┘
///
/// Usage:
///   decoration: BoxDecoration(
///     boxShadow: AppDepth.card(context),
///   )
abstract final class AppDepth {
  // ── Level 0: Background ───────────────────────────────────────────────────
  /// Flat — background elements, atmospheric decorations.
  /// No shadow. Used by: scaffold, atmospheric layers, star fields.
  static const List<BoxShadow> background = [];

  // ── Level 1: Base content ─────────────────────────────────────────────────
  /// Subtle lift — list tiles, simple stat rows.
  static List<BoxShadow> content(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ]
        : AppShadows.elevated(alpha: 0.04);
  }

  // ── Level 2: Standard card ────────────────────────────────────────────────
  /// Standard card shadow — game cards, subject cards, list items.
  static List<BoxShadow> card(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppShadows.drop() : AppShadows.elevated(alpha: 0.06);
  }

  // ── Level 3: Featured card ────────────────────────────────────────────────
  /// Featured / highlighted card — hero items, current path node, spotlight.
  static List<BoxShadow> featured(BuildContext context, Color accent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
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
    ];
  }

  // ── Level 4: Modal / overlay ──────────────────────────────────────────────
  /// Modal, bottom sheet, dialog — heavy shadow for overlay surfaces.
  static List<BoxShadow> modal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.18),
        blurRadius: 48,
        offset: const Offset(0, 20),
      ),
    ];
  }

  // ── Level 5: Reward / critical ────────────────────────────────────────────
  /// Maximum emphasis — reward reveals, achievement unlocks, critical CTAs.
  /// Use at most once per screen; only for truly earned moments.
  static List<BoxShadow> reward(BuildContext context, Color accent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: accent.withValues(alpha: isDark ? 0.50 : 0.22),
        blurRadius: 40,
        spreadRadius: 2,
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.12),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ];
  }
}

/// Depth-aware container — applies the correct depth shadow for its level.
///
/// Example:
///   DepthContainer(
///     level: DepthLevel.card,
///     child: MyCard(),
///   )
enum DepthLevel { background, content, card, featured, modal, reward }

class DepthContainer extends StatelessWidget {
  const DepthContainer({
    super.key,
    required this.child,
    this.level = DepthLevel.card,
    this.accent,
    this.padding,
    this.borderRadius,
    this.color,
  });

  final Widget child;
  final DepthLevel level;
  final Color? accent;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final br = borderRadius ?? BorderRadius.circular(20);
    final bg = color ?? scheme.surface;

    List<BoxShadow> shadows;
    switch (level) {
      case DepthLevel.background:
        shadows = AppDepth.background;
      case DepthLevel.content:
        shadows = AppDepth.content(context);
      case DepthLevel.card:
        shadows = AppDepth.card(context);
      case DepthLevel.featured:
        shadows = AppDepth.featured(context, accent ?? AppColors.primary);
      case DepthLevel.modal:
        shadows = AppDepth.modal(context);
      case DepthLevel.reward:
        shadows = AppDepth.reward(context, accent ?? AppColors.xp);
    }

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: br, boxShadow: shadows),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: level == DepthLevel.background ? null : bg,
          borderRadius: br,
          border: Border.all(
            color: isDark
                ? AppColors.border
                : AppLightColors.border,
          ),
        ),
        child: child,
      ),
    );
  }
}
