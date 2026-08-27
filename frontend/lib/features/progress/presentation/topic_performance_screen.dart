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
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/game_button.dart';
import '../../../shared/widgets/game_card.dart';
import '../../../shared/widgets/recommendation_card.dart' show DifficultyPill;

/// TOPIC-001 + PROG-002 + DASH mastery row + recent activity sparkline for one topic.
class TopicPerformanceScreen extends ConsumerStatefulWidget {
  const TopicPerformanceScreen({super.key, required this.topicId});

  final String topicId;

  @override
  ConsumerState<TopicPerformanceScreen> createState() =>
      _TopicPerformanceScreenState();
}

class _TopicPerformanceScreenState
    extends ConsumerState<TopicPerformanceScreen> {
  late Future<(Topic, TopicProgress?, RecentTopicMastery?, List<RecentQuizRun>)>
  _future;

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
          progress = null;
        }
        final dashboard = await intel.dashboard();
        final masteryRow = dashboard.mastery.recentTopics.firstWhere(
          (t) => t.topicId == widget.topicId,
          orElse: () => RecentTopicMastery.empty,
        );
        // Filter recent attempts for this topic to build honest trajectory.
        final topicQuizzes = dashboard.recentActivity.quizzes
            .where((q) => q.topicId == widget.topicId)
            .toList(growable: false);
        return (
          topic,
          progress,
          masteryRow.topicName.isEmpty ? null : masteryRow,
          topicQuizzes,
        );
      }();
    });
  }

  Color _tintForLevel(String level) => switch (level) {
    'MASTERED' => AppColors.xp,
    'PROFICIENT' => AppColors.success,
    'DEVELOPING' => AppColors.warning,
    'BEGINNER' => AppColors.error,
    _ => AppColors.secondaryDeep,
  };

  IconData _iconForLevel(String level) => switch (level) {
    'MASTERED' => Icons.emoji_events_rounded,
    'PROFICIENT' => Icons.verified_rounded,
    'DEVELOPING' => Icons.trending_up_rounded,
    'BEGINNER' => Icons.flag_rounded,
    _ => Icons.circle_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TOPIC PERFORMANCE')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done && !snap.hasData) {
            return ListView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: const [SkeletonList(itemCount: 3, itemHeight: 100)],
            );
          }
          if (snap.hasError) {
            final err = describeError(snap.error!);
            return ErrorState(
              title: err.title,
              message: err.message,
              onRetry: _reload,
            );
          }
          final (topic, progress, mastery, topicQuizzes) = snap.data!;
          final tint = mastery != null
              ? _tintForLevel(mastery.masteryLevel)
              : AppColors.locked;
          final isWeak = mastery?.masteryLevel == 'BEGINNER';
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isCompact = width < 600;
              final horizontalPad = isCompact ? 16.0 : 20.0;
              final contentMax = width >= 1024 ? 720.0 : double.infinity;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMax),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPad,
                      8,
                      horizontalPad,
                      32,
                    ),
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
                          Expanded(
                            child: Text(
                              topic.subjectName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (mastery != null)
                        GameCard(
                          borderColor: isWeak
                              ? tint.withValues(alpha: 0.45)
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: tint.withValues(alpha: 0.15),
                                      border: Border.all(
                                        color: tint.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Icon(
                                      _iconForLevel(mastery.masteryLevel),
                                      size: 18,
                                      color: tint,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'MASTERY (AI-ASSESSED)',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    Formatters.percent(mastery.masteryScore),
                                    style: TextStyle(
                                      fontFamily: AppTypography.displayFamily,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: tint,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: LinearProgressIndicator(
                                  value: (mastery.masteryScore / 100).clamp(
                                    0,
                                    1,
                                  ),
                                  minHeight: 8,
                                  color: tint,
                                  backgroundColor: AppColors.surfaceHigh,
                                  semanticsLabel:
                                      '${topic.name} mastery ${Formatters.percent(mastery.masteryScore)}',
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _LevelChip(
                                    label: mastery.masteryLevel,
                                    tint: tint,
                                  ),
                                  DifficultyPill(
                                    difficulty: mastery.currentDifficulty,
                                  ),
                                  _TrendChip(trend: mastery.trend),
                                ],
                              ),
                              if (mastery.lastAssessedAt != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Updated ${Formatters.shortDate(mastery.lastAssessedAt)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                              if (isWeak) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: tint.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                    border: Border.all(
                                      color: tint.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lightbulb_rounded,
                                        size: 16,
                                        color: tint,
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'This skill needs practice — your next mission can strengthen it.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            height: 1.35,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      else
                        const EmptyMiniCard(
                          text:
                              'No mastery data yet — take the challenge first.',
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
                              progress?.status.toLowerCase().replaceAll(
                                    '_',
                                    ' ',
                                  ) ??
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

                      const SizedBox(height: 18),
                      const Text(
                        'PERFORMANCE TRAJECTORY',
                        style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (topicQuizzes.length >= 2)
                        GameCard(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 72,
                                width: double.infinity,
                                child: _TopicSparkline(
                                  scores: topicQuizzes.reversed
                                      .map((q) => q.score)
                                      .toList(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    Formatters.percent(topicQuizzes.last.score),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                  const Text(
                                    'most recent →',
                                    style: TextStyle(
                                      fontSize: 10,
                                      letterSpacing: 1,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                  Text(
                                    Formatters.percent(
                                      topicQuizzes.first.score,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${topicQuizzes.length} recent attempts shown · scores from backend',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (topicQuizzes.length == 1)
                        const EmptyMiniCard(
                          text:
                              'One attempt recorded — complete one more mission on this topic to reveal your skill trend.',
                        )
                      else
                        const EmptyMiniCard(
                          text:
                              'Complete a few missions on this topic to reveal your skill trend. Performance history will appear after you have at least 2 attempts.',
                        ),

                      const SizedBox(height: 22),
                      PrimaryGameButton(
                        label: 'Open training',
                        icon: Icons.menu_book_rounded,
                        onTap: () =>
                            context.push(Routes.lesson(widget.topicId)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      color: tint.withValues(alpha: 0.14),
      border: Border.all(color: tint.withValues(alpha: 0.5)),
    ),
    child: Text(
      label.isEmpty ? 'Unknown' : label,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: tint,
      ),
    ),
  );
}

class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.trend});

  final String trend;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (trend) {
      'IMPROVING' => (Icons.north_east_rounded, 'Improving', AppColors.success),
      'STABLE' => (Icons.drag_handle_rounded, 'Stable', AppColors.secondary),
      'DECLINING' => (
        Icons.south_east_rounded,
        'Needs attention',
        AppColors.warning,
      ),
      'INSUFFICIENT_DATA' => (
        Icons.bubble_chart_rounded,
        'New',
        AppColors.textTertiary,
      ),
      _ => (
        Icons.circle_outlined,
        trend.isEmpty ? 'New' : trend,
        AppColors.textTertiary,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
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
}

class _TopicSparkline extends StatelessWidget {
  const _TopicSparkline({required this.scores});

  final List<double> scores;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _SparklinePainter(scores: scores, color: AppColors.primaryBright),
    size: Size.infinite,
  );
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.scores, required this.color});

  final List<double> scores;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.length < 2 || size.width <= 0 || size.height <= 0) return;
    final stepX = size.width / (scores.length - 1);
    final path = Path();
    final points = <Offset>[];
    for (var i = 0; i < scores.length; i++) {
      final x = stepX * i;
      final normalized = (scores[i] / 100).clamp(0.0, 1.0);
      final y = size.height - normalized * size.height;
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prev = points[i - 1];
        final c1 = Offset(prev.dx + stepX * 0.3, prev.dy);
        final c2 = Offset(x - stepX * 0.3, y);
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, x, y);
      }
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.18), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fill, fillPaint);
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
    final dot = Paint()..color = color;
    final border = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (final p in points) {
      canvas.drawCircle(p, 3, border);
      canvas.drawCircle(p, 2.1, dot);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.scores != scores || old.color != color;
}
