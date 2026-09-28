import 'package:flutter/widgets.dart';

import '../../core/theme/app_breakpoints.dart';

/// Single source of truth for the global command-dock geometry and the
/// bottom clearance shell content must reserve.
///
/// The dock itself lives in [ShellScreen]'s `Scaffold.bottomNavigationBar`
/// (viewport-anchored, never inside scrollable page content). Because the
/// shell uses `extendBody: true` for the floating dock treatment, page
/// content extends behind the dock and must reserve:
///
///   dock height + dock bottom margin + SafeArea bottom inset + design gap
///
/// Hardcoding that sum (e.g. `bottom: 110`) drifts from the real dock
/// geometry and ignores device insets (Redmi gesture nav vs. web), causing
/// overlap on high-inset devices and arbitrary gaps elsewhere. Pages under
/// the shell must use [bottomClearance] instead of magic numbers.
abstract final class ShellDockMetrics {
  /// Visual height of the dock container (`SizedBox(height: …)`).
  static const double dockHeight = 78.0;

  /// Bottom margin below the dock container (`Padding(bottom: …)`).
  static const double dockBottomMargin = 8.0;

  /// Horizontal margin on each side (`Padding(left/right: …)`).
  static const double dockHorizontalMargin = 16.0;

  /// Max dock width on wide compact windows (`ConstrainedBox`).
  static const double dockMaxWidth = 520.0;

  /// Intentional design gap between dock top and last content pixel.
  static const double contentGap = 16.0;

  /// Bottom padding shell content must reserve so its last card/CTA stays
  /// reachable above the viewport-anchored dock.
  static double bottomClearance(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return dockHeight + dockBottomMargin + safeBottom + contentGap;
  }

  /// Deliberate visual gap between the dock top and Nova's bottom edge.
  /// Large enough to prevent touch overlap, small enough that Nova still
  /// feels like a floating assistant.
  static const double novaGap = 12.0;

  /// Material Scaffold endFloat FAB margin (framework default): the inner
  /// Scaffold already lifts its FAB slot this far above its own bottom.
  static const double scaffoldFabMargin = 16.0;

  /// Extra bottom lift the Dashboard Nova FAB needs inside its Scaffold
  /// FAB slot on compact (bottom-dock) layouts so Nova's bottom sits
  /// [novaGap] above the dock top:
  ///
  ///   lift = dockHeight + dockBottomMargin + SafeArea + novaGap
  ///          − scaffoldFabMargin (already provided by the slot)
  ///
  /// Uses viewPadding (true system inset): the shell wraps its body with
  /// extendBody:true, so MediaQuery.padding inside already contains the
  /// dock occupancy and must NOT be added again. Zero on rail layouts
  /// where no bottom dock exists, preserving desktop composition.
  static double novaLift(BuildContext context) {
    if (AppBreakpoints.isRailVisible(context)) return 0.0;
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    return dockHeight + dockBottomMargin + safeBottom + novaGap - scaffoldFabMargin;
  }
}
