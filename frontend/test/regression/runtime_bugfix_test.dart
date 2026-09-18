import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gamelearn_app/core/audio/audio_manager.dart';
import 'package:gamelearn_app/core/providers.dart';
import 'package:gamelearn_app/features/profile/presentation/settings_screen.dart';
import 'package:gamelearn_app/shared/widgets/premium_settings.dart';

import '../helpers/fake_backend.dart';

void main() {
  group('Runtime bugfix regression', () {
    testWidgets('SwitchTile and logout row have Material ancestor with transparent clip',
        (tester) async {
      // Pump isolated SwitchTile and the premium logout row as they appear
      // inside GameCard/SectionCard. This validates the fix for DecoratedBox
      // ink assert without needing full SettingsScreen auth. SwitchTile now
      // renders the premium row (Switch, not SwitchListTile) and sign-out
      // renders PremiumAccountRow — both keep the transparent Material +
      // antiAlias clip contract.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const SwitchTile(
                  icon: Icons.music_note_rounded,
                  title: 'Background music',
                  subtitle: 'Ambient adventure soundtrack',
                  value: true,
                  onChanged: _noop,
                ),
                PremiumAccountRow(
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  subtitle: 'Ends this session on this device',
                  danger: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final logoutRows = find.byType(PremiumAccountRow);
      expect(logoutRows, findsOneWidget);
      final rowMaterials = find.descendant(
        of: logoutRows,
        matching: find.byType(Material),
      );
      expect(rowMaterials, findsWidgets,
          reason: 'PremiumAccountRow must bring Material for ink');
      expect(
        tester
            .widgetList<Material>(rowMaterials)
            .any((m) => m.color == Colors.transparent && m.clipBehavior == Clip.antiAlias),
        isTrue,
        reason: 'Row Material must be transparent + antiAlias clipped',
      );

      final switches = find.byType(Switch);
      expect(switches, findsWidgets);
      for (final e in tester.widgetList<Switch>(switches)) {
        final ctx = tester.element(find.byWidget(e));
        final materials = <Material>[];
        ctx.visitAncestorElements((el) {
          final w = el.widget;
          if (w is Material) materials.add(w);
          return true;
        });
        expect(materials, isNotEmpty,
            reason: 'Switch must have Material ancestor');
        expect(
          materials.any((m) =>
              m.color == Colors.transparent &&
              m.clipBehavior == Clip.antiAlias),
          isTrue,
          reason: 'SwitchTile Material must be transparent + antiAlias clipped',
        );
      }
    });

    testWidgets('SettingsScreen renders without ListTile ink assert and preserves tap',
        (tester) async {
      // Full screen test using ProviderScope with required overrides.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              await _fakePrefs(),
            ),
            audioManagerProvider.overrideWith((ref) => SilentAudioManager()),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'No Flutter assert like ListTile ink invisible should fire');
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.text('Background music'), findsOneWidget);
      // Ripple/ink visibility would throw assert if broken; pump tap to verify no exception
      await tester.ensureVisible(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Sign out?'), findsOneWidget);
    });

    test('AudioManager lifecycle: repeated init, double dispose, stream-closed degrade silent',
        () async {
      final audio = AudioManager(prefs: null);
      await audio.play(Sfx.buttonTap);
      await audio.play(Sfx.buttonTap);
      await audio.playContext(MusicContext.menu);
      await audio.playContext(MusicContext.menu);
      await audio.playContext(MusicContext.dashboard);
      await audio.dispose();
      await audio.dispose();
      await audio.play(Sfx.correct);
      await audio.playContext(MusicContext.quiz);
      await audio.stopMusic();
      expect(true, isTrue);
    });

    test('AudioManager handles rapid playContext switching without stream-closed exception',
        () async {
      final audio = AudioManager(prefs: null);
      final f1 = audio.playContext(MusicContext.menu);
      final f2 = audio.playContext(MusicContext.adventure);
      await Future.wait([f1, f2]);
      await audio.stopMusic();
      await audio.dispose();
    });
  });
}

void _noop(bool v) {}

Future<SharedPreferences> _fakePrefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}


