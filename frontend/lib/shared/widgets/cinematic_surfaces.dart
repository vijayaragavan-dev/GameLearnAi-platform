import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_typography.dart';
import 'app_backgrounds.dart';
import 'nova_companion.dart';
import 'pressable.dart';

/// Cinematic premium surface system — the new-UI visual language.
///
/// Derived from the `new-ui/` reference designs:
///   - glassmorphic neon-bordered panels
///   - cinematic gradient heroes with ambient glow orbs
///   - gradient glow CTAs (purple / cyan / gold)
///   - uppercase eyebrow labels with wide letter-spacing
///   - LIVE / NEW / SCAN status pills
///   - neon section headers with "View All" affordances
///
/// Rules:
///   - EXTENDS [AppColors]/[AppGradients]/[AppShadows]/[AppGlows]. No parallel
///     color system; all accents resolve through existing tokens.
///   - Theme-aware: dark gets the cinematic neon treatment, light gets a
///     clean premium treatment with the same structure.
///   - No BackdropFilter, no continuous animation, const-friendly.
///   - All interactive elements keep Semantics labels; state is never
///     communicated by color alone (pills always carry text/icons).

// ─────────────────────────────────────────────────────────────────────────────
// CINEMATIC HERO — gradient hero panel with glow orbs + optional Nova
// ─────────────────────────────────────────────────────────────────────────────

/// Cinematic hero panel used at the top of premium screens.
///
/// [gradient] tints the hero (defaults to brand purple). [novaMood] shows a
/// Nova companion at [novaSize] when non-null. [badge] is an overline pill
/// (e.g. "FEATURED WORLD", "CURRENT MISSION"). [tagline] renders as the
/// neon side-quote seen across references (hidden when null or on narrow
/// widths where it would crowd content).
class CinematicHero extends StatelessWidget {
  const CinematicHero({
    super.key,
    this.gradient,
    this.accent = AppColors.primary,
    this.badge,
    this.badgeIcon,
    required this.title,
    this.subtitle,
    this.tagline,
    this.novaMood,
    this.novaSize = 84,
    this.leading,
    this.trailing,
    this.bottom,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 20),
  });

  final Gradient? gradient;
  final Color accent;
  final String? badge;
  final IconData? badgeIcon;
  final Widget title;
  final Widget? subtitle;
  final String? tagline;
  final NovaMood? novaMood;
  final double novaSize;
  final Widget? leading;
  final Widget? trailing;
  final Widget? bottom;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final showTagline = tagline != null && width >= 560;

    return Semantics(
      container: true,
      child: Container(
        decoration: BoxDecoration(
          gradient:
              gradient ??
              AppGradients.featured(context, accent: accent),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isDark
                ? accent.withValues(alpha: 0.38)
                : AppLightColors.borderStrong,
          ),
          boxShadow: isDark
              ? AppShadows.depth3(accent, dark: true)
              : AppShadows.elevated(alpha: 0.08),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Stack(
            children: [
              // Ambient orbs — static, cheap, behind content.
              if (isDark)
                const Positioned(
                  top: -70,
                  right: -50,
                  child: GlowOrb(
                    color: AppColors.primary,
                    size: 220,
                    opacity: 0.22,
                  ),
                ),
              if (isDark)
                const Positioned(
                  bottom: -90,
                  left: -60,
                  child: GlowOrb(
                    color: AppColors.secondary,
                    size: 200,
                    opacity: 0.14,
                  ),
                ),
              if (isDark)
                const Positioned.fill(
                  child: StarFieldDecoration(starCount: 22, seed: 7),
                ),
              Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (badge != null)
                      _HeroBadge(
                        label: badge!,
                        icon: badgeIcon,
                        accent: accent,
                      ),
                    if (badge != null) const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(width: 14),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              title,
                              if (subtitle != null) ...[
                                const SizedBox(height: 6),
                                subtitle!,
                              ],
                            ],
                          ),
                        ),
                        if (novaMood != null) ...[
                          const SizedBox(width: 8),
                          NovaCompanion(
                            size: novaSize,
                            mood: novaMood!,
                          ),
                        ] else if (trailing != null) ...[
                          const SizedBox(width: 8),
                          trailing!,
                        ],
                      ],
                    ),
                    if (showTagline) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: NeonQuote(text: tagline!),
                      ),
                    ],
                    if (bottom != null) ...[
                      const SizedBox(height: 14),
                      bottom!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.label,
    this.icon,
    required this.accent,
  });

  final String label;
  final IconData? icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: accent),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
              color: isDark ? Colors.white : AppLightColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASS PANEL — neon-bordered glass card
// ─────────────────────────────────────────────────────────────────────────────

