import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gamelearn_app/core/audio/audio_manager.dart';

/// In-memory stand-in for [AudioPlayer]: records volume/play/stop/dispose
/// calls instead of touching platform channels.
class FakeAudioPlayer extends AudioPlayer {
  FakeAudioPlayer();

  final List<double> volumeCalls = [];
  double? get lastVolume =>
      volumeCalls.isEmpty ? null : volumeCalls.last;

  int playCount = 0;
  Source? lastSource;
  int stopCount = 0;
  int pauseCount = 0;
  int resumeCount = 0;
  int disposeCount = 0;
  bool releaseModeLoop = false;

  @override
  PlayerState get state => PlayerState.stopped;

  @override
  Future<void> setVolume(double volume) async {
    volumeCalls.add(volume);
  }

  @override
  Future<void> setReleaseMode(ReleaseMode releaseMode) async {
    releaseModeLoop = releaseMode == ReleaseMode.loop;
  }

  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    playCount++;
    lastSource = source;
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<void> pause() async {
    pauseCount++;
  }

  @override
  Future<void> resume() async {
    resumeCount++;
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
  }
}

class FakePlayerScope {
  FakePlayerScope(this.prefs);

  final SharedPreferences prefs;
  final List<FakeAudioPlayer> created = [];

  AudioManager manager() => AudioManager(
        prefs: prefs,
        playerFactory: () {
          final p = FakeAudioPlayer();
          created.add(p);
          return p;
        },
      );

  List<FakeAudioPlayer> get musicPlayers =>
      created.where((p) => p.releaseModeLoop).toList();
}

Future<FakePlayerScope> _scope(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return FakePlayerScope(prefs);
}

