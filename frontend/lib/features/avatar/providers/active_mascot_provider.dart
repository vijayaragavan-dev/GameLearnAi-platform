import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/mascot_character.dart';

class ActiveMascotState {
  const ActiveMascotState({
    required this.character,
    required this.accessory,
    required this.mood,
    required this.adminUnlockAll,
    this.adminLevelOverride,
  });

  final MascotCharacter character;
  final MascotAccessory accessory;
  final MascotMood mood;
  final bool adminUnlockAll;
  final int? adminLevelOverride;

  ActiveMascotState copyWith({
    MascotCharacter? character,
    MascotAccessory? accessory,
    MascotMood? mood,
    bool? adminUnlockAll,
    int? adminLevelOverride,
    bool clearLevelOverride = false,
  }) {
    return ActiveMascotState(
      character: character ?? this.character,
      accessory: accessory ?? this.accessory,
      mood: mood ?? this.mood,
      adminUnlockAll: adminUnlockAll ?? this.adminUnlockAll,
      adminLevelOverride: clearLevelOverride ? null : (adminLevelOverride ?? this.adminLevelOverride),
    );
  }
}

class ActiveMascotNotifier extends Notifier<ActiveMascotState> {
  static const _kPrefCharacterId = 'gamelearn_active_character_id';
  static const _kPrefAccessory = 'gamelearn_active_accessory';
  static const _kPrefAdminUnlock = 'gamelearn_admin_unlock_all';
  static const _kPrefAdminLevel = 'gamelearn_admin_level_override';

  @override
  ActiveMascotState build() {
    _loadFromPreferences();
    return ActiveMascotState(
      character: MascotRoster.characters.first,
      accessory: MascotAccessory.none,
      mood: MascotMood.idle,
      adminUnlockAll: false,
      adminLevelOverride: null,
    );
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final charId = prefs.getString(_kPrefCharacterId);
      final accId = prefs.getString(_kPrefAccessory);
      final adminUnlock = prefs.getBool(_kPrefAdminUnlock) ?? false;
      final adminLvl = prefs.getInt(_kPrefAdminLevel);

      final character = charId != null ? MascotRoster.findById(charId) : MascotRoster.characters.first;
      final accessory = MascotAccessory.fromId(accId);

      state = state.copyWith(
        character: character,
        accessory: accessory,
        adminUnlockAll: adminUnlock,
        adminLevelOverride: adminLvl,
      );
    } catch (_) {
      // Graceful fallback to initial in-memory defaults
    }
  }

  Future<void> selectCharacter(String characterId) async {
    final char = MascotRoster.findById(characterId);
    state = state.copyWith(character: char);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefCharacterId, characterId);
    } catch (_) {}
  }

  Future<void> setAccessory(MascotAccessory accessory) async {
    state = state.copyWith(accessory: accessory);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefAccessory, accessory.id);
    } catch (_) {}
  }

  void setMood(MascotMood mood) {
    state = state.copyWith(mood: mood);
  }

  Future<void> toggleAdminUnlockAll() async {
    final next = !state.adminUnlockAll;
    state = state.copyWith(adminUnlockAll: next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPrefAdminUnlock, next);
    } catch (_) {}
  }

  Future<void> setAdminLevelOverride(int? level) async {
    if (level == null) {
      state = state.copyWith(clearLevelOverride: true);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_kPrefAdminLevel);
      } catch (_) {}
    } else {
      state = state.copyWith(adminLevelOverride: level);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_kPrefAdminLevel, level);
      } catch (_) {}
    }
  }
}

final activeMascotProvider = NotifierProvider<ActiveMascotNotifier, ActiveMascotState>(
  ActiveMascotNotifier.new,
);
