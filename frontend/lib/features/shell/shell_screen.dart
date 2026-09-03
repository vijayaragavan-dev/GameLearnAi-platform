import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_styles.dart';

/// Responsive navigation scaffold.
///
/// - compact (<600): bottom navigation bar (touch-friendly, 66dp)
/// - medium+ (>=600): NavigationRail (80dp) + constrained content
/// - wide (>=1200): extended rail variant for higher density reading
///
/// Routes remain identical; only chrome adapts. No game logic changed.
class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _tabs = [
    ('/home', Icons.dashboard_outlined, Icons.dashboard_rounded, 'Command'),
    ('/subjects', Icons.public_outlined, Icons.public_rounded, 'Worlds'),
    ('/progress', Icons.insights_outlined, Icons.insights_rounded, 'Stats'),
    ('/profile', Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
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
    final shouldConstrain = MediaQuery.sizeOf(context).width >= AppBreakpoints.medium;

    if (!isRail) {
      return Scaffold(
        extendBody: true,
        body: child,
        bottomNavigationBar: _BottomBar(index: index),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _Rail(
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
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              // Center-constrain shell content on tablet/desktop for
              // higher density without stretching. Mobile remains full.
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

class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.index});

  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ShellScreen._tabs;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.border : AppLightColors.border,
          ),
        ),
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
                    child: AnimatedScale(
                      scale: selected ? 1.12 : 1.0,
                      duration: AppMotion.fast,
                      curve: AppMotion.spring,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
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
                          const SizedBox(height: 4),
                          Text(
                            tab.$4.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
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
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.index,
    required this.extended,
    required this.onTap,
  });

  final int index;
  final bool extended;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final tabs = ShellScreen._tabs;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return NavigationRail(
      extended: extended,
      minWidth: extended ? AppLayout.railExtendedWidth : AppLayout.railWidth,
      minExtendedWidth: AppLayout.railExtendedWidth,
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedIndex: index,
      onDestinationSelected: onTap,
      labelType:
          extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
      useIndicator: true,
      indicatorColor: AppColors.primary
          .withValues(alpha: isDark ? 0.18 : 0.10),
      leading: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.brand,
                boxShadow: AppShadows.glow(AppColors.primary, alpha: 0.3),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            if (!extended) const SizedBox(height: 8),
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
              ),
            if (extended)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'GameLearn AI',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isDark
                        ? AppColors.textPrimary
                        : AppLightColors.textPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
      trailing: extended
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border:
                      Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 14,
                      color: AppColors.primaryBright,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Learn → Play → Master',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      destinations: [
        for (final tab in tabs)
          NavigationRailDestination(
            icon: Icon(tab.$2),
            selectedIcon: Icon(tab.$3),
            label: Text(tab.$4),
            padding: const EdgeInsets.symmetric(vertical: 4),
          ),
      ],
    );
  }
}
