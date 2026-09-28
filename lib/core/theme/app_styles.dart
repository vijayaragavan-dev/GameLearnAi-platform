import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'neo_brutalism.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SPACING
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// LAYOUT
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// RADIUS
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double xxl = 36;
  static const double pill = 999;
}

// ─────────────────────────────────────────────────────────────────────────────
// ELEVATION
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppElevation {
  static const double card = 2;
  static const double raised = 8;
}

// ─────────────────────────────────────────────────────────────────────────────
// SHADOWS — structured depth system
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppShadows {
  /// Soft drop shadow — general card depth.
  static List<BoxShadow> soft(Color color, {double alpha = 0.35}) => [
    BoxShadow(
      color: color.withValues(alpha: alpha),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  /// Colored glow — for active/selected/reward elements. Keep alpha ≤ 0.45.
  static List<BoxShadow> glow(Color color, {double alpha = 0.45}) => [
    BoxShadow(
      color: color.withValues(alpha: alpha),
      blurRadius: 26,
      spreadRadius: 1,
    ),
  ];

  /// Generic drop — dark cards baseline.
  static List<BoxShadow> drop() => const [
    BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 8)),
  ];

  /// Multi-layer elevated shadow — light theme cards.
  static List<BoxShadow> elevated({double alpha = 0.08}) => NeoBrutalShadows.hard;

  /// Hover shadow — restrained glow on pointer hover.
  static List<BoxShadow> interactive(Color color, {double alpha = 0.18}) => [
    BoxShadow(
      color: color.withValues(alpha: alpha),
      blurRadius: 22,
      offset: const Offset(0, 6),
    ),
  ];

  /// Focus ring — spread-only, no offset.
  static List<BoxShadow> focus(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.35),
      blurRadius: 0,
      spreadRadius: 3,
    ),
  ];

  /// Depth-0 baseline — no shadow (flat background elements).
  static const List<BoxShadow> none = [];

  /// Depth-1 subtle — content level cards.
  static List<BoxShadow> depth1({bool dark = true}) => dark
      ? [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.20),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ]
      : NeoBrutalShadows.hardSm;

  /// Depth-2 card — standard card depth.
  static List<BoxShadow> depth2({bool dark = true}) => dark
      ? [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.28),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ]
      : NeoBrutalShadows.hard;

  /// Depth-3 featured — featured/highlighted card.
  static List<BoxShadow> depth3(Color accent, {bool dark = true}) => dark
      ? [
    BoxShadow(
      color: accent.withValues(alpha: 0.22),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.30),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ]
      : NeoBrutalShadows.hardLg;

  /// Depth-4 modal — overlay/dialog shadow.
  static List<BoxShadow> depth4({bool dark = true}) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: dark ? 0.55 : 0.18),
      blurRadius: 48,
      offset: const Offset(0, 20),
    ),
  ];

  /// Depth-5 reward — maximum emphasis for reward/celebration elements.
  static List<BoxShadow> depth5(Color accent, {bool dark = true}) => [
    BoxShadow(
      color: accent.withValues(alpha: dark ? 0.50 : 0.22),
      blurRadius: 40,
      spreadRadius: 2,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: dark ? 0.40 : 0.12),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// GLOW SYSTEM — controlled, typed glow definitions
// ─────────────────────────────────────────────────────────────────────────────

/// Centralized glow definitions. Never use raw BoxShadow glow values directly.
/// All glows are restrained (blurRadius ≤ 28, alpha ≤ 0.50 dark / 0.22 light).
abstract final class AppGlows {
  /// Accent glow — primary purple. For selected/active interactive elements.
  static List<BoxShadow> accent({bool dark = true}) => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: dark ? 0.40 : 0.18),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  /// Active glow — cyan energy. For Nova, active states, energy indicators.
  static List<BoxShadow> active({bool dark = true}) => [
    BoxShadow(
      color: AppColors.secondary.withValues(alpha: dark ? 0.40 : 0.18),
      blurRadius: 22,
      spreadRadius: 0,
    ),
  ];

  /// Success glow — emerald. For completion, correct answers.
  static List<BoxShadow> success({bool dark = true}) => [
    BoxShadow(
      color: AppColors.success.withValues(alpha: dark ? 0.38 : 0.16),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];

  /// Reward glow — gold XP. For reward reveals, XP earned.
  static List<BoxShadow> reward({bool dark = true}) => [
    BoxShadow(
      color: AppColors.xp.withValues(alpha: dark ? 0.45 : 0.20),
      blurRadius: 28,
      spreadRadius: 1,
    ),
  ];

  /// Focus glow — keyboard focus indicator. Spread only, no blur.
  static List<BoxShadow> focus({bool dark = true}) => [
    BoxShadow(
      color: AppColors.borderFocus.withValues(alpha: dark ? 0.40 : 0.30),
      blurRadius: 0,
      spreadRadius: 3,
    ),
  ];

  /// Game glow — custom color for game identity surfaces.
  static List<BoxShadow> game(Color accent, {bool dark = true}) => [
    BoxShadow(
      color: accent.withValues(alpha: dark ? 0.35 : 0.14),
      blurRadius: 22,
      spreadRadius: 0,
    ),
  ];

  /// Streak glow — orange flame for active streak.
  static List<BoxShadow> streak({bool dark = true}) => [
    BoxShadow(
      color: AppColors.streak.withValues(alpha: dark ? 0.42 : 0.18),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];

  /// Error glow — coral for errors/danger states.
  static List<BoxShadow> error({bool dark = true}) => [
    BoxShadow(
      color: AppColors.error.withValues(alpha: dark ? 0.38 : 0.16),
      blurRadius: 18,
      spreadRadius: 0,
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// GRADIENTS — centralized gradient language
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppGradients {
  // ── Brand ────────────────────────────────────────────────────────────────

  /// Primary brand gradient — deep purple → electric purple.
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryDeep, AppColors.primary],
  );

  /// Premium diagonal — purple → cyan. For hero sections.
  static const LinearGradient premium = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.secondary],
    stops: [0.0, 1.0],
  );

  /// Cyan secondary gradient.
  static const LinearGradient cyan = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.secondaryDeep, AppColors.secondary],
  );

  // ── Reward / gamification ────────────────────────────────────────────────

  /// XP gold gradient — amber → gold.
  static const LinearGradient xpGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB45309), AppColors.xp],
  );

  /// Streak fire — deep orange → orange.
  static const LinearGradient streakFire = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFC2410C), AppColors.streak],
  );

  /// Reward highlight — warm gold wash for reward cards.
  static const LinearGradient rewardHighlight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF92400E), AppColors.xp],
  );

  // ── Semantic states ───────────────────────────────────────────────────────

  /// Success green gradient.
  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF065F46), AppColors.success],
  );

  /// Info sky gradient.
  static const LinearGradient info = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.infoDeep, AppColors.info],
  );

  /// Error coral gradient.
  static const LinearGradient error = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF991B1B), AppColors.error],
  );

  // ── Background / atmosphere ───────────────────────────────────────────────

  /// Background wash — subtle top-to-bottom depth for dark theme.
  static const LinearGradient backgroundWash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0B1226), AppColors.background],
  );

  /// Atmosphere — deep background with energy tint.
  static const LinearGradient atmosphere = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF050913), Color(0xFF0D1527), Color(0xFF070C1A)],
    stops: [0.0, 0.5, 1.0],
  );

  /// Nova radial gradient — AI companion orb core.
  static RadialGradient novaCore({Color? tint}) => RadialGradient(
    colors: [
      (tint ?? AppColors.secondary).withValues(alpha: 0.95),
      (tint ?? AppColors.primary).withValues(alpha: 0.55),
      Colors.transparent,
    ],
    stops: const [0.0, 0.55, 1.0],
  );

  // ── Surface treatments ────────────────────────────────────────────────────

  /// Card highlight — color-tinted surface wash for game/world cards.
  static LinearGradient cardHighlight(Color base) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [base.withValues(alpha: 0.14), base.withValues(alpha: 0.02)],
  );

  /// Premium sheen — subtle top-left highlight for elevated cards.
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

  /// Featured surface — diagonal brand wash for highlighted content.
  static LinearGradient featured(BuildContext context, {Color? accent}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accent ?? AppColors.primary;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
        color.withValues(alpha: 0.18),
        AppColors.surfaceElevated,
        AppColors.surfaceElevated.withValues(alpha: 0.95),
      ]
          : [
        color.withValues(alpha: 0.08),
        AppLightColors.surface,
      ],
      stops: isDark ? const [0.0, 0.55, 1.0] : const [0.0, 1.0],
    );
  }

  // ── Game identity gradients (mapped by game family) ───────────────────────

  // ── Game identity gradients (mapped by game family) ───────────────────────

  /// Quiz / battle family — #243B69 → #DCE7FF (Accent #3B82F6).
  static const LinearGradient gameQuiz = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF243B69), Color(0xFFDCE7FF)],
  );

  /// Memory / cognitive family — #155E63 → #D7F5F3 (Accent #06B6D4).
  static const LinearGradient gameMemory = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF155E63), Color(0xFFD7F5F3)],
  );

  /// Speed / arcade family — streak fire.
  static const LinearGradient gameSpeed = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C2D12), Color(0xFFFED7AA)],
  );

  /// Debug / logic family — emerald hacker.
  static const LinearGradient gameDebug = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF064E3B), Color(0xFFD8F5E9)],
  );

  /// Unlock / mystery family — gold vault.
  static const LinearGradient gameMystery = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF78350F), Color(0xFFFEF08A)],
  );

  /// Puzzle / builder family — #4C2A72 → #E9DFFF (Accent #7C3AED).
  static const LinearGradient gamePuzzle = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4C2A72), Color(0xFFE9DFFF)],
  );

  /// Boss / combat family — #6B3035 → #FFE0E0 (Accent #EF4444).
  static const LinearGradient gameBoss = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6B3035), Color(0xFFFFE0E0)],
  );

  /// Connectivity / network family — teal grid.
  static const LinearGradient gameNetwork = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF134E4A), Color(0xFFD8F4F7)],
  );

  /// Snake & Ladder — board game amber.
  static const LinearGradient gameBoard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF68421E), Color(0xFFF8E5CE)],
  );

  // ── World / subject gradients (keyed by subject iconKey) ─────────────────

  /// Programming world — #25245C → #DDE1FF (Icon #6366F1).
  static const LinearGradient worldProgramming = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF25245C), Color(0xFFDDE1FF)],
  );

  /// Networks world — #124E5B → #D8F4F7 (Icon #06B6D4).
  static const LinearGradient worldNetworks = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF124E5B), Color(0xFFD8F4F7)],
  );

  /// DBMS world — #68421E → #F8E5CE (Icon #F59E0B).
  static const LinearGradient worldDatabase = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF68421E), Color(0xFFF8E5CE)],
  );

  /// OS world — #303746 → #E2E6ED (Icon #64748B).
  static const LinearGradient worldOS = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF303746), Color(0xFFE2E6ED)],
  );

  /// Data Structures world — #145A45 → #D8F5E9 (Icon #10B981).
  static const LinearGradient worldDataStructures = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF145A45), Color(0xFFD8F5E9)],
  );

  /// Algorithms world — violet analysis.
  static const LinearGradient worldAlgorithms = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E1065), Color(0xFFE9DFFF)],
  );

  /// OOP world — #155B70 → #D7F4FA (Icon #06B6D4).
  static const LinearGradient worldOOP = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF155B70), Color(0xFFD7F4FA)],
  );

  /// AI/ML world — rose intelligence.
  static const LinearGradient worldAIML = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF500724), Color(0xFFFCE7F3)],
  );

  /// Data Science world — teal insight.
  static const LinearGradient worldDataScience = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF134E4A), Color(0xFFCCFBF1)],
  );

  /// Web world — #174A7A → #DDEEFF (Icon #3B82F6).
  static const LinearGradient worldWeb = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF174A7A), Color(0xFFDDEEFF)],
  );

  /// OOSE world — #39435A → #E4E8F0 (Icon #64748B).
  static const LinearGradient worldOOSE = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF39435A), Color(0xFFE4E8F0)],
  );

  /// Nova card gradient — #123C46 → #D9F4F5.
  static const LinearGradient novaCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF123C46), Color(0xFFD9F4F5)],
  );

  /// Progress card gradient — #172554 → #DCE7FF.
  static const LinearGradient progressCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF172554), Color(0xFFDCE7FF)],
  );

  /// Overall Mastery practice gradient — #7F1D1D → #FFE4E6.
  static const LinearGradient masteryPractice = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7F1D1D), Color(0xFFFFE4E6)],
  );

  /// Fallback world gradient for unmapped subjects.
  static const LinearGradient worldDefault = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF172554), Color(0xFFDCE7FF)],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// INTERACTIVE STATE TOKENS
// ─────────────────────────────────────────────────────────────────────────────

/// Interactive state tokens — single source for hover/pressed/focus/disabled opacity.
abstract final class AppStates {
  static const double hoverOpacity = 0.08;
  static const double pressedScale = 0.97;
  static const double selectedGlowAlpha = 0.18;
  static const double disabledOpacity = 0.48;
  static const double focusBorderWidth = 2;
}
