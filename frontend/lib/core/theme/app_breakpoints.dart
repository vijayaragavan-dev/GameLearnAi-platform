import 'package:flutter/widgets.dart';

/// Centralized breakpoint tokens for GameLearn AI.
///
/// Mobile-first. Values align with Material 3 window size classes
/// but tuned for the product's information density:
///
/// | Range        | Width          | Nav              | Content            |
/// |--------------|----------------|------------------|--------------------|
/// | compact      | < 600          | bottom bar       | single column      |
/// | medium       | 600 – 899      | NavigationRail   | 1-2 col, gutters 20|
/// | expanded     | 900 – 1199     | NavigationRail+  | 2-3 col, max 1120  |
/// | wide         | >= 1200        | extended rail    | 3+ col, max 1200   |
abstract final class AppBreakpoints {
  static const double compact = 600;
  static const double medium = 900;
  static const double expanded = 1200;

  /// Max content width for centered constrained layouts.
  static const double maxContentWidth = 1120;

  /// Wide max for very large displays (keeps density, not stretch).
  static const double wideContentWidth = 1200;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compact;

  static bool isMedium(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= compact && w < medium;
  }

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= medium &&
      MediaQuery.sizeOf(context).width < expanded;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expanded;

  static bool isRailVisible(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= compact;
}

/// Convenience extension on BuildContext / Size.
extension AppBreakpointX on BuildContext {
  bool get isCompact => AppBreakpoints.isCompact(this);
  bool get isMedium => AppBreakpoints.isMedium(this);
  bool get isExpanded => AppBreakpoints.isExpanded(this);
  bool get isWide => AppBreakpoints.isWide(this);
  bool get showRail => AppBreakpoints.isRailVisible(this);
}

/// Layout helpers for consistent padding/gutters.
abstract final class AppGutters {
  /// Horizontal page padding per breakpoint.
  static double pagePadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= AppBreakpoints.expanded) return 32;
    if (w >= AppBreakpoints.medium) return 24;
    return 20;
  }

  /// Cross-axis count for adaptive grids (e.g. subjects, cards).
  static int columns(BuildContext context, {int compact = 1, int medium = 2, int expanded = 3, int wide = 3}) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= AppBreakpoints.expanded) return wide;
    if (w >= AppBreakpoints.medium) return expanded;
    if (w >= AppBreakpoints.compact) return medium;
    return compact;
  }
}
