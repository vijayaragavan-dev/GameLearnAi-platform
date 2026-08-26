import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';

/// Animated numeric counter - used for score reveals and XP gains.
class AnimatedCounter extends StatefulWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = AppMotion.feature,
    this.style,
    this.prefix,
    this.suffix,
  });

  final int value;
  final Duration duration;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _from;
  late int _to;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _from = 0;
    _to = widget.value;
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      setState(() {
        _from = old.value;
        _to = widget.value;
      });
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final eased = Curves.easeOutCubic.transform(_controller.value);
        final current = (_from + (_to - _from) * eased).round();
        return Text(
          '${widget.prefix ?? ''}$current${widget.suffix ?? ''}',
          style: widget.style ?? Theme.of(context).textTheme.titleLarge,
        );
      },
    );
  }
}

/// XP progress bar. `remainingXpToNextLevel` is rendered from backend fields.
class XPBar extends StatelessWidget {
  const XPBar({
    super.key,
    required this.currentLevel,
    required this.totalXp,
    required this.xpToNextLevel,
    this.height = 10,
    this.animateFrom,
    this.showLabels = true,
  });

  final int currentLevel;
  final int totalXp;
  final int? xpToNextLevel; // null at max level
  final double height;
  final int? animateFrom;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    // The backend exposes total XP + remaining distance to the next level.
    // A deterministic visual fill is derived ONLY from these server values:
    // at level L with threshold T(L) known via xpToNext, we render
    // "xpToNextLevel" as the unfilled remainder of a normalized bar using the
    // previous threshold when provided by callers through animateFrom.
    final atMax = xpToNextLevel == null;
    final fraction = atMax ? 1.0 : _fractionForDisplay();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabels)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('LEVEL ${currentLevel.toString().padLeft(2, '0')}'),
                Text(
                  atMax ? 'MAX LEVEL' : '$xpToNextLevel XP TO NEXT',
                  style: const TextStyle(color: AppColors.xp),
                ),
              ],
            ),
          ),
        Stack(
          children: [
            Container(
              height: height,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(height),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: animateFrom?.toDouble(), end: fraction),
                  duration: AppMotion.celebration,
                  curve: AppMotion.easeOut,
                  builder: (context, value, _) => Container(
                    width: constraints.maxWidth * value.clamp(0.0, 1.0),
                    height: height,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFB45309), AppColors.xp],
                      ),
                      borderRadius: BorderRadius.circular(height),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.xp.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  double _fractionForDisplay() {
    // Presentational ratio derived ONLY from server-provided numbers:
    // accumulated XP measured against the next level's absolute threshold.
    // No level formula is duplicated here.
    if (xpToNextLevel == null) return 1.0;
    final next = totalXp + xpToNextLevel!;
    if (next <= 0) return 0.0;
    return (totalXp / next).clamp(0.02, 1.0);
  }
}
