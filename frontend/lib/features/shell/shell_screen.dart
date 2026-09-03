import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/progress_indicators.dart';
import '../dashboard/providers/dashboard_provider.dart';

/// Premium game-HUD navigation scaffold.
///
/// - compact (<600): bottom navigation 66dp — compact HUD selection
/// - medium (600–<1200): NavigationRail 80dp
/// - wide (>=1200): extended rail 256dp with player HUD (real data only)
///
/// All routes, redirects, deep-links preserved. No feature screen redesign.
class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _tabs = [
    ('/home', AppIcons.navHomeIdle, AppIcons.navHomeActive, 'Command'),
    ('/subjects', AppIcons.navWorldsIdle, AppIcons.navWorldsActive, 'Worlds'),
    ('/progress', AppIcons.navStatsIdle, AppIcons.navStatsActive, 'Stats'),
    ('/profile', AppIcons.navProfileIdle, AppIcons.navProfileActive, 'Profile'),
  ];

  int _selectedIndex(String loc) {
    final idx = _tabs.indexWhere((t) => loc.startsWith(t.$1));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = _selectedIndex(location);
    final isRail = AppBreakpoints.isRailVisible(context);
    final isWide = AppBreakpoints.isWide(context);
    final shouldConstrain =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.medium;

    if (!isRail) {
      return Scaffold(
        extendBody: true,
        body: _ShellBackground(child: child),
        bottomNavigationBar: _PremiumBottomBar(index: index),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _PremiumRail(
            index: index,
            extended: isWide,
            onTap: (i) {
              if (i == index) return;
              ref.read(hapticsProvider).tap();
              context.go(_tabs[i].$1);
            },
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Theme.of(context).dividerColor,
          ),
          Expanded(
            child: _ShellBackground(
              child: shouldConstrain
                  ? Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppLayout.maxContentWidth,
                        ),
                        child: child,
                      ),
                    )
                  : child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle immersive wash + depth separation for content area.
/// Restrained: one gradient, no animation, no blur.
class _ShellBackground extends StatelessWidget {
  const _ShellBackground({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0D142E), Color(0xFF070B17)],
                stops: [0.0, 0.55],
              )
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color(0xFFF8FAFC), AppLightColors.background],
              ),
      ),
      child: Container(
        // extremely subtle radial highlight at top-center — one per shell
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -1.2),
            radius: 1.4,
            colors: isDark
                ? [
                    AppColors.primaryDeep.withValues(alpha: 0.08),
                    Colors.transparent,
                  ]
                : [
                    AppColors.primary.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Premium bottom bar — 66dp compact HUD. Active = glow + strong label, inactive muted.
class _PremiumBottomBar extends ConsumerWidget {
  const _PremiumBottomBar({required this.index});
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ShellScreen._tabs;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      decoration: BoxDecoration(
        color: surface.withValues(alpha: isDark ? 0.96 : 0.98),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.border : AppLightColors.border,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final selected = index == i;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: '${tab.$4} tab',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: selected
                        ? null
                        : () {
                            ref.read(hapticsProvider).tap();
                            context.go(tab.$1);
                          },
                    child: AnimatedContainer(
                      duration: AppMotion.fast,
                      curve: AppMotion.easeOut,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(
                                alpha: isDark ? 0.14 : 0.09,
                              )
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: selected
                            ? Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: isDark ? 0.22 : 0.16,
                                ),
                              )
                            : null,
                      ),
                      child: AnimatedScale(
                        scale: selected ? 1.04 : 1.0,
                        duration: AppMotion.fast,
                        curve: AppMotion.spring,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: selected
                                  ? BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: AppShadows.glow(
                                        AppColors.primary,
                                        alpha: isDark ? 0.22 : 0.10,
                                      ),
                                    )
                                  : null,
                              child: Icon(
                                selected ? tab.$3 : tab.$2,
                                size: 23,
                                color: selected
                                    ? (isDark
                                          ? AppColors.primaryBright
                                          : AppColors.primary)
                                    : (isDark
                                          ? AppColors.textTertiary
                                          : AppLightColors.textTertiary),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tab.$4.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.3,
                                color: selected
                                    ? (isDark
                                          ? AppColors.primaryBright
                                          : AppColors.primary)
                                    : (isDark
                                          ? AppColors.textTertiary
                                          : AppLightColors.textTertiary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _PremiumRail extends StatelessWidget {
  const _PremiumRail({
    required this.index,
    required this.extended,
    required this.onTap,
  });
  final int index;
  final bool extended;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = ShellScreen._tabs;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        // subtle left-edge depth on dark
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(2, 0),
                ),
              ]
            : null,
      ),
      child: NavigationRail(
        extended: extended,
        minWidth: extended ? AppLayout.railExtendedWidth : AppLayout.railWidth,
        minExtendedWidth: AppLayout.railExtendedWidth,
        backgroundColor: Colors.transparent,
        selectedIndex: index,
        onDestinationSelected: onTap,
        labelType: extended
            ? NavigationRailLabelType.none
            : NavigationRailLabelType.all,
        useIndicator: true,
        indicatorColor: AppColors.primary.withValues(
          alpha: isDark ? 0.16 : 0.10,
        ),
        leading: _RailHeader(extended: extended),
        trailing: extended ? const _RailFooter() : null,
        destinations: [
          for (final tab in tabs)
            NavigationRailDestination(
              icon: Icon(tab.$2),
              selectedIcon: Icon(tab.$3),
              label: Text(tab.$4),
              padding: const EdgeInsets.symmetric(vertical: 4),
            ),
        ],
      ),
    );
  }
}

