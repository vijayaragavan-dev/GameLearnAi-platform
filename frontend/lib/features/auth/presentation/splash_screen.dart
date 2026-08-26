import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/session_controller.dart';
import '../../../shared/widgets/nova_companion.dart';

/// Boot sequence: brand reveal + session restoration.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    // Restore the session once the reveal has had a beat.
    Future<void>.delayed(const Duration(milliseconds: 650), () async {
      await ref.read(sessionProvider.notifier).restore();
      if (!mounted) return;
      final phase = ref.read(sessionProvider).phase;
      switch (phase) {
        case SessionPhase.authenticated:
          context.go(Routes.home);
        case SessionPhase.unauthenticated:
          context.go(Routes.onboarding);
        case SessionPhase.restoring:
          // Still restoring (offline probe); router redirect handles it.
          break;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sessionProvider); // react to phase changes
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppGradientsExt.backgroundDeep,
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = Curves.easeOutCubic.transform(_controller.value);
              return Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.9 + 0.1 * t,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const NovaCompanion(size: 110, mood: NovaMood.idle),
                      const SizedBox(height: 30),
                      const Text(
                        'GAMELEARN',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 8,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppGradientsExt.cyan.createShader(bounds),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            fontFamily: AppTypography.displayFamily,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 42),
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.primaryBright.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Local gradient extension to avoid importing the whole style file here.
abstract final class AppGradientsExt {
  static const LinearGradient backgroundDeep = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF101A38), AppColors.background],
  );

  static const LinearGradient cyan = LinearGradient(
    colors: [AppColors.secondary, AppColors.primary],
  );
}
