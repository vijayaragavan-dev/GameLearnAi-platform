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

  static const EdgeInsets pagePaddingCompact =
      EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets pagePaddingMedium =
      EdgeInsets.symmetric(horizontal: 24);
  static const EdgeInsets pagePaddingExpanded =
      EdgeInsets.symmetric(horizontal: 32);
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
}
