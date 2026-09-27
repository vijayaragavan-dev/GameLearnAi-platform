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
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../data/study_lab_repository.dart';
import '../domain/study_document.dart';
import 'widgets/document_card.dart';
import 'widgets/upload_sheet.dart';

/// AI STUDY LAB — the learner's personal document workspace entry.
///
/// RAG-FE-1 UI foundation: hero, quick actions, and the document
/// library. Documents come from [StudyLabRepository] (honestly empty
/// until the MlRag service lands); every action without an
/// implementation behind it renders locked and explains honestly
/// instead of navigating anywhere fake.
class AiStudyLabScreen extends ConsumerStatefulWidget {
  const AiStudyLabScreen({super.key});

  @override
  ConsumerState<AiStudyLabScreen> createState() => _AiStudyLabScreenState();
}

class _AiStudyLabScreenState extends ConsumerState<AiStudyLabScreen> {
  late Future<List<StudyDocument>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(studyLabRepoProvider).documents();
  }

  void _retry() => setState(() {
    _future = ref.read(studyLabRepoProvider).documents();
  });

  void _tap() {
    ref.read(audioManagerProvider).play(Sfx.buttonTap);
    ref.read(hapticsProvider).tap();
  }

  Future<void> _openUpload() async {
    _tap();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const UploadSheet(),
      ),
    );
  }

  /// Honest locked-action dialog: names what is missing, offers the
  /// real Upload entry — never a fake destination.
  Future<void> _lockedAction(String title, String message) {
    _tap();
    return showPremiumDialog<void>(
      context: context,
      builder: (dialogContext) => CinematicDialog(
        accent: AppColors.secondary,
        title: Text(title),
        content: Text(message),
        actions: [
          PremiumDialogActions(
            primaryLabel: 'Upload document',
            onPrimary: () {
              Navigator.of(dialogContext).pop();
              _openUpload();
            },
            secondaryLabel: 'Not now',
            onSecondary: () => Navigator.of(dialogContext).pop(),
            accent: AppColors.secondary,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('AI STUDY LAB')),
      body: Stack(
        children: [
          const Positioned.fill(child: AtmosphericBackground()),
          if (isDark)
            const Positioned(
              top: -60,
              right: -40,
              child: GlowOrb(
                color: AppColors.secondary,
                size: 260,
                opacity: 0.10,
              ),
            ),
          // Full-screen route outside the shell: no command dock renders
          // here, so only the system SafeArea inset + content spacing
          // apply (same convention as arena/character/realm routes).
          SafeArea(
            top: true,
            bottom: true,
            child: FutureBuilder<List<StudyDocument>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done &&
                    !snap.hasData) {
                  return const CinematicLoading(
                    message: 'Preparing your study lab...',
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
                final docs = snap.data ?? const <StudyDocument>[];
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _LabHero(onUpload: _openUpload),
                          const SizedBox(height: 18),
                          const NeonSectionHeader(
                            icon: Icons.bolt_rounded,
                            title: 'Quick actions',
                            subtitle: 'Start from your documents',
                            accent: AppColors.secondary,
                          ),
                          const SizedBox(height: 12),
                          _QuickActions(
                            onUpload: _openUpload,
                            onLocked: _lockedAction,
                          ),
                          const SizedBox(height: 18),
                          const NeonSectionHeader(
                            icon: Icons.folder_rounded,
                            title: 'Recent documents',
                            subtitle: 'Pick up where you left off',
                            accent: AppColors.primary,
                          ),
                          const SizedBox(height: 12),
                          if (docs.isEmpty)
                            EmptyState(
                              icon: Icons.science_rounded,
                              title: 'Your Study Lab is empty',
                              message:
                                  'Upload a document and turn it into an '
                                  'interactive learning experience.',
                              action: PrimaryGameButton(
                                label: 'Upload document',
                                icon: Icons.cloud_upload_rounded,
                                expanded: false,
                                onTap: _openUpload,
                              ),
                            )
                          else
                            AdaptiveGrid(
                              compact: 1,
                              medium: 2,
                              expanded: 3,
                              wide: 3,
                              spacing: 12,
                              children: [
                                for (final doc in docs)
                                  DocumentCard(
                                    document: doc,
                                    // Processing documents are not openable
                                    // yet; failed ones offer an honest
                                    // reload instead of a fake retry.
                                    onOpen: doc.isProcessing
                                        ? null
                                        : () {
                                            _tap();
                                            context.push(
                                              Routes.aiStudyDocument(doc.id),
                                            );
                                          },
                                    onRetry: doc.status ==
                                            DocumentStatus.failed
                                        ? _retry
                                        : null,
                                  ),
                              ],
                            ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Nova-led hero: knowledge-core identity in Nova cyan, one primary CTA.
class _LabHero extends StatelessWidget {
  const _LabHero({required this.onUpload});

  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return CinematicHero(
      accent: AppColors.secondary,
      badge: 'Nova AI',
      badgeIcon: Icons.psychology_rounded,
      scene: ScenePalette.indigo,
      sceneSeed: 7,
      title: Text(
        'AI STUDY LAB',
        style: AppTypography.hero(context, size: 26),
      ),
      subtitle: Row(
        children: [
          const NovaCompanion(size: 38, mood: NovaMood.encouraging),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Turn your documents into an interactive learning experience.',
              style: AppTypography.bodySecondary(context),
            ),
          ),
        ],
      ),
      tagline: 'UPLOAD • STUDY\nASK • MASTER',
    );
  }
}

/// Four quick actions. Only Upload is live (opens the upload sheet);
/// the rest render locked until a document library exists, each
/// explaining honestly on tap instead of navigating.
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onUpload, required this.onLocked});

  final VoidCallback onUpload;
  final Future<void> Function(String title, String message) onLocked;

  @override
  Widget build(BuildContext context) {
    return AdaptiveGrid(
      compact: 2,
      medium: 4,
      expanded: 4,
      wide: 4,
      spacing: 12,
      children: [
        _QuickTile(
          icon: Icons.cloud_upload_rounded,
          label: 'Upload',
          available: true,
          onTap: onUpload,
        ),
        _QuickTile(
          icon: Icons.psychology_rounded,
          label: 'Ask Nova',
          available: false,
          onTap: () => onLocked(
            'Ask Nova — Coming next',
            'Upload a document first — Nova will answer from your '
                'material once the Study Lab service arrives.',
          ),
        ),
        _QuickTile(
          icon: Icons.fitness_center_rounded,
          label: 'Practice',
          available: false,
          onTap: () => onLocked(
            'Practice — Coming next',
            'Practice drills generate from your documents once the '
                'Study Lab service arrives. Nothing is faked meanwhile.',
          ),
        ),
        _QuickTile(
          icon: Icons.play_arrow_rounded,
          label: 'Continue',
          available: false,
          onTap: () => onLocked(
            'Nothing to continue yet',
            'Your library is empty — upload a document to start '
                'your first study session.',
          ),
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.available,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lockedColor = isDark ? AppColors.locked : AppLightColors.locked;
    return Pressable(
      onTap: onTap,
      semanticsLabel: available
          ? '$label. Opens upload.'
          : '$label unavailable. Activate for details.',
      child: GameCard(
        variant: available
            ? GameCardVariant.standard
            : GameCardVariant.locked,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    : Colors.transparent,
                border: Border.all(
                  color: available
                      ? AppColors.secondary.withValues(alpha: 0.40)
                      : lockedColor.withValues(alpha: 0.40),
                ),
              ),
              child: Icon(
                available ? icon : Icons.lock_outline_rounded,
                size: 22,
                color: available ? AppColors.secondary : lockedColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
