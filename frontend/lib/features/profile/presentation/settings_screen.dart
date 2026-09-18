import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/audio/audio_manager.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_controller.dart';
import '../../auth/providers/session_controller.dart';
import '../../../shared/widgets/game_card.dart';
import '../../../shared/widgets/cinematic_scenery.dart';
import '../../../shared/widgets/cinematic_surfaces.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/premium_settings.dart';
import '../../../shared/widgets/responsive_layout.dart';

/// Local preferences only (audio, haptics). Server-side settings do not
/// exist yet (USER-002 is deferred), so nothing here claims to be synced.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final audio = ref.watch(audioManagerProvider);
    final themeMode = ref.watch(themeControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      // Title-less bar: back affordance stays; the "Settings" title lives
      // once in the cinematic hero below.
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          // ── Cinematic settings header (reference: illustrated header,
          // "Customize your experience") ──
          CinematicHero(
            accent: AppColors.primary,
            badge: 'Settings',
            badgeIcon: Icons.tune_rounded,
            scene: ScenePalette.indigo,
            sceneSeed: 99,
            // No Nova here: Settings must stay animation-free so taps
            // settle instantly (runtime regression contract); the scene
            // art carries the cinematic identity.
            title: Text(
              'CUSTOMIZE YOUR EXPERIENCE',
              style: TextStyle(
                fontFamily: AppTypography.displayFamily,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: isDark
                    ? AppColors.textPrimary
                    : AppLightColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'A better you, for a brighter tomorrow.',
              style: TextStyle(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: isDark
                    ? AppColors.textSecondary
                    : AppLightColors.textSecondary,
              ),
            ),
            tagline: 'GOOD THINGS\nTAKE TIME',
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'APPEARANCE',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Theme',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppTypography.bodyFamily,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          themeMode == ThemeMode.system
                              ? 'System'
                              : themeMode == ThemeMode.light
                                  ? 'Light'
                                  : 'Dark',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? AppColors.textSecondary
                                : AppLightColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    PremiumSegmentedControl<ThemeMode>(
                      segments: const [
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto_rounded, size: 16),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode_rounded, size: 16),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode_rounded, size: 16),
                        ),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (Set<ThemeMode> s) {
                        ref
                            .read(themeControllerProvider.notifier)
                            .set(s.first);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'System follows your device setting. Light is a true light theme — not inverted dark.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textTertiary
                            : AppLightColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'AUDIO',
            children: [
              SwitchTile(
                icon: Icons.music_note_rounded,
                title: 'Background music',
                subtitle: 'Ambient adventure soundtrack',
                value: audio.musicEnabled,
                onChanged: (v) async {
                  // setMusicEnabled already resumes the last requested
                  // context; do not force MusicContext.menu here (that would
                  // restart/switch the track unnecessarily).
                  await audio.setMusicEnabled(v);
                  setState(() {});
                },
              ),
              VolumeTile(
                icon: Icons.music_note_rounded,
                title: 'Music Volume',
                subtitle: audio.musicEnabled
                    ? '${(audio.musicVolume * 100).round()}% • ${audio.musicVolume == 0 ? 'muted' : audio.musicVolume < 0.33 ? 'quiet' : audio.musicVolume < 0.66 ? 'medium' : audio.musicVolume < 0.9 ? 'loud' : 'maximum'}'
                    : 'Music is disabled',
                value: audio.musicVolume,
                enabled: audio.musicEnabled,
                onChanged: (v) async {
                  await audio.setMusicVolume(v);
                  setState(() {});
                },
              ),
              SwitchTile(
                icon: Icons.volume_up_rounded,
                title: 'Sound effects',
                subtitle: 'Taps, rewards and celebrations',
                value: audio.sfxEnabled,
                onChanged: (v) async {
                  await audio.setSfxEnabled(v);
                  if (v) audio.play(Sfx.buttonConfirm);
                  setState(() {});
                },
              ),
              VolumeTile(
                icon: Icons.volume_up_rounded,
                title: 'Sound Effects Volume',
                subtitle: audio.sfxEnabled
                    ? '${(audio.sfxVolume * 100).round()}% • ${audio.sfxVolume == 0 ? 'muted' : audio.sfxVolume < 0.33 ? 'quiet' : audio.sfxVolume < 0.66 ? 'medium' : audio.sfxVolume < 0.9 ? 'loud' : 'maximum'}'
                    : 'Sound effects are disabled',
                value: audio.sfxVolume,
                enabled: audio.sfxEnabled,
                onChanged: (v) async {
                  await audio.setSfxVolume(v);
                  if (v > 0) audio.play(Sfx.buttonTap);
                  setState(() {});
                },
              ),
              SwitchTile(
                icon: Icons.vibration_rounded,
                title: 'Haptic feedback',
                subtitle: 'Vibration on key interactions',
                value: audio.hapticsEnabled,
                onChanged: (v) async {
                  await audio.setHapticsEnabled(v);
                  ref.read(hapticsProvider).enabled = v;
                  if (v) ref.read(hapticsProvider).tap();
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'ACCOUNT',
            children: [
              PremiumAccountRow(
                icon: Icons.logout_rounded,
                title: 'Sign out',
                subtitle: 'Ends this session on this device',
                danger: true,
                semanticLabel: 'Sign out. Ends this session on this device',
                onTap: () => _confirmLogout(context),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              'GameLearn AI · ${ref.watch(appConfigInfoProvider).env.toUpperCase()} · '
              '${ref.watch(appConfigInfoProvider).baseUrl}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                color: isDark
                    ? AppColors.textTertiary
                    : AppLightColors.textTertiary,
              ),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showPremiumDialog<bool>(
      context: context,
      builder: (dialogContext) => CinematicDialog(
        accent: AppColors.error,
        title: const Text('Sign out?'),
        content: const Text('Your progress lives safely on the servers.'),
        actions: [
          PremiumDialogActions(
            primaryLabel: 'Sign out',
            onPrimary: () => Navigator.of(dialogContext).pop(true),
            secondaryLabel: 'Cancel',
            onSecondary: () => Navigator.of(dialogContext).pop(false),
            accent: AppColors.error,
            destructive: true,
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref.read(hapticsProvider).select();
      await ref.read(sessionProvider.notifier).logout();
      if (context.mounted) {
        ref.read(audioManagerProvider).stopMusic();
        context.go(Routes.login);
      }
    }
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => GameCard(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textTertiary
                  : AppLightColors.textTertiary,
            ),
          ),
        ),
        ...children,
      ],
    ),
  );
}

/// Legacy name kept for test compatibility — delegates to the premium
/// settings row so the rendered UI stays in the GameLearnAI language.
class VolumeTile extends StatelessWidget {
  const VolumeTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return PremiumSliderRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      value: value,
      enabled: enabled,
      onChanged: onChanged,
    );
  }
}

/// Legacy name kept for test compatibility — delegates to the premium
/// settings row so the rendered UI stays in the GameLearnAI language.
class SwitchTile extends StatelessWidget {
  const SwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return PremiumSwitchRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      value: value,
      onChanged: onChanged,
    );
  }
}
