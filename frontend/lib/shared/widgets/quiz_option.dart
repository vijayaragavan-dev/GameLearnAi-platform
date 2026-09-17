import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_styles.dart';
import 'game_button.dart';

enum QuizOptionState { idle, selected, correct, incorrect }

/// Single answer choice with selection/correctness animation states.
class QuizOption extends StatelessWidget {
  const QuizOption({
    super.key,
    required this.label,
    required this.index,
    required this.state,
    required this.onTap,
  });

  final String label;
  final int index;
  final QuizOptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppLightColors.surface;
    final borderIdle =
        isDark ? AppColors.border : AppLightColors.borderStrong;
    final inkPrimary =
        isDark ? AppColors.textPrimary : AppLightColors.textPrimary;
    final inkSecondary =
        isDark ? AppColors.textSecondary : AppLightColors.textSecondary;
    final (border, fill, glyphColor, textColor) = switch (state) {
      QuizOptionState.selected => (
        AppColors.primary,
        AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.10),
        AppColors.primaryBright,
        inkPrimary,
      ),
      QuizOptionState.correct => (
        AppColors.success,
        AppColors.success.withValues(alpha: isDark ? 0.14 : 0.10),
        AppColors.success,
        inkPrimary,
      ),
      QuizOptionState.incorrect => (
        AppColors.error,
        AppColors.error.withValues(alpha: isDark ? 0.14 : 0.10),
        AppColors.error,
        inkPrimary,
      ),
      QuizOptionState.idle => (
        borderIdle,
        surface,
        isDark ? AppColors.textTertiary : AppLightColors.textTertiary,
        inkSecondary,
      ),
    };

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final isSelected = state == QuizOptionState.selected;

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          'Option ${String.fromCharCode(65 + index)}: $label, ${isSelected ? 'selected' : 'not selected'}',
      child: PressableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : AppMotion.fast,
          curve: AppMotion.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: border,
              width: state == QuizOptionState.idle ? 1.2 : 1.8,
            ),
            boxShadow: state == QuizOptionState.selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: glyphColor.withValues(alpha: 0.14),
                  border: Border.all(color: glyphColor.withValues(alpha: 0.5)),
                ),
                child: state == QuizOptionState.correct
                    ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: AppColors.success,
                      )
                    : state == QuizOptionState.incorrect
                    ? const Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: AppColors.error,
                      )
                    : Text(
                        String.fromCharCode(65 + index), // A, B, C...
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: glyphColor,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFamily,
                    fontSize: 14.5,
                    fontWeight: state == QuizOptionState.idle
                        ? FontWeight.w500
                        : FontWeight.w600,
                    height: 1.35,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Challenge progress dots for the question strip.
class QuestionProgress extends StatelessWidget {
  const QuestionProgress({
    super.key,
    required this.total,
    required this.current,
    required this.answeredFlags,
  });

  final int total;
  final int current; // 0-based
  final List<bool> answeredFlags;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: List.generate(total, (i) {
        final answered = i < answeredFlags.length && answeredFlags[i];
        final isCurrent = i == current;
        return Expanded(
          child: AnimatedContainer(
            duration: AppMotion.normal,
            curve: AppMotion.easeOut,
            height: 4,
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: answered
                  ? AppColors.success
                  : isCurrent
                  ? AppColors.primaryBright
                  : (isDark
                        ? AppColors.surfaceHigh
                        : AppLightColors.surfaceHigh),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: AppColors.primaryBright.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
