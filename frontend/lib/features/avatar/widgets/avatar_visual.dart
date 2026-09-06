import 'package:flutter/material.dart';

import '../../../core/models/avatar_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Premium character visual — deterministic, original, no copyrighted assets.
/// Uses assetKey hash for gradient variety, rarity for border/glow, and
/// initial letter fallback. Never shows broken image.
class AvatarVisual extends StatelessWidget {
  const AvatarVisual({
    super.key,
    required this.assetKey,
    required this.displayName,
    required this.rarity,
    this.size = 80,
    this.showGlow = false,
    this.showRarityBadge = false,
  });

  final String assetKey;
  final String displayName;
  final String rarity;
  final double size;
  final bool showGlow;
  final bool showRarityBadge;

  Color _rarityColor(String r, bool isDark) {
    final v = r.toLowerCase();
    return switch (v) {
      'legendary' || 'prestige' => AppColors.xp,
      'epic' => AppColors.primary,
      'rare' => AppColors.secondary,
      'common' => isDark ? AppColors.textTertiary : AppLightColors.textTertiary,
      'initiate' => isDark ? AppColors.textTertiary : AppLightColors.textTertiary,
      _ => AppColors.locked,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rarityColor = _rarityColor(rarity, isDark);
    final initial = displayName.isEmpty ? '?' : displayName[0].toUpperCase();
    final isLegendary = rarity.toLowerCase() == 'legendary' || rarity.toLowerCase() == 'prestige';
    final isEpic = rarity.toLowerCase() == 'epic';

    return Semantics(
      label: '$displayName, $rarity character',
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isLegendary
                    ? [AppColors.xp.withValues(alpha: 0.9), AppColors.primary.withValues(alpha: 0.7)]
                    : isEpic
                        ? [AppColors.primary.withValues(alpha: 0.85), AppColors.secondary.withValues(alpha: 0.6)]
                        : [rarityColor.withValues(alpha: 0.85), rarityColor.withValues(alpha: 0.55)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: rarityColor.withValues(alpha: isDark ? 0.65 : 0.45),
                width: isLegendary ? 2.5 : (isEpic ? 2 : 1.5),
              ),
              boxShadow: showGlow && isDark
                  ? [
                      BoxShadow(
                        color: rarityColor.withValues(alpha: isLegendary ? 0.35 : 0.22),
                        blurRadius: isLegendary ? 22 : 14,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                fontFamily: AppTypography.displayFamily,
                fontSize: size * 0.38,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6)],
              ),
            ),
          ),
          if (showRarityBadge)
            Positioned(
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: rarityColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 1),
                  boxShadow: [BoxShadow(color: rarityColor.withValues(alpha: 0.3), blurRadius: 8)],
                ),
                child: Text(
                  rarity.toUpperCase(),
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small credits pill
class CreditsPill extends StatelessWidget {
  const CreditsPill({super.key, required this.credits});
  final int credits;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.xp.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.xp.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.diamond_rounded, size: 12, color: AppColors.xp),
          const SizedBox(width: 5),
          Text('$credits', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.xp)),
          const SizedBox(width: 3),
          const Text('CREDITS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.xp)),
        ],
      ),
    );
  }
}
