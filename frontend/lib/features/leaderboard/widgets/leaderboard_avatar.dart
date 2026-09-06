import 'package:flutter/material.dart';

import '../../../core/models/leaderboard_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Safe avatar renderer for leaderboard — uses backend assetKey but falls back
/// to a deterministic stylized placeholder when no local asset exists.
/// Never shows broken-image icon or copyrighted characters.
class LeaderboardAvatarView extends StatelessWidget {
  const LeaderboardAvatarView({
    super.key,
    required this.avatar,
    required this.displayName,
    this.size = 40,
    this.rarityBorder = true,
    this.showGlow = false,
  });

  final LeaderboardAvatar avatar;
  final String displayName;
  final double size;
  final bool rarityBorder;
  final bool showGlow;

  Color _rarityColor(AvatarRarity r) => switch (r) {
        AvatarRarity.legendary => AppColors.xp,
        AvatarRarity.epic => AppColors.primary,
        AvatarRarity.rare => AppColors.secondary,
        AvatarRarity.common => AppColors.locked,
        AvatarRarity.initiate => AppColors.locked,
        AvatarRarity.prestige => AppColors.xp,
        AvatarRarity.unknown => AppColors.locked,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rarityColor = _rarityColor(avatar.rarity);
    final initial = displayName.isEmpty ? '?' : displayName[0].toUpperCase();
    // Deterministic gradient based on assetKey hash for placeholder variety
    final hash = avatar.assetKey.hashCode;
    final gradient = LinearGradient(
      colors: [
        rarityColor.withValues(alpha: 0.85),
        rarityColor.withValues(alpha: 0.55),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Semantics(
      label: '$displayName avatar, ${avatar.rarity.name} tier',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient,
          border: Border.all(
            color: rarityBorder ? rarityColor.withValues(alpha: isDark ? 0.55 : 0.35) : Colors.transparent,
            width: rarityBorder ? (size > 60 ? 2.5 : 1.5) : 0,
          ),
          boxShadow: showGlow && isDark
              ? [BoxShadow(color: rarityColor.withValues(alpha: 0.28), blurRadius: 14, spreadRadius: 1)]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            fontFamily: AppTypography.displayFamily,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4)],
          ),
        ),
      ),
    );
  }
}
