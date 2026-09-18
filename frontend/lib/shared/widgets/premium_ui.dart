/// Premium UI kit distilled from the `new-ui/` reference designs.
///
/// Visual language:
///
/// Data rules: every widget takes REAL values from callers. No hardcoded
/// XP/levels/ranks. Empty states stay honest.
library premium_ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_typography.dart';
import 'app_backgrounds.dart';
import 'game_button.dart' show PressableScale;

// ─────────────────────────────────────────────────────────────────────────────
// CINEMATIC SCAFFOLD — atmospheric page wrapper
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps a screen in the reference atmosphere: deep background, two restrained
/// glow orbs, star field. Static — no animations, no blur, no BackdropFilter.
class CinematicScaffold extends StatelessWidget {
  const CinematicScaffold({
    super.key,
    required this.body,
    this.primaryGlow = AppColors.primary,
    this.secondaryGlow = AppColors.secondary,
    this.topPadding = true,
  });

  final Widget body;
  final Color primaryGlow;
  final Color secondaryGlow;
  final bool topPadding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        const Positioned.fill(child: AtmosphericBackground()),
        if (isDark) ...[
          Positioned(
            top: -90,
            left: -70,
            child: IgnorePointer(
              child: GlowOrb(color: primaryGlow, size: 300, opacity: 0.13),
            ),
          ),
          Positioned(
            top: 220,
            right: -90,
            child: IgnorePointer(
              child: GlowOrb(color: secondaryGlow, size: 260, opacity: 0.09),
            ),
          ),
        ],
        Positioned.fill(child: body),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER — "YOUR LEARNING JOURNEY ... View All →"
// ─────────────────────────────────────────────────────────────────────────────

/// Reference-style section header: leading icon, uppercase tracked title,
/// subtitle, trailing action link. Honors text scale, min 48dp action target.
class PremiumSectionHeader extends StatelessWidget {
  const PremiumSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final subColor =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    return Row(
      crossAxisAlignment: subtitle == null
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 22, color: AppColors.secondary),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: titleColor,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: subColor,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          Semantics(
            button: true,
            label: actionLabel,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLOW CTA — full-width purple gradient button
// ─────────────────────────────────────────────────────────────────────────────

/// The signature reference CTA: purple→blue gradient, outer glow, uppercase
/// tracked label, trailing arrow. Pressable scale + haptics via [PressableScale].
class GlowCTA extends StatelessWidget {
  const GlowCTA({
    super.key,
    required this.label,
    this.onTap,
    this.icon = Icons.arrow_forward_rounded,
    this.leading,
    this.busy = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Widget? leading;
  final bool busy;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabled = onTap == null || busy;
    return Semantics(
      button: true,
      enabled: !disabled,
      label: semanticLabel ?? label,
      child: PressableScale(
        onTap: busy ? null : onTap,
        enabled: !disabled,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: isDark ? 0.45 : 0.25,
                      ),
                      blurRadius: 28,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              gradient: disabled
                  ? null
                  : const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFFA855F7), Color(0xFF7C3AED)],
                    ),
              color: disabled
                  ? (isDark
                        ? AppColors.lockedSurface
                        : AppLightColors.lockedSurface)
                  : null,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: disabled
                    ? (isDark ? AppColors.border : AppLightColors.border)
                    : Colors.white.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: Colors.white,
                    ),
                  )
                else ...[
                  if (leading != null) ...[leading!, const SizedBox(width: 10)],
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 10),
                    Icon(icon, size: 22, color: Colors.white),
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
// STATUS PILL — LIVE / NEW / COMING SOON / difficulty
// ─────────────────────────────────────────────────────────────────────────────

/// Small pill with dot/label. Never color-alone: always text + optional icon.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.color = AppColors.success,
    this.icon,
  });

  /// Green LIVE-style pill.
  const StatusPill.live({super.key, this.label = 'LIVE'})
    : color = AppColors.success,
      icon = Icons.fiber_manual_record_rounded;

  /// Purple NEW-style pill.
  const StatusPill.fresh({super.key, this.label = 'NEW'})
    : color = AppColors.primaryBright,
      icon = null;

  /// Muted COMING SOON pill.
  const StatusPill.soon({super.key, this.label = 'COMING SOON'})
    : color = AppColors.locked,
      icon = Icons.schedule_rounded;

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BENEFIT CARD — knowledge-scan style trio cards
// ─────────────────────────────────────────────────────────────────────────────

/// Compact glass benefit card: icon medallion + title + description.
/// Used for scan benefits, mission intel, tutor suggested actions.
class BenefitCard extends StatelessWidget {
  const BenefitCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.accent = AppColors.secondary,
    this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surface.withValues(alpha: 0.72)
            : AppLightColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.30 : 0.22),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : AppShadows.elevated(alpha: 0.05),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: isDark ? 0.14 : 0.10),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.25),
                        blurRadius: 16,
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, size: 24, color: accent),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimary
                  : AppLightColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark
                  ? AppColors.textSecondary
                  : AppLightColors.textSecondary,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return PressableScale(onTap: onTap, child: card);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOVA HERO PANEL — glass panel with Nova + message
// ─────────────────────────────────────────────────────────────────────────────

/// Glass panel pairing a leading visual (Nova) with a title + message.
/// Keeps real copy from callers; purely presentational.
class NovaHeroPanel extends StatelessWidget {
  const NovaHeroPanel({
    super.key,
    required this.leading,
    required this.title,
    required this.message,
    this.accentWord,
    this.accent = AppColors.secondary,
  });

  final Widget leading;
  final String title;
  final String message;
  final String? accentWord;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.07),
                  Colors.white.withValues(alpha: 0.02),
                ]
              : [Colors.white, Colors.white],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? accent.withValues(alpha: 0.28)
              : AppLightColors.border,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : AppShadows.elevated(alpha: 0.06),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 6),
                _RichMessage(
                  message: message,
                  accentWord: accentWord,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RichMessage extends StatelessWidget {
  const _RichMessage({
    required this.message,
    required this.accentWord,
    required this.isDark,
  });

  final String message;
  final String? accentWord;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: 14,
      height: 1.5,
      color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
    );
    if (accentWord == null || !message.contains(accentWord!)) {
      return Text(message, style: base);
    }
    final parts = message.split(accentWord!);
    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            TextSpan(text: parts[i], style: base),
            if (i < parts.length - 1)
              TextSpan(
                text: accentWord,
                style: base.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBright,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FLOATING GLASS NAV — reference bottom navigation shell
// ─────────────────────────────────────────────────────────────────────────────

/// Floating rounded glass container for the bottom nav bar.
/// Content (tabs) is injected so routing stays in the shell.
class FloatingGlassNav extends StatelessWidget {
  const FloatingGlassNav({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surface.withValues(alpha: 0.92)
            : AppLightColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.22)
              : AppLightColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          if (isDark)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: child,
      ),
    );
  }
}

/// Selected tab glow wrapper — restrained single-glow treatment.
class NavTabGlow extends StatelessWidget {
  const NavTabGlow({
    super.key,
    required this.selected,
    required this.child,
  });

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: selected
            ? const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
              )
            : null,
        borderRadius: BorderRadius.circular(18),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: isDark ? 0.5 : 0.3,
                  ),
                  blurRadius: 18,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
