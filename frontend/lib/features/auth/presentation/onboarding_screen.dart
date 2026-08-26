import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/audio/audio_manager.dart' show Sfx;
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/game_button.dart';
import '../../../shared/widgets/nova_companion.dart';

/// Three-panel introduction establishing the mental model:
/// Student = Player, Learning = Adventure, Nova = companion.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const _panels = [
    (
      NovaMood.encouraging,
      Icons.sports_esports_rounded,
      'Play your way to mastery',
      'Every subject is a world. Every topic a mission. Your learning becomes an adventure with XP, levels and achievements.',
    ),
    (
      NovaMood.thinking,
      Icons.auto_graph_rounded,
      'An AI Game Master',
      'The adaptive engine studies your performance and reshapes every mission to match your pace - never too easy, never unfair.',
    ),
    (
      NovaMood.celebrating,
      Icons.auto_awesome_rounded,
      'Meet NOVA',
      'Your holographic learning companion. Nova explains, encourages and celebrates every milestone by your side.',
    ),
  ];

  void _next() {
    ref.read(audioManagerProvider).play(Sfx.buttonTap);
    if (_page < _panels.length - 1) {
      _pageController.nextPage(
        duration: AppMotion.normal,
        curve: AppMotion.easeInOut,
      );
    } else {
      context.go(Routes.login);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _panels.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final panel = _panels[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        NovaCompanion(size: 120, mood: panel.$1),
                        const SizedBox(height: 44),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: AppColors.primary.withValues(alpha: 0.12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Icon(
                            panel.$2,
                            size: 30,
                            color: AppColors.primaryBright,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          panel.$3,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: AppTypography.displayFamily,
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          panel.$4,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: AppTypography.bodyFamily,
                            fontSize: 15,
                            height: 1.55,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_panels.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: AppMotion.fast,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: active
                              ? AppColors.primaryBright
                              : AppColors.surfaceHigh,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      if (_page > 0)
                        TextButton(
                          onPressed: () => _pageController.previousPage(
                            duration: AppMotion.normal,
                            curve: AppMotion.easeInOut,
                          ),
                          child: const Text('BACK'),
                        )
                      else
                        TextButton(
                          onPressed: () => context.go(Routes.login),
                          child: const Text('SKIP'),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PrimaryGameButton(
                          label: _page == _panels.length - 1
                              ? 'Enter the adventure'
                              : 'Next',
                          onTap: _next,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
