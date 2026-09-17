import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/audio/audio_manager.dart' show MusicContext, Sfx;
import '../../../../core/models/dashboard_models.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_backgrounds.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_surfaces.dart';
import '../../../../shared/widgets/nova_companion.dart';
import '../../../../shared/widgets/recommendation_card.dart'
    show DifficultyPill, PriorityPill;

/// PERFORMANCE -> AI ADAPTATION -> NEXT MISSION. Shows only approved
/// backend fields (activity type, difficulty, reason) - no internals.
class RecommendationScreen extends ConsumerStatefulWidget {
  const RecommendationScreen({super.key, required this.item});

  final RecommendationItem item;

  @override
  ConsumerState<RecommendationScreen> createState() =>
      _RecommendationScreenState();
}

class _RecommendationScreenState extends ConsumerState<RecommendationScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(audioManagerProvider).playContext(MusicContext.adventure);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final canStart = item.topicId != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEXT MISSION'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AtmosphericBackground()),
          SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          children: [
            const SizedBox(height: 6),
            const Center(
              child: NovaCompanion(size: 88, mood: NovaMood.encouraging),
            ),
            const SizedBox(height: 20),
            Text(
              'The Game Master has chosen',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.displayFamily,
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimary
                    : AppLightColors.textPrimary,
              ),
            ),

            if (item.topicName != null) ...[
              const SizedBox(height: 22),
              FeaturedSurface(
                accent: AppColors.primary,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      item.topicName!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimary
                            : AppLightColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (item.priority > 0) ...[
                          PriorityPill(priority: item.priority),
                          const SizedBox(width: 8),
                        ],
                        DifficultyPill(difficulty: item.recommendedDifficulty),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            _activityLabel(item.activityType),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            if (item.reason.trim().isNotEmpty) ...[
              // WHY - backend reason string, verbatim.
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'WHY THIS MISSION',
                    style: TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textTertiary
                          : AppLightColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              NovaMessageBubble(
                message: item.reason,
                mood: NovaMood.speaking,
                compact: true,
              ),
            ] else ...[
              const SizedBox(height: 18),
              Text(
                'No explanation was provided for this recommendation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark
                      ? AppColors.textTertiary
                      : AppLightColors.textTertiary,
                ),
              ),
            ],

            const SizedBox(height: 30),
            PrimaryGameButton(
              label: canStart ? 'Accept mission' : 'Back to command center',
              icon: canStart
                  ? Icons.play_arrow_rounded
                  : Icons.dashboard_rounded,
              onTap: () {
                ref.read(audioManagerProvider).play(Sfx.buttonConfirm);
                final topicId = item.topicId;
                if (topicId != null) {
                  final destination = item.activityType == 'CONTINUE_LESSON'
                      ? Routes.lesson(topicId)
                      : Routes.quiz(topicId);
                  context.pushReplacement(destination);
                } else {
                  context.go(Routes.home);
                }
              },
            ),
            const SizedBox(height: 12),
            SecondaryGameButton(
              label: 'Back to command center',
              icon: Icons.dashboard_rounded,
              color: AppColors.textSecondary,
              onTap: () => context.go(Routes.home),
            ),
          ],
        ),
          ),
        ],
      ),
    );
  }

  static String _activityLabel(String t) =>
      t.toLowerCase().replaceAll('_', ' ');
}
