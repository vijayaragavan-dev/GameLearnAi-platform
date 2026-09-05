import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// GameLearn AI atmospheric background system.
///
/// Lightweight background primitives that give the app a futuristic
/// game-world feel without expensive blur, BackdropFilter, or shader effects.
///
/// Performance rules enforced here:
///   - No BackdropFilter anywhere in this file
///   - No ImageFilter.blur usage
///   - No continuous animations (static or single-frame only)
///   - All CustomPainters are lightweight (<50 draw calls)
///   - All elements positioned behind content (never interrupt readability)
///
/// Usage pattern:
///   Stack(children: [
///     const AtmosphericBackground(),
///     // ... page content
///   ])

// ─────────────────────────────────────────────────────────────────────────────
// ATMOSPHERIC BACKGROUND — main page background
// ─────────────────────────────────────────────────────────────────────────────

/// Primary atmospheric background for GameLearnAI screens.
///
/// Dark: Deep space atmosphere with subtle radial ambient lights and a star field.
/// Light: Clean gradient with subtle accent wash.
///
/// This is a STATIC layer — no animations, no timers.
/// Use once per screen, as the lowest layer in the Stack.
class AtmosphericBackground extends StatelessWidget {
  const AtmosphericBackground({
    super.key,
    this.primaryGlow,
    this.secondaryGlow,
    this.showStarField = true,
    this.intensity = 1.0,
  });

  /// Custom primary glow color (defaults to primary purple).
  final Color? primaryGlow;

  /// Custom secondary glow color (defaults to cyan).
  final Color? secondaryGlow;

  /// Whether to show the star field decoration layer.
  final bool showStarField;

  /// Intensity multiplier for the glow effects (0.0 = none, 1.0 = full).
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = primaryGlow ?? AppColors.primary;
    final secondary = secondaryGlow ?? AppColors.secondary;

    if (!isDark) {
      // Light: clean, premium, subtle gradient wash
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppLightColors.backgroundElevated,
              AppLightColors.background,
            ],
          ),
        ),
      );
    }

    // Dark: layered atmosphere
    return CustomPaint(
      painter: _AtmospherePainter(
        primaryGlow: primary,
        secondaryGlow: secondary,
        showStarField: showStarField,
        intensity: intensity.clamp(0.0, 1.0),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  const _AtmospherePainter({
    required this.primaryGlow,
    required this.secondaryGlow,
    required this.showStarField,
    required this.intensity,
  });

  final Color primaryGlow;
  final Color secondaryGlow;
  final bool showStarField;
  final double intensity;

  // Deterministic "random" star positions (seeded, never random at runtime)
  static const _starSeeds = [
    (0.12, 0.08), (0.35, 0.15), (0.72, 0.05), (0.88, 0.20),
    (0.05, 0.30), (0.55, 0.25), (0.92, 0.35), (0.20, 0.45),
    (0.65, 0.40), (0.42, 0.55), (0.78, 0.60), (0.15, 0.65),
    (0.30, 0.72), (0.85, 0.70), (0.50, 0.80), (0.08, 0.85),
    (0.95, 0.88), (0.60, 0.92), (0.25, 0.95), (0.75, 0.15),
    (0.47, 0.32), (0.18, 0.52), (0.83, 0.48), (0.38, 0.78),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.backgroundDeep,
    );

    // 2. Primary atmospheric radial glow — top-left corner
    final primaryPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.6, -0.7),
        radius: 0.9,
        colors: [
          primaryGlow.withValues(alpha: 0.12 * intensity),
          primaryGlow.withValues(alpha: 0.04 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      primaryPaint,
    );

    // 3. Secondary atmospheric radial glow — bottom-right corner
    final secondaryPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.7, 0.8),
        radius: 0.7,
        colors: [
          secondaryGlow.withValues(alpha: 0.08 * intensity),
          secondaryGlow.withValues(alpha: 0.02 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      secondaryPaint,
    );

    // 4. Subtle top vignette — pulls focus to content
    final vignetteTop = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.center,
        colors: [
          Colors.black.withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.4));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.4),
      vignetteTop,
    );

    // 5. Star field — deterministic, never random at paint time
    if (showStarField) {
      _paintStarField(canvas, size);
    }
  }

  void _paintStarField(Canvas canvas, Size size) {
    final starPaint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < _starSeeds.length; i++) {
      final (fx, fy) = _starSeeds[i];
      final x = fx * size.width;
      final y = fy * size.height;

      // Vary star size and brightness deterministically
      final brightness = 0.3 + (i % 5) * 0.12;
      final radius = 0.6 + (i % 3) * 0.4;

      starPaint.color = Colors.white.withValues(alpha: brightness * intensity);
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  @override
  bool shouldRepaint(_AtmospherePainter oldDelegate) =>
      oldDelegate.primaryGlow != primaryGlow ||
      oldDelegate.secondaryGlow != secondaryGlow ||
      oldDelegate.showStarField != showStarField ||
      oldDelegate.intensity != intensity;
}

