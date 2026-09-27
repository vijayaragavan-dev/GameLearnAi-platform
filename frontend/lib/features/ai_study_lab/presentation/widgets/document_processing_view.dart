import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_backgrounds.dart';
import '../../domain/study_document.dart';
import 'document_card.dart';

/// Premium processing visual: the document being transformed into a
/// learning experience ("Knowledge Core" motif, restrained).
///
/// Deliberately lightweight: one static glow, one document glyph, one
/// indeterminate ring. No controllers, no continuous custom animation —
/// nothing to dispose, nothing to drain. Honors the ambient Nova mood
/// system only through static composition.
class DocumentProcessingView extends StatelessWidget {
  const DocumentProcessingView({
    super.key,
    this.title = 'Preparing your document…',
    this.message =
        'Your document will become available here when processing is complete.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: '$title In progress',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const GlowOrb(
                  color: AppColors.secondary,
                  size: 120,
                  opacity: 0.12,
                ),
                const DocumentTypeIcon(
                  fileType: DocumentFileType.pdf,
                  size: 56,
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? AppColors.surfaceElevated
                          : AppLightColors.surface,
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTypography.h3(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: AppTypography.bodySecondary(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
