import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/audio/audio_manager.dart' show MusicContext, Sfx;
import '../../../../core/error/user_facing_error.dart';
import '../../../../core/models/content_models.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/badges.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';

/// TOPIC-001 mission briefing.
class TopicDetailScreen extends ConsumerStatefulWidget {
  const TopicDetailScreen({super.key, required this.topicId});

  final String topicId;

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  late Future<Topic> _future;

  @override
  void initState() {
    super.initState();
    ref.read(audioManagerProvider).playContext(MusicContext.adventure);
    _future = ref.read(contentRepoProvider).topic(widget.topicId);
    // Best-effort mastery lookup for context display (PROG-002).
  }

  void _retry() => setState(() {
    _future = ref.read(contentRepoProvider).topic(widget.topicId);
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Topic>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done && !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            final err = describeError(snap.error!);
            return ErrorState(
              title: err.title,
              message: err.message,
              onRetry: _retry,
            );
          }
          final topic = snap.data!;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 170,
                title: const Text('MISSION BRIEFING'),
                flexibleSpace: FlexibleSpaceBar(
                  background: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2A1B54), AppColors.background],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic.subjectName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10.5,
                              letterSpacing: 2.4,
                              fontWeight: FontWeight.w800,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            topic.name,
                            style: const TextStyle(
                              fontFamily: AppTypography.displayFamily,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DifficultyBadge(difficulty: topic.difficulty),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList.list(
                  children: [
                    GameCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'INTEL',
                            style: TextStyle(
                              fontSize: 10.5,
                              letterSpacing: 2.2,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            topic.description.isNotEmpty
                                ? topic.description
                                : 'Conquer this topic through training and challenges.',
                            style: const TextStyle(
                              fontSize: 14.5,
                              height: 1.55,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryGameButton(
                      label: 'Enter training',
                      icon: Icons.menu_book_rounded,
                      onTap: () => context.push(Routes.lesson(topic.id)),
                    ),
                    const SizedBox(height: 12),
                    SecondaryGameButton(
                      label: 'Take the challenge',
                      icon: Icons.sports_esports_rounded,
                      onTap: () {
                        ref.read(audioManagerProvider).play(Sfx.buttonConfirm);
                        context.push(Routes.quiz(topic.id));
                      },
                    ),
                    const SizedBox(height: 12),
                    // Game Arena entry - subject-aware hub
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.18), AppColors.surfaceElevated]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            ref.read(audioManagerProvider).play(Sfx.buttonConfirm);
                            context.push(
                              Routes.gameHub(topic.id, subjectId: topic.subjectId, subjectName: topic.subjectName),
                              extra: topic.name,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [AppColors.primaryDeep, AppColors.primary])), child: const Icon(Icons.sports_esports_rounded, color: Colors.white, size: 22)),
                                const SizedBox(width: 12),
                                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('GAME ARENA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.4)), SizedBox(height: 2), Text('Quiz Battle • Memory • Drag & Drop • Speed Run', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary))])),
                                const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