/// Glassmorphic panel with a neon edge — the reference card language.
///
/// [glowColor] drives border + ambient shadow. Content is [child].
/// Set [padding] to [EdgeInsets.zero] when the child manages its own inset.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.glowColor = AppColors.primary,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = AppRadius.lg,
    this.semanticsLabel,
  });

  final Widget child;
  final Color glowColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panel = Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceElevated.withValues(alpha: 0.72)
            : AppLightColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark
              ? glowColor.withValues(alpha: 0.32)
              : AppLightColors.borderStrong,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.14),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.30),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : AppShadows.elevated(alpha: 0.07),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Top sheen — subtle premium highlight.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 1.2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      (isDark ? Colors.white : glowColor).withValues(
                        alpha: isDark ? 0.22 : 0.35,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
    if (semanticsLabel == null) return panel;
    return Semantics(container: true, label: semanticsLabel, child: panel);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLOW CTA — gradient CTA button with press feedback
// ─────────────────────────────────────────────────────────────────────────────

/// Full-width gradient CTA with glow — SIGN IN / BEGIN SCAN / CONTINUE.
///
/// [gradient] defaults to brand purple. [onPressed] null renders the
/// disabled state (reduced opacity + disabled semantics).
class GlowCTA extends StatelessWidget {
  const GlowCTA({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon = Icons.arrow_forward_rounded,
    this.gradient,
    this.glowColor = AppColors.primary,
    this.semanticsLabel,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final Gradient? gradient;
  final Color glowColor;
  final String? semanticsLabel;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onPressed != null && !isLoading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticsLabel ?? label,
      child: Pressable(
        onTap: enabled ? onPressed : null,
        semanticsLabel: semanticsLabel ?? label,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
          decoration: BoxDecoration(
            gradient:
                gradient ??
                const LinearGradient(
                  colors: [Color(0xFFA855F7), AppColors.primary, Color(0xFF6366F1)],
                ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.22 : 0.0),
            ),
            boxShadow: enabled && isDark
                ? AppShadows.glow(glowColor, alpha: 0.45)
                : AppShadows.none,
          ),
          child: Opacity(
            opacity: enabled ? 1.0 : 0.55,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: Colors.white),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      label.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 10),
                    Icon(trailingIcon, size: 20, color: Colors.white),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEON SECTION HEADER — icon + title + subtitle + View All
// ─────────────────────────────────────────────────────────────────────────────

/// Section header matching the reference language (icon tile, uppercase
/// title, muted subtitle, trailing "View All →" action).
class NeonSectionHeader extends StatelessWidget {
  const NeonSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.accent = AppColors.primary,
    this.onViewAll,
    this.viewAllLabel = 'View All',
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accent;
  final VoidCallback? onViewAll;
  final String viewAllLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: isDark ? 0.14 : 0.10),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: accent.withValues(alpha: 0.40)),
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: isDark
                      ? AppColors.textPrimary
                      : AppLightColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondary
                        : AppLightColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onViewAll != null)
          Pressable(
            onTap: onViewAll,
            semanticsLabel: '$viewAllLabel for $title',
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    viewAllLabel,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.secondary
                          : AppColors.secondaryDeep,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: isDark
                        ? AppColors.secondary
                        : AppColors.secondaryDeep,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WORLD STATUS BADGE — LIVE / NEW / SCAN / COMING SOON / LOCKED
// ─────────────────────────────────────────────────────────────────────────────

/// Truthful world availability badge. State is always text + icon, never
/// color alone.
enum WorldStatus { live, fresh, scan, comingSoon, locked }

class WorldStatusBadge extends StatelessWidget {
  const WorldStatusBadge({super.key, required this.status});

  final WorldStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (label, icon, color) = switch (status) {
      WorldStatus.live => ('LIVE', Icons.bolt_rounded, AppColors.success),
      WorldStatus.fresh => ('NEW', Icons.auto_awesome_rounded, AppColors.xp),
      WorldStatus.scan => ('SCAN', Icons.radar_rounded, AppColors.secondary),
      WorldStatus.comingSoon => (
        'COMING SOON',
        Icons.schedule_rounded,
        AppColors.textTertiary,
      ),
      WorldStatus.locked => (
        'LOCKED',
        Icons.lock_rounded,
        AppColors.textTertiary,
      ),
    };
    return Semantics(
      label: 'World status: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.14 : 0.10),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEON QUOTE — slanted neon side-quote decoration
// ─────────────────────────────────────────────────────────────────────────────

/// Angled neon quote text used as hero decoration ("LEARN • PLAY • GROW").
/// Purely decorative — excluded from semantics.
class NeonQuote extends StatelessWidget {
  const NeonQuote({
    super.key,
    required this.text,
    this.color = AppColors.secondary,
    this.fontSize = 12,
  });

  final String text;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isDark) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: Transform.rotate(
        angle: -0.06,
        child: Text(
          text,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: AppTypography.displayFamily,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
            height: 1.5,
            color: color.withValues(alpha: 0.85),
            shadows: [
              Shadow(
                color: color.withValues(alpha: 0.65),
                blurRadius: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BRAND WORDMARK — GameLearnAI logo lockup with tagline
// ─────────────────────────────────────────────────────────────────────────────

/// Polished brand lockup: gamepad glyph in gradient tile + wordmark +
/// "PLAY • LEARN • GROW • REPEAT" tagline. Uses the real product identity.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.compact = false});

  final bool compact;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 38 : 44,
          height: compact ? 38 : 44,
          decoration: BoxDecoration(
            gradient: AppGradients.brand,
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.0),
            ),
            boxShadow: isDark
                ? AppShadows.glow(AppColors.primary, alpha: 0.35)
                : AppShadows.elevated(alpha: 0.10),
          ),
          child: Icon(
            Icons.sports_esports_rounded,
            size: compact ? 20 : 24,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  // Canonical wordmark (single Text widget so responsive
                  // regression tests can assert its bounds).
                  'GAMELEARN AI',
                  style: TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                  ),
                ),
              ),
              if (!compact)
                Text(
                  'PLAY • LEARN • GROW • REPEAT',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                    color: isDark
                        ? AppColors.textTertiary
                        : AppLightColors.textTertiary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// JOURNEY DOTS — Learn → Practice → Challenge → Master timeline
// ─────────────────────────────────────────────────────────────────────────────

/// Four-stage progression timeline from the Mission Briefing reference.
/// [stage] is the 0-based active stage (clamped 0..3); labels stay truthful.
class JourneyTimeline extends StatelessWidget {
  const JourneyTimeline({super.key, this.stage = 0});

  final int stage;

  static const _stages = [
    (Icons.menu_book_rounded, 'Learn', 'Understand'),
    (Icons.track_changes_rounded, 'Practice', 'Build Skills'),
    (Icons.emoji_events_outlined, 'Challenge', 'Earn XP'),
    (Icons.workspace_premium_outlined, 'Master', 'Level Up'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = stage.clamp(0, 3);
    return Semantics(
      label:
          'Journey stage ${active + 1} of 4: ${_stages[active].$2}',
      child: Row(
        children: [
          for (var i = 0; i < _stages.length; i++) ...[
            Expanded(child: _JourneyNode(
              icon: _stages[i].$1,
              title: _stages[i].$2,
              subtitle: _stages[i].$3,
              state: i < active
                  ? _JourneyState.done
                  : (i == active
                        ? _JourneyState.active
                        : _JourneyState.todo),
              isDark: isDark,
            )),
            if (i < _stages.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 34),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: i < active
                        ? AppColors.primary.withValues(alpha: 0.6)
                        : (isDark
                              ? AppColors.border
                              : AppLightColors.border),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

enum _JourneyState { done, active, todo }

class _JourneyNode extends StatelessWidget {
  const _JourneyNode({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.state,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final _JourneyState state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accent = state == _JourneyState.todo
        ? (isDark ? AppColors.textTertiary : AppLightColors.textTertiary)
        : AppColors.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: state == _JourneyState.active
                ? AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.12)
                : Colors.transparent,
            border: Border.all(
              color: state == _JourneyState.done
                  ? AppColors.success.withValues(alpha: 0.7)
                  : accent.withValues(
                      alpha: state == _JourneyState.active ? 0.9 : 0.4,
                    ),
              width: state == _JourneyState.active ? 2 : 1.4,
            ),
            boxShadow: state == _JourneyState.active && isDark
                ? AppShadows.glow(AppColors.primary, alpha: 0.45)
                : null,
          ),
          child: Icon(
            state == _JourneyState.done ? Icons.check_rounded : icon,
            size: 20,
            color: state == _JourneyState.done ? AppColors.success : accent,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: state == _JourneyState.todo
                ? (isDark
                      ? AppColors.textTertiary
                      : AppLightColors.textTertiary)
                : (isDark
                      ? AppColors.textPrimary
                      : AppLightColors.textPrimary),
          ),
        ),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            color: isDark
                ? AppColors.textTertiary
                : AppLightColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CINEMATIC SCAFFOLD — page scaffold with atmosphere + safe scroll
// ─────────────────────────────────────────────────────────────────────────────

/// Page scaffold: atmospheric background + optional glow tint + safe-area
/// scroll body with responsive gutters and a max content width on wide
/// viewports. Keeps heroes edge-to-edge on mobile while constraining text
/// density on desktop.
class CinematicScaffold extends StatelessWidget {
  const CinematicScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.glowColor,
    this.maxWidth = 720,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? glowColor;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          AtmosphericBackground(
            primaryGlow: glowColor ?? AppColors.primary,
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
