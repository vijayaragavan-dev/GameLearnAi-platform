import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/neo_brutalism.dart';
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
    final surface = isDark ? AppColors.surface : Colors.white;
    final borderIdle =
        isDark ? AppColors.border : NeoBrutalColors.ink;
    final inkPrimary =
        isDark ? AppColors.textPrimary : NeoBrutalColors.ink;
    final inkSecondary =
        isDark ? AppColors.textSecondary : NeoBrutalColors.ink;
    final (border, fill, glyphColor, textColor) = switch (state) {
      QuizOptionState.selected => (
        isDark ? AppColors.primary : NeoBrutalColors.ink,
        isDark
            ? AppColors.primary.withValues(alpha: 0.16)
            : NeoBrutalColors.cardYellow,
        isDark ? AppColors.primaryBright : NeoBrutalColors.xpYellow,
        inkPrimary,
      ),
      QuizOptionState.correct => (
        isDark ? AppColors.success : NeoBrutalColors.ink,
        isDark
            ? AppColors.success.withValues(alpha: 0.14)
            : NeoBrutalColors.cardGreen,
        isDark ? AppColors.success : NeoBrutalColors.growthGreen,
        inkPrimary,
      ),
      QuizOptionState.incorrect => (
        isDark ? AppColors.error : NeoBrutalColors.ink,
        isDark
            ? AppColors.error.withValues(alpha: 0.14)
            : NeoBrutalColors.cardPink,
        isDark ? AppColors.error : NeoBrutalColors.error,
        inkPrimary,
      ),
      QuizOptionState.idle => (
        borderIdle,
        surface,
        isDark ? AppColors.textTertiary : const Color(0xFFEFEDF3),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: border,
              width: isDark ? (state == QuizOptionState.idle ? 1.2 : 1.8) : 2.5,
            ),
            boxShadow: isDark
                ? (state == QuizOptionState.selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 18,
                        ),
                      ]
                    : null)
                : (state == QuizOptionState.idle
                    ? const [
                        BoxShadow(
                          color: NeoBrutalColors.ink,
                          offset: Offset(2.5, 2.5),
                          blurRadius: 0,
                        ),
                      ]
                    : const [
                        BoxShadow(
                          color: NeoBrutalColors.ink,
                          offset: Offset(3.5, 3.5),
                          blurRadius: 0,
                        ),
                      ]),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isDark ? glyphColor.withValues(alpha: 0.14) : glyphColor,
                  border: Border.all(
                    color: isDark ? glyphColor.withValues(alpha: 0.5) : NeoBrutalColors.ink,
                    width: isDark ? 1 : 1.5,
                  ),
                ),
                child: state == QuizOptionState.correct
                    ? const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Colors.white,
                      )
                    : state == QuizOptionState.incorrect
                    ? const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.white,
                      )
                    : Text(
                        String.fromCharCode(65 + index), // A, B, C...
                        style: TextStyle(
                          fontFamily: NeoBrutalTypography.displayFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? glyphColor : NeoBrutalColors.ink,
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
                        : FontWeight.w700,
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
