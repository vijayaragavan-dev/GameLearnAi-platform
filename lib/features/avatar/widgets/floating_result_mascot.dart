import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_manager.dart' show Sfx;
import '../../../core/models/mascot_character.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/neo_brutalism.dart';
import '../providers/active_mascot_provider.dart';
import 'cartoon_mascot_view.dart';

/// Floating mascot companion widget rendered specifically on result screens
/// (Quiz, Assessment, Game Over).
///
/// Features:
/// - True physics float/hover in mid-air with dynamic responsive ground shadow.
/// - Dynamic particle field (tears for failed, sparks for moderate, stars for good).
/// - 3-tier emotional state:
///     * FAILED (<50%): Sound downs, sad droop animation, consoling quotes.
///     * MODERATE (50%-79%): Motivated spirit, hover nod, inspiring quotes.
///     * GOOD (>=80%): Triumphant celebration, victory bounce, starburst quotes.
/// - Interactive tap: high-fives the mascot, cycles speech quotes, and plays SFX.
class FloatingResultMascot extends ConsumerStatefulWidget {
  const FloatingResultMascot({
    super.key,
    required this.score,
    this.customMessage,
    this.onTap,
    this.compact = false,
  });

  /// Player's score percentage (0.0 to 100.0)
  final double score;

  /// Optional override message for the dialogue bubble
  final String? customMessage;

  /// Optional callback when tapped
  final VoidCallback? onTap;

  /// Compact layout flag for smaller dialogs/views
  final bool compact;

  @override
  ConsumerState<FloatingResultMascot> createState() => _FloatingResultMascotState();
}

