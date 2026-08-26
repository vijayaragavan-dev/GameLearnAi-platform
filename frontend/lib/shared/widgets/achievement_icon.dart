import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Renders a backend achievement's [iconKey] as an original GameLearn badge.
/// Unknown keys fall back to the generic star sigil - never a raw placeholder.
class AchievementIcon extends StatelessWidget {
  const AchievementIcon({
    super.key,
    required this.iconKey,
    required this.unlocked,
    this.size = 64,
  });

  final String iconKey;
  final bool unlocked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(iconKey);
    return CustomPaint(
      size: Size.square(size),
      painter: _BadgePainter(
        unlocked: unlocked,
        tint: spec.tint,
        glyph: spec.glyph,
      ),
    );
  }

  _Spec _specFor(String key) => switch (key) {
    'ach_first_quiz' ||
    'FIRST_QUIZ' => const _Spec(Icons.flag_rounded, AppColors.secondary),
    'ach_persistent_learner' ||
    'TEN_QUIZZES' => const _Spec(Icons.bolt_rounded, AppColors.primaryBright),
    'ach_flawless_victory' ||
    'PERFECT_SCORE' => const _Spec(Icons.emoji_events_rounded, AppColors.xp),
    'ach_topic_mastered' || 'FIRST_MASTERED' => const _Spec(
      Icons.workspace_premium_rounded,
      AppColors.success,
    ),
    'ach_streak_3' => const _Spec(
      Icons.local_fire_department_rounded,
      AppColors.streak,
    ),
    'ach_week_warrior' ||
    'STREAK_7' => const _Spec(Icons.whatshot_rounded, AppColors.error),
    _ => const _Spec(Icons.auto_awesome_rounded, AppColors.primaryBright),
  };
}

class _Spec {
  const _Spec(this.glyph, this.tint);

  final IconData glyph;
  final Color tint;
}

class _BadgePainter extends CustomPainter {
  const _BadgePainter({
    required this.unlocked,
    required this.tint,
    required this.glyph,
  });

  final bool unlocked;
  final Color tint;
  final IconData glyph;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.46;

    // Hexagonal frame.
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = math.pi / 6 + i * math.pi / 3;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    if (unlocked) {
      canvas.drawShadow(path, Colors.black, 6, true);
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tint.withValues(alpha: 0.9),
              tint.withValues(alpha: 0.45),
              AppColors.surfaceElevated,
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.025
          ..color = tint.withValues(alpha: 0.95),
      );
    } else {
      canvas.drawPath(path, Paint()..color = AppColors.lockedSurface);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.02
          ..color = AppColors.locked.withValues(alpha: 0.7),
      );
    }

    // Glyph or lock.
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final iconData = unlocked ? glyph : Icons.lock_rounded;
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontFamily: iconData.fontFamily,
        fontSize: size.width * (unlocked ? 0.4 : 0.34),
        color: unlocked ? Colors.white : AppColors.textTertiary,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_BadgePainter oldDelegate) =>
      oldDelegate.unlocked != unlocked ||
      oldDelegate.tint != tint ||
      oldDelegate.glyph != glyph;
}

/// Subject identity glyph derived from the seeded icon_key values.
/// Falls back to a neutral atom for any future subject key.
class SubjectGlyph extends StatelessWidget {
  const SubjectGlyph({
    super.key,
    required this.iconKey,
    required this.color,
    this.size = 44,
  });

  final String iconKey;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (icon, tint) = switch (iconKey) {
      'subject_programming' => (Icons.terminal_rounded, AppColors.primary),
      'subject_networks' => (Icons.lan_rounded, AppColors.secondary),
      'subject_dbms' => (Icons.storage_rounded, AppColors.success),
      'subject_operating_systems' => (Icons.memory_rounded, AppColors.warning),
      'subject_data_structures' => (
        Icons.account_tree_rounded,
        AppColors.streak,
      ),
      _ => (Icons.auto_awesome_rounded, color),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.withValues(alpha: 0.32), tint.withValues(alpha: 0.1)],
        ),
        border: Border.all(color: tint.withValues(alpha: 0.5)),
      ),
      child: Icon(icon, size: size * 0.52, color: tint),
    );
  }
}
