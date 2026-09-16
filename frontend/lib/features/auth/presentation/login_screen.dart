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

/// AUTH-001. Cinematic GameLearnAI login — Nova storytelling hero, premium
/// glass sign-in card, glowing CTA. Failures stay a generic message
/// (anti-enumeration). No social login: the backend contract offers
/// email/password only, so no fake buttons are rendered.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await ref
        .read(sessionProvider.notifier)
        .login(_email.text, _password.text);
    if (!mounted) return;
    if (!ok) return;
    if (mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Neon side-quote is wide-only: rotated text overflows 320–390px phones.
    final wide = MediaQuery.sizeOf(context).width >= 560;
    return Scaffold(
      body: Stack(
        children: [
          const AtmosphericBackground(),
          // Cinematic world backdrop (reference: mountain castle vista
          // behind the sign-in card). Static, low-intensity, decorative.
          const Positioned.fill(
            child: CinematicScenery(
              palette: ScenePalette.indigo,
              seed: 3,
              intensity: 0.55,
            ),
          ),
          if (isDark)
            const Positioned(
              top: -80,
              left: -60,
              child: GlowOrb(
                color: AppColors.primary,
                size: 260,
                opacity: 0.22,
              ),
            ),
          if (isDark)
            const Positioned(
              bottom: -100,
              right: -70,
              child: GlowOrb(
                color: AppColors.secondary,
                size: 260,
                opacity: 0.16,
              ),
            ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppGutters.pagePadding(context),
                  vertical: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Brand + Nova storytelling hero ──
                          const Center(child: BrandWordmark()),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nova's real character art — the reference's
                              // robot guide greeting the player.
                              const NovaAvatar(size: 92),
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
                                    'Hey Player! 👋 Ready to continue your journey?',
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
                          const SizedBox(height: 8),
                          // Neon side-quote — desktop/wide only; rotated
                          // text would overflow 320–390px viewports.
                          if (wide)
                            const Center(
                              child: NeonQuote(
                                text: 'LEARN LIKE A GAME\nWIN IN REAL LIFE',
                                fontSize: 11,
                                color: AppColors.secondary,
                              ),
                            ),
                          const SizedBox(height: 18),
                          // ── Glass sign-in card ──
                          GlassPanel(
                            glowColor: AppColors.primary,
                            semanticsLabel: 'Sign in card',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  // Single Text widget (not split spans) so
                                  // responsive regression tests can assert it.
                                  'Welcome back, Player',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily:
                                        AppTypography.displayFamily,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.textPrimary
                                        : AppLightColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Your adventure is waiting.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySecondary(context),
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: _email,
                                  keyboardType:
                                      TextInputType.emailAddress,
                                  autofillHints: const [
                                    AutofillHints.email,
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
                                      return 'Enter your email';
                                    }
                                    if (!value.contains('@') ||
                                        !value.contains('.')) {
                                      return 'That email does not look right';
                                    }
                                    if (value.length > 255) {
                                      return 'Email is too long';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _password,
                                  obscureText: _obscure,
                                  autofillHints: const [
                                    AutofillHints.password,
                                  ],
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: '••••••••',
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
                                  validator: (v) =>
                                      (v == null || v.isEmpty)
                                      ? 'Enter your password'
                                      : null,
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
                                  label: 'Sign in',
                                  icon: Icons.arrow_forward_rounded,
                                  trailingIcon: null,
                                  onPressed: session.busy ? null : _submit,
                                  isLoading: session.busy,
                                  semanticsLabel: 'Sign in to GameLearnAI',
                                ),
                                const SizedBox(height: 14),
                                TextButton(
                                  onPressed: session.busy
                                      ? null
                                      : () => context.go(Routes.register),
                                  child: RichText(
                                    text: const TextSpan(
                                      style: TextStyle(
                                        fontFamily:
                                            AppTypography.bodyFamily,
                                        fontSize: 13.5,
                                        color: AppColors.textSecondary,
                                      ),
                                      children: [
                                        TextSpan(text: 'New here? '),
                                        TextSpan(
                                          text: 'Create your player →',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color:
                                                AppColors.primaryBright,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          // ── Product pillars (static, decorative) ──
                          // Expanded (never fixed widths) so 320px phones
                          // cannot overflow; labels wrap, never clip.
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _Pillar(
                                  icon: Icons.bolt_rounded,
                                  label: 'GAIN\nSKILLS',
                                  color: AppColors.secondary,
                                ),
                              ),
                              Expanded(
                                child: _Pillar(
                                  icon: Icons.track_changes_rounded,
                                  label: 'COMPLETE\nMISSIONS',
                                  color: AppColors.secondary,
                                ),
                              ),
                              Expanded(
                                child: _Pillar(
                                  icon: Icons.emoji_events_outlined,
                                  label: 'EARN\nREWARDS',
                                  color: AppColors.xp,
                                ),
                              ),
                              Expanded(
                                child: _Pillar(
                                  icon: Icons.group_outlined,
                                  label: 'BUILD\nYOUR FUTURE',
                                  color: AppColors.primaryBright,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: Text(
                              '“Same doubts. Greater knowledge.”',
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppLightColors.textSecondary,
                              ),
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

class _Pillar extends StatelessWidget {
  const _Pillar({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              height: 1.4,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: isDark
                  ? AppColors.textTertiary
                  : AppLightColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
