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
      NovaMood.idle,
      Icons.rocket_launch_rounded,
      'Welcome to GameLearnAI',
      'Learn concepts. Master challenges. Level up. Your personal game-powered learning adventure starts here.',
    ),
    (
      NovaMood.encouraging,
      Icons.sports_esports_rounded,
      'Learn → Play → Master',
      'Every subject is a world. Every topic a mission. Play 14 distinct games to practice, not just memorize.',
    ),
    (
      NovaMood.thinking,
      Icons.auto_graph_rounded,
      'Adapts to You',
      'Our AI studies your performance and recommends what to learn next — never too easy, never unfair. Your mastery shapes the journey.',
    ),
    (
      NovaMood.celebrating,
      Icons.auto_awesome_rounded,
      'Level Up with Nova',
      'Earn XP, keep your streak, unlock achievements and characters. Nova celebrates every milestone by your side.',
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    try {
      context.go(Routes.login);
    } catch (_) {
      // No GoRouter in test harness — persistence is the important assertion.
    }
  }

  void _next() {
    ref.read(audioManagerProvider).play(Sfx.buttonTap);
    if (_page < _panels.length - 1) {
      _pageController.nextPage(
        duration: AppMotion.normal,
        curve: AppMotion.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _skip() async {
    ref.read(audioManagerProvider).play(Sfx.buttonTap);
    await _completeOnboarding();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Scaffold(
      body: Stack(
        children: [
          // Premium atmospheric background (A9) — subtle, theme-aware
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [const Color(0xFF0F172A), AppColors.background, AppColors.backgroundDeep]
                      : [AppLightColors.background, AppLightColors.backgroundElevated],
                ),
              ),
            ),
          ),
          if (isDark && !reduceMotion)
            Positioned(top: -40, right: -30, child: IgnorePointer(child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.primary.withValues(alpha: 0.12), Colors.transparent]))))),
          SafeArea(
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
                            Semantics(header: true, child: NovaCompanion(size: 120, mood: panel.$1)),
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
                          style: TextStyle(
                            fontFamily: AppTypography.displayFamily,
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: isDark ? AppColors.textPrimary : AppLightColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          panel.$4,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTypography.bodyFamily,
                            fontSize: 15,
                            height: 1.55,
                            color: isDark ? AppColors.textSecondary : AppLightColors.textSecondary,
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
                              : (isDark ? AppColors.surfaceHigh : AppLightColors.surfaceHigh),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      if (_page > 0)
                        Semantics(button: true, label: 'Go back', child: TextButton(
                          onPressed: () => _pageController.previousPage(
                            duration: AppMotion.normal,
                            curve: AppMotion.easeInOut,
                          ),
                          child: const Text('BACK'),
                        ))
                      else
                        Semantics(button: true, label: 'Skip onboarding', child: TextButton(onPressed: _skip, child: const Text('SKIP'))),
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
        ],
      ),
    );
  }
}
