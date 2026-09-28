import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/audio/audio_manager.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../data/study_lab_repository.dart';
import '../../domain/study_document.dart';
import '../../domain/study_upload.dart';
import 'document_card.dart';
import 'document_processing_view.dart';

/// A locally selected file awaiting upload. Presentation-layer only:
/// tests may inject one via [UploadSheet.initialPreview] to exercise
/// preview/remove; production selection always flows through the
/// platform picker in [_UploadSheetState._selectFile].
class SelectedStudyFile {
  const SelectedStudyFile({required this.name, required this.fileType});

  final String name;
  final DocumentFileType fileType;
}

/// Deterministic upload state machine (RAG-FE-2).
///
/// Honest boundary: selection + validation are fully real (platform
/// picker, product-owned rules). The network step calls
/// [StudyLabRepository.uploadDocument]; with no service connected the
/// repository returns [UploadUnavailable] and the sheet shows it —
/// NEVER a fabricated success. `success` exists only for the future
/// real implementation (close sheet → open workspace handoff).
enum _SheetPhase { idle, selecting, ready, uploading, unavailable, failure }

/// Document-upload sheet. Must be shown with `showModalBottomSheet`.
class UploadSheet extends ConsumerStatefulWidget {
  const UploadSheet({super.key, this.initialPreview});

  /// Test/fixture-only preselected file. Production call sites omit it.
  final SelectedStudyFile? initialPreview;

  @override
  ConsumerState<UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends ConsumerState<UploadSheet> {
  _SheetPhase _phase = _SheetPhase.idle;
  PickedStudyFile? _selected;
  String? _error;

  @override
  void initState() {
    super.initState();
    final preview = widget.initialPreview;
    if (preview != null) {
      _selected = PickedStudyFile(name: preview.name, sizeBytes: null);
      _phase = _SheetPhase.ready;
    }
  }

  void _tap() {
    ref.read(audioManagerProvider).play(Sfx.buttonTap);
    ref.read(hapticsProvider).tap();
  }

  /// Real platform file selection (PDF-first). Cancellation returns to
  /// idle; unreadable results stay idle with an honest message.
  Future<void> _selectFile() async {
    _tap();
    setState(() {
      _phase = _SheetPhase.selecting;
      _error = null;
    });
    try {
      final platformFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (!mounted) return;
      if (platformFile == null) {
        // User cancelled the picker — back to idle, nothing selected.
        setState(() => _phase = _SheetPhase.idle);
        return;
      }
      final validation = validatePickedFile(
        name: platformFile.name,
        sizeBytes: platformFile.lengthSync(),
      );
      if (!validation.valid) {
        setState(() {
          _selected = null;
          _phase = _SheetPhase.idle;
          _error = validation.errorMessage;
        });
        return;
      }
      Uint8List bytes;
      try {
        bytes = await platformFile.readAsBytes();
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _selected = null;
          _phase = _SheetPhase.idle;
          _error = "We couldn't read this file. Please choose another PDF.";
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _selected = PickedStudyFile(
          name: platformFile.name,
          sizeBytes: platformFile.lengthSync(),
          bytes: bytes,
        );
        _phase = _SheetPhase.ready;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selected = null;
        _phase = _SheetPhase.idle;
        _error = "We couldn't read this file. Please choose another PDF.";
      });
    }
  }

  void _removeSelection() {
    _tap();
    setState(() {
      _selected = null;
      _error = null;
      _phase = _SheetPhase.idle;
    });
  }

  /// Explicit upload attempt. The repository decides: unavailable (no
  /// service), failure (genuine error), or — only from a real backend
  /// implementation — success with the authoritative document.
  Future<void> _upload() async {
    final selected = _selected;
    if (selected == null) return;
    _tap();
    setState(() => _phase = _SheetPhase.uploading);
    UploadResult result;
    try {
      result = await ref.read(studyLabRepoProvider).uploadDocument(selected);
    } catch (_) {
      if (!mounted) return;
      setState(() => _phase = _SheetPhase.failure);
      return;
    }
    if (!mounted) return;
    switch (result) {
      case UploadSuccess(:final document):
        Navigator.of(context).pop();
        context.push(Routes.aiStudyDocument(document.id));
      case UploadUnavailable(:final message):
        setState(() {
          _phase = _SheetPhase.unavailable;
          _error = message;
        });
      case UploadFailure(:final message):
        setState(() {
          _phase = _SheetPhase.failure;
          _error = message;
        });
    }
  }

