import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sound effect identifiers mapped to bundled royalty-free assets
/// (synthesized in-house - no copyrighted material).
enum Sfx {
  buttonTap('sfx_tap.wav'),
  buttonConfirm('sfx_confirm.wav'),
  correct('sfx_correct.wav'),
  incorrect('sfx_incorrect.wav'),
  xpGain('sfx_xp.wav'),
  levelUp('sfx_levelup.wav'),
  achievementUnlock('sfx_achievement.wav'),
  missionComplete('sfx_mission.wav'),
  nodeUnlock('sfx_node.wav'),
  streakContinue('sfx_streak.wav'),
  notification('sfx_notification.wav');

  const Sfx(this.asset);

  final String asset;
}

/// Ambient contexts; one looping track per context, subtle by design.
enum MusicContext {
  menu('music_menu.wav'),
  dashboard('music_menu.wav'),
  adventure('music_adventure.wav'),
  quiz('music_quiz.wav'),
  celebration('music_adventure.wav'),
  tutor('music_quiz.wav');

  const MusicContext(this.asset);

  final String asset;
}

/// Centralized audio state. Music and SFX toggle independently; preferences
/// persist locally. All playback is fail-safe: a missing asset, unsupported
/// host or missing platform channel never crashes the app.
class AudioManager {
  AudioManager({SharedPreferences? prefs}) : _prefs = prefs {
    musicEnabled = _prefs?.getBool(_kMusic) ?? true;
    sfxEnabled = _prefs?.getBool(_kSfx) ?? true;
    hapticsEnabled = _prefs?.getBool(_kHaptics) ?? true;
  }

  static const String _kMusic = 'pref_music_enabled';
  static const String _kSfx = 'pref_sfx_enabled';
  static const String _kHaptics = 'pref_haptics_enabled';

  final SharedPreferences? _prefs;

  bool musicEnabled = true;
  bool sfxEnabled = true;
  bool hapticsEnabled = true;

  bool _platformBroken = false;

  final Map<String, AudioPlayer> _musicPlayers = {};
  AudioPlayer? _sfxPlayer;
  MusicContext? _currentContext;

  // ---- Settings -----------------------------------------------------------

  Future<void> setMusicEnabled(bool value) async {
    musicEnabled = value;
    await _prefs?.setBool(_kMusic, value);
    if (!value) await stopMusic();
  }

  Future<void> setSfxEnabled(bool value) async {
    sfxEnabled = value;
    await _prefs?.setBool(_kSfx, value);
  }

  Future<void> setHapticsEnabled(bool value) async {
    hapticsEnabled = value;
    await _prefs?.setBool(_kHaptics, value);
  }

  // ---- SFX ----------------------------------------------------------------

  /// Deduplicates rapid-fire calls caused by widget rebuilds.
  DateTime _lastPlay = DateTime.fromMillisecondsSinceEpoch(0);
  Sfx? _lastSfx;

  Future<void> play(Sfx sfx) async {
    if (!sfxEnabled || _platformBroken) return;
    final now = DateTime.now();
    if (_lastSfx == sfx &&
        now.difference(_lastPlay) < const Duration(milliseconds: 60)) {
      return;
    }
    _lastPlay = now;
    _lastSfx = sfx;
    try {
      _sfxPlayer ??= AudioPlayer();
      await _sfxPlayer!.setVolume(0.9); // system volume governs the rest
      await _sfxPlayer!.play(AssetSource('audio/${sfx.asset}'));
    } catch (e) {
      _degrade(e);
    }
  }

  // ---- Music --------------------------------------------------------------

  Future<void> playContext(MusicContext context) async {
    if (!musicEnabled || _platformBroken) return;
    if (_currentContext == context) return;
    try {
      await stopMusic();
      final player = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
      _musicPlayers[context.asset] = player;
      await player.setVolume(0.16); // subtle, study-friendly
      await player.play(AssetSource('audio/${context.asset}'));
      _currentContext = context;
    } catch (e) {
      _degrade(e);
    }
  }

  Future<void> stopMusic() async {
    try {
      for (final p in _musicPlayers.values) {
        await p.stop();
        await p.dispose();
      }
    } catch (e) {
      debugPrint('AudioManager.stopMusic degraded: $e');
    }
    _musicPlayers.clear();
    _currentContext = null;
  }

  void _degrade(Object e) {
    // One hard failure (missing asset/plugin) disables audio for the session
    // instead of spamming errors. App remains fully functional.
    _platformBroken = true;
    debugPrint('AudioManager degraded to silent mode: $e');
  }

  Future<void> dispose() async {
    await stopMusic();
    try {
      await _sfxPlayer?.dispose();
    } catch (_) {}
    _sfxPlayer = null;
  }
}
