import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_typography.dart';

/// NOVA - the GameLearn AI companion. A holographic energy orb.
enum NovaMood { idle, thinking, speaking, celebrating, encouraging, error }

class NovaCompanion extends StatefulWidget {
  const NovaCompanion({super.key, this.size = 64, this.mood = NovaMood.idle});

  final double size;
  final NovaMood mood;

  @override
  State<NovaCompanion> createState() => _NovaCompanionState();
}

class _NovaCompanionState extends State<NovaCompanion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void didUpdateWidget(NovaCompanion old) {
    super.didUpdateWidget(old);
    // React to mood transitions with a tempo shift.
    switch (widget.mood) {
      case NovaMood.celebrating || NovaMood.speaking:
        _controller.duration = const Duration(milliseconds: 900);
      case NovaMood.thinking:
        _controller.duration = const Duration(milliseconds: 1400);
      case NovaMood.error:
        _controller.duration = const Duration(milliseconds: 1800);
      case NovaMood.idle || NovaMood.encouraging:
        _controller.duration = const Duration(milliseconds: 2600);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _tint => switch (widget.mood) {
    NovaMood.error => AppColors.error,
    NovaMood.celebrating => AppColors.xp,
    NovaMood.encouraging => AppColors.success,
    _ => AppColors.secondary,
  };

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _NovaPainter(
              progress: _controller.value,
              mood: widget.mood,
              tint: _tint,
            ),
          ),
        ),
      ),
    );
  }
}

class _NovaPainter extends CustomPainter {
  const _NovaPainter({
    required this.progress,
    required this.mood,
    required this.tint,
  });

  final double progress;
  final NovaMood mood;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.32;

    // Outer halo rings.
    for (var i = 0; i < 2; i++) {
      final phase = (progress + i * 0.5) % 1.0;
      final ringRadius =
          radius *
          (1.15 + phase * 0.55) *
          (mood == NovaMood.thinking ? 1.15 : 1);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.012 * (1 - phase)
        ..color = tint.withValues(alpha: (0.5 * (1 - phase)).clamp(0.0, 1.0));
      canvas.drawCircle(center, ringRadius, paint);
    }

    // Thinking orbit particles.
    if (mood == NovaMood.thinking) {
      final dotPaint = Paint()..color = AppColors.secondary;
      for (var i = 0; i < 3; i++) {
        final angle = progress * 2 * math.pi + i * 2.0944;
        final pos = Offset(
          center.dx + radius * 1.35 * math.cos(angle),
          center.dy + radius * 1.35 * math.sin(angle),
        );
        canvas.drawCircle(pos, size.width * 0.02, dotPaint);
      }
    }

    // Core.
    final pulse =
        1.0 +
        0.05 *
            math.sin(progress * 2 * math.pi * (mood == NovaMood.idle ? 1 : 2));
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.95),
          tint,
          tint.withValues(alpha: 0.25),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius * pulse, corePaint);

    // Inner highlight.
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(
      center.translate(-radius * 0.28, -radius * 0.32),
      radius * 0.16,
      highlight,
    );

    // Celebratory sparks.
    if (mood == NovaMood.celebrating) {
      final spark = Paint()..color = AppColors.xp;
      for (var i = 0; i < 6; i++) {
        final angle = i * 1.0472;
        final dist = radius * (1.5 + 0.3 * math.sin(progress * 6.283 + i));
        canvas.drawCircle(
          center.translate(dist * math.cos(angle), dist * math.sin(angle)),
          size.width * 0.018,
          spark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_NovaPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.mood != mood ||
      oldDelegate.tint != tint;
}

/// Speech bubble anchored to a small Nova orb.
class NovaMessageBubble extends StatelessWidget {
  const NovaMessageBubble({
    super.key,
    required this.message,
    this.mood = NovaMood.speaking,
    this.compact = false,
    this.trailing,
  });

  final String message;
  final NovaMood mood;
  final bool compact;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: _borderColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NovaCompanion(size: compact ? 30 : 40, mood: mood),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOVA',
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.2,
                    color: _borderColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFamily,
                    fontSize: compact ? 13 : 14,
                    height: 1.45,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (trailing != null) ...[const SizedBox(height: 8), trailing!],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color get _borderColor =>
      mood == NovaMood.error ? AppColors.error : AppColors.secondary;
}
