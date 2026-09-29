import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/leaderboard_models.dart';
import '../../../core/models/mascot_character.dart';
import '../../../core/theme/app_colors.dart';
import '../../avatar/providers/active_mascot_provider.dart';
import '../../avatar/widgets/cartoon_mascot_view.dart';

/// Cartoon Mascot Avatar renderer for leaderboard — replaces dummy robot
/// with the user's active companion and rich animal companions for competitors.
class LeaderboardAvatarView extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rarityColor = _rarityColor(avatar.rarity);
    final activeMascot = ref.watch(activeMascotProvider);

    final isMe = displayName.trim().toLowerCase() == 'you';
    final character = isMe
        ? activeMascot.character
        : MascotRoster.characters[displayName.hashCode.abs() % MascotRoster.characters.length];
    final accessory = isMe ? activeMascot.accessory : MascotAccessory.none;

    return Semantics(
      label: '$displayName avatar, ${avatar.rarity.name} tier',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF1E2430) : character.bellyColor,
          border: Border.all(
            color: rarityBorder ? rarityColor.withValues(alpha: isDark ? 0.65 : 0.45) : Colors.transparent,
            width: rarityBorder ? (size > 60 ? 2.5 : 1.8) : 0,
          ),
          boxShadow: showGlow && isDark
              ? [BoxShadow(color: rarityColor.withValues(alpha: 0.28), blurRadius: 14, spreadRadius: 1)]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: CartoonMascotView(
          character: character,
          accessory: accessory,
          mood: MascotMood.idle,
          size: size * 0.88,
          isAnimated: false,
        ),
      ),
    );
  }
}