// ─────────────────────────────────────────────────────────────────────────────
// GLOW ORB — ambient decorative light source
// ─────────────────────────────────────────────────────────────────────────────

/// A static ambient glow orb — decorative background element.
///
/// Use sparingly (1-2 per screen max). Always position behind content.
/// Provides atmospheric depth without animation cost.
class GlowOrb extends StatelessWidget {
  const GlowOrb({
    super.key,
    required this.color,
    this.size = 200,
    this.opacity = 0.15,
  });

  final Color color;
  final double size;

  /// Alpha for the orb glow. Keep ≤ 0.25 for dark, ≤ 0.10 for light.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: opacity * 0.4),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AMBIENT LAYER — decorative section background
// ─────────────────────────────────────────────────────────────────────────────

/// Adds a subtle colored ambient wash behind a section or card cluster.
/// Use for differentiating major content regions without harsh borders.
class AmbientLayer extends StatelessWidget {
  const AmbientLayer({
    super.key,
    required this.child,
    this.color,
    this.intensity = 0.06,
  });

  final Widget child;
  final Color? color;

  /// Background tint intensity. Keep ≤ 0.10 for dark, ≤ 0.05 for light.
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = color ?? AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [
            tint.withValues(alpha: isDark ? intensity : intensity * 0.5),
            Colors.transparent,
          ],
        ),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAR FIELD DECORATION — standalone star field
// ─────────────────────────────────────────────────────────────────────────────

/// Lightweight static star field CustomPainter widget.
/// Use as a background decoration for hero sections or world cards.
class StarFieldDecoration extends StatelessWidget {
  const StarFieldDecoration({
    super.key,
    this.starCount = 30,
    this.starColor,
    this.seed = 42,
  });

  final int starCount;
  final Color? starColor;

  /// Seed for deterministic star positions (reproducible layout).
  final int seed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isDark) return const SizedBox.shrink(); // Not shown on light theme

    return CustomPaint(
      painter: _StarFieldPainter(
        starCount: starCount.clamp(5, 60),
        starColor: starColor ?? Colors.white,
        seed: seed,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter({
    required this.starCount,
    required this.starColor,
    required this.seed,
  });

  final int starCount;
  final Color starColor;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rng = math.Random(seed);

    for (var i = 0; i < starCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = 0.5 + rng.nextDouble() * 1.0;
      final alpha = 0.2 + rng.nextDouble() * 0.5;

      paint.color = starColor.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_StarFieldPainter oldDelegate) =>
      oldDelegate.starCount != starCount ||
      oldDelegate.starColor != starColor ||
      oldDelegate.seed != seed;
}

// ─────────────────────────────────────────────────────────────────────────────
// GRADIENT WASH — section gradient separator
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps a section in a gradient color wash — for separating major content areas.
class GradientWash extends StatelessWidget {
  const GradientWash({
    super.key,
    required this.child,
    this.gradient,
    this.padding,
    this.borderRadius,
  });

  final Widget child;
  final LinearGradient? gradient;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grad = gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primaryDeep.withValues(alpha: 0.12),
                  AppColors.backgroundElevated,
                ]
              : [
                  AppColors.primary.withValues(alpha: 0.04),
                  AppLightColors.backgroundElevated,
                ],
        );

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: grad,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CORNER ACCENT — decorative corner detail
// ─────────────────────────────────────────────────────────────────────────────

/// A small decorative corner accent — subtle premium detail for cards.
/// Place as an overlay inside a Stack at a specific corner.
class CornerAccent extends StatelessWidget {
  const CornerAccent({
    super.key,
    this.color,
    this.size = 60,
    this.corner = Alignment.topRight,
  });

  final Color? color;
  final double size;
  final Alignment corner;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isDark) return const SizedBox.shrink();

    final accent = color ?? AppColors.primary;
    return Align(
      alignment: corner,
      child: CustomPaint(
        size: Size(size, size),
        painter: _CornerAccentPainter(color: accent),
      ),
    );
  }
}

class _CornerAccentPainter extends CustomPainter {
  const _CornerAccentPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topRight,
        radius: 1.0,
        colors: [
          color.withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_CornerAccentPainter old) => old.color != color;
}
