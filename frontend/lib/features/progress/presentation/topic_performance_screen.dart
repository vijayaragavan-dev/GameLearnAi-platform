import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/error/user_facing_error.dart';
import '../../../core/models/content_models.dart';
import '../../../core/models/dashboard_models.dart';
import '../../../core/models/gamification_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/badges.dart';
import '../../../shared/widgets/recommendation_card.dart' show DifficultyPill;
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_button.dart';
import '../../../shared/widgets/game_card.dart';

/// TOPIC-001 + PROG-002 + DASH mastery row for one topic.
class TopicPerformanceScreen extends ConsumerStatefulWidget {
  const TopicPerformanceScreen({super.key, required this.topicId});

  final String topicId;

  @override
  ConsumerState<TopicPerformanceScreen> createState() =>
      _TopicPerformanceScreenState();
}

class _TopicPerformanceScreenState
    extends ConsumerState<TopicPerformanceScreen> {
  late Future<(Topic, TopicProgress?, RecentTopicMastery?)> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      final content = ref.read(contentRepoProvider);
      final gam = ref.read(gamificationRepoProvider);
      final intel = ref.read(intelligenceRepoProvider);
      _future = () async {
        final topic = await content.topic(widget.topicId);
        TopicProgress? progress;
        try {
          progress = await gam.progressForTopic(widget.topicId);
        } on NotFoundException {
          progress = null; // no progress record yet - valid state
        }
        final dashboard = await intel.dashboard();
        final masteryRow = dashboard.mastery.recentTopics.firstWhere(
          (t) => t.topicId == widget.topicId,
          orElse: () => RecentTopicMastery.empty,
        );
        return (
          topic,
          progress,
          masteryRow.topicName.isEmpty ? null : masteryRow,
        );
      }();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TOPIC PERFORMANCE')),
      body: FutureBuilder(
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
              onRetry: _reload,
            );
          }
          final (topic, progress, mastery) = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                topic.name,
                style: const TextStyle(
                  fontFamily: AppTypography.displayFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  DifficultyBadge(difficulty: topic.difficulty),
                  const SizedBox(width: 8),
                  Text(
                    topic.subjectName,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (mastery != null)
                GameCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MASTERY (AI-ASSESSED)',
                        style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                value: (mastery.masteryScore / 100).clamp(0, 1),
                                minHeight: 8,
                                color: AppColors.primaryBright,
                                backgroundColor: AppColors.surfaceHigh,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            Formatters.percent(mastery.masteryScore),
                            style: const TextStyle(
                              fontFamily: AppTypography.displayFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          LevelChip(label: mastery.masteryLevel),
                          DifficultyPill(difficulty: mastery.currentDifficulty),
                          TrendChip(trend: mastery.trend),
                        ],
                      ),
                    ],
                  ),
                )
              else
                const EmptyMiniCard(
                  text: 'No mastery data yet - take the challenge first.',
                ),

              const SizedBox(height: 14),
              GameCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MISSION STATUS',
                      style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      progress?.status.toLowerCase().replaceAll('_', ' ') ??
                          'not started',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                    if (progress?.lastActivityAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Last activity ${Formatters.shortDate(progress!.lastActivityAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),
              PrimaryGameButton(
                label: 'Open training',
                icon: Icons.menu_book_rounded,
                onTap: () => context.push(Routes.lesson(widget.topicId)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class LevelChip extends StatelessWidget {
  const LevelChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: AppColors.success,
      ),
    ),
  );
}

class TrendChip extends StatelessWidget {
  const TrendChip({super.key, required this.trend});

  final String trend;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(color: AppColors.borderStrong),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          switch (trend) {
            'IMPROVING' => Icons.north_east_rounded,
            'DECLINING' => Icons.priority_high_rounded,
            _ => Icons.drag_handle_rounded,
          },
          size: 11,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          trend.isEmpty ? 'NEW' : trend.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}
