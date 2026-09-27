import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../../../shared/widgets/pressable.dart';
import '../../domain/study_document.dart';

/// Workspace learning-action card.
///
/// Available actions navigate to real experiences; unavailable ones render
/// locked and explain honestly on tap instead of pretending to work.
/// Locked state uses the shared [GameCardVariant.locked] treatment plus a
/// lock glyph — state is never conveyed by color alone.
class WorkspaceActionCard extends StatelessWidget {
  const WorkspaceActionCard({
    super.key,
    required this.action,
    required this.available,
    required this.onTap,
    this.unavailableLabel = 'Coming next',
  });

  final StudyLabAction action;
  final bool available;
  final VoidCallback onTap;
  final String unavailableLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Pressable(
      onTap: onTap,
      semanticsLabel: available
          ? '${action.title}. ${action.blurb}'
          : '${action.title} unavailable. $unavailableLabel',
      child: GameCard(
        variant: available
            ? GameCardVariant.standard
            : GameCardVariant.locked,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: available
                    ? AppColors.secondary.withValues(
                        alpha: isDark ? 0.14 : 0.10,
                      )
                    : (isDark
                          ? AppColors.lockedSurface
                          : AppLightColors.lockedSurface),
                border: Border.all(
                  color: available
                      ? AppColors.secondary.withValues(alpha: 0.40)
                      : (isDark ? AppColors.border : AppLightColors.border),
                ),
              ),
              child: Icon(
                available ? action.icon : Icons.lock_rounded,
                size: 22,
                color: available
                    ? AppColors.secondary
                    : (isDark ? AppColors.locked : AppLightColors.locked),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    available ? action.blurb : unavailableLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondary
                          : AppLightColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              available
                  ? Icons.chevron_right_rounded
                  : Icons.lock_outline_rounded,
              size: 20,
              color: available
                  ? AppColors.primaryBright
                  : (isDark ? AppColors.locked : AppLightColors.locked),
            ),
          ],
        ),
      ),
    );
  }
}
