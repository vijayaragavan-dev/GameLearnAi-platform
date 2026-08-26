import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/audio/audio_manager.dart' show MusicContext, Sfx;
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/nova_companion.dart';
import '../providers/assessment_provider.dart';

/// Assessment introduction - sets expectations honestly (no pass/fail).
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
    return Scaffold(
      appBar: AppBar(title: const Text('KNOWLEDGE SCAN')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NovaCompanion(size: 96, mood: NovaMood.thinking),
                        SizedBox(height: 28),
                        Text(
                          'Calibration scan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTypography.displayFamily,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 14),
                        NovaMessageBubble(
                          message:
                              'I will ask a short set of questions across this world. '
                              'This is NOT a test - there is no pass or fail. '
                              'Your answers calibrate your missions to the right difficulty.',
                          mood: NovaMood.speaking,
                          compact: true,
                        ),
                        SizedBox(height: 20),
                        _FactRow(
                          icon: Icons.shield_outlined,
                          text: 'No XP at stake - pure calibration',
                        ),
                        _FactRow(
                          icon: Icons.speed_rounded,
                          text: 'Answer at your own pace',
                        ),
                        _FactRow(
                          icon: Icons.lock_reset_rounded,
                          text: 'One scan per world - it sets your baseline',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    state.error!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: PrimaryGameButton(
                  label: 'Begin scan',
                  icon: Icons.radar_rounded,
                  busy: false,
                  onTap: () async {
                    ref.read(audioManagerProvider).play(Sfx.buttonConfirm);
                    await _start();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 16, color: AppColors.secondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}
