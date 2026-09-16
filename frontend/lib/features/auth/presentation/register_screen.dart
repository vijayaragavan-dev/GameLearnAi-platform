import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_backgrounds.dart';
import '../../../shared/widgets/cinematic_scenery.dart';
import '../../../shared/widgets/cinematic_surfaces.dart';
import '../../../shared/widgets/nova_companion.dart';
import '../providers/session_controller.dart';

/// AUTH-002. Cinematic player-creation screen — same visual family as login.
///
/// Client-side validation mirrors the backend's bean constraints
/// (email <=255, password 8..72, displayName 2..100 with allowed charset).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  static final RegExp _namePattern = RegExp(
    r"^[\p{L}\p{N} .\-_']+$",
    unicode: true,
  );

  @override
  void dispose() {
    _displayName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await ref
        .read(sessionProvider.notifier)
        .register(_email.text, _password.text, _displayName.text);
    if (!mounted) return;
    if (ok) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('CREATE PLAYER')),
      body: Stack(
        children: [
          const AtmosphericBackground(),
          // Cinematic world backdrop — matches login atmosphere.
          const Positioned.fill(
            child: CinematicScenery(
              palette: ScenePalette.indigo,
              seed: 4,
              intensity: 0.55,
            ),
          ),
          if (isDark)
            const Positioned(
              top: -80,
              right: -60,
              child: GlowOrb(
                color: AppColors.primary,
                size: 260,
                opacity: 0.20,
              ),
            ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppGutters.pagePadding(context),
                  vertical: 12,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const NovaAvatar(size: 64),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.surfaceElevated.withValues(
                                            alpha: 0.85,
                                          )
                                        : AppLightColors.surface,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.lg,
                                    ),
                                    border: Border.all(
                                      color: AppColors.secondary.withValues(
                                        alpha: 0.45,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Level 1 starts now. Pick your player name!',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      height: 1.45,
                                      color: isDark
                                          ? AppColors.textPrimary
                                          : AppLightColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GlassPanel(
                            glowColor: AppColors.primary,
                            semanticsLabel: 'Create player card',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Begin your journey',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: AppTypography.displayFamily,
                                    fontSize: 23,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.textPrimary
                                        : AppLightColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _displayName,
                                  textCapitalization:
                                      TextCapitalization.words,
                                  maxLength: 100,
                                  buildCounter:
                                      (
                                        _, {
                                        required currentLength,
                                        required isFocused,
                                        maxLength,
                                      }) => null,
                                  decoration: const InputDecoration(
                                    labelText: 'Display name',
                                    hintText: 'Choose a player name',
                                    prefixIcon: Icon(
                                      Icons.badge_outlined,
                                      size: 19,
                                    ),
                                  ),
                                  validator: (v) {
                                    final value = v?.trim() ?? '';
                                    if (value.isEmpty) {
                                      return 'Pick a display name';
                                    }
                                    if (value.length < 2) {
                                      return 'At least 2 characters';
                                    }
                                    if (value.length > 100) {
                                      return 'At most 100 characters';
                                    }
                                    if (!_namePattern.hasMatch(value)) {
                                      return "Letters, numbers and . - _ ' only";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _email,
                                  keyboardType:
                                      TextInputType.emailAddress,
                                  autofillHints: const [
                                    AutofillHints.newUsername,
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'you@example.com',
                                    prefixIcon: Icon(
                                      Icons.alternate_email_rounded,
                                      size: 19,
                                    ),
                                  ),
                                  validator: (v) {
                                    final value = v?.trim() ?? '';
                                    if (value.isEmpty) {
                                      return 'Enter an email';
                                    }
                                    if (value.length > 255) {
                                      return 'Email is too long';
                                    }
                                    final emailPattern = RegExp(
                                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                    );
                                    if (!emailPattern.hasMatch(value)) {
                                      return 'That email does not look right';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _password,
                                  obscureText: _obscure,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: '••••••••',
                                    helperText: '8-72 characters',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 18,
                                    ),
                                    suffixIcon: IconButton(
                                      iconSize: 20,
                                      tooltip: _obscure
                                          ? 'Show password'
                                          : 'Hide password',
                                      onPressed: () => setState(
                                        () => _obscure = !_obscure,
                                      ),
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (v) {
                                    final value = v ?? '';
                                    if (value.isEmpty) {
                                      return 'Choose a password';
                                    }
                                    if (value.length < 8) {
                                      return 'At least 8 characters';
                                    }
                                    if (value.length > 72) {
                                      return 'At most 72 characters';
                                    }
                                    return null;
                                  },
                                ),
                                if (session.error != null) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.error.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          size: 17,
                                          color: AppColors.error,
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Text(
                                            session.error!.message,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                GlowCTA(
                                  label: 'Create player',
                                  icon: Icons.rocket_launch_outlined,
                                  trailingIcon: null,
                                  onPressed: session.busy ? null : _submit,
                                  isLoading: session.busy,
                                  semanticsLabel:
                                      'Create your GameLearnAI player',
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: session.busy
                                      ? null
                                      : () => context.go(Routes.login),
                                  child: const Text(
                                    'Already have a player? Sign in →',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryBright,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
