import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_styles.dart';

/// Compact stat tile used across streak/progress/profile.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.tint,
    this.sub,
  });

  final String label;
  final String value;
  final Color tint;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: tint.withValues(alpha: 0.35)),
        boxShadow: isDark ? null : AppShadows.elevated(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w800,
              color: tint,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTypography.displayFamily,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimary
                  : AppLightColors.textPrimary,
            ),
          ),
          if (sub != null)
            Text(
              sub!,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.textSecondary
                    : AppLightColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
