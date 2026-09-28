import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/audio/audio_manager.dart' show Sfx;
import '../../../../core/error/user_facing_error.dart';
import '../../../../core/models/content_models.dart';
import '../../../../core/models/tutor_models.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/nova_companion.dart';

/// LESSON-001 training room. Content is rendered verbatim from the backend.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.topicId});

  final String topicId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  late Future<Lesson> _future;
  bool _hintExpanded = false;
  bool _hintLoading = false;
  String? _hintText;
  String? _hintError;

  @override
  void initState() {
    super.initState();
    _future = ref.read(contentRepoProvider).lesson(widget.topicId);
  }

  void _retry() => setState(() {
    _future = ref.read(contentRepoProvider).lesson(widget.topicId);
  });

  Future<void> _askNovaHint(Lesson lesson) async {
    if (_hintLoading) return;
    if (_hintText != null && _hintExpanded) {
      setState(() => _hintExpanded = !_hintExpanded);
      return;
    }
    if (_hintText != null) {
      setState(() => _hintExpanded = true);
      return;
    }
    setState(() {
      _hintLoading = true;
      _hintError = null;
      _hintExpanded = true;
    });
    ref.read(audioManagerProvider).play(Sfx.buttonTap);
    try {
      final response = await ref
          .read(intelligenceRepoProvider)
          .askTutor(
            TutorRequest(
              question:
                  'Explain "${lesson.title}" in simple terms with a quick example.',
              topicId: widget.topicId,
            ),
          );
      if (!mounted) return;
      setState(() {
        _hintText = response.answer;
        _hintLoading = false;
      });
      ref.read(hapticsProvider).tap();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hintError = describeError(e).message;
        _hintLoading = false;
      });
    }
  }

  void _openTutor() {
    ref.read(audioManagerProvider).play(Sfx.buttonTap);
    // Keep the lesson's topic context, like the inline hint path and the
    // world/tutor entries elsewhere — a bare tutor route loses it.
    context.push(Routes.tutorWithContext(topicId: widget.topicId));
  }

  @override
  Widget build(BuildContext context) {
    // Lesson is a reading surface — every text/surface token resolves per
    // theme so the module stays legible in the light theme (previously
    // hardcoded dark tokens rendered near-white text on white).
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: FutureBuilder<Lesson>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done && !snap.hasData) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 14),
                  Text(
                    'Preparing training...',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppLightColors.textSecondary,
                    ),
                  ),
                ],
              ),
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
          final lesson = snap.data!;
          final paragraphs = lesson.content
              .split('\n')
              .map((p) => p.trim())
              .toList();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(
                  lesson.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  IconButton(
                    tooltip: 'Ask Nova',
                    onPressed: _openTutor,
                    icon: const Icon(Icons.auto_awesome_rounded),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                sliver: SliverList.list(
                  children: [
                    Row(
                      children: [
                        DifficultyBadge(difficulty: lesson.difficulty),
                        const SizedBox(width: 10),
                        if (lesson.summary.isNotEmpty)
                          Expanded(
                            child: Text(
                              'TRAINING MODULE',
                              style: TextStyle(
                                fontSize: 10.5,
                                letterSpacing: 2.2,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.textTertiary
                                    : AppLightColors.textTertiary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Nova inline hint (Screen-AI-002).
                    GestureDetector(
                      onTap: () => _askNovaHint(lesson),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.32),
                          ),
                        ),
                        child: Row(
                          children: [
                            const NovaCompanion(size: 28, mood: NovaMood.idle),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _hintExpanded && _hintText != null
                                    ? 'Nova explains'
                                    : 'Need a hint? Ask Nova',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                            if (_hintLoading)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              Icon(
                                _hintExpanded
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                size: 18,
                                color: AppColors.secondary,
                              ),
                            const SizedBox(width: 6),
                            GameChip(label: 'FULL CHAT', icon: Icons.forum_rounded, color: AppColors.secondary, onTap: _openTutor),
                          ],
                        ),
                      ),
                    ),
                    if (_hintExpanded) ...[
                      const SizedBox(height: 10),
                      if (_hintLoading)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceElevated
                                : AppLightColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.border
                                  : AppLightColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Nova is thinking...',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark
                                      ? AppColors.textSecondary
                                      : AppLightColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_hintError != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            _hintError!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.error,
                            ),
                          ),
                        )
                      else if (_hintText != null)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceElevated
                                : AppLightColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.secondary.withValues(alpha: 0.25)
                                  : AppColors.secondary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            _hintText!,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.55,
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppLightColors.textPrimary,
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 18),
                    if (paragraphs.every((p) => p.isEmpty))
                      const EmptyMiniCard(
                        text: 'This training module has no content yet.',
                      )
                    else
                      for (final p in paragraphs) ...[
                        if (p.isNotEmpty)
                          SelectableText(
                            p,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.7,
                              color:
                                  (isDark
                                          ? AppColors.textPrimary
                                          : AppLightColors.textPrimary)
                                      .withValues(alpha: 0.92),
                            ),
                          ),
                        if (p.isNotEmpty) const SizedBox(height: 14),
                      ],
                    if (lesson.summary.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 15,
                                  color: AppColors.secondary,
                                ),
                                SizedBox(width: 7),
                                Text(
                                  'KEY TAKEAWAYS',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              lesson.summary,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.55,
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppLightColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.paddingOf(context).bottom + 14,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceElevated
              : AppLightColors.surface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.border : AppLightColors.border,
            ),
          ),
        ),
        child: PrimaryGameButton(
          label: 'Take the challenge',
          icon: Icons.sports_esports_rounded,
          onTap: () => context.push(Routes.quiz(widget.topicId)),
        ),
      ),
    );
  }
}
