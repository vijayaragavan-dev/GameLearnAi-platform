import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';

/// Procedural cinematic scenery — the F7 artwork system.
///
/// The new-UI references are built on illustrated fantasy landscapes:
/// night skies, glowing moons, mountain ranges, floating islands, energy
/// portals, mist valleys. The repo ships no bitmap artwork and must not
/// depend on copyrighted images, so this file paints that language
/// deterministically with a single lightweight [CustomPainter].
///
/// Performance contract:
///   - ~45 draw calls per scene, static (no animation, no timers).
///   - Always mounted inside a [RepaintBoundary].
///   - Purely decorative → wrapped in [ExcludeSemantics].
///   - Theme-aware: full cinematic detail in dark mode, soft tinted
///     daylight treatment in light mode (same composition, readable).
///
/// Data honesty: palettes are keyed by stable world/game identity
/// ([scenePaletteForWorld]/[scenePaletteForGame]) — never by display
/// name — with a neutral [ScenePalette.arcane] fallback for unknowns.

@immutable
class ScenePalette {
  const ScenePalette({
    required this.skyTop,
    required this.skyBottom,
    required this.moon,
    required this.mountainFar,
    required this.mountainNear,
    required this.islandRim,
    required this.portal,
    required this.portalCore,
    required this.mist,
    required this.groundGlow,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color moon;
  final Color mountainFar;
  final Color mountainNear;
  final Color islandRim;
  final Color portal;
  final Color portalCore;
  final Color mist;
  final Color groundGlow;

  // ── Named worlds ──────────────────────────────────────────────────
  static const arcane = ScenePalette(
    skyTop: Color(0xFF0B0620),
    skyBottom: Color(0xFF2A1658),
    moon: Color(0xFFE9E4FF),
    mountainFar: Color(0xFF241645),
    mountainNear: Color(0xFF120B26),
    islandRim: Color(0xFFA78BFA),
    portal: Color(0xFF8B5CF6),
    portalCore: Color(0xFFC4B5FD),
    mist: Color(0xFF8B5CF6),
    groundGlow: Color(0xFF8B5CF6),
  );

  static const indigo = ScenePalette(
    skyTop: Color(0xFF060A24),
    skyBottom: Color(0xFF1E2A78),
    moon: Color(0xFFE0E7FF),
    mountainFar: Color(0xFF1B2452),
    mountainNear: Color(0xFF0B1030),
    islandRim: Color(0xFF818CF8),
    portal: Color(0xFF6366F1),
    portalCore: Color(0xFFA5B4FC),
    mist: Color(0xFF6366F1),
    groundGlow: Color(0xFF6366F1),
  );

  static const abyss = ScenePalette(
    skyTop: Color(0xFF031420),
    skyBottom: Color(0xFF0C4A6E),
    moon: Color(0xFFE0F7FF),
    mountainFar: Color(0xFF0E3A56),
    mountainNear: Color(0xFF06222F),
    islandRim: Color(0xFF22D3EE),
    portal: Color(0xFF06B6D4),
    portalCore: Color(0xFFA5F3FC),
    mist: Color(0xFF06B6D4),
    groundGlow: Color(0xFF06B6D4),
  );

  static const ember = ScenePalette(
    skyTop: Color(0xFF1C0B04),
    skyBottom: Color(0xFF7C2D12),
    moon: Color(0xFFFFF1D6),
    mountainFar: Color(0xFF4A1D0C),
    mountainNear: Color(0xFF200C05),
    islandRim: Color(0xFFFB923C),
    portal: Color(0xFFF97316),
    portalCore: Color(0xFFFDBA74),
    mist: Color(0xFFF97316),
    groundGlow: Color(0xFFF97316),
  );

  static const verdant = ScenePalette(
    skyTop: Color(0xFF04160F),
    skyBottom: Color(0xFF065F46),
    moon: Color(0xFFDCFCE7),
    mountainFar: Color(0xFF0B3B2C),
    mountainNear: Color(0xFF041F16),
    islandRim: Color(0xFF34D399),
    portal: Color(0xFF10B981),
    portalCore: Color(0xFFA7F3D0),
    mist: Color(0xFF10B981),
    groundGlow: Color(0xFF10B981),
  );

  static const solar = ScenePalette(
    skyTop: Color(0xFF1A1002),
    skyBottom: Color(0xFF713F12),
    moon: Color(0xFFFFF7D6),
    mountainFar: Color(0xFF45300A),
    mountainNear: Color(0xFF1E1404),
    islandRim: Color(0xFFFACC15),
    portal: Color(0xFFEAB308),
    portalCore: Color(0xFFFEF08A),
    mist: Color(0xFFEAB308),
    groundGlow: Color(0xFFEAB308),
  );

  static const rose = ScenePalette(
    skyTop: Color(0xFF1E0716),
    skyBottom: Color(0xFF831843),
    moon: Color(0xFFFFE4F1),
    mountainFar: Color(0xFF4A1030),
    mountainNear: Color(0xFF220816),
    islandRim: Color(0xFFF472B6),
    portal: Color(0xFFEC4899),
    portalCore: Color(0xFFFBCFE8),
    mist: Color(0xFFEC4899),
    groundGlow: Color(0xFFEC4899),
  );

  static const slate = ScenePalette(
    skyTop: Color(0xFF0A0F1E),
    skyBottom: Color(0xFF334155),
    moon: Color(0xFFF1F5F9),
    mountainFar: Color(0xFF26314A),
    mountainNear: Color(0xFF0E1526),
    islandRim: Color(0xFF94A3B8),
    portal: Color(0xFF64748B),
    portalCore: Color(0xFFCBD5E1),
    mist: Color(0xFF64748B),
    groundGlow: Color(0xFF64748B),
  );

  static const crimson = ScenePalette(
    skyTop: Color(0xFF1C0505),
    skyBottom: Color(0xFF7F1D1D),
    moon: Color(0xFFFFE4E4),
    mountainFar: Color(0xFF4A1212),
    mountainNear: Color(0xFF1E0707),
    islandRim: Color(0xFFF87171),
    portal: Color(0xFFEF4444),
    portalCore: Color(0xFFFECACA),
    mist: Color(0xFFEF4444),
    groundGlow: Color(0xFFEF4444),
  );

  static const teal = ScenePalette(
    skyTop: Color(0xFF02201D),
    skyBottom: Color(0xFF115E59),
    moon: Color(0xFFD9FFFB),
    mountainFar: Color(0xFF0B3B37),
    mountainNear: Color(0xFF03211E),
    islandRim: Color(0xFF2DD4BF),
    portal: Color(0xFF14B8A6),
    portalCore: Color(0xFF99F6E4),
    mist: Color(0xFF14B8A6),
    groundGlow: Color(0xFF14B8A6),
  );

  static const violet = ScenePalette(
    skyTop: Color(0xFF120726),
    skyBottom: Color(0xFF5B21B6),
    moon: Color(0xFFF1E8FF),
    mountainFar: Color(0xFF341460),
    mountainNear: Color(0xFF170A30),
    islandRim: Color(0xFFA855F7),
    portal: Color(0xFF9333EA),
    portalCore: Color(0xFFD8B4FE),
    mist: Color(0xFF9333EA),
    groundGlow: Color(0xFF9333EA),
  );
}

/// Resolves a world palette from a stable backend [iconKey].
/// Keyword matching is on controlled backend keys (not display names);
/// unknown keys fall back to [ScenePalette.arcane].
ScenePalette scenePaletteForWorld(String iconKey) {
  final key = iconKey.toLowerCase();
  if (key.contains('network') || key.contains('signal')) {
    return ScenePalette.abyss;
  }
  if (key.contains('data_base') ||
      key.contains('database') ||
      key.contains('db_')) {
    return ScenePalette.ember;
  }
  if (key.contains('os') || key.contains('system') || key.contains('kernel')) {
    return ScenePalette.slate;
  }
  if (key.contains('data_struct') ||
      key.contains('tree') ||
      key.contains('graph')) {
    return ScenePalette.verdant;
  }
  if (key.contains('algo') || key.contains('analy')) {
    return ScenePalette.violet;
  }
  if (key.contains('oop') || key.contains('object') || key.contains('cube')) {
    return ScenePalette.abyss;
  }
  if (key.contains('ai') ||
      key.contains('ml') ||
      key.contains('neural') ||
      key.contains('brain')) {
    return ScenePalette.rose;
  }
  if (key.contains('science') || key.contains('chart')) {
    return ScenePalette.teal;
  }
  if (key.contains('web') || key.contains('globe') || key.contains('code')) {
    return ScenePalette.indigo;
  }
  if (key.contains('arch') || key.contains('board')) {
    return ScenePalette.solar;
  }
  return ScenePalette.arcane;
}

/// Resolves a game palette from a stable game id/type key.
/// Unknown keys fall back to [ScenePalette.arcane].
ScenePalette scenePaletteForGame(String gameKey) {
  final key = gameKey.toLowerCase();
  if (key.contains('memory')) return ScenePalette.abyss;
  if (key.contains('speed') || key.contains('snake') || key.contains('ladder')) {
    return ScenePalette.ember;
  }
  if (key.contains('debug') || key.contains('sequence')) {
    return ScenePalette.verdant;
  }
  if (key.contains('unlock') || key.contains('mystery') || key.contains('target')) {
    return ScenePalette.solar;
  }
  if (key.contains('boss')) {
    return ScenePalette.crimson;
  }
  if (key.contains('connect') || key.contains('network')) {
    return ScenePalette.teal;
  }
  if (key.contains('puzzle') ||
      key.contains('concept') ||
      key.contains('quiz')) {
    return ScenePalette.violet;
  }
  return ScenePalette.arcane;
}

// ─────────────────────────────────────────────────────────────────────────────
// CINEMATIC SCENERY — static fantasy landscape painter
// ─────────────────────────────────────────────────────────────────────────────

/// Full-bleed static scenery layer. Expands to its parent [Stack].
class CinematicScenery extends StatelessWidget {
  const CinematicScenery({
    super.key,
    this.palette = ScenePalette.arcane,
    this.seed = 7,
    this.intensity = 1.0,
  });

  final ScenePalette palette;
  final int seed;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _ScenePainter(
            palette: palette,
            seed: seed,
            dark: dark,
            intensity: intensity.clamp(0.0, 1.0),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.palette,
    required this.seed,
    required this.dark,
    required this.intensity,
  });

  final ScenePalette palette;
  final int seed;
  final bool dark;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final rng = math.Random(seed);
    final p = palette;

    // Light mode: same composition as a soft daylight tint so card art
    // stays visible without dark glass assumptions.
    final skyTop = dark ? p.skyTop : const Color(0xFFE8EFF8);
    final skyBottom = dark
        ? p.skyBottom
        : p.portal.withValues(alpha: 0.30);
    final mFar = dark ? p.mountainFar : const Color(0xFFC9D6EA);
    final mNear = dark ? p.mountainNear : const Color(0xFF9FB2CC);

    // 1. Sky.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skyTop, skyBottom],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 2. Stars (dark only).
    if (dark) {
      final star = Paint()..style = PaintingStyle.fill;
      for (var i = 0; i < 26; i++) {
        final x = rng.nextDouble() * w;
        final y = rng.nextDouble() * h * 0.55;
        final r = 0.5 + rng.nextDouble() * 1.1;
        star.color = Colors.white.withValues(
          alpha: (0.25 + rng.nextDouble() * 0.55) * intensity,
        );
        canvas.drawCircle(Offset(x, y), r, star);
      }
    }

    // 3. Moon + halo. Wide viewports cap the disc so it reads as a
    // moon, not a backdrop wall (phones are unaffected — all values
    // below exceed phone geometry).
    final moonC = Offset(w * 0.78, h * 0.26);
    final moonR = math.min(
      math.min(w, h) * (w > h ? 0.09 : 0.10),
      72.0,
    );
    canvas.drawCircle(
      moonC,
      moonR * 2.6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            p.moon.withValues(alpha: (dark ? 0.30 : 0.35) * intensity),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: moonC, radius: moonR * 2.6)),
    );
    canvas.drawCircle(
      moonC,
      moonR,
      Paint()..color = dark ? p.moon : Colors.white.withValues(alpha: 0.95),
    );

    // 4. Birds (dark only) — two tiny arcs near the moon.
    if (dark) {
      final bird = Paint()
        ..color = Colors.black.withValues(alpha: 0.55 * intensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 3; i++) {
        final bx = w * (0.52 + i * 0.05) + rng.nextDouble() * 6;
        final by = h * (0.30 + (i % 2) * 0.05);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(bx, by), radius: 4.5),
          math.pi * 1.15,
          math.pi * 0.7,
          false,
          bird,
        );
      }
    }

    // 5. Far mountain range.
    canvas.drawPath(
      _ridge(w, h, 0.60, 0.10, rng),
      Paint()..color = mFar,
    );

    // 6. Portal (right side, behind island) — rings + core. Ring radii
    // are capped so ultra-wide heroes keep a portal, not a stadium.
    final portalC = Offset(w * 0.70, h * 0.56);
    final prx = math.min(w * 0.105, 110.0);
    final pry = h * 0.135;
    canvas.drawCircle(
      portalC,
      prx * 2.2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            p.portal.withValues(alpha: (dark ? 0.40 : 0.22) * intensity),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(center: portalC, radius: prx * 2.2),
        ),
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    for (var i = 0; i < 3; i++) {
      final t = 1.0 - i * 0.24;
      ring.color = p.portal.withValues(
        alpha: ((dark ? 0.65 : 0.45) - i * 0.15) * intensity,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: portalC,
          width: prx * 2 * t,
          height: pry * 2 * t,
        ),
        ring,
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: portalC,
        width: prx * 0.9,
        height: pry * 0.9,
      ),
      Paint()
        ..shader = RadialGradient(
          colors: [
            (dark ? p.portalCore : Colors.white).withValues(
              alpha: (dark ? 0.9 : 0.75) * intensity,
            ),
            p.portal.withValues(alpha: 0.25 * intensity),
          ],
        ).createShader(
          Rect.fromCenter(
            center: portalC,
            width: prx * 0.9,
            height: pry * 0.9,
          ),
        ),
    );

    // 7. Floating island (left-center) with glow rim + hanging shard.
    // Width is capped so wide screens keep an island, not a horizon wire.
    final icx = w * 0.30;
    final icy = h * 0.60;
    final iw = math.min(w * 0.38, 400.0);
    final ih = h * 0.085;
    canvas.drawCircle(
      Offset(icx, icy + ih * 0.4),
      iw * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [
            p.islandRim.withValues(alpha: (dark ? 0.30 : 0.18) * intensity),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(icx, icy + ih * 0.4),
            radius: iw * 0.55,
          ),
        ),
    );
    final island = Path()
      ..moveTo(icx - iw / 2, icy)
      ..lineTo(icx + iw / 2, icy)
      ..lineTo(icx + iw * 0.16, icy + ih)
      ..lineTo(icx - iw * 0.16, icy + ih)
      ..close();
    canvas.drawPath(island, Paint()..color = mNear);
    // Grassy rim light along the top edge.
    canvas.drawLine(
      Offset(icx - iw / 2, icy),
      Offset(icx + iw / 2, icy),
      Paint()
        ..color = (dark ? p.islandRim : p.portal).withValues(
          alpha: (dark ? 0.9 : 0.6) * intensity,
        )
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    // Hanging shard.
    final shard = Path()
      ..moveTo(icx - iw * 0.05, icy + ih)
      ..lineTo(icx + iw * 0.05, icy + ih)
      ..lineTo(icx, icy + ih * 2.1)
      ..close();
    canvas.drawPath(shard, Paint()..color = mNear);
    // Island beacon.
    canvas.drawCircle(
      Offset(icx, icy - ih * 0.55),
      3.2,
      Paint()
        ..color = (dark ? p.portalCore : p.portal).withValues(
          alpha: 0.95 * intensity,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // 8. Near mountain range.
    canvas.drawPath(
      _ridge(w, h, 0.74, 0.08, rng),
      Paint()..color = mNear,
    );

    // 9. Mist band.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.62, w, h * 0.20),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            p.mist.withValues(alpha: (dark ? 0.16 : 0.10) * intensity),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, h * 0.62, w, h * 0.20)),
    );

    // 10. Foreground hill + ground glow.
    canvas.drawPath(
      _ridge(w, h, 0.92, 0.05, rng),
      Paint()..color = dark ? p.skyTop : const Color(0xFFD9E4F3),
    );
    canvas.drawCircle(
      Offset(w * 0.5, h * 1.02),
      w * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [
            p.groundGlow.withValues(alpha: (dark ? 0.22 : 0.12) * intensity),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(w * 0.5, h * 1.02),
          radius: w * 0.55,
        )),
    );
  }

  Path _ridge(
    double w,
    double h,
    double baseY,
    double variance,
    math.Random rng,
  ) {
    final path = Path()..moveTo(0, h * baseY);
    const steps = 7;
    for (var i = 1; i <= steps; i++) {
      final x = w * i / steps;
      final y = h * (baseY - rng.nextDouble() * variance);
      path.lineTo(x, y);
    }
    path
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    return path;
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.palette != palette ||
      old.seed != seed ||
      old.dark != dark ||
      old.intensity != intensity;
}

