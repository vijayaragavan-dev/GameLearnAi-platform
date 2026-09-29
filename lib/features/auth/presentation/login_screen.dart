import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_controller.dart';
import '../providers/session_controller.dart';

/// AUTH-001. Comic GameLearnAI login with Sparky mascot, neo-brutalist cards,
/// theme switch, explore demo button, and feature badges.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'alex@gamelearn.ai');
  final _password = TextEditingController(text: 'Password123!');
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

    var email = _email.text.trim();
    var password = _password.text;

    // Map any legacy demo input to the live backend seeded user
    if (email == 'demo@gamelearn.ai' && password == 'demo123') {
      email = 'alex@gamelearn.ai';
      password = 'Password123!';
    }

    final ok = await ref.read(sessionProvider.notifier).login(email, password);
    if (!mounted) return;
    if (!ok) return;
    if (mounted) context.go(Routes.home);
  }

  Future<void> _quickLogin() async {
    _email.text = 'alex@gamelearn.ai';
    _password.text = 'Password123!';
    await _submit();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final themeMode = ref.watch(themeControllerProvider);
    final isDark = themeMode == ThemeMode.dark;

    final bgLight = const Color(0xFFFAF9F5);
    final bgDark = const Color(0xFF0F172A);
    final ink = isDark ? Colors.white : const Color(0xFF171923);

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      body: Stack(
        children: [
          // ── Decorative Comic Background Elements ──
          Positioned(
            top: 60,
            left: 20,
            child: IgnorePointer(
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE047),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ink, width: 2),
                  boxShadow: [
                    BoxShadow(color: ink, offset: const Offset(2, 2)),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.star_rounded, size: 22, color: Color(0xFF171923)),
              ),
            ),
          ),
          Positioned(
            top: 220,
            left: -15,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.25,
                child: Icon(Icons.favorite_rounded, size: 80, color: isDark ? Colors.blue : const Color(0xFF93C5FD)),
              ),
            ),
          ),
          Positioned(
            top: 240,
            right: -10,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.25,
                child: Icon(Icons.change_history_rounded, size: 90, color: isDark ? Colors.teal : const Color(0xFF86EFAC)),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            right: 18,
            child: IgnorePointer(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ink, width: 2),
                  boxShadow: [
                    BoxShadow(color: ink, offset: const Offset(2, 2)),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.sports_esports_rounded, size: 24, color: Color(0xFF171923)),
              ),
            ),
          ),
          Positioned(
            bottom: 90,
            left: -20,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.22,
                child: Icon(Icons.circle_outlined, size: 100, color: isDark ? Colors.amber : const Color(0xFFFDE047)),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Top Header Row (Theme Switch Pill) ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: ink, width: 2),
                              boxShadow: [
                                BoxShadow(color: ink, offset: const Offset(2, 2)),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => ref.read(themeControllerProvider.notifier).set(ThemeMode.light),
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: !isDark ? const Color(0xFFFDE047) : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.wb_sunny_rounded, size: 15, color: Color(0xFF171923)),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => ref.read(themeControllerProvider.notifier).set(ThemeMode.dark),
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF38BDF8) : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.nightlight_round,
                                      size: 15,
                                      color: isDark ? Colors.white : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // ── App Branding Logo ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: ink, width: 2.2),
                              boxShadow: [
                                BoxShadow(color: ink, offset: const Offset(2.5, 2.5)),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.sports_esports_rounded, size: 28, color: Colors.white),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GAMELEARN AI',
                                style: TextStyle(
                                  fontFamily: AppTypography.displayFamily,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: ink,
                                ),
                              ),
                              const SizedBox(height: 3),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontFamily: AppTypography.displayFamily,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2.0,
                                  ),
                                  children: [
                                    const TextSpan(text: 'LEARN', style: TextStyle(color: Color(0xFF3B82F6))),
                                    TextSpan(text: ' • ', style: TextStyle(color: ink)),
                                    const TextSpan(text: 'PLAY', style: TextStyle(color: Color(0xFF10B981))),
                                    TextSpan(text: ' • ', style: TextStyle(color: ink)),
                                    const TextSpan(text: 'ADAPT', style: TextStyle(color: Color(0xFFF97316))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ── Mascot Sparky + Speech Bubble ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Image.asset(
                              'assets/images/sparky_login.png',
                              width: 110,
                              height: 98,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.cruelty_free_rounded,
                                size: 64,
                                color: Color(0xFFF97316),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: ink, width: 2),
                                  boxShadow: [
                                    BoxShadow(color: ink, offset: const Offset(2, 2)),
                                  ],
                                ),
                                child: Text(
                                  'Ready to continue\nyour journey?',
                                  style: TextStyle(
                                    fontFamily: AppTypography.displayFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                    color: ink,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Main Sign In Card ──
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: ink, width: 2.5),
                          boxShadow: [
                            BoxShadow(color: ink, offset: const Offset(4, 4)),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Welcome back!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTypography.displayFamily,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                  color: ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your adventure is waiting.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTypography.bodyFamily,
                                  fontSize: 13.5,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Email Field
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                style: TextStyle(
                                  fontFamily: AppTypography.bodyFamily,
                                  color: ink,
                                  fontSize: 14.5,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Email',
                                  hintStyle: TextStyle(
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.mail_outline_rounded,
                                    size: 20,
                                    color: Color(0xFF64748B),
                                  ),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: ink, width: 1.8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: ink, width: 1.8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2.2),
                                  ),
                                ),
                                validator: (v) {
                                  final val = v?.trim() ?? '';
                                  if (val.isEmpty) return 'Enter your email';
                                  if (!val.contains('@') || !val.contains('.')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // Password Field
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) => _submit(),
                                style: TextStyle(
                                  fontFamily: AppTypography.bodyFamily,
                                  color: ink,
                                  fontSize: 14.5,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  hintStyle: TextStyle(
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 20,
                                    color: Color(0xFF64748B),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      size: 20,
                                      color: const Color(0xFF64748B),
                                    ),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: ink, width: 1.8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: ink, width: 1.8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2.2),
                                  ),
                                ),
                                validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                              ),

                              if (session.error != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.error, width: 1.5),
                                  ),
                                  child: Text(
                                    session.error!.message,
                                    style: const TextStyle(fontSize: 12, color: AppColors.error),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),

                              // SIGN IN Button
                              GestureDetector(
                                onTap: session.busy ? null : _submit,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: ink, width: 2.2),
                                    boxShadow: [
                                      BoxShadow(color: ink, offset: const Offset(3, 3)),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: session.busy
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                        )
                                      : const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 19),
                                            SizedBox(width: 8),
                                            Text(
                                              'SIGN IN',
                                              style: TextStyle(
                                                fontFamily: AppTypography.displayFamily,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.8,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Create Player Link
                              GestureDetector(
                                onTap: () => context.go(Routes.register),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontFamily: AppTypography.bodyFamily,
                                        fontSize: 13.5,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                      children: const [
                                        TextSpan(text: 'New here? '),
                                        TextSpan(
                                          text: 'Create your player ➔',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── OR Divider ──
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                              thickness: 1.2,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                fontFamily: AppTypography.displayFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                              thickness: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ── EXPLORE DEMO Button ──
                      GestureDetector(
                        onTap: session.busy ? null : _quickLogin,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: ink, width: 2.2),
                            boxShadow: [
                              BoxShadow(color: ink, offset: const Offset(3, 3)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEFF6FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'EXPLORE DEMO',
                                    style: TextStyle(
                                      fontFamily: AppTypography.displayFamily,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                      color: ink,
                                    ),
                                  ),
                                  Text(
                                    'Demo learner • Alex',
                                    style: TextStyle(
                                      fontFamily: AppTypography.bodyFamily,
                                      fontSize: 11.5,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── 4 Feature Badges Row ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _FeatureBadge(
                            icon: Icons.bolt_rounded,
                            iconColor: const Color(0xFFEAB308),
                            label: 'GAIN\nSKILLS',
                            ink: ink,
                          ),
                          _FeatureBadge(
                            icon: Icons.track_changes_rounded,
                            iconColor: const Color(0xFFEF4444),
                            label: 'COMPLETE\nMISSIONS',
                            ink: ink,
                          ),
                          _FeatureBadge(
                            icon: Icons.emoji_events_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            label: 'EARN\nREWARDS',
                            ink: ink,
                          ),
                          _FeatureBadge(
                            icon: Icons.groups_rounded,
                            iconColor: const Color(0xFF8B5CF6),
                            label: 'BUILD\nYOUR FUTURE',
                            ink: ink,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
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

class _FeatureBadge extends StatelessWidget {
  const _FeatureBadge({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.ink,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 28, color: iconColor),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.displayFamily,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: 0.4,
            color: ink,
          ),
        ),
      ],
    );
  }
}
