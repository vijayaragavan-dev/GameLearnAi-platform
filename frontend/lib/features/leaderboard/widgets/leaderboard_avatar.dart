import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/models/leaderboard_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/avatar_asset_resolver.dart';

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
    final assetPath = resolveAvatarAsset(avatar.assetKey);
    return Semantics(
      label: '$displayName avatar, ${avatar.rarity.name} tier',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: rarityBorder ? rarityColor.withValues(alpha: isDark ? 0.55 : 0.35) : Colors.transparent,
            width: rarityBorder ? (size > 60 ? 2.5 : 1.5) : 0,
          ),
          boxShadow: showGlow && isDark
              ? [BoxShadow(color: rarityColor.withValues(alpha: 0.28), blurRadius: 14, spreadRadius: 1)]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: SvgPicture.asset(
          assetPath,
          width: size * 0.9,
          height: size * 0.9,
          fit: BoxFit.contain,
          placeholderBuilder: (ctx) => Center(
            child: Text(
              displayName.isEmpty ? '?' : displayName[0].toUpperCase(),
              style: TextStyle(
                fontFamily: AppTypography.displayFamily,
                fontSize: size * 0.42,
                fontWeight: FontWeight.w800,
                color: rarityColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