/// Stable deterministic seed for a backend identity key (world id, game
/// id, topic id). Same key always yields the same artwork — art varies by
/// identity, never by display name or by user data.
int seedForKey(String key) {
  var hash = 5381;
  for (var i = 0; i < key.length; i++) {
    hash = ((hash << 5) + hash + key.codeUnitAt(i)) & 0x7FFFFFFF;
  }
  return hash % 100000;
}

// ─────────────────────────────────────────────────────────────────────────────
// SCENE THUMB — compact identity artwork for world / game cards
// ─────────────────────────────────────────────────────────────────────────────

/// Compact framed scenery tile with a centered identity glyph.
///
/// Used for the right-side artwork on world rows and game cards (the
/// illustrated panels in the new-UI references). [palette] and [seed] must
/// come from stable backend identity ([scenePaletteForWorld]/[seedForKey]),
/// [icon]/[accent] from the matching visual registry — art is scenery, the
/// glyph carries the real identity. Decorative background is excluded from
/// semantics; pass [label] to expose the identity accessibly.
class SceneThumb extends StatelessWidget {
  const SceneThumb({
    super.key,
    required this.palette,
    required this.seed,
    required this.icon,
    required this.accent,
    this.width = 92,
    this.height = 84,
    this.iconSize = 26,
    this.borderRadius = 14,
    this.label,
  });

