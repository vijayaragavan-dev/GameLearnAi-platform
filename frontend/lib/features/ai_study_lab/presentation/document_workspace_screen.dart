import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/audio/audio_manager.dart';
import '../../../core/error/user_facing_error.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_backgrounds.dart';
import '../../../shared/widgets/cinematic_scenery.dart';
import '../../../shared/widgets/cinematic_surfaces.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_button.dart';
import '../../../shared/widgets/game_card.dart';
import '../../../shared/widgets/nova_companion.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../data/study_lab_repository.dart';
import '../domain/study_document.dart';
import 'widgets/document_action_card.dart';
import 'widgets/document_card.dart';

/// DOCUMENT WORKSPACE — one document's study hub (RAG-FE-1 foundation).
///
/// Resolves [documentId] against [StudyLabRepository] BY ID and renders
/// the header, overview, Nova entry, and the four learning actions.
/// Every action without an implementation behind it renders locked and
/// explains honestly on tap. Unknown ids render an honest unavailable
/// state — never a substituted or fabricated document.
class DocumentWorkspaceScreen extends ConsumerStatefulWidget {
  const DocumentWorkspaceScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DocumentWorkspaceScreen> createState() =>
      _DocumentWorkspaceScreenState();
}

class _DocumentWorkspaceScreenState
    extends ConsumerState<DocumentWorkspaceScreen> {
  late Future<StudyDocument?> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(studyLabRepoProvider).documentById(widget.documentId);
  }

  void _retry() => setState(() {
    _future = ref.read(studyLabRepoProvider).documentById(widget.documentId);
  });

  void _tap() {
    ref.read(audioManagerProvider).play(Sfx.buttonTap);
    ref.read(hapticsProvider).tap();
  }

  /// Honest locked-action dialog with an optional real alternative.
  Future<void> _unavailable(
    String title,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _tap();
    return showPremiumDialog<void>(
      context: context,
      builder: (dialogContext) => CinematicDialog(
        accent: AppColors.secondary,
        title: Text(title),
        content: Text(message),
        actions: [
          if (actionLabel != null && onAction != null)
            PremiumDialogActions(
              primaryLabel: actionLabel,
              onPrimary: () {
                Navigator.of(dialogContext).pop();
                onAction();
              },
              secondaryLabel: 'Not now',
              onSecondary: () => Navigator.of(dialogContext).pop(),
              accent: AppColors.secondary,
            )
          else
            PremiumDialogActions(
              primaryLabel: 'Got it',
              onPrimary: () => Navigator.of(dialogContext).pop(),
              accent: AppColors.secondary,
            ),
        ],
      ),
    );
  }

  void _openNova() {
    _tap();
    context.push(Routes.tutor);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('DOCUMENT WORKSPACE')),
      body: Stack(
        children: [
          const Positioned.fill(child: AtmosphericBackground()),
          if (isDark)
            const Positioned(
              top: -60,
              right: -40,
              child: GlowOrb(
                color: AppColors.secondary,
                size: 240,
                opacity: 0.10,
              ),
            ),
          // Full-screen route outside the shell (same convention as the
          // Study Lab, arena, and realm routes): SafeArea only.
          SafeArea(
            top: true,
            bottom: true,
            child: FutureBuilder<StudyDocument?>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done &&
                    !snap.hasData) {
                  return const CinematicLoading(
                    message: 'Opening workspace...',
                  );
                }
                if (snap.hasError) {
                  final err = describeError(snap.error!);
                  return ErrorState(
                    title: err.title,
                    message: err.message,
                    onRetry: _retry,
                  );
                }
                final doc = snap.data;
                if (doc == null) {
                  return EmptyState(
                    icon: Icons.description_rounded,
                    title: 'Document unavailable',
                    message:
                        'This document is not available right now. It may '
                        'still be processing, or the reference is no longer '
                        'valid — nothing was lost.',
                    action: SecondaryGameButton(
                      label: 'Back to Study Lab',
                      icon: Icons.science_rounded,
                      expanded: false,
                      onTap: () => context.go(Routes.aiStudyLab),
                    ),
                  );
                }
                return _WorkspaceBody(
                  document: doc,
                  onRetry: _retry,
                  onOpenNova: _openNova,
                  onLocked: _unavailable,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceBody extends StatelessWidget {
  const _WorkspaceBody({
    required this.document,
    required this.onRetry,
    required this.onOpenNova,
    required this.onLocked,
  });

  final StudyDocument document;
  final VoidCallback onRetry;
  final VoidCallback onOpenNova;
  final Future<void> Function(
    String title,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  })
  onLocked;

  @override
  Widget build(BuildContext context) {
    final twoColumn = AppBreakpoints.isExpanded(context);
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ResponsiveCenter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppGutters.pagePadding(context),
            8,
            AppGutters.pagePadding(context),
            24,
          ),
          child: twoColumn
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _OverviewColumn(
                        document: document,
                        onRetry: onRetry,
                        onOpenNova: onOpenNova,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionsColumn(
                        document: document,
                        onLocked: onLocked,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OverviewColumn(
                      document: document,
                      onRetry: onRetry,
                      onOpenNova: onOpenNova,
                    ),
                    const SizedBox(height: 18),
                    _ActionsColumn(document: document, onLocked: onLocked),
                    const SizedBox(height: 8),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Header card, overview facts, and the Nova entry.
class _OverviewColumn extends StatelessWidget {
  const _OverviewColumn({
    required this.document,
    required this.onRetry,
    required this.onOpenNova,
  });

  final StudyDocument document;
  final VoidCallback onRetry;
  final VoidCallback onOpenNova;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doc = document;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GameCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DocumentTypeIcon(fileType: doc.fileType, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTypography.displayFamily,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${doc.fileType.extensionLabel} document',
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
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DocumentStatusBadge(status: doc.status),
                  DocumentTopicChip(topicCount: doc.topicCount),
                ],
              ),
              if (doc.progressFraction != null) ...[
                const SizedBox(height: 10),
                DocumentProgressBar(fraction: doc.progressFraction!),
              ],
              if (doc.isProcessing) ...[
                const SizedBox(height: 12),
                const EmptyMiniCard(
                  text: 'Indexing your document — topics and actions '
                      'unlock here when it is ready.',
                ),
              ],
              if (doc.status == DocumentStatus.failed) ...[
                const SizedBox(height: 12),
                EmptyMiniCard(
                  text: doc.failureMessage ??
                      'Processing hit a snag. Your original file is '
                          'untouched — please try again later.',
                  action: GameChip(
                    label: 'RELOAD',
                    icon: Icons.refresh_rounded,
                    color: AppColors.secondary,
                    onTap: onRetry,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        // ── NOVA ENTRY ──
        // Nova remains the ONE assistant: this panel links the real
        // tutor today; document-aware answers arrive with the service.
        GameCard(
          child: Row(
            children: [
              const NovaCompanion(size: 44, mood: NovaMood.idle),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ask Nova about this document',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Document-aware answers arrive with the Study Lab '
                      'service — Nova helps with everything else today.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondary
                            : AppLightColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    PrimaryGameButton(
                      label: 'Open Nova',
                      icon: Icons.psychology_rounded,
                      onTap: onOpenNova,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The four learning actions. FE-1: all locked with distinct honest
/// labels; document-aware Nova additionally offers the real tutor.
class _ActionsColumn extends StatelessWidget {
  const _ActionsColumn({required this.document, required this.onLocked});

  final StudyDocument document;
  final Future<void> Function(
    String title,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  })
  onLocked;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NeonSectionHeader(
          icon: Icons.grid_view_rounded,
          title: 'Learn with this document',
          subtitle: 'Four ways in, once ready',
          accent: AppColors.secondary,
        ),
        const SizedBox(height: 12),
        WorkspaceActionCard(
          action: StudyLabAction.study,
          available: false,
          onTap: () => onLocked(
            'Study mode — Coming next',
            'Guided lessons generate from your document once the '
                'Study Lab service arrives.',
          ),
          unavailableLabel: 'Coming next',
        ),
        const SizedBox(height: 12),
        WorkspaceActionCard(
          action: StudyLabAction.askNova,
          available: false,
          onTap: () => onLocked(
            'Document answers — Coming next',
            'Nova will answer from this document once the Study Lab '
                'service arrives.',
            actionLabel: 'Open Nova now',
            onAction: () => context.push(Routes.tutor),
          ),
          unavailableLabel: 'Coming next',
        ),
        const SizedBox(height: 12),
        WorkspaceActionCard(
          action: StudyLabAction.practice,
          available: false,
          onTap: () => onLocked(
            'No practice generated yet',
            'Practice drills appear here once your document is '
                'processed. Nothing is faked meanwhile.',
          ),
          unavailableLabel: 'No practice generated yet',
        ),
        const SizedBox(height: 12),
        WorkspaceActionCard(
          action: StudyLabAction.play,
          available: false,
          onTap: () => onLocked(
            'Play — Coming next',
            'Document-powered games unlock with the Study Lab service.',
          ),
          unavailableLabel: 'Coming next',
        ),
      ],
    );
  }
}
