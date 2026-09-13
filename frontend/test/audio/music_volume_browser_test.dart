@TestOn('browser')
// Browser-only verification of the music-volume bug fix on the REAL web
// audio stack (audioplayers_web): the effective music volume lives in a
// WebAudio GainNode per player, so this test hooks AudioContext.createGain
// to observe the exact values the active player receives when the Settings
// slider (real VolumeTile wiring) moves. No fake players, no mocks.
//
// Run: flutter test --platform chrome test/audio/music_volume_browser_test.dart
// Plain `flutter test` skips this file.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gamelearn_app/core/audio/audio_manager.dart';
import 'package:gamelearn_app/features/profile/presentation/settings_screen.dart';

/// Installs a GainNode registry + clears localStorage. Must run before any
/// AudioManager/player is created.
void _installAudioProbe() {
  globalContext.callMethod(
    'eval'.toJS,
    r'''
      window.__gainNodes = [];
      window.__gainSeq = 0;
      (function hook() {
        const proto = window.AudioContext && window.AudioContext.prototype;
        if (!proto || !proto.createGain || proto.__gainHooked) return;
        proto.__gainHooked = true;
        const orig = proto.createGain;
        proto.createGain = function(...args) {
          const node = orig.apply(this, args);
          node.__gid = window.__gainSeq++;
          window.__gainNodes.push(node);
          return node;
        };
      })();
      window.localStorage.clear();
    '''.toJS,
  );
}

JSArray get _gainNodes =>
    globalContext.getProperty('__gainNodes'.toJS) as JSArray;

int gainNodeCount() => _gainNodes.length;

double gainValue(int index) {
  final node = _gainNodes[index] as JSObject;
  final gain = node.getProperty('gain'.toJS) as JSObject;
  return (gain.getProperty('value'.toJS) as JSNumber).toDartDouble;
}

int gainId(int index) {
  final node = _gainNodes[index] as JSObject;
  return (node.getProperty('__gid'.toJS) as JSNumber).toDartInt;
}

/// Minimal host mirroring the SettingsScreen Music Volume wiring exactly:
/// Slider value comes from AudioManager and onChanged forwards to it.
class _VolumeHarness extends StatefulWidget {
  const _VolumeHarness({required this.audio});

  final AudioManager audio;

  @override
  State<_VolumeHarness> createState() => _VolumeHarnessState();
}

class _VolumeHarnessState extends State<_VolumeHarness> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: VolumeTile(
          icon: Icons.music_note_rounded,
          title: 'Music Volume',
          subtitle: '${(widget.audio.musicVolume * 100).round()}%',
          value: widget.audio.musicVolume,
          enabled: widget.audio.musicEnabled,
          onChanged: (v) async {
            await widget.audio.setMusicVolume(v);
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }
}

void main() {
  testWidgets('browser: music slider drives the live web player volume',
      (tester) async {
    _installAudioProbe();
    final prefs = await SharedPreferences.getInstance();
    final audio = AudioManager(prefs: prefs);

    // Dashboard-style music starts at the documented effective volume.
    await audio.playContext(MusicContext.menu);
    expect(gainNodeCount(), 1);
    expect(gainValue(0), closeTo(0.16, 0.02));
    final int liveId = gainId(0);

    await tester.pumpWidget(_VolumeHarness(audio: audio));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsOneWidget);

    // Drag the real slider down: the ACTIVE web player must get quieter
    // without being recreated (same gain node, same track).
    await tester.drag(find.byType(Slider), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(gainNodeCount(), 1);
    expect(gainId(0), liveId);
    final double quieter = gainValue(0);
    expect(quieter, lessThan(0.16));
    expect(quieter, greaterThan(0.0));

    // Drag back up: louder again, still the same player.
    await tester.drag(find.byType(Slider), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(gainNodeCount(), 1);
    expect(gainId(0), liveId);
    expect(gainValue(0), greaterThan(quieter));

    // Tap the far left edge: silent. Far right edge: resumes, same player.
    final Rect track = tester.getRect(find.byType(Slider));
    await tester.tapAt(Offset(track.left + 4, track.center.dy));
    await tester.pumpAndSettle();
    expect(gainValue(0), closeTo(0.0, 0.005));
    await tester.tapAt(Offset(track.right - 4, track.center.dy));
    await tester.pumpAndSettle();
    expect(gainNodeCount(), 1);
    expect(gainId(0), liveId);
    expect(gainValue(0), greaterThan(0.1));

    // Persisted value survives a fresh manager (real localStorage round-trip).
    final double stored = audio.musicVolume;
    final AudioManager restarted =
        AudioManager(prefs: await SharedPreferences.getInstance());
    expect(restarted.musicVolume, closeTo(stored, 1e-9));

    // SFX stays independent on the real web path: its own player/gain node
    // at 0.9 * sfxVolume while the music node is untouched.
    final double musicNow = gainValue(0);
    await audio.setSfxVolume(0.3);
    await audio.play(Sfx.buttonTap);
    await audio.play(Sfx.correct);
    expect(gainNodeCount(), greaterThanOrEqualTo(2));
    final double sfxGain = gainValue(gainNodeCount() - 1);
    expect(sfxGain, closeTo(0.9 * 0.3, 0.03));
    expect(gainValue(0), closeTo(musicNow, 1e-9));

    // Disable stops; re-enable resumes a player at the stored music volume.
    await audio.setMusicEnabled(false);
    await audio.setMusicEnabled(true);
    expect(gainNodeCount(), greaterThanOrEqualTo(2));
    expect(gainValue(gainNodeCount() - 1), closeTo(0.16 * stored, 0.03));

    await audio.dispose();
  });
}
