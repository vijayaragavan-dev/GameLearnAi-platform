import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_typography.dart';
import 'badges.dart';
import 'nova_companion.dart';
import 'achievement_icon.dart';

/// Particle confetti burst overlay. Pure CustomPainter - no dependency.
class ConfettiEffect extends StatefulWidget {
  const ConfettiEffect({
    super.key,
    this.particleCount = 90,
    this.duration = AppMotion.celebration,
    this.colors = const [
      AppColors.xp,
      AppColors.primaryBright,
      AppColors.secondary,
      AppColors.success,
      AppColors.streak,
    ],
  });

  final int particleCount;
  final Duration duration;
  final List<Color> colors;

  @override
  State<ConfettiEffect> createState() => _ConfettiEffectState();
}

class _ConfettiEffectState extends State<ConfettiEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _particles = _generate();
    _controller.forward();
  }

  List<_Particle> _generate() {
    final rng = math.Random(42);
    return List.generate(widget.particleCount, (_) {
      final angle = rng.nextDouble() * math.pi * 2;
      final speed = 0.35 + rng.nextDouble() * 0.65;
      return _Particle(
        dx: math.cos(angle) * speed,
        dy: math.sin(angle) * speed - 0.35, // bias upward
        size: 3 + rng.nextDouble() * 5,
        color: widget.colors[rng.nextInt(widget.colors.length)],
        spin: (rng.nextDouble() - 0.5) * 12,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            t: Curves.easeOutCubic.transform(_controller.value),
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.dx,
    required this.dy,
    required this.size,
    required this.color,
    required this.spin,
  });

  final double dx;
  final double dy;
  final double size;
  final Color color;
  final double spin;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.particles, required this.t});

  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    for (final p in particles) {
      final gravity = 2.4 * t * t;
      final pos =
          center +
          Offset(
            p.dx * size.width * 0.55 * t,
            p.dy * size.height * 0.6 * t + gravity * size.height * 0.25,
          );
      final opacity = (1 - t).clamp(0.0, 1.0);
      if (opacity <= 0.01) continue;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 1.7,
        ),
        Paint()..color = p.color.withValues(alpha: opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.t != t;
}

/// Floating "+N XP" chip that rises and fades.
class XpGainAnimation extends StatefulWidget {
  const XpGainAnimation({super.key, required this.amount});

  final int amount;

  @override
  State<XpGainAnimation> createState() => _XpGainAnimationState();
}

class _XpGainAnimationState extends State<XpGainAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.celebration,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final rise = Curves.easeOutCubic.transform(t);
          final fade = t < 0.7 ? 1.0 : 1 - ((t - 0.7) / 0.3);
          final scale = t < 0.18 ? Curves.elasticOut.transform(t / 0.18) : 1.0;
          return Opacity(
            opacity: fade.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -70 * rise),
              child: Transform.scale(
                scale: scale.clamp(0.0, 10.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB45309), AppColors.xp],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.xp.withValues(alpha: 0.6),
                        blurRadius: 22,
                      ),
                    ],
                  ),
                  child: Text(
                    '+${widget.amount} XP',
                    style: const TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// EPIC-tier full-screen level up sequence: energy builds -> burst -> reveal.
class LevelUpOverlay extends StatefulWidget {
  const LevelUpOverlay({
    super.key,
    required this.newLevel,
    required this.onContinue,
  });

  final int newLevel;
  final VoidCallback onContinue;

  static Future<void> show(BuildContext context, {required int newLevel}) =>
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: AppColors.scrim,
        builder: (_) => Dialog.fullscreen(
          backgroundColor: Colors.transparent,
          child: LevelUpOverlay(
            newLevel: newLevel,
            onContinue: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
        ),
      );

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.celebration,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ConfettiEffect(),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = Curves.easeOutCubic.transform(_controller.value);
              return Center(
                child: Transform.scale(
                  scale: 0.8 + 0.2 * t,
                  child: Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const NovaCompanion(
                          size: 92,
                          mood: NovaMood.celebrating,
                        ),
                        const SizedBox(height: 26),
                        Text(
                          'LEVEL UP',
                          style: TextStyle(
                            fontFamily: AppTypography.displayFamily,
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 6,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: AppColors.primary.withValues(alpha: 0.9),
                                blurRadius: 40,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        LevelBadge(level: widget.newLevel, size: 88),
                        const SizedBox(height: 30),
                        const Text(
                          'Your power grows.',
                          style: TextStyle(
                            fontFamily: AppTypography.bodyFamily,
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 36),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 38,
                              vertical: 16,
                            ),
                          ),
                          onPressed: widget.onContinue,
                          child: const Text('CONTINUE'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// EPIC-tier achievement unlock reveal.
class AchievementUnlockOverlay extends StatelessWidget {
  const AchievementUnlockOverlay({
    super.key,
    required this.name,
    required this.description,
    required this.iconKey,
    this.xpReward,
    required this.onContinue,
  });

  final String name;
  final String description;
  final String iconKey;
  final int? xpReward; // only when supplied by the backend payload
  final VoidCallback onContinue;

  static Future<void> show(
    BuildContext context, {
    required String name,
    required String description,
    required String iconKey,
    int? xpReward,
  }) => showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: AppColors.scrim,
    builder: (_) => AchievementUnlockOverlay(
      name: name,
      description: description,
      iconKey: iconKey,
      xpReward: xpReward,
      onContinue: () => Navigator.of(context, rootNavigator: true).pop(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Positioned.fill(child: ConfettiEffect()),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.xp.withValues(alpha: 0.16),
                  AppColors.surfaceElevated,
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.xp.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.xp.withValues(alpha: 0.25),
                  blurRadius: 60,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ACHIEVEMENT UNLOCKED',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: AppColors.xp,
                  ),
                ),
                const SizedBox(height: 24),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.4, end: 1),
                  duration: AppMotion.celebration,
                  curve: AppMotion.spring,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: AchievementIcon(
                    iconKey: iconKey,
                    unlocked: true,
                    size: 96,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTypography.displayFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTypography.bodyFamily,
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (xpReward != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        size: 17,
                        color: AppColors.xp,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+$xpReward XP',
                        style: const TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.xp,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 28),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.xp),
                  onPressed: onContinue,
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(color: AppColors.textOnColor),
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
