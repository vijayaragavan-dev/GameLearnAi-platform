import 'package:flutter/widgets.dart';

/// Centralized motion token system for GameLearn AI — Version 2.0
///
/// Every animation must communicate a state change, interaction, progress,
/// reward, or navigation. Motion is never decorative for its own sake.
///
/// Philosophy:
///   - Fast (≤180ms) → immediate feedback, micro-interactions
///   - Normal (300ms) → page transitions, state changes
///   - Feature (500ms) → prominent entrance animations
///   - Celebration (950ms) → reward reveals, XP gain, confetti
///
/// Always check [AppMotion.reducedMotion] before running non-essential animations.
abstract final class AppMotion {
  // ── Duration tokens ───────────────────────────────────────────────────────

  /// Instant — < 100ms. For opacity flickers, tiny state hints.
  static const Duration instant = Duration(milliseconds: 80);

  /// Fast — 180ms. Press feedback, badge state, icon swap.
  static const Duration fast = Duration(milliseconds: 180);

  /// Hover — 160ms. Hover enter/exit on desktop/web.
  static const Duration hover = Duration(milliseconds: 160);

  /// Press — 120ms. Scale-down on tap-down, release.
  static const Duration press = Duration(milliseconds: 120);

  /// Normal — 300ms. Cards entering, container resize, route transition.
  static const Duration normal = Duration(milliseconds: 300);

  /// Fade — 250ms. Content fade-in/out, loading shimmer to content.
  static const Duration fade = Duration(milliseconds: 250);

  /// Scale — 220ms. Dialog/popup appear with scale.
  static const Duration scale = Duration(milliseconds: 220);

  /// Feature — 500ms. Prominent element entrance, hero section load.
  static const Duration feature = Duration(milliseconds: 500);

  /// Page transition — 380ms. Screen navigation, push/pop.
  static const Duration pageTransition = Duration(milliseconds: 380);

  /// Celebration — 950ms. Reward reveal, XP bar fill, achievement unlock.
  static const Duration celebration = Duration(milliseconds: 950);

  /// Reward — 1200ms. Multi-stage reward presentation.
  static const Duration reward = Duration(milliseconds: 1200);

  /// Stagger unit — 55ms. Used to offset list item entrance animations.
  static const Duration staggerUnit = Duration(milliseconds: 55);

  // ── Curve tokens ──────────────────────────────────────────────────────────

  /// Standard smooth deceleration — default for most transitions.
  static const Curve easeOut = Curves.easeOutCubic;

  /// Smooth ease-in-out — container resizes, progress bar fills.
  static const Curve easeInOut = Curves.easeInOutCubic;

  /// Material standard — system-level transitions.
  static const Curve standard = Curves.fastOutSlowIn;

  /// Spring — elastic for reward/celebration entrances.
  static const Curve spring = Curves.elasticOut;

  /// Decelerate — hero cards, major elements entering from edge.
  static const Curve decelerate = Curves.decelerate;

  /// Emphasized accelerate — elements exiting quickly.
  static const Curve emphasizedAccelerate = Curves.easeInCubic;

  /// Emphasized decelerate — elements entering with authority.
  static const Curve emphasizedDecelerate = Curves.easeOutQuart;

  /// Bounce out — playful landing for game reward elements.
  static const Curve bounceOut = Curves.bounceOut;

  /// Linear — timer bars, progress fills that must be visually linear.
  static const Curve linear = Curves.linear;

  // ── Reduced motion support ────────────────────────────────────────────────

  /// Returns true if the user has requested reduced motion via OS settings.
  /// Always check this before non-essential animations.
  ///
  /// Usage:
  ///   if (!AppMotion.reducedMotion(context)) {
  ///     // run animation
  ///   }
  static bool reducedMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// Returns the duration, or [Duration.zero] if reduced motion is enabled.
  /// Use for non-essential animations that should be skipped for accessibility.
  static Duration durFor(BuildContext context, Duration duration) =>
      reducedMotion(context) ? Duration.zero : duration;

  // ── Stagger helpers ────────────────────────────────────────────────────────

  /// Computes delay for a staggered list item at [index].
  static Duration staggerDelay(int index, {int maxItems = 12}) {
    final clampedIndex = index.clamp(0, maxItems);
    return staggerUnit * clampedIndex;
  }
}
