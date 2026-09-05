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
  bool _disposed = false;
  int _contextSeq = 0;
  bool _stoppingMusic = false;

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
    if (!sfxEnabled || _platformBroken || _disposed) return;
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
      // Each operation is individually guarded; a closed stream must not
      // crash or spam logs. _isStreamClosed errors degrade silently.
      try {
        await _sfxPlayer!.setVolume(0.9);
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

  // ---- Music --------------------------------------------------------------

  Future<void> playContext(MusicContext context) async {
    if (!musicEnabled || _platformBroken || _disposed) return;
    if (_currentContext == context) return;
    final int seq = ++_contextSeq;
    // Stop previous music first; if a newer request arrives while stopping,
    // abort this attempt so the latest context wins.
    try {
      await stopMusic();
    } catch (_) {
      // stopMusic already guards; ignore here.
    }
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
      // Register early so stopMusic can dispose it if a concurrent
      // playContext/stop/dispose arrives.
      _musicPlayers[context.asset] = player;
      try {
        await player.setVolume(0.16);
      } catch (e) {
        if (_isBenignAudioError(e)) {
          _silentDegrade();
          // Keep player registered but silent; do not throw.
        } else {
          _degrade(e);
          return;
        }
      }
      if (_disposed || seq != _contextSeq) {
        // Stale request: clean up this player.
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
      // Ensure partially-created player does not leak.
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
    // Increment seq to invalidate any in-flight playContext that has not
    // yet finished preparation; caller playContext already captures seq.
    // Do not increment here for explicit stopMusic from UI — but guard
    // against race where stopMusic is called concurrently with playContext.
    try {
      // Copy and clear atomically to avoid concurrent modification
      // if stopMusic is called re-entrantly from playContext.
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

  bool _isBenignAudioError(Object e) {
    final s = e.toString();
    // audioplayers throws "Stream closed before it got prepared",
    // "Player has been disposed", StateError/Bad state etc. when
    // dispose races with prepare. These are expected on web/hot-reload
    // and should degrade silently rather than spamming logs.
    // MissingPluginException is benign in tests / unsupported platforms.
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
    // Graceful silent fallback — no noisy debugPrint for benign
    // browser/platform races (autoplay blocked, stream closed on
    // dispose, etc.). App remains fully functional.
  }

  void _degrade(Object e) {
    if (_isBenignAudioError(e)) {
      _silentDegrade();
      return;
    }
    // One hard failure (missing asset/plugin) disables audio for the session
    // instead of spamming errors. App remains fully functional.
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
    // Invalidate any pending playContext.
    _contextSeq++;
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
  }
}
