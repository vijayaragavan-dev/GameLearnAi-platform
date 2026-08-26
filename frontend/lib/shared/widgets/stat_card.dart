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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: tint.withValues(alpha: 0.35)),
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
          style: const TextStyle(
            fontFamily: AppTypography.displayFamily,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (sub != null)
          Text(
            sub!,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    ),
  );
}
