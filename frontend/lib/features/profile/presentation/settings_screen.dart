import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/audio/audio_manager.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/session_controller.dart';
import '../../../shared/widgets/game_card.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          SectionCard(
            title: 'AUDIO',
            children: [
              SwitchTile(
                icon: Icons.music_note_rounded,
                title: 'Background music',
                subtitle: 'Ambient adventure soundtrack',
                value: audio.musicEnabled,
                onChanged: (v) async {
                  await audio.setMusicEnabled(v);
                  if (v) {
                    audio.playContext(MusicContext.menu);
                  }
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
              ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  size: 21,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Sign out',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                subtitle: const Text(
                  'Ends this session on this device',
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
                onTap: () => _confirmLogout(context),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              'GameLearn AI Â· ${ref.watch(appConfigInfoProvider).env.toUpperCase()} Â· '
              '${ref.watch(appConfigInfoProvider).baseUrl}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Your progress lives safely on the servers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('SIGN OUT'),
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
            style: const TextStyle(
              fontSize: 10.5,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w800,
              color: AppColors.textTertiary,
            ),
          ),
        ),
        ...children,
      ],
    ),
  );
}

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
  Widget build(BuildContext context) => SwitchListTile(
    secondary: Icon(icon, size: 20, color: AppColors.secondary),
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        fontFamily: AppTypography.bodyFamily,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
        fontFamily: AppTypography.bodyFamily,
      ),
    ),
    value: value,
    activeThumbColor: AppColors.primaryBright,
    onChanged: onChanged,
  );
}
