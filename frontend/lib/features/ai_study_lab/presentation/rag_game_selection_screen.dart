import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/audio/audio_manager.dart';
import '../../../core/error/user_facing_error.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../shared/widgets/app_backgrounds.dart';
import '../../../shared/widgets/cinematic_surfaces.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_button.dart';
import '../../../shared/widgets/game_card.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../game_engine/models/game_models.dart';
import '../domain/rag_game_capability.dart';
import '../domain/study_document.dart';
import 'widgets/document_card.dart';

/// RAG GAME SELECTION (RAG-FE-5 foundation).
///
/// Lists all 14 engine games against the audited [RagGameCapability]
/// registry with honest availability: mappable games explain the
/// backend dependency ("Coming later"), structurally incompatible
/// games explain why ("Not available for this document"). Nothing
/// launches today — no fake Play buttons, no invented content. The
/// day backend RAG content lands, [RagGameCapability.playable] flips
/// per game with no UI restructuring.
class RagGameSelectionScreen extends ConsumerStatefulWidget {
  const RagGameSelectionScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<RagGameSelectionScreen> createState() =>
      _RagGameSelectionScreenState();
}

class _RagGameSelectionScreenState
    extends ConsumerState<RagGameSelectionScreen> {
  late Future<StudyDocument?> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(studyLabRepoProvider).documentById(widget.documentId);
  }

  void _tap() {
    ref.read(audioManagerProvider).play(Sfx.buttonTap);
    ref.read(hapticsProvider).tap();
  }

  /// Honest per-game explanation. Mappable games name the backend
  /// dependency; custom games name the structural reason.
  Future<void> _explain(RagGameCapability capability) {
    _tap();
    final mappable = capability.contentMappable;
    return showPremiumDialog<void>(
      context: context,
      builder: (dialogContext) => CinematicDialog(
        accent: AppColors.secondary,
        title: Text(
          mappable
              ? '${capability.gameType.displayName} — Coming later'
              : '${capability.gameType.displayName} unavailable',
        ),
        content: Text(
          mappable
              ? '${capability.reason} This game stays locked until then — '
                  'nothing is faked meanwhile.'
              : '${capability.reason}'
                  '${capability.specialRules == null ? '' : ' ${capability.specialRules}'}',
        ),
        actions: [
          PremiumDialogActions(
            primaryLabel: 'Got it',
            onPrimary: () => Navigator.of(dialogContext).pop(),
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
      appBar: AppBar(title: const Text('PLAY WITH DOCUMENT')),
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
          // Study Lab, workspace, tutor, and practice routes).
          SafeArea(
            top: true,
            bottom: true,
            child: FutureBuilder<StudyDocument?>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done &&
                    !snap.hasData) {
                  return const CinematicLoading(
                    message: 'Opening game selection...',
                  );
                }
                if (snap.hasError) {
                  final err = describeError(snap.error!);
                  return ErrorState(
                    title: err.title,
                    message: err.message,
                    onRetry: () => setState(() {
                      _future = ref
                          .read(studyLabRepoProvider)
                          .documentById(widget.documentId);
                    }),
                  );
                }
                final doc = snap.data;
                if (doc == null) {
                  return EmptyState(
                    icon: Icons.sports_esports_rounded,
                    title: 'Document unavailable',
                    message:
                        'Games need a document and none is available '
                        'right now.',
                    action: SecondaryGameButton(
                      label: 'Back to Study Lab',
                      icon: Icons.science_rounded,
                      expanded: false,
                      onTap: () => context.go(Routes.aiStudyLab),
                    ),
                  );
                }
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
                          GameCard(
                            child: Row(
                              children: [
                                DocumentTypeIcon(
                                  fileType: doc.fileType,
                                  size: 44,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 12,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'AI GENERATED PLAY',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: AppColors.secondary
                                    .withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Play with ${doc.title}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        semanticsLabel:
                                            'Play games with document ${doc.title}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          const NeonSectionHeader(
                            icon: Icons.sports_esports_rounded,
                            title: 'Compatible games',
                            subtitle: 'Honest availability per game',
                            accent: AppColors.secondary,
                          ),
                          const SizedBox(height: 12),
                          AdaptiveGrid(
                            compact: 1,
                            medium: 2,
                            expanded: 3,
                            wide: 3,
                            spacing: 12,
                            children: [
                              for (final definition in GameDefinition.all)
                                _RagGameCard(
                                  definition: definition,
                                  capability:
                                      RagGameCapabilityRegistry.forGame(
                                        definition.type,
                                      ),
                                  onTap: () => _explain(
                                    RagGameCapabilityRegistry.forGame(
                                      definition.type,
                                    ),
                                  ),
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

class _RagGameCard extends StatelessWidget {
  const _RagGameCard({
    required this.definition,
    required this.capability,
    required this.onTap,
  });

  final GameDefinition definition;
  final RagGameCapability capability;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mappable = capability.contentMappable;
    final pillColor = mappable
        ? AppColors.secondary
        : (isDark ? AppColors.locked : AppLightColors.locked);
    final pillLabel = mappable ? 'COMING LATER' : 'NOT AVAILABLE';
    return Pressable(
      onTap: onTap,
      semanticsLabel:
          '${definition.displayName} unavailable for this document. '
          '${capability.reason}',
      child: GameCard(
        variant: GameCardVariant.locked,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: pillColor.withValues(alpha: 0.40),
                ),
              ),
              child: Text(
                definition.icon,
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    definition.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    definition.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondary
                          : AppLightColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      color: pillColor.withValues(
                        alpha: isDark ? 0.12 : 0.08,
                      ),
                      border: Border.all(
                        color: pillColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      pillLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: pillColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.lock_outline_rounded,
              size: 20,
              color: isDark ? AppColors.locked : AppLightColors.locked,
            ),
          ],
        ),
      ),
    );
  }
}
