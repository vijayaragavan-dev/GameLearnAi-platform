import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_typography.dart';

/// Premium settings primitives — one row language for the settings
/// experience (appearance / audio / account).
///
/// Replaces raw [SwitchListTile]/[ListTile]/[Slider]/[SegmentedButton]
/// compositions with theme-aware GameLearnAI rows. Behavior-neutral:
/// values and callbacks pass straight through; only the surface,
/// spacing (56dp rows), icon treatment and semantics are governed.
class PremiumSwitchRow extends StatelessWidget {
  const PremiumSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.accent = AppColors.secondary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      toggled: value,
      label: '$title. $subtitle',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onChanged(!value),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: isDark ? 0.14 : 0.10),
                    border:
                        Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Icon(icon, size: 17, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTypography.bodyFamily,
                          color: isDark
                              ? AppColors.textPrimary
                              : AppLightColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          fontFamily: AppTypography.bodyFamily,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppLightColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(value: value, onChanged: onChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium slider row — volume / intensity controls with a governed
/// label + value pill + themed slider.
class PremiumSliderRow extends StatelessWidget {
  const PremiumSliderRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.accent = AppColors.secondary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = enabled
        ? (isDark ? AppColors.textPrimary : AppLightColors.textPrimary)
        : (isDark ? AppColors.textTertiary : AppLightColors.textTertiary);
    return Semantics(
      label: '$title ${(value * 100).round()} percent',
      slider: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(
                        alpha: enabled ? (isDark ? 0.14 : 0.10) : 0.06),
                    border: Border.all(
                      color: accent.withValues(alpha: enabled ? 0.35 : 0.18),
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 17,
                    color: enabled
                        ? accent
                        : (isDark
                            ? AppColors.textTertiary
                            : AppLightColors.textTertiary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTypography.bodyFamily,
                          color: ink,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: AppTypography.bodyFamily,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppLightColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                        alpha: enabled ? 0.10 : 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: AppColors.primary.withValues(
                          alpha: enabled ? 0.28 : 0.14),
                    ),
                  ),
                  child: Text(
                    '${(value * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: enabled
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.textTertiary
                              : AppLightColors.textTertiary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              label: '${(value * 100).round()}%',
              activeColor: AppColors.primary,
              inactiveColor:
                  isDark ? AppColors.border : AppLightColors.border,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium segmented control — appearance/mode pickers with governed
/// density, radius and selected treatment.
class PremiumSegmentedControl<T> extends StatelessWidget {
  const PremiumSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
  });

  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: SegmentedButton<T>(
        segments: segments,
        selected: selected,
        onSelectionChanged: onSelectionChanged,
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontFamily: AppTypography.bodyFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium account/action row — sign-out, danger and navigation rows
/// with a single icon + text + chevron language.
class PremiumAccountRow extends StatelessWidget {
  const PremiumAccountRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
    this.semanticLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = danger ? AppColors.error : AppColors.secondary;
    final titleColor = danger
        ? AppColors.error
        : (isDark ? AppColors.textPrimary : AppLightColors.textPrimary);
    return Semantics(
      button: true,
      label: semanticLabel ?? '$title. $subtitle',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: isDark ? 0.14 : 0.10),
                    border:
                        Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Icon(icon, size: 17, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTypography.bodyFamily,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: AppTypography.bodyFamily,
                          color: isDark
                              ? AppColors.textTertiary
                              : AppLightColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark
                      ? AppColors.textTertiary
                      : AppLightColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
