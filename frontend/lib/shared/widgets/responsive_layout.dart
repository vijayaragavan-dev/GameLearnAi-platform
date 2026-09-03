import 'package:flutter/material.dart';

import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';

/// Centers content and constrains its width on tablet/desktop.
/// Mobile: no constraint, full-bleed with page padding.
/// Tablet/Desktop: maxWidth centered, higher density.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.maxContentWidth,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final horizontal = AppGutters.pagePadding(context);
    final effectivePadding =
        padding ?? EdgeInsets.symmetric(horizontal: horizontal);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: effectivePadding,
          child: child,
        ),
      ),
    );
  }
}

/// Slim wrapper for scrollable content that should be constrained and
/// padded responsively. Keeps existing ListView/CustomScrollView semantics
/// by injecting the constraint via Center.
class ResponsiveInset extends StatelessWidget {
  const ResponsiveInset({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Adaptive grid that switches column count by breakpoint.
/// Uses Wrap-safe layout with no fixed widths that can overflow.
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    super.key,
    required this.children,
    this.compact = 1,
    this.medium = 2,
    this.expanded = 3,
    this.wide = 3,
    this.spacing = 14,
    this.runSpacing = 14,
  });

  final List<Widget> children;
  final int compact;
  final int medium;
  final int expanded;
  final int wide;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        int cols;
        if (w >= AppBreakpoints.expanded) {
          cols = wide;
        } else if (w >= AppBreakpoints.medium) {
          cols = expanded;
        } else if (w >= AppBreakpoints.compact) {
          cols = medium;
        } else {
          cols = compact;
        }
        if (cols <= 1) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == children.length - 1 ? 0 : runSpacing,
                  ),
                  child: children[i],
                ),
            ],
          );
        }
        // For 2+ cols, use GridView-safe Wrap with constrained children.
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children
              .map(
                (c) => SizedBox(
                  width: (w - spacing * (cols - 1)) / cols,
                  child: c,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

/// Consistent section spacing that adapts to density.
class SectionSpacing extends StatelessWidget {
  const SectionSpacing({super.key, this.compact = 16, this.expanded = 24});

  final double compact;
  final double expanded;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).width >= AppBreakpoints.medium
        ? expanded
        : compact;
    return SizedBox(height: h);
  }
}

/// Subtle surface container used to give desktop content area a
/// premium, contained feel without adding a second design system.
class ContentSurface extends StatelessWidget {
  const ContentSurface({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.medium;
    if (!isWide) return child;
    // On wide, add very subtle containment — not a card, just structure.
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.0),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Helper to prevent fixed-width overflow: wraps in Flexible/Expanded-agnostic
/// safe Row. Prefer this over bare Row(text, button) patterns.
class SafeRow extends StatelessWidget {
  const SafeRow({
    super.key,
    required this.children,
    this.spacing = 12,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final List<Widget> children;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          Flexible(child: children[i]),
          if (i != children.length - 1) SizedBox(width: spacing),
        ],
      ],
    );
  }
}

/// Token for card elevation consistency.
abstract final class AppCardStyle {
  static BorderRadius get radius =>
      BorderRadius.circular(AppRadius.lg);
  static BorderRadius get radiusXl =>
      BorderRadius.circular(AppRadius.xl);
}
