import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// Persisted theme preference. Uses SharedPreferences (already available via
/// sharedPreferencesProvider). No new dependency.
class ThemeController extends Notifier<ThemeMode> {
  static const String _kPref = 'pref_theme_mode';
  // Stored as string: system / light / dark
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_kPref);
    return _fromString(raw);
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kPref, _toString(mode));
  }

  static ThemeMode _fromString(String? v) {
    return switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static String _toString(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      };

  String get label => switch (state) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        _ => 'System',
      };
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);
