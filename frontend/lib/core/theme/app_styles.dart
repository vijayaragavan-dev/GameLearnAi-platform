import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double huge = 48;

  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: 20);
}

abstract final class AppLayout {
  static const double maxContentWidth = 1120;
  static const double wideContentWidth = 1200;
  static const double railWidth = 80;
  static const double railExtendedWidth = 256;

  static const EdgeInsets pagePaddingCompact = EdgeInsets.symmetric(
    horizontal: 20,
  );
  static const EdgeInsets pagePaddingMedium = EdgeInsets.symmetric(
    horizontal: 24,
  );
  static const EdgeInsets pagePaddingExpanded = EdgeInsets.symmetric(
    horizontal: 32,
  );
}

abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

abstract final class AppElevation {
  static const double card = 2;
  static const double raised = 8;
}

abstract final class AppShadows {
  static List<BoxShadow> soft(Color color, {double alpha = 0.35}) => [
    BoxShadow(
      color: color.withValues(alpha: alpha),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> glow(Color color, {double alpha = 0.45}) => [
    BoxShadow(
      color: color.withValues(alpha: alpha),
      blurRadius: 26,
      spreadRadius: 1,
    ),
  ];

  static List<BoxShadow> drop() => const [
    BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 8)),
  ];

  /// Subtle elevated shadow for cards on light surfaces — theme-aware caller picks opacity.
  static List<BoxShadow> elevated({double alpha = 0.08}) => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: alpha),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: alpha * 0.6),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  /// Interactive hover shadow — restrained glow for hover state.
  static List<BoxShadow> interactive(Color color, {double alpha = 0.18}) => [
    BoxShadow(
      color: color.withValues(alpha: alpha),
      blurRadius: 22,
      offset: const Offset(0, 6),
    ),
  ];

  /// Focus ring — use via border, not shadow on most widgets; this is for elevated focus.
  static List<BoxShadow> focus(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.35),
      blurRadius: 0,
      spreadRadius: 3,
    ),
  ];
}

abstract final class AppGradients {
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryDeep, AppColors.primary],
  );

  static const LinearGradient cyan = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.secondaryDeep, AppColors.secondary],
  );

  static const LinearGradient xpGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB45309), AppColors.xp],
  );

  static const LinearGradient streakFire = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFC2410C), AppColors.streak],
  );

  static const LinearGradient backgroundWash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0B1226), AppColors.background],
  );

  static RadialGradient novaCore({Color? tint}) => RadialGradient(
    colors: [
      (tint ?? AppColors.secondary).withValues(alpha: 0.95),
      (tint ?? AppColors.primary).withValues(alpha: 0.55),
      Colors.transparent,
    ],
    stops: const [0.0, 0.55, 1.0],
  );

  // ---- Premium surfaces: subtle game-oriented accent washes (restrained) ----

  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF065F46), AppColors.success],
  );

  static const LinearGradient info = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.infoDeep, AppColors.info],
  );

  static LinearGradient cardHighlight(Color base) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [base.withValues(alpha: 0.14), base.withValues(alpha: 0.02)],
  );

  static LinearGradient rewardHighlight = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF92400E), AppColors.xp],
  );

  /// Subtle sheen for elevated cards — dark: white α0.06 → transparent; light: primary α0.03 → transparent.
  static LinearGradient sheen(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [Colors.white.withValues(alpha: 0.07), Colors.transparent]
          : [AppColors.primary.withValues(alpha: 0.04), Colors.transparent],
    );
  }
}

/// Interactive state tokens — single source for hover/pressed/focus/disabled opacity.
abstract final class AppStates {
  static const double hoverOpacity = 0.08;
  static const double pressedScale = 0.97;
  static const double selectedGlowAlpha = 0.18;
  static const double disabledOpacity = 0.48;
  static const double focusBorderWidth = 2;
}