  final ScenePalette palette;
  final int seed;
  final IconData icon;
  final Color accent;
  final double width;
  final double height;
  final double iconSize;
  final double borderRadius;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final art = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: CinematicScenery(
                palette: palette,
                seed: seed,
                intensity: dark ? 1.0 : 0.6,
              ),
            ),
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
                          alpha: dark ? 0.35 : 0.15,
                        ),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Container(
                padding: EdgeInsets.all(iconSize * 0.42),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: dark ? 0.45 : 0.30,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.65),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: dark ? 0.45 : 0.25),
                      blurRadius: 14,
                      offset: Offset.zero,
                    ),
                  ],
                ),
                child: Icon(icon, size: iconSize, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
    if (label == null) {
      return ExcludeSemantics(child: art);
    }
    return Semantics(label: label, excludeSemantics: true, child: art);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCENE ART — framed artwork panel for cards and heroes
// ─────────────────────────────────────────────────────────────────────────────

/// Framed scenery panel: rounded clip + readability scrim + optional
/// foreground [child]. Decorative background is excluded from semantics.
class SceneArt extends StatelessWidget {
  const SceneArt({
    super.key,
    this.palette = ScenePalette.arcane,
    this.seed = 7,
    this.borderRadius = AppRadius.lg,
    this.scrimStrength = 0.55,
    this.child,
  });

  final ScenePalette palette;
  final int seed;
  final double borderRadius;

  /// Bottom scrim strength for text legibility (0 = none, 1 = heavy).
  final double scrimStrength;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: [
          Positioned.fill(
            child: CinematicScenery(palette: palette, seed: seed),
          ),
          if (scrimStrength > 0)
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
                          alpha: (dark ? scrimStrength : scrimStrength * 0.45),
                        ),
                      ],
                      stops: const [0.35, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          if (child != null) Positioned.fill(child: child!),
        ],
      ),
    );
  }
}
