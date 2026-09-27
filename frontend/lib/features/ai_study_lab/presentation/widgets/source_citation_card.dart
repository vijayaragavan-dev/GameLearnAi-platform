import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_styles.dart';
import '../../domain/study_tutor.dart';

/// Source citation card: the visible proof of document grounding.
///
/// Renders ONLY fields present on [source] — document title, page,
/// section, snippet. Missing fields render nothing (never invented
/// placeholders like "Page 42"). Deliberately non-interactive: no
/// document viewer exists yet, so the card never pretends to open one.
class SourceCitationCard extends StatelessWidget {
  const SourceCitationCard({super.key, required this.source});

  final GroundedSource source;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final src = source;
    final hasPage = src.page != null;
    final title = src.documentTitle ?? 'Source document';
    return Semantics(
      label:
          'Source${hasPage ? ', page ${src.page}' : ''}'
          '${src.section != null ? ', ${src.section}' : ''}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceElevated.withValues(alpha: 0.7)
              : AppLightColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.secondary.withValues(
                  alpha: isDark ? 0.14 : 0.10,
                ),
              ),
              child: const Icon(
                Icons.description_rounded,
                size: 18,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (hasPage) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppRadius.pill,
                            ),
                            color: AppColors.secondary.withValues(
                              alpha: isDark ? 0.14 : 0.10,
                            ),
                          ),
                          child: Text(
                            'Page ${src.page}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (src.section != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      src.section!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? AppColors.textSecondary
                            : AppLightColors.textSecondary,
                      ),
                    ),
                  ],
                  if (src.snippet != null && src.snippet!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '“${src.snippet!}”',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: isDark
                            ? AppColors.textSecondary
                            : AppLightColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