class _FloatingResultMascotState extends ConsumerState<FloatingResultMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  int _quoteIndex = 0;

  bool get _isFailed => widget.score < 50.0;
  bool get _isModerate => widget.score >= 50.0 && widget.score < 80.0;

  MascotMood get _mood {
    if (_isFailed) return MascotMood.sad;
    if (_isModerate) return MascotMood.motivating;
    return MascotMood.celebrating;
  }

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  void _onTapMascot(MascotCharacter character) {
    setState(() {
      _quoteIndex++;
    });
    ref.read(hapticsProvider).tap();
    ref.read(audioManagerProvider).play(Sfx.buttonTap);
    widget.onTap?.call();
  }

  String _getQuote(MascotCharacter character) {
    if (widget.customMessage != null && widget.customMessage!.isNotEmpty) {
      return widget.customMessage!;
    }
    List<String> list;
    if (_isFailed) {
      list = character.sadQuotes;
    } else if (_isModerate) {
      list = character.moderateQuotes;
    } else {
      list = character.victoryQuotes;
    }
    if (list.isEmpty) list = character.quotes;
    return list[_quoteIndex % list.length];
  }

  Color get _accentColor {
    if (_isFailed) return const Color(0xFF38BDF8); // Cool Calming Sky Blue
    if (_isModerate) return const Color(0xFFF59E0B); // Energizing Amber
    return const Color(0xFF10B981); // Radiant Emerald Gold
  }

  String get _tierBadgeLabel {
    if (_isFailed) return 'DON\'T GIVE UP • LET\'S RETRY 💧';
    if (_isModerate) return 'SO CLOSE TO 100%! • KEEP GOING ⚡';
    return 'SPECTACULAR! • MASTER OF THE REALM 🌟';
  }

  @override
  Widget build(BuildContext context) {
    final activeMascot = ref.watch(activeMascotProvider);
    final character = activeMascot.character;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQuote = _getQuote(character);

    final mascotSize = widget.compact ? 78.0 : 96.0;

    return Semantics(
      label: '${character.name} the ${character.species} companion says: $currentQuote',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B26) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isDark ? _accentColor.withValues(alpha: 0.45) : NeoBrutalColors.ink,
            width: isDark ? 1.5 : 2.5,
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: _accentColor.withValues(alpha: 0.14),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : NeoBrutalShadows.hard,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Ambient particle background (falling tears, rising sparks, or swirling stars)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _floatController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _FloatingParticlePainter(
                      progress: _floatController.value,
                      isFailed: _isFailed,
                      isModerate: _isModerate,
                      accentColor: _accentColor,
                      isDark: isDark,
                    ),
                  );
                },
              ),
            ),

            // Main Content Row
            Padding(
              padding: EdgeInsets.all(widget.compact ? 12 : 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Floating Mascot Column with 3D Ground Shadow
                  GestureDetector(
                    onTap: () => _onTapMascot(character),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedBuilder(
                      animation: _floatController,
                      builder: (context, child) {
                        final t = _floatController.value;
                        // Smooth floating sinusoidal translation
                        final floatOffset = math.sin(t * 2 * math.pi) * 6.5;
                        // Shadow scale shrinks when mascot floats higher
                        final shadowScale = 1.0 - (math.sin(t * 2 * math.pi) * 0.18);
                        final shadowOpacity = (0.28 - (math.sin(t * 2 * math.pi) * 0.08)).clamp(0.10, 0.45);

                        return SizedBox(
                          width: mascotSize + 10,
                          height: mascotSize * 1.25,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              // Dynamic Ground Shadow
                              Positioned(
                                bottom: 2,
                                child: Transform.scale(
                                  scaleX: shadowScale,
                                  scaleY: shadowScale * 0.65,
                                  child: Container(
                                    width: mascotSize * 0.68,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: (isDark ? Colors.black : NeoBrutalColors.ink)
                                          .withValues(alpha: shadowOpacity),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              // Floating Mascot
                              Positioned(
                                top: 6 + floatOffset,
                                child: CartoonMascotView(
                                  character: character,
                                  accessory: activeMascot.accessory,
                                  mood: _mood,
                                  size: mascotSize,
                                  onTap: () => _onTapMascot(character),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Speech Bubble & Reaction Information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header row: Mascot name + Status badge
                        Row(
                          children: [
                            Text(
                              '${character.name.toUpperCase()} ${character.emoji}',
                              style: TextStyle(
                                fontFamily: NeoBrutalTypography.displayFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color: isDark ? Colors.white : NeoBrutalColors.ink,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: _accentColor.withValues(alpha: isDark ? 0.20 : 0.15),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                  color: _accentColor.withValues(alpha: 0.5),
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                _mood.label.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: _accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        // Subtitle Motivation/Feedback Pill
                        Text(
                          _tierBadgeLabel,
                          style: TextStyle(
                            fontFamily: AppTypography.bodyFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: _accentColor,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Character Speech Quote
                        InkWell(
                          onTap: () => _onTapMascot(character),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E2433)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : NeoBrutalColors.ink.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    currentQuote,
                                    style: TextStyle(
                                      fontFamily: AppTypography.bodyFamily,
                                      fontSize: widget.compact ? 12 : 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                      color: isDark
                                          ? AppColors.textPrimary
                                          : NeoBrutalColors.ink,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.touch_app_rounded,
                                  size: 14,
                                  color: (isDark ? AppColors.textTertiary : NeoBrutalColors.ink)
                                      .withValues(alpha: 0.4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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

/// Canvas painter that animates floating ambient particles:
/// - Failed: gentle blue teardrop rain drifting down
/// - Moderate: fiery amber sparks and embers drifting up
/// - Good: radiant 4-point golden starbursts and confetti pieces floating and spinning
class _FloatingParticlePainter extends CustomPainter {
  _FloatingParticlePainter({
    required this.progress,
    required this.isFailed,
    required this.isModerate,
    required this.accentColor,
    required this.isDark,
  });

  final double progress;
  final bool isFailed;
  final bool isModerate;
  final Color accentColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;

    if (isFailed) {
      // Gentle raindrops / tears drifting down
      paint.color = accentColor.withValues(alpha: isDark ? 0.35 : 0.25);
      const count = 7;
      for (int i = 0; i < count; i++) {
        final seed = i / count;
        final x = (size.width * (0.15 + (seed * 0.75))) % size.width;
        final y = ((progress + seed) % 1.0) * size.height;
        final drop = Path()
          ..moveTo(x, y - 5)
          ..quadraticBezierTo(x + 2, y, x, y + 2)
          ..quadraticBezierTo(x - 2, y, x, y - 5);
        canvas.drawPath(drop, paint);
      }
    } else if (isModerate) {
      // Energetic sparks drifting upwards
      paint.color = accentColor.withValues(alpha: isDark ? 0.40 : 0.30);
      const count = 8;
      for (int i = 0; i < count; i++) {
        final seed = i / count;
        final x = (size.width * (0.1 + (seed * 0.8)) + math.sin(progress * 2 * math.pi + i) * 8) % size.width;
        final y = (1.0 - ((progress + seed) % 1.0)) * size.height;
        final radius = 2.0 + (i % 3);
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    } else {
      // Celebratory 4-point stars & confetti fluttering
      paint.color = accentColor.withValues(alpha: isDark ? 0.45 : 0.35);
      const count = 9;
      for (int i = 0; i < count; i++) {
        final seed = i / count;
        final x = (size.width * (0.1 + (seed * 0.82)) + math.cos(progress * 2 * math.pi + i) * 10) % size.width;
        final y = ((progress + seed) % 1.0) * size.height;
        final spin = progress * 2 * math.pi + (i * 0.7);

        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(spin);

        if (i % 2 == 0) {
          // 4-point diamond star
          final star = Path()
            ..moveTo(0, -5)
            ..lineTo(1.5, -1.5)
            ..lineTo(5, 0)
            ..lineTo(1.5, 1.5)
            ..lineTo(0, 5)
            ..lineTo(-1.5, 1.5)
            ..lineTo(-5, 0)
            ..lineTo(-1.5, -1.5)
            ..close();
          canvas.drawPath(star, paint);
        } else {
          // Confetti rectangle
          canvas.drawRect(
            const Rect.fromLTWH(-2.5, -1.5, 5, 3),
            paint..color = (i % 3 == 0 ? Colors.amber : accentColor).withValues(alpha: isDark ? 0.5 : 0.4),
          );
        }
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingParticlePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isFailed != isFailed ||
        oldDelegate.isModerate != isModerate;
  }
}
