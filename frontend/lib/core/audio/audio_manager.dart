import 'dart:async';

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
  notification('sfx_notification.wav'),
  typingFast('sfx/keyboard_typing_faast.wav');

  const Sfx(this.asset);

  final String asset;
}

/// Ambient contexts; one looping track per context, subtle by design.
/// Uses gamelearnai_ambient_theme as the premium default for HOME/MENU.
enum MusicContext {
  menu('music/gamelearnai_ambient_theme.mp3'),
  dashboard('music/gamelearnai_ambient_theme.mp3'),
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
    musicVolume = (_prefs?.getDouble(_kMusicVolume) ?? 1.0).clamp(0.0, 1.0);
    sfxVolume = (_prefs?.getDouble(_kSfxVolume) ?? 1.0).clamp(0.0, 1.0);
  }

  static const String _kMusic = 'pref_music_enabled';
  static const String _kSfx = 'pref_sfx_enabled';
  static const String _kHaptics = 'pref_haptics_enabled';
  static const String _kMusicVolume = 'pref_music_volume';
  static const String _kSfxVolume = 'pref_sfx_volume';

  final SharedPreferences? _prefs;

  bool musicEnabled = true;
  bool sfxEnabled = true;
  bool hapticsEnabled = true;
  double musicVolume = 1.0;
  double sfxVolume = 1.0;

  bool _platformBroken = false;
  bool _disposed = false;
  int _contextSeq = 0;
  bool _stoppingMusic = false;

  final Map<String, AudioPlayer> _musicPlayers = {};
  AudioPlayer? _sfxPlayer;
  AudioPlayer? _typingPlayer;
  MusicContext? _currentContext;

  // ---- Settings -----------------------------------------------------------

  Future<void> setMusicEnabled(bool value) async {
    musicEnabled = value;
    await _prefs?.setBool(_kMusic, value);
    if (!value) {
      await stopMusic();
    } else if (musicVolume > 0) {
      // Resume current context if any, otherwise play menu
      final ctx = _currentContext ?? MusicContext.menu;
      // Clear current so playContext will replay
      _currentContext = null;
      await playContext(ctx);
    }
  }

  Future<void> setSfxEnabled(bool value) async {
    sfxEnabled = value;
    await _prefs?.setBool(_kSfx, value);
    if (!value) {
      try {
        await _typingPlayer?.stop();
      } catch (_) {}
    }
  }

  Future<void> setHapticsEnabled(bool value) async {
    hapticsEnabled = value;
    await _prefs?.setBool(_kHaptics, value);
  }

  Future<void> setMusicVolume(double value) async {
    final v = value.clamp(0.0, 1.0);
    musicVolume = v;
    await _prefs?.setDouble(_kMusicVolume, v);
    // Apply to currently playing music immediately
    if (_currentContext != null && musicEnabled) {
      final player = _musicPlayers[_currentContext!.asset];
      if (player != null) {
        try {
          await player.setVolume(_musicEffectiveVolume());
        } catch (e) {
          if (!_isBenignAudioError(e)) debugPrint('AudioManager setMusicVolume: $e');
        }
      }
      // If volume is 0, keep player but silent; if was 0 and now >0, ensure playing
      if (v == 0) {
        // Keep music paused conceptually but not stopped; just silent
      }
    }
  }

  Future<void> setSfxVolume(double value) async {
    final v = value.clamp(0.0, 1.0);
    sfxVolume = v;
    await _prefs?.setDouble(_kSfxVolume, v);
    // SFX volume is applied per-play, no need to update ongoing SFX
  }

  double _musicEffectiveVolume() {
    // Base music volume is subtle (0.16) scaled by user musicVolume
    // When musicVolume is 0, effective is 0 (silent)
    return 0.16 * musicVolume;
  }

  double _sfxEffectiveVolume() {
    // Base SFX volume 0.9 scaled by user sfxVolume
    return 0.9 * sfxVolume;
  }

  // ---- SFX ----------------------------------------------------------------

  /// Deduplicates rapid-fire calls caused by widget rebuilds.
  DateTime _lastPlay = DateTime.fromMillisecondsSinceEpoch(0);
  Sfx? _lastSfx;

  Future<void> play(Sfx sfx) async {
    if (!sfxEnabled || sfxVolume == 0 || _platformBroken || _disposed) return;
    final now = DateTime.now();
    if (_lastSfx == sfx &&
        now.difference(_lastPlay) < const Duration(milliseconds: 60)) {
      return;
    }
    _lastPlay = now;
    _lastSfx = sfx;
    try {
      if (_disposed) return;
      _sfxPlayer ??= AudioPlayer();
      try {
        await _sfxPlayer!.setVolume(_sfxEffectiveVolume());
      } catch (e) {
        if (_isBenignAudioError(e)) {
          _silentDegrade();
          return;
        }
        _degrade(e);
        return;
      }
      if (_disposed || _platformBroken) return;
      await _sfxPlayer!.play(AssetSource('audio/${sfx.asset}'));
    } catch (e) {
      if (_isBenignAudioError(e)) {
        _silentDegrade();
      } else {
        _degrade(e);
      }
    }
  }

  // ---- Typing SFX (throttled, non-spamming) -------------------------------

  DateTime _lastTypingPlay = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _typingInactivityTimer;
  bool _typingActive = false;

  /// Call this on actual text input (e.g., onChanged with non-empty diff).
  /// Throttles to prevent spam: at most one playback per 120ms, no overlapping.
  Future<void> playTyping() async {
    if (!sfxEnabled || sfxVolume == 0 || _platformBroken || _disposed) return;
    if (_typingActive && DateTime.now().difference(_lastTypingPlay) < const Duration(milliseconds: 120)) {
      return;
    }
    // Prevent overlapping: if typing player is still playing, skip
    if (_typingPlayer != null) {
      try {
        final state = _typingPlayer!.state;
        if (state == PlayerState.playing) return;
      } catch (_) {}
    }
    _typingActive = true;
    _lastTypingPlay = DateTime.now();
    _typingInactivityTimer?.cancel();
    _typingInactivityTimer = Timer(const Duration(milliseconds: 800), () {
      _typingActive = false;
    });
    try {
      _typingPlayer ??= AudioPlayer();
      await _typingPlayer!.setVolume(_sfxEffectiveVolume() * 0.85);
      await _typingPlayer!.play(AssetSource('audio/${Sfx.typingFast.asset}'));
    } catch (e) {
      if (_isBenignAudioError(e)) {
        _silentDegrade();
      } else {
        _degrade(e);
      }
    }
  }

  void resetTyping() {
    _typingActive = false;
    _typingInactivityTimer?.cancel();
    _typingInactivityTimer = null;
  }

  // ---- Music --------------------------------------------------------------

  Future<void> playContext(MusicContext context) async {
    if (!musicEnabled || musicVolume == 0 || _platformBroken || _disposed) return;
    if (_currentContext == context) {
      // If same context but volume changed, update volume
      final player = _musicPlayers[context.asset];
      if (player != null) {
        try {
          await player.setVolume(_musicEffectiveVolume());
        } catch (_) {}
      }
      return;
    }
    final int seq = ++_contextSeq;
    try {
      await stopMusic();
    } catch (_) {}
    if (_disposed || _platformBroken || seq != _contextSeq) return;

    AudioPlayer? player;
    try {
      if (_disposed || seq != _contextSeq) return;
      player = AudioPlayer();
      try {
        await player.setReleaseMode(ReleaseMode.loop);
      } catch (e) {
        if (_isBenignAudioError(e)) {
          _silentDegrade();
          await _safeDisposePlayer(player);
          return;
        }
        _degrade(e);
        await _safeDisposePlayer(player);
        return;
      }
      if (_disposed || seq != _contextSeq) {
        await _safeDisposePlayer(player);
        return;
      }
      _musicPlayers[context.asset] = player;
      try {
        await player.setVolume(_musicEffectiveVolume());
      } catch (e) {
        if (_isBenignAudioError(e)) {
          _silentDegrade();
        } else {
          _degrade(e);
          return;
        }
      }
      if (_disposed || seq != _contextSeq) {
        _musicPlayers.remove(context.asset);
        await _safeDisposePlayer(player);
        return;
      }
      await player.play(AssetSource('audio/${context.asset}'));
      if (_disposed || seq != _contextSeq) {
        _musicPlayers.remove(context.asset);
        await _safeDisposePlayer(player);
        return;
      }
      _currentContext = context;
    } catch (e) {
      if (player != null) {
        _musicPlayers.remove(context.asset);
        await _safeDisposePlayer(player);
      }
      if (_isBenignAudioError(e)) {
        _silentDegrade();
      } else {
        _degrade(e);
      }
    }
  }

  Future<void> stopMusic() async {
    if (_stoppingMusic) return;
    _stoppingMusic = true;
    try {
      final players = Map<String, AudioPlayer>.from(_musicPlayers);
      _musicPlayers.clear();
      _currentContext = null;
      for (final p in players.values) {
        try {
          await p.stop();
        } catch (e) {
          if (!_isBenignAudioError(e)) {
            debugPrint('AudioManager.stopMusic stop degraded: $e');
          }
        }
        await _safeDisposePlayer(p);
      }
    } catch (e) {
      if (!_isBenignAudioError(e)) {
        debugPrint('AudioManager.stopMusic degraded: $e');
      }
    } finally {
      _stoppingMusic = false;
    }
  }

  // Lifecycle helpers
  Future<void> pauseForBackground() async {
    for (final p in _musicPlayers.values) {
      try {
        await p.pause();
      } catch (_) {}
    }
    try {
      await _sfxPlayer?.pause();
    } catch (_) {}
    try {
      await _typingPlayer?.pause();
    } catch (_) {}
  }

  Future<void> resumeFromBackground() async {
    if (!musicEnabled || musicVolume == 0 || _disposed || _platformBroken) return;
    if (_currentContext != null) {
      final player = _musicPlayers[_currentContext!.asset];
      if (player != null) {
        try {
          await player.resume();
          return;
        } catch (_) {}
      }
      // If resume fails, replay context
      final ctx = _currentContext!;
      _currentContext = null;
      await playContext(ctx);
    }
  }

  bool _isBenignAudioError(Object e) {
    final s = e.toString();
    return s.contains('Stream closed') ||
        s.contains('Stream has already been listened') ||
        s.contains('Bad state') ||
        s.contains('has been closed') ||
        s.contains('disposed') ||
        s.contains('MissingPluginException') ||
        s.contains('No implementation found') ||
        s.contains('PlatformException') && s.contains('closed');
  }

  void _silentDegrade() {
    _platformBroken = true;
  }

  void _degrade(Object e) {
    if (_isBenignAudioError(e)) {
      _silentDegrade();
      return;
    }
    _platformBroken = true;
    debugPrint('AudioManager degraded to silent mode: $e');
  }

  Future<void> _safeDisposePlayer(AudioPlayer p) async {
    try {
      await p.dispose();
    } catch (e) {
      if (!_isBenignAudioError(e)) {
        debugPrint('AudioManager dispose degraded: $e');
      }
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _contextSeq++;
    _typingInactivityTimer?.cancel();
    _typingInactivityTimer = null;
    await stopMusic();
    try {
      await _sfxPlayer?.stop();
    } catch (e) {
      if (!_isBenignAudioError(e)) debugPrint('AudioManager sfx stop: $e');
    }
    if (_sfxPlayer != null) {
      await _safeDisposePlayer(_sfxPlayer!);
    }
    _sfxPlayer = null;
    if (_typingPlayer != null) {
      try {
        await _typingPlayer?.stop();
      } catch (_) {}
      await _safeDisposePlayer(_typingPlayer!);
      _typingPlayer = null;
    }
  }
}