void main() {
  // FakeAudioPlayer extends the real AudioPlayer, whose constructor touches
  // platform channels; the test binding must exist before any construction.
  TestWidgetsFlutterBinding.ensureInitialized();

  // The fake extends the real AudioPlayer, whose constructor performs
  // fire-and-forget platform init/create calls. Neutralize them so no
  // MissingPluginException escapes as an unhandled async error. All
  // playback/volume methods under test are overridden by the fake and never
  // reach the platform. (Mock handlers are reset between tests by flutter_test,
  // hence setUp instead of setUpAll.)
  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall call) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall call) async => null,
    );
  });

  group('Music volume live control (regression)', () {
    test('setMusicVolume updates state and persists', () async {
      final scope = await _scope({});
      final audio = scope.manager();

      await audio.setMusicVolume(0.5);

      expect(audio.musicVolume, 0.5);
      expect(scope.prefs.getDouble('pref_music_volume'), 0.5);
    });

    test('slider change immediately updates the active player, no restart',
        () async {
      final scope = await _scope({});
      final audio = scope.manager();

      await audio.playContext(MusicContext.menu);
      expect(scope.musicPlayers, hasLength(1));
      final player = scope.musicPlayers.single;
      expect(player.lastVolume, closeTo(0.16 * 1.0, 1e-9));
      final playsBefore = player.playCount;

      await audio.setMusicVolume(0.5);
      expect(player.lastVolume, closeTo(0.16 * 0.5, 1e-9));

      await audio.setMusicVolume(1.0);
      expect(player.lastVolume, closeTo(0.16 * 1.0, 1e-9));

      // Volume change must not recreate or restart the track.
      expect(player.playCount, playsBefore);
      expect(scope.musicPlayers, hasLength(1));
    });

    test('volume 0 silences in place; raising restores without restart',
        () async {
      final scope = await _scope({});
      final audio = scope.manager();

      await audio.playContext(MusicContext.menu);
      final player = scope.musicPlayers.single;

      await audio.setMusicVolume(0.0);
      expect(player.lastVolume, 0.0);
      // Player is kept (silent), not stopped/disposed: position preserved.
      expect(player.stopCount, 0);
      expect(player.disposeCount, 0);

      await audio.setMusicVolume(0.6);
      expect(player.lastVolume, closeTo(0.16 * 0.6, 1e-9));
      expect(player.playCount, 1);
    });

    test('raising volume from 0 with no active player resumes playback',
        () async {
      final scope = await _scope({'pref_music_volume': 0.0});
      final audio = scope.manager();
      expect(audio.musicVolume, 0.0);

      // Nothing can start while muted; the request is only remembered.
      await audio.playContext(MusicContext.quiz);
      expect(scope.musicPlayers, isEmpty);

      await audio.setMusicVolume(0.8);
      expect(scope.musicPlayers, hasLength(1));
      final player = scope.musicPlayers.single;
      expect(player.playCount, 1);
      expect(player.lastVolume, closeTo(0.16 * 0.8, 1e-9));
      expect(
        (player.lastSource as AssetSource).path,
        contains('music_quiz.wav'),
      );
    });

    test('navigating while muted resumes the current screen track, not stale',
        () async {
      final scope = await _scope({'pref_music_volume': 0.0});
      final audio = scope.manager();

      await audio.playContext(MusicContext.dashboard);
      await audio.playContext(MusicContext.quiz);

      await audio.setMusicVolume(0.5);
      expect(scope.musicPlayers, hasLength(1));
      final player = scope.musicPlayers.single;
      expect(
        (player.lastSource as AssetSource).path,
        contains('music_quiz.wav'),
      );
      expect(player.lastVolume, closeTo(0.16 * 0.5, 1e-9));
    });

    test('music and SFX volumes stay independent', () async {
      final scope = await _scope({});
      final audio = scope.manager();

      await audio.playContext(MusicContext.menu);
      final music = scope.musicPlayers.single;

      await audio.setMusicVolume(0.2);
      expect(audio.sfxVolume, 1.0);
      expect(music.lastVolume, closeTo(0.16 * 0.2, 1e-9));

      await audio.play(Sfx.buttonTap);
      await audio.play(Sfx.correct);
      final sfxPlayer =
          scope.created.firstWhere((p) => !p.releaseModeLoop);
      expect(sfxPlayer.lastVolume, closeTo(0.9 * 1.0, 1e-9));

      await audio.setSfxVolume(0.2);
      expect(audio.musicVolume, 0.2);
      // Music player untouched by the SFX change.
      expect(music.lastVolume, closeTo(0.16 * 0.2, 1e-9));
      expect(scope.prefs.getDouble('pref_sfx_volume'), 0.2);
      expect(scope.prefs.getDouble('pref_music_volume'), 0.2);
    });

    test('persisted music volume is restored and used after restart',
        () async {
      final scope = await _scope({'pref_music_volume': 0.4});
      final audio = scope.manager();
      expect(audio.musicVolume, 0.4);

      await audio.playContext(MusicContext.menu);
      expect(
        scope.musicPlayers.single.lastVolume,
        closeTo(0.16 * 0.4, 1e-9),
      );

      // Simulate leaving settings / app restart with the same store.
      final restarted = scope.manager();
      expect(restarted.musicVolume, 0.4);
    });

    test('disable stops music; re-enable resumes stored volume', () async {
      final scope = await _scope({});
      final audio = scope.manager();

      await audio.playContext(MusicContext.menu);
      final first = scope.musicPlayers.single;
      await audio.setMusicVolume(0.5);

      await audio.setMusicEnabled(false);
      expect(audio.musicEnabled, isFalse);
      expect(first.stopCount, greaterThanOrEqualTo(1));

      await audio.setMusicEnabled(true);
      expect(scope.musicPlayers, hasLength(2));
      final resumed = scope.musicPlayers.last;
      expect(resumed.playCount, 1);
      expect(resumed.lastVolume, closeTo(0.16 * 0.5, 1e-9));
    });

    test('volume is clamped to 0..1', () async {
      final scope = await _scope({});
      final audio = scope.manager();

      await audio.setMusicVolume(2.0);
      expect(audio.musicVolume, 1.0);
      await audio.setMusicVolume(-1.0);
      expect(audio.musicVolume, 0.0);
    });

    test('switching context disposes the old player, keeps a single live one',
        () async {
      final scope = await _scope({});
      final audio = scope.manager();

      await audio.playContext(MusicContext.menu);
      final first = scope.musicPlayers.single;

      await audio.playContext(MusicContext.quiz);
      expect(first.disposeCount, 1);
      expect(scope.musicPlayers, hasLength(2));
      final live = scope.musicPlayers.last;
      expect(live.playCount, 1);
      expect(
        (live.lastSource as AssetSource).path,
        contains('music_quiz.wav'),
      );
    });

    test('rapid switching never orphans a player outside the registry',
        () async {
      final scope = await _scope({});
      final audio = scope.manager();

      final f1 = audio.playContext(MusicContext.menu);
      final f2 = audio.playContext(MusicContext.adventure);
      await Future.wait([f1, f2]);

      // Every created music player is either disposed or holds the latest
      // effective volume: no silent orphan stuck at an old volume.
      await audio.setMusicVolume(0.5);
      for (final p in scope.musicPlayers) {
        if (p.disposeCount == 0) {
          expect(p.lastVolume, closeTo(0.16 * 0.5, 1e-9));
        }
      }
      final live = scope.musicPlayers.where((p) => p.disposeCount == 0);
      expect(live.length, lessThanOrEqualTo(1));
    });

    test('volume change while disabled never starts playback (D)', () async {
      final scope = await _scope({});
      final audio = scope.manager();

      await audio.playContext(MusicContext.menu);
      expect(scope.musicPlayers, hasLength(1));

      await audio.setMusicEnabled(false);
      expect(audio.musicEnabled, isFalse);
      final stopped = scope.musicPlayers.single;
      expect(stopped.stopCount, greaterThanOrEqualTo(1));

      // Slider moves while disabled: persisted, but stays silent.
      await audio.setMusicVolume(0.7);
      expect(audio.musicVolume, 0.7);
      expect(scope.prefs.getDouble('pref_music_volume'), 0.7);
      expect(scope.musicPlayers, hasLength(1));
      expect(scope.musicPlayers.single.playCount, 1);

      // Re-enable resumes a fresh player at the latest stored volume.
      await audio.setMusicEnabled(true);
      expect(scope.musicPlayers, hasLength(2));
      final resumed = scope.musicPlayers.last;
      expect(resumed.playCount, 1);
      expect(resumed.lastVolume, closeTo(0.16 * 0.7, 1e-9));
    });

    test('context switch uses the latest volume (F)', () async {
      final scope = await _scope({});
      final audio = scope.manager();

      await audio.playContext(MusicContext.menu);
      final first = scope.musicPlayers.single;
      expect(first.lastVolume, closeTo(0.16 * 1.0, 1e-9));

      await audio.setMusicVolume(0.25);
      await audio.playContext(MusicContext.quiz);

      expect(first.disposeCount, 1);
      expect(scope.musicPlayers, hasLength(2));
      final live = scope.musicPlayers.last;
      expect(live.playCount, 1);
      expect(live.lastVolume, closeTo(0.16 * 0.25, 1e-9));
      expect(
        (live.lastSource as AssetSource).path,
        contains('music_quiz.wav'),
      );
    });

    test('repeated volume changes never duplicate players (G)', () async {
      final scope = await _scope({});
      final audio = scope.manager();

      await audio.playContext(MusicContext.menu);
      final player = scope.musicPlayers.single;
      final playsBefore = player.playCount;

      for (var i = 0; i <= 10; i++) {
        final v = i / 10.0;
        await audio.setMusicVolume(v);
        expect(player.lastVolume, closeTo(0.16 * v, 1e-9));
      }

      expect(scope.musicPlayers, hasLength(1));
      expect(player.playCount, playsBefore);
      expect(player.stopCount, 0);
      expect(player.disposeCount, 0);
      expect(scope.prefs.getDouble('pref_music_volume'), 1.0);
    });

    test('pause/resume preserves volume without duplicating players (I)',
        () async {
      final scope = await _scope({});
      final audio = scope.manager();

      await audio.playContext(MusicContext.menu);
      final player = scope.musicPlayers.single;

      await audio.pauseForBackground();
      expect(player.pauseCount, 1);

      // Slider moves while paused: pushed to the paused player in place.
      await audio.setMusicVolume(0.4);
      expect(player.lastVolume, closeTo(0.16 * 0.4, 1e-9));
      expect(player.playCount, 1);

      await audio.resumeFromBackground();
      expect(player.resumeCount, 1);
      expect(player.playCount, 1);
      expect(scope.musicPlayers, hasLength(1));
    });

    test('resume stays silent when muted or disabled (I)', () async {
      final scope = await _scope({});
      final audio = scope.manager();

      await audio.playContext(MusicContext.menu);
      final player = scope.musicPlayers.single;

      await audio.setMusicVolume(0.0);
      await audio.pauseForBackground();
      await audio.resumeFromBackground();
      expect(player.resumeCount, 0);
      expect(player.playCount, 1);

      await audio.setMusicVolume(0.5);
      await audio.setMusicEnabled(false);
      await audio.resumeFromBackground();
      // Disabled: no player revived, nothing recreated.
      expect(scope.musicPlayers, hasLength(1));
      expect(scope.musicPlayers.single.playCount, 1);
    });

    test('dispose stops music; later volume change is safe (I)', () async {
      final scope = await _scope({});
      final audio = scope.manager();

      await audio.playContext(MusicContext.menu);
      final player = scope.musicPlayers.single;

      await audio.dispose();
      expect(player.disposeCount, greaterThanOrEqualTo(1));

      // Must persist without touching players or throwing.
      await audio.setMusicVolume(0.5);
      expect(audio.musicVolume, 0.5);
      expect(scope.prefs.getDouble('pref_music_volume'), 0.5);
      expect(scope.musicPlayers, hasLength(1));

      // A fresh manager restores the persisted value.
      final restarted = scope.manager();
      expect(restarted.musicVolume, 0.5);
    });
  });
}
