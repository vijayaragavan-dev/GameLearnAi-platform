import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/mascot_character.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/neo_brutalism.dart';
import '../../features/avatar/providers/active_mascot_provider.dart';
import '../../features/avatar/widgets/cartoon_mascot_view.dart';

/// NOVA - the GameLearn AI companion. 2D Cartoon Learning Companion.
enum NovaMood { idle, thinking, speaking, celebrating, encouraging, error, sad, motivating }

class NovaCompanion extends ConsumerWidget {
  const NovaCompanion({super.key, this.size = 64, this.mood = NovaMood.idle});

  final double size;
  final NovaMood mood;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMascot = ref.watch(activeMascotProvider);
    final mascotMood = switch (mood) {
      NovaMood.celebrating => MascotMood.celebrating,
      NovaMood.thinking => MascotMood.thinking,
      NovaMood.speaking || NovaMood.encouraging => MascotMood.waving,
      NovaMood.error => MascotMood.focused,
      NovaMood.sad => MascotMood.sad,
      NovaMood.motivating => MascotMood.motivating,
      NovaMood.idle => MascotMood.idle,
    };

    return CartoonMascotView(
      character: activeMascot.character,
      accessory: activeMascot.accessory,
      mood: mascotMood,
      size: size,
    );
  }
}

/// NOVA avatar — 2D Cartoon Learning Companion Art
/// Presents the player's active companion with glow ring, halo, and status dot.
class NovaAvatar extends ConsumerWidget {
  const NovaAvatar({
    super.key,
    this.size = 72,
    this.ringColor = AppColors.secondary,
    this.showHalo = true,
    this.statusDot,
    this.semanticsLabel = 'Your AI learning companion',
  });

  final double size;
  final Color ringColor;
  final bool showHalo;

  /// Optional small status dot (e.g. online/strong). Null hides it.
  final Color? statusDot;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeMascot = ref.watch(activeMascotProvider);

    return Semantics(
      label: semanticsLabel,
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (showHalo && isDark)
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ringColor.withValues(alpha: 0.35),
                      blurRadius: size * 0.35,
                      spreadRadius: size * 0.04,
                    ),
                  ],
                ),
              ),
            Container(
              width: size * 0.94,
              height: size * 0.94,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? AppColors.surfaceElevated
                    : activeMascot.character.bellyColor,
                border: Border.all(
                  color: isDark ? ringColor.withValues(alpha: 0.65) : NeoBrutalColors.ink,
                  width: isDark ? 2 : 2.5,
                ),
                boxShadow: isDark ? null : NeoBrutalShadows.hardSm,
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: CartoonMascotView(
                character: activeMascot.character,
                accessory: activeMascot.accessory,
                mood: MascotMood.idle,
                size: size * 0.82,
                isAnimated: false,
              ),
            ),
            if (statusDot != null)
              Positioned(
                right: size * 0.04,
                bottom: size * 0.04,
                child: ExcludeSemantics(
                  child: Container(
                    width: size * 0.20,
                    height: size * 0.20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusDot,
                      border: Border.all(
                        color: isDark
                            ? AppColors.background
                            : AppLightColors.background,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevated.withValues(alpha: 0.9) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? _borderColor.withValues(alpha: 0.4) : NeoBrutalColors.ink,
          width: isDark ? 1.0 : 2.5,
        ),
        boxShadow: isDark ? null : NeoBrutalShadows.hardSm,
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
                    fontFamily: AppTypography.displayFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                    color: isDark ? _borderColor : NeoBrutalColors.cobaltBlue,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFamily,
                    fontSize: compact ? 13 : 14,
                    height: 1.45,
                    color: isDark ? AppColors.textPrimary : NeoBrutalColors.ink,
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