class _RailHeader extends StatelessWidget {
  const _RailHeader({required this.extended});
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Column(
        children: [
          // Brand identity — compact game platform mark
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.brand,
              boxShadow: AppShadows.glow(
                AppColors.primary,
                alpha: isDark ? 0.28 : 0.14,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.0),
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          if (!extended)
            Text(
              'GL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: isDark
                    ? AppColors.textTertiary
                    : AppLightColors.textTertiary,
              ),
            )
          else
            Column(
              children: [
                Text(
                  'GAMELEARN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                    color: isDark
                        ? AppColors.textTertiary
                        : AppLightColors.textTertiary,
                  ),
                ),
                Text(
                  'AI',
                  style: TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: isDark
                        ? AppColors.textPrimary
                        : AppLightColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                // Player HUD only on extended rail — real data, graceful hide if unavailable
                const _DesktopPlayerHUD(),
                const SizedBox(height: 12),
                Divider(
                  color: isDark ? AppColors.border : AppLightColors.border,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Desktop extended rail player HUD — reads real dashboard data only.
/// Shows level/XP/streak when available; otherwise omits gracefully (no fake numbers).
class _DesktopPlayerHUD extends ConsumerWidget {
  const _DesktopPlayerHUD();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final data = state.data;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (data == null) {
      // Loading / error — hide metrics gracefully, keep brand + nav functional.
      // Show subtle placeholder hint without fabricating numbers.
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.surfaceHigh : AppLightColors.surfaceHigh)
              .withValues(alpha: isDark ? 0.5 : 1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isDark ? AppColors.border : AppLightColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.shield_outlined,
              size: 13,
              color: isDark
                  ? AppColors.textTertiary
                  : AppLightColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Syncing command center…',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textTertiary
                      : AppLightColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final learnerName = data.learner.displayName;
    final initial = learnerName.isNotEmpty
        ? learnerName.trim().characters.first.toUpperCase()
        : 'A';
    final gam = data.gamification;
    final streakDays = data.streak.currentStreakDays;
    final atMax = gam.atMaxLevel;

    // XP fraction from real server values — same derivation as XPBar.
    double xpFraction = 0.0;
    if (!atMax && gam.xpToNextLevel != null) {
      final next = gam.totalXp + gam.xpToNextLevel!;
      if (next > 0) xpFraction = (gam.totalXp / next).clamp(0.02, 1.0);
    } else if (atMax) {
      xpFraction = 1.0;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.surfaceElevated,
                  AppColors.surface.withValues(alpha: 0.9),
                ]
              : [AppLightColors.surface, const Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.border : AppLightColors.border,
        ),
        boxShadow: isDark ? null : AppShadows.elevated(alpha: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Identity row — avatar initial + name
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.brand,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                    width: 1.2,
                  ),
                  boxShadow: AppShadows.glow(
                    AppColors.primary,
                    alpha: isDark ? 0.22 : 0.12,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      learnerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: isDark
                            ? AppColors.textPrimary
                            : AppLightColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'OPERATIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: isDark
                            ? AppColors.textTertiary
                            : AppLightColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Level + XP row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: isDark ? 0.14 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.military_tech_rounded,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'LVL ${gam.currentLevel}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  atMax ? 'MAX LEVEL' : '${gam.totalXp} XP',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: atMax
                        ? AppColors.success
                        : (isDark
                              ? AppColors.textSecondary
                              : AppLightColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          XPProgress(fraction: xpFraction, height: 6),
          const SizedBox(height: 6),
          Text(
            atMax
                ? 'Peak mastery reached'
                : '${gam.xpToNextLevel} XP to next level',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textTertiary
                  : AppLightColors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          // Streak — real value, hide glow if 0
          Semantics(
            label: 'Streak $streakDays days',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: streakDays > 0
                    ? AppColors.streak.withValues(alpha: isDark ? 0.14 : 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: streakDays > 0
                      ? AppColors.streak.withValues(alpha: 0.45)
                      : (isDark ? AppColors.border : AppLightColors.border),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    streakDays > 0
                        ? Icons.local_fire_department_rounded
                        : Icons.local_fire_department_outlined,
                    size: 14,
                    color: streakDays > 0
                        ? AppColors.streak
                        : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$streakDays',
                    style: TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: streakDays > 0
                          ? AppColors.streak
                          : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    streakDays == 1 ? 'DAY STREAK' : 'DAY STREAK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: streakDays > 0
                          ? AppColors.streak
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailFooter extends StatelessWidget {
  const _RailFooter();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: isDark ? 0.07 : 0.05),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: isDark ? AppColors.primaryBright : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Learn → Play → Master',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: isDark
                      ? AppColors.textSecondary
                      : AppLightColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
