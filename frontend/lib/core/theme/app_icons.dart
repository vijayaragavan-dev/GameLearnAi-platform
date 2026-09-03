import 'package:flutter/material.dart';

/// Centralized icon mapping — single language, no scattered IconData.
///
/// Categories use rounded filled when selected, outlined when idle.
/// Game types map to distinct but cohesive icons; difficulty uses shield/fire.

abstract final class AppIcons {
  // ---- Navigation (rounded pair: outlined idle / rounded selected) ----
  static const navHomeIdle = Icons.dashboard_outlined;
  static const navHomeActive = Icons.dashboard_rounded;
  static const navWorldsIdle = Icons.public_outlined;
  static const navWorldsActive = Icons.public_rounded;
  static const navStatsIdle = Icons.insights_outlined;
  static const navStatsActive = Icons.insights_rounded;
  static const navProfileIdle = Icons.person_outline_rounded;
  static const navProfileActive = Icons.person_rounded;

  // ---- Game categories (for hub filtering / card header) ----
  static IconData categoryIcon(String category) =>
      switch (category.toLowerCase()) {
        'arcade' => Icons.sports_esports_rounded,
        'puzzle' => Icons.extension_rounded,
        'speed' => Icons.bolt_rounded,
        'memory' => Icons.psychology_rounded,
        'logic' => Icons.lightbulb_rounded,
        'strategy' => Icons.military_tech_rounded,
        _ => Icons.videogame_asset_rounded,
      };

  // ---- Game type icons (14 games — cohesive rounded style) ----
  static IconData gameIcon(String gameType) => switch (gameType.toLowerCase()) {
    'quiz_battle' => Icons.quiz_rounded,
    'memory_match' => Icons.grid_view_rounded,
    'drag_drop' => Icons.drag_indicator_rounded,
    'speed_run' => Icons.timer_rounded,
    'debug_arena' => Icons.bug_report_rounded,
    'unlock_code' => Icons.lock_open_rounded,
    'concept_builder' => Icons.account_tree_rounded,
    'sequence_master' => Icons.format_list_numbered_rounded,
    'target_challenge' => Icons.gps_fixed_rounded,
    'mystery_case' => Icons.search_rounded,
    'boss_battle' => Icons.shield_rounded,
    'puzzle_arena' => Icons.extension_rounded,
    'connectivity_lab' => Icons.hub_rounded,
    'snake_and_ladder' => Icons.casino_rounded,
    _ => Icons.sports_esports_rounded,
  };

  // ---- Difficulty ----
  static IconData difficultyIcon(String diff) => switch (diff.toUpperCase()) {
    'EASY' => Icons.shield_outlined,
    'MEDIUM' => Icons.shield_rounded,
    'HARD' => Icons.local_fire_department_rounded,
    _ => Icons.shield_outlined,
  };

  // ---- Status / gamification ----
  static const xp = Icons.star_rounded;
  static const streak = Icons.local_fire_department_rounded;
  static const streakIdle = Icons.local_fire_department_outlined;
  static const level = Icons.military_tech_rounded;
  static const achievement = Icons.emoji_events_rounded;
  static const locked = Icons.lock_rounded;
  static const completed = Icons.verified_rounded;
  static const available = Icons.play_circle_rounded;
  static const inProgress = Icons.timelapse_rounded;

  // ---- Feedback ----
  static const correct = Icons.check_circle_rounded;
  static const incorrect = Icons.cancel_rounded;
  static const warning = Icons.warning_rounded;
  static const info = Icons.info_rounded;
  static const reward = Icons.card_giftcard_rounded;

  // ---- Actions ----
  static const play = Icons.play_arrow_rounded;
  static const replay = Icons.replay_rounded;
  static const next = Icons.arrow_forward_rounded;
  static const back = Icons.arrow_back_rounded;
  static const close = Icons.close_rounded;
  static const share = Icons.share_rounded;
  static const settings = Icons.settings_rounded;
  static const nova = Icons.auto_awesome_rounded;
}

/// Helper to pick nav icon pair by selection.
IconData navIcon(String route, {required bool selected}) {
  if (route.startsWith('/subjects'))
    return selected ? AppIcons.navWorldsActive : AppIcons.navWorldsIdle;
  if (route.startsWith('/progress'))
    return selected ? AppIcons.navStatsActive : AppIcons.navStatsIdle;
  if (route.startsWith('/profile'))
    return selected ? AppIcons.navProfileActive : AppIcons.navProfileIdle;
  return selected ? AppIcons.navHomeActive : AppIcons.navHomeIdle;
}
