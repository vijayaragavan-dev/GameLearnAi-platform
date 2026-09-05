import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_styles.dart';
import '../../core/theme/app_typography.dart';

/// GameLearn AI asset path architecture.
///
/// Conceptual organization for all visual assets.
/// Assets must be added to pubspec.yaml before use.
///
/// Directory structure (under assets/):
///
/// assets/
///   images/
///     characters/       — avatar, nova, companion characters
///     games/            — per-game artwork (14 game folders)
///     worlds/           — subject/world artwork
///     rewards/          — badges, achievement artwork, trophy
///     backgrounds/      — atmospheric background images
///     decorations/      — ambient decorative elements
///
/// Naming convention:
///   [category]_[name]_[variant].[ext]
///   Example: game_quiz_battle_banner.png
///            world_programming_bg.png
///            reward_streak_badge.png
abstract final class AssetPaths {
  // ── Characters ────────────────────────────────────────────────────────────
  static const String _charBase = 'assets/images/characters/';
  static const String avatarDefault = '${_charBase}avatar_default.png';
  static const String novaIdle = '${_charBase}nova_idle.png';
  static const String novaCelebrate = '${_charBase}nova_celebrate.png';

  // ── Games ─────────────────────────────────────────────────────────────────
  static const String _gameBase = 'assets/images/games/';
  static String gameBanner(String gameId) => '${_gameBase}${gameId}_banner.png';
  static String gameIcon(String gameId) => '${_gameBase}${gameId}_icon.png';
  static String gameBackground(String gameId) =>
      '${_gameBase}${gameId}_bg.png';

  // ── Worlds / subjects ─────────────────────────────────────────────────────
  static const String _worldBase = 'assets/images/worlds/';
  static String worldBackground(String subjectKey) =>
      '${_worldBase}${subjectKey}_bg.png';
  static String worldIcon(String subjectKey) =>
      '${_worldBase}${subjectKey}_icon.png';

  // ── Rewards ───────────────────────────────────────────────────────────────
  static const String _rewardBase = 'assets/images/rewards/';
  static const String badgeXP = '${_rewardBase}badge_xp.png';
  static const String badgeStreak = '${_rewardBase}badge_streak.png';
  static const String badgeLevel = '${_rewardBase}badge_level.png';
  static const String trophy = '${_rewardBase}trophy.png';
  static String achievementBadge(String achievementId) =>
      '${_rewardBase}achievement_$achievementId.png';

  // ── Backgrounds ───────────────────────────────────────────────────────────
  static const String _bgBase = 'assets/images/backgrounds/';
  static const String atmosphericMain = '${_bgBase}atmospheric_main.png';
  static const String atmosphericGame = '${_bgBase}atmospheric_game.png';

  // ── Decorations ───────────────────────────────────────────────────────────
  static const String _decorBase = 'assets/images/decorations/';
  static const String orbPrimary = '${_decorBase}orb_primary.png';
  static const String starField = '${_decorBase}star_field.png';
}

/// Clean branded placeholder for any missing image asset.
///
/// Renders a premium-looking placeholder that never looks broken.
/// Use this everywhere an image asset might not exist yet.
///
/// Example:
///   Image.asset(
///     AssetPaths.worldBackground('code'),
///     errorBuilder: (_, __, ___) => const AssetPlaceholder(
///       icon: Icons.code_rounded,
///       label: 'Programming World',
///     ),
///   )
class AssetPlaceholder extends StatelessWidget {
  const AssetPlaceholder({
    super.key,
    this.icon,
    this.label,
    this.color,
    this.size,
    this.borderRadius,
  });

  final IconData? icon;
  final String? label;
  final Color? color;
  final Size? size;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = color ?? AppColors.primary;
    final br = borderRadius ?? BorderRadius.circular(AppRadius.md);

    return Container(
      width: size?.width,
      height: size?.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  accent.withValues(alpha: 0.12),
                  AppColors.surfaceElevated,
                ]
              : [
                  accent.withValues(alpha: 0.06),
                  AppLightColors.surfaceElevated,
                ],
        ),
        borderRadius: br,
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.25 : 0.15),
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? AppIcons.nova,
            size: (size?.height ?? 48) * 0.35,
            color: accent.withValues(alpha: 0.65),
          ),
          if (label != null) ...[
            const SizedBox(height: 6),
            Text(
              label!,
              style: AppTypography.caption(context),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Avatar placeholder — for user avatars that haven't loaded.
/// Shows initials on a gradient circle.
class AvatarPlaceholder extends StatelessWidget {
  const AvatarPlaceholder({
    super.key,
    this.initials,
    this.size = 40,
  });

  final String? initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.brand,
      ),
      alignment: Alignment.center,
      child: Text(
        initials ?? '?',
        style: TextStyle(
          fontFamily: AppTypography.displayFamily,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
