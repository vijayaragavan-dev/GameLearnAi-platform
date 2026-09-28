import 'package:flutter/material.dart';

/// Neo-Brutalist Comic Editorial Design System Tokens
/// Based on stitch_gamelearnai_ui_design_system (DESIGN.md)
abstract final class NeoBrutalColors {
  // Canvases & Base Surfaces
  static const Color canvas = Color(0xFFF7F5EF); // Warm Ivory
  static const Color cream = Color(0xFFF7F5EF); // Warm Ivory alias
  static const Color canvasDark = Color(0xFF111318); // Obsidian Dark Canvas
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A1D24);

  // Ink & Outlines
  static const Color ink = Color(0xFF171923); // Deep Ink universal outline
  static const Color inkSecondary = Color(0xFF596174); // Slate
  static const Color inkMuted = Color(0xFF596174);
  static const Color textMuted = Color(0xFF596174);

  // Primaries & Saturated Accents
  static const Color cobaltBlue = Color(0xFF3B82F6); // Electric Blue Primary
  static const Color xpYellow = Color(0xFFFFD43B); // Game Yellow / Progression
  static const Color lemonYellow = Color(0xFFFFD43B); // Tactile Game Button Yellow
  static const Color growthGreen = Color(0xFF10B981); // Emerald Mastery / Success
  static const Color emeraldGreen = Color(0xFF10B981); // Badge / Success
  static const Color celebrationPink = Color(0xFFFF6FAE); // Achievements
  static const Color magentaPink = Color(0xFFA72867); // Rarity / Accent
  static const Color tutorCyan = Color(0xFF06B6D4); // Bright Cyan / Nova
  static const Color challengeOrange = Color(0xFFF59E0B); // Amber / Daily Challenges
  static const Color errorRed = Color(0xFFEF4444); // Coral Red / Needs Practice
  static const Color error = Color(0xFFEF4444); // Error alias
  static const Color vividPurple = Color(0xFF7C3AED); // Vivid Purple

  // Saturated Pastels for Cards & Categories (Soft accents)
  static const Color pastelYellow = Color(0xFFFEF08A);
  static const Color pastelGreen = Color(0xFFBBF7D0);
  static const Color pastelOrange = Color(0xFFFED7AA);
  static const Color pastelPurple = Color(0xFFE9DFFF);
  static const Color pastelBlue = Color(0xFFDCE9FF); // Soft Blue accent
  static const Color pastelMint = Color(0xFFD8F5E9); // Soft Mint accent
  static const Color pastelCyan = Color(0xFFD9F4F5); // Soft Cyan accent
  static const Color cardWarmCream = Color(0xFFFFFFFF);
  static const Color cardYellow = Color(0xFFFFF8E7);
  static const Color cardGreen = Color(0xFFE8F8EE);
  static const Color cardPink = Color(0xFFFFEFEF);
}

abstract final class NeoBrutalBorders {
  static const double standardWidth = 2.5;
  static const double thinWidth = 2.0;
  static const double thickWidth = 3.0;

  static const BorderSide inkSide = BorderSide(
    color: NeoBrutalColors.ink,
    width: standardWidth,
  );

  static const BorderSide inkSideThin = BorderSide(
    color: NeoBrutalColors.ink,
    width: thinWidth,
  );

  static const BorderSide inkSideThick = BorderSide(
    color: NeoBrutalColors.ink,
    width: thickWidth,
  );

  static Border all({double width = standardWidth, Color color = NeoBrutalColors.ink}) {
    return Border.all(color: color, width: width);
  }

  // Radii
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(24));
  static const BorderRadius radiusPill = BorderRadius.all(Radius.circular(9999));
}

abstract final class NeoBrutalShadows {
  /// Default Neo-Brutalist hard drop shadow: 4px 4px 0px #17181C
  static const List<BoxShadow> hard = [
    BoxShadow(
      color: NeoBrutalColors.ink,
      offset: Offset(4, 4),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  /// Compact Neo-Brutalist shadow: 2.5px 2.5px 0px #17181C
  static const List<BoxShadow> hardSm = [
    BoxShadow(
      color: NeoBrutalColors.ink,
      offset: Offset(2.5, 2.5),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  /// Extra small hard shadow: 1.5px 1.5px 0px #17181C
  static const List<BoxShadow> hardXs = [
    BoxShadow(
      color: NeoBrutalColors.ink,
      offset: Offset(1.5, 1.5),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  /// Hero/Elevated shadow: 6px 6px 0px #17181C
  static const List<BoxShadow> hardLg = [
    BoxShadow(
      color: NeoBrutalColors.ink,
      offset: Offset(6, 6),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  /// Pressed state shadow: 1.5px 1.5px 0px #17181C
  static const List<BoxShadow> hardPressed = [
    BoxShadow(
      color: NeoBrutalColors.ink,
      offset: Offset(1.5, 1.5),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  /// Custom offset hard shadow
  static List<BoxShadow> hardOffset(double x, double y, {Color color = NeoBrutalColors.ink}) {
    return [
      BoxShadow(
        color: color,
        offset: Offset(x, y),
        blurRadius: 0,
        spreadRadius: 0,
      ),
    ];
  }
}

abstract final class NeoBrutalTypography {
  static const String displayFamily = 'GameLearnDisplay';
  static const String bodyFamily = 'GameLearnBody';
}
