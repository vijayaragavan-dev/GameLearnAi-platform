import 'package:flutter/material.dart';

/// GameLearn AI icon language — Version 2.0
///
/// Single source for all IconData. No scattered Material icon references.
/// All icons use rounded style for visual consistency.
///
/// Categories:
///   Navigation, Game types (14), Game categories, Difficulty,
///   Gamification/status, Actions, Feedback, World/subjects, Characters
abstract final class AppIcons {
  // ── Navigation ────────────────────────────────────────────────────────────
  static const navHomeIdle = Icons.dashboard_outlined;
  static const navHomeActive = Icons.dashboard_rounded;
  static const navWorldsIdle = Icons.public_outlined;
  static const navWorldsActive = Icons.public_rounded;
  static const navStatsIdle = Icons.insights_outlined;
  static const navStatsActive = Icons.insights_rounded;
  static const navProfileIdle = Icons.person_outline_rounded;
  static const navProfileActive = Icons.person_rounded;
  static const navGamesIdle = Icons.sports_esports_outlined;
  static const navGamesActive = Icons.sports_esports_rounded;

  // ── Game type icons (14 games — cohesive rounded style) ───────────────────
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

  // ── Game category icons ───────────────────────────────────────────────────
  static IconData categoryIcon(String category) =>
      switch (category.toLowerCase()) {
        'arcade' => Icons.sports_esports_rounded,
        'puzzle' => Icons.extension_rounded,
        'speed' => Icons.bolt_rounded,
        'memory' => Icons.psychology_rounded,
        'logic' => Icons.lightbulb_rounded,
        'strategy' => Icons.military_tech_rounded,
        'battle' => Icons.shield_rounded,
        'mystery' => Icons.search_rounded,
        'network' => Icons.hub_rounded,
        'board' => Icons.casino_rounded,
        _ => Icons.videogame_asset_rounded,
      };

  // ── Difficulty ────────────────────────────────────────────────────────────
  static IconData difficultyIcon(String diff) => switch (diff.toUpperCase()) {
    'EASY' => Icons.shield_outlined,
    'MEDIUM' => Icons.shield_rounded,
    'HARD' => Icons.local_fire_department_rounded,
    _ => Icons.shield_outlined,
  };

  // ── Status / progression ─────────────────────────────────────────────────
  static const xp = Icons.star_rounded;
  static const xpBolt = Icons.bolt_rounded;
  static const streak = Icons.local_fire_department_rounded;
  static const streakIdle = Icons.local_fire_department_outlined;
  static const level = Icons.military_tech_rounded;
  static const levelUp = Icons.trending_up_rounded;
  static const mastery = Icons.verified_rounded;
  static const achievement = Icons.emoji_events_rounded;
  static const trophy = Icons.emoji_events_rounded;
  static const challenge = Icons.flag_rounded;
  static const path = Icons.route_rounded;
  static const world = Icons.public_rounded;

  // ── Node states ────────────────────────────────────────────────────────────
  static const locked = Icons.lock_rounded;
  static const lockedOutline = Icons.lock_outline_rounded;
  static const completed = Icons.verified_rounded;
  static const available = Icons.play_circle_rounded;
  static const inProgress = Icons.timelapse_rounded;
  static const current = Icons.radio_button_checked_rounded;

  // ── Reward / gamification ─────────────────────────────────────────────────
  static const reward = Icons.card_giftcard_rounded;
  static const badge = Icons.workspace_premium_rounded;
  static const coin = Icons.monetization_on_rounded;
  static const diamond = Icons.diamond_rounded;
  static const crown = Icons.emoji_events_rounded;

  // ── Feedback ──────────────────────────────────────────────────────────────
  static const correct = Icons.check_circle_rounded;
  static const incorrect = Icons.cancel_rounded;
  static const warning = Icons.warning_rounded;
  static const info = Icons.info_rounded;
  static const hint = Icons.lightbulb_rounded;

  // ── Actions ───────────────────────────────────────────────────────────────
  static const play = Icons.play_arrow_rounded;
  static const replay = Icons.replay_rounded;
  static const next = Icons.arrow_forward_rounded;
  static const back = Icons.arrow_back_rounded;
  static const close = Icons.close_rounded;
  static const share = Icons.share_rounded;
  static const settings = Icons.settings_rounded;
  static const filter = Icons.tune_rounded;
  static const search = Icons.search_rounded;
  static const more = Icons.more_horiz_rounded;

  // ── Nova / AI companion ────────────────────────────────────────────────────
  static const nova = Icons.auto_awesome_rounded;
  static const novaAlt = Icons.psychology_rounded;
  static const aiSpark = Icons.auto_awesome_mosaic_rounded;

  // ── Subjects / worlds ─────────────────────────────────────────────────────
  static IconData subjectIcon(String iconKey) =>
      switch (iconKey.toLowerCase()) {
        'code' || 'programming' || 'cs' => Icons.code_rounded,
        'network' || 'networks' || 'computer_networks' => Icons.hub_rounded,
        'database' || 'dbms' || 'db' => Icons.storage_rounded,
        'os' || 'operating_systems' => Icons.developer_board_rounded,
        'data_structures' || 'dsa' || 'algorithms' =>
          Icons.account_tree_rounded,
        'math' || 'mathematics' => Icons.calculate_rounded,
        'science' => Icons.science_rounded,
        _ => Icons.school_rounded,
      };

  // ── Performance / result labels ────────────────────────────────────────────
  static IconData performanceIcon(String label) =>
      switch (label.toUpperCase()) {
        'LEGENDARY' => Icons.emoji_events_rounded,
        'EXCELLENT' => Icons.star_rounded,
        'GOOD' => Icons.thumb_up_rounded,
        'FAIR' => Icons.trending_flat_rounded,
        _ => Icons.refresh_rounded,
      };

  // ── Theme / display ────────────────────────────────────────────────────────
  static const themeDark = Icons.dark_mode_rounded;
  static const themeLight = Icons.light_mode_rounded;
  static const themeSystem = Icons.brightness_auto_rounded;
}

/// Helper to resolve nav icon by route and selection state.
IconData navIcon(String route, {required bool selected}) {
  if (route.startsWith('/subjects')) {
    return selected ? AppIcons.navWorldsActive : AppIcons.navWorldsIdle;
  }
  if (route.startsWith('/progress')) {
    return selected ? AppIcons.navStatsActive : AppIcons.navStatsIdle;
  }
  if (route.startsWith('/profile')) {
    return selected ? AppIcons.navProfileActive : AppIcons.navProfileIdle;
  }
  if (route.startsWith('/games')) {
    return selected ? AppIcons.navGamesActive : AppIcons.navGamesIdle;
  }
  return selected ? AppIcons.navHomeActive : AppIcons.navHomeIdle;
}
