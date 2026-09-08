import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gamelearn_app/core/audio/audio_manager.dart';

/// Regression test for the web audio outage where
/// `assets/audio/music/gamelearnai_ambient_theme.mp3` (and
/// `assets/audio/sfx/keyboard_typing_faast.wav`) were missing from the
/// release bundle: the pubspec declared only `assets/audio/`, which did not
/// pull in nested subdirectories, so Chrome failed with
/// MEDIA_ELEMENT_ERROR Code 4 ("Failed to set source").
///
/// These tests run against the real [Sfx]/[MusicContext] enums, the real
/// pubspec declarations, and the real files on disk, so any future asset
/// move/rename that breaks the bundle fails loudly here instead of
/// silently degrading to silent mode in production.
void main() {
  List<String> declaredAssetDirs() {
    final lines = File('pubspec.yaml').readAsLinesSync();
    final dirs = <String>[];
    var inAssets = false;
    for (final line in lines) {
      if (!inAssets) {
        if (line.trim() == 'assets:') inAssets = true;
        continue;
      }
      final trimmed = line.trim();
      if (trimmed.startsWith('- ')) {
        dirs.add(trimmed.substring(2).trim());
      } else if (trimmed.isNotEmpty && !line.startsWith(' ')) {
        break;
      }
    }
    return dirs;
  }

  bool isCovered(String assetPath, List<String> dirs) {
    // Flutter matches a directory entry against nested files; an entry
    // covers a file when the file path starts with the entry prefix.
    // A parent entry alone is NOT trusted to cover nested subdirectories
    // (that assumption caused the production outage), so coverage requires
    // the deepest applicable declared directory to equal the file's own
    // directory.
    final fileDir = 'assets/${assetPath.split('/').sublist(0, assetPath.split('/').length - 1).join('/')}';
    return dirs.any((d) {
      final dir = d.endsWith('/') ? d.substring(0, d.length - 1) : d;
      return dir == fileDir || dir == 'assets/$assetPath';
    });
  }

  group('Audio production assets (web bundle regression)', () {
    test('every Sfx asset file exists on disk', () {
      for (final sfx in Sfx.values) {
        final file = File('assets/audio/${sfx.asset}');
        expect(file.existsSync(), isTrue,
            reason: 'missing SFX asset: assets/audio/${sfx.asset}');
        expect(file.lengthSync(), greaterThan(0),
            reason: 'empty SFX asset: assets/audio/${sfx.asset}');
      }
    });

    test('every MusicContext asset file exists on disk', () {
      for (final ctx in MusicContext.values) {
        final file = File('assets/audio/${ctx.asset}');
        expect(file.existsSync(), isTrue,
            reason: 'missing music asset: assets/audio/${ctx.asset}');
        expect(file.lengthSync(), greaterThan(0),
            reason: 'empty music asset: assets/audio/${ctx.asset}');
      }
    });

    test('ambient theme is a real MP3 (MPEG frame sync, not renamed)', () {
      final bytes =
          File('assets/audio/music/gamelearnai_ambient_theme.mp3')
              .readAsBytesSync();
      // First frame header: 0xFF 0xFB = MPEG-1 Layer III sync.
      expect(bytes.length, greaterThan(1000));
      expect(bytes[0], equals(0xFF));
      expect(bytes[1] & 0xE0, equals(0xE0));
    });

    test('pubspec declares cover every audio asset directory', () {
      final dirs = declaredAssetDirs();
      final assets = <String>[
        for (final sfx in Sfx.values) 'audio/${sfx.asset}',
        for (final ctx in MusicContext.values) 'audio/${ctx.asset}',
      ];
      for (final asset in assets) {
        expect(isCovered(asset, dirs), isTrue,
            reason:
                'pubspec asset declarations $dirs do not explicitly cover $asset; '
                'nested subdirectories must be declared or the file is dropped from release bundles');
      }
    });
  });
}
