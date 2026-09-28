import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/audio/audio_manager.dart' show MusicContext, Sfx;
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_backgrounds.dart';
import '../../../../shared/widgets/cinematic_scenery.dart';
import '../../../../shared/widgets/cinematic_surfaces.dart';
import '../../../../shared/widgets/nova_companion.dart';
import '../providers/assessment_provider.dart';

/// Assessment introduction — Nova-centered Knowledge Scan experience.
///
/// Sets expectations honestly (no pass/fail). Scan algorithm, question flow,
/// persistence and routing are untouched; only the presentation is cinematic.
class AssessmentIntroScreen extends ConsumerStatefulWidget {
  const AssessmentIntroScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  ConsumerState<AssessmentIntroScreen> createState() =>
      _AssessmentIntroScreenState();
}

class _AssessmentIntroScreenState extends ConsumerState<AssessmentIntroScreen> {
  Future<void> _start() async {
    ref.read(audioManagerProvider).playContext(MusicContext.quiz);
    await ref.read(assessmentProvider(widget.subjectId).notifier).load();
    if (!mounted) return;
    context.push(Routes.assessmentRun(widget.subjectId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider(widget.subjectId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      // Title-less bar: the back affordance stays, but the "KNOWLEDGE
      // SCAN" title lives once in the cinematic hero below — stacking
      // both reads as a duplicate.
      appBar: AppBar(),
      body: Stack(
        children: [
          const AtmosphericBackground(),
          if (isDark)
            const Positioned(
              top: -60,
              right: -40,
              child: GlowOrb(
                color: AppColors.secondary,
                size: 240,
                opacity: 0.18,
              ),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Let\'s find your starting point',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppLightColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ── Nova scan hero ──
                      CinematicHero(
                        accent: AppColors.secondary,
                        badge: 'Nova · Calibration',
                        badgeIcon: Icons.radar_rounded,
                        scene: ScenePalette.abyss,
                        sceneSeed: 21,
                        title: Text(
                          'KNOWLEDGE SCAN',
                          style: TextStyle(
                            fontFamily: AppTypography.displayFamily,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: isDark
                                ? AppColors.textPrimary
                                : AppLightColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Small questions today, bigger progress tomorrow.',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? AppColors.textSecondary
                                : AppLightColors.textSecondary,
                          ),
                        ),
                        tagline: 'LEARN\nADAPT\nIMPROVE\nREPEAT',
                        // Nova's real character art leads the scan (the
                        // reference's robot guide); the radar badge below
                        // carries the calibration state.
                        leading: const NovaAvatar(size: 88),
                      ),
                      const SizedBox(height: 16),
                      // ── Nova explanation panel ──
                      GlassPanel(
                        glowColor: AppColors.secondary,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                NovaCompanion(
                                  size: 30,
                                  mood: NovaMood.speaking,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'NOVA',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.55,
                                  color: isDark
                                      ? AppColors.textPrimary
                                      : AppLightColors.textPrimary,
                                ),
                                children: const [
                                  TextSpan(
                                    text:
                                        'I\'ll ask a short set of questions across this world. '
                                        'This is ',
                                  ),
                                  TextSpan(
                                    text: 'NOT a test',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        ' — there is no pass or fail. Your answers calibrate your missions to the ',
                                  ),
                                  TextSpan(
                                    text: 'right difficulty.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryBright,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ── Benefit cards ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Expanded(
                            child: _ScanBenefit(
                              icon: Icons.shield_outlined,
                              title: 'No XP at stake',
                              body: 'Pure calibration to understand you',
                              accent: AppColors.secondary,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _ScanBenefit(
                              icon: Icons.speed_rounded,
                              title: 'Answer at your own pace',
                              body: 'Take your time. Think clearly.',
                              accent: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _ScanBenefit(
                              icon: Icons.track_changes_rounded,
                              title: 'One scan per world',
                              body: 'It sets your learning baseline.',
                              accent: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      if (state.error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          state.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      GlowCTA(
                        label: 'Begin scan',
                        icon: Icons.radar_rounded,
                        glowColor: AppColors.primary,
                        onPressed: () async {
                          ref
                              .read(audioManagerProvider)
                              .play(Sfx.buttonConfirm);
                          await _start();
                        },
                        semanticsLabel:
                            'Begin knowledge scan for this world',
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          '“Know yourself. Learn better.”',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? AppColors.textTertiary
                                : AppLightColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanBenefit extends StatelessWidget {
  const _ScanBenefit({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassPanel(
      glowColor: accent,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      borderRadius: AppRadius.md,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: isDark ? 0.14 : 0.10),
              border: Border.all(color: accent.withValues(alpha: 0.45)),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimary
                  : AppLightColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: isDark
                  ? AppColors.textSecondary
                  : AppLightColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
