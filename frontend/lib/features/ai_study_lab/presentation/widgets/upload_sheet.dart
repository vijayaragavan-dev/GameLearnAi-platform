import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/audio_manager.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../domain/study_document.dart';
import 'document_card.dart';

/// A locally selected file awaiting upload. Presentation-layer only:
/// the FE-1 sheet never transmits bytes anywhere. Tests may inject one
/// via [UploadSheet.initialPreview] to exercise preview/remove; production
/// passes nothing (no picker/service exists yet).
class SelectedStudyFile {
  const SelectedStudyFile({required this.name, required this.fileType});

  final String name;
  final DocumentFileType fileType;
}

/// Document-upload entry sheet (RAG-FE-1 presentation layer only).
///
/// Honest boundary: PDF-first messaging, supported-type presentation,
/// selected-file preview with remove, Cancel dismissal. There is NO
/// upload service yet, so the primary CTA stays disabled with a
/// "Coming next" explanation and NO bytes ever leave the device.
/// Must be shown with `showModalBottomSheet`.
class UploadSheet extends ConsumerStatefulWidget {
  const UploadSheet({super.key, this.initialPreview});

  /// Test/fixture-only preselected file. Production call sites omit it.
  final SelectedStudyFile? initialPreview;

  @override
  ConsumerState<UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends ConsumerState<UploadSheet> {
  SelectedStudyFile? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialPreview;
  }

  void _removeSelection() {
    ref.read(audioManagerProvider).play(Sfx.buttonTap);
    ref.read(hapticsProvider).tap();
    setState(() => _selected = null);
  }

  void _cancel() {
    ref.read(audioManagerProvider).play(Sfx.buttonTap);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _selected;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppGutters.pagePadding(context),
          12,
          AppGutters.pagePadding(context),
          MediaQuery.paddingOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  color: isDark ? AppColors.border : AppLightColors.border,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Upload study material',
              style: AppTypography.h2(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'PDF files are supported for the AI Study Lab.',
              style: AppTypography.bodySecondary(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: const [
                _SupportedTypeChip(label: 'PDF', recommended: true),
                _SupportedTypeChip(label: 'DOCX'),
                _SupportedTypeChip(label: 'TXT'),
              ],
            ),
            if (selected != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceElevated
                      : AppLightColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isDark ? AppColors.border : AppLightColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    DocumentTypeIcon(fileType: selected.fileType, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selected.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove selected file',
                      onPressed: _removeSelection,
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            const EmptyMiniCard(
              text: 'Uploads open with the Study Lab service — '
                  'your files stay on this device for now.',
            ),
            const SizedBox(height: 14),
            PrimaryGameButton(
              label: 'Upload document',
              icon: Icons.cloud_upload_rounded,
              // No service yet: honestly disabled with an explanation below.
              onTap: null,
              busy: false,
            ),
            const SizedBox(height: 6),
            Text(
              'Coming next — file transfer activates with the service.',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark
                    ? AppColors.textTertiary
                    : AppLightColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            SecondaryGameButton(
              label: 'Cancel',
              icon: Icons.close_rounded,
              onTap: _cancel,
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportedTypeChip extends StatelessWidget {
  const _SupportedTypeChip({required this.label, this.recommended = false});

  final String label;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        color: recommended
            ? AppColors.secondary.withValues(alpha: isDark ? 0.14 : 0.10)
            : Colors.transparent,
        border: Border.all(
          color: recommended
              ? AppColors.secondary.withValues(alpha: 0.45)
              : (isDark ? AppColors.border : AppLightColors.border),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (recommended)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(
                Icons.star_rounded,
                size: 13,
                color: AppColors.secondary,
              ),
            ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: recommended
                  ? AppColors.secondary
                  : (isDark
                        ? AppColors.textSecondary
                        : AppLightColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
