import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';

/// Bottom-navigation scaffold for the four authenticated tabs.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = _tabs.indexWhere((t) => location.startsWith(t.$1));
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.96),
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
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
                                  ? AppColors.primaryBright
                                  : AppColors.textTertiary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tab.$4.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                                color: selected
                                    ? AppColors.primaryBright
                                    : AppColors.textTertiary,
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
      ),
    );
  }
}