  void _cancel() {
    _tap();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
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
              switch (_phase) {
                _SheetPhase.uploading => const DocumentProcessingView(
                  title: 'Uploading your document…',
                  message: 'Connecting to the service…',
                ),
                _SheetPhase.unavailable => _TerminalState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Service unavailable',
                  message:
                      _error ??
                      'Document services are currently unavailable.',
                  primaryLabel: 'Try Again',
                  onPrimary: _upload,
                  onCancel: _cancel,
                ),
                _SheetPhase.failure => _TerminalState(
                  icon: Icons.error_outline_rounded,
                  title: "We couldn't upload this document.",
                  message: _error ?? 'Something went wrong. Please try again.',
                  primaryLabel: 'Try Again',
                  onPrimary: _upload,
                  onCancel: _cancel,
                ),
                _SheetPhase.idle ||
                _SheetPhase.selecting ||
                _SheetPhase.ready => _SelectionBody(
                  phase: _phase,
                  selected: _selected,
                  error: _error,
                  onSelect: _selectFile,
                  onRemove: _removeSelection,
                  onUpload: _upload,
                  onCancel: _cancel,
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

/// Idle/selected content: PDF-first messaging, preview, CTAs.
class _SelectionBody extends StatelessWidget {
  const _SelectionBody({
    required this.phase,
    required this.selected,
    required this.error,
    required this.onSelect,
    required this.onRemove,
    required this.onUpload,
    required this.onCancel,
  });

  final _SheetPhase phase;
  final PickedStudyFile? selected;
  final String? error;
  final VoidCallback onSelect;
  final VoidCallback onRemove;
  final VoidCallback onUpload;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ready = phase == _SheetPhase.ready && selected != null;
    final sizeLabel = selected == null
        ? null
        : formatStudyFileSize(selected!.sizeBytes);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Upload your study material',
          style: AppTypography.h2(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Turn your PDF into an interactive AI learning experience.',
          style: AppTypography.bodySecondary(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            const _SupportedTypeChip(label: 'PDF', recommended: true),
            Text(
              'More formats coming',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark
                    ? AppColors.textTertiary
                    : AppLightColors.textTertiary,
              ),
            ),
          ],
        ),
        if (selected != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                DocumentTypeIcon(
                  fileType: selected!.inferredType,
                  size: 36,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        semanticsLabel: 'Selected file ${selected!.name}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (sizeLabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          sizeLabel,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? AppColors.textSecondary
                                : AppLightColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onSelect,
                  child: const Text('Replace'),
                ),
                IconButton(
                  tooltip: 'Remove selected document',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
          ),
        ],
        if (error != null &&
            (phase == _SheetPhase.idle ||
                phase == _SheetPhase.selecting)) ...[
          const SizedBox(height: 10),
          Text(
            error!,
            style: const TextStyle(fontSize: 12.5, color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 14),
        if (ready)
          PrimaryGameButton(
            label: 'Upload document',
            icon: Icons.cloud_upload_rounded,
            onTap: onUpload,
          )
        else
          PrimaryGameButton(
            label: 'Select PDF',
            icon: Icons.folder_open_rounded,
            onTap: onSelect,
          ),
        const SizedBox(height: 10),
        SecondaryGameButton(
          label: 'Cancel',
          icon: Icons.close_rounded,
          onTap: onCancel,
        ),
      ],
    );
  }
}

/// Terminal service state (unavailable/failure) with retry + cancel.
class _TerminalState extends StatelessWidget {
  const _TerminalState({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onCancel,
  });

  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 6),
        Icon(
          icon,
          size: 44,
          color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary,
          semanticLabel: title,
        ),
        const SizedBox(height: 12),
        Text(title, style: AppTypography.h3(context), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(
          message,
          style: AppTypography.bodySecondary(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        PrimaryGameButton(
          label: primaryLabel,
          icon: Icons.refresh_rounded,
          onTap: onPrimary,
        ),
        const SizedBox(height: 10),
        SecondaryGameButton(
          label: 'Cancel',
          icon: Icons.close_rounded,
          onTap: onCancel,
        ),
      ],
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
