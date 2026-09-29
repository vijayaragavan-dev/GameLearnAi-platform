import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_controller.dart';
import '../providers/session_controller.dart';

/// AUTH-002. Comic GameLearnAI register screen matching attached mockup with
/// Teacher & Sparky mascots, neo-brutalist cards, display name/email/password,
/// create player button, sign in link, and bottom curiosity banner.
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
    final themeMode = ref.watch(themeControllerProvider);
    final isDark = themeMode == ThemeMode.dark;

    final bgLight = const Color(0xFFFAF9F5);
    final bgDark = const Color(0xFF0F172A);
    final ink = isDark ? Colors.white : const Color(0xFF171923);

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      body: Stack(
        children: [
          // ── Background Comic Doodles ──
          const Positioned(
            top: 130,
            left: 20,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.25,
                child: Icon(Icons.star_rounded, size: 40, color: Color(0xFFFDE047)),
              ),
            ),
          ),
          const Positioned(
            top: 220,
            right: 15,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.25,
                child: Icon(Icons.all_inclusive_rounded, size: 55, color: Color(0xFF60A5FA)),
              ),
            ),
          ),
          const Positioned(
            bottom: 160,
            left: -15,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.22,
                child: Icon(Icons.circle_outlined, size: 85, color: Color(0xFFFDE047)),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Top Navigation Bar & App Logo ──
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(Routes.login);
                              }
                            },
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDE047),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: ink, width: 2.2),
                                boxShadow: [
                                  BoxShadow(color: ink, offset: const Offset(2, 2)),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                size: 22,
                                color: Color(0xFF171923),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: ink, width: 2),
                                    boxShadow: [
                                      BoxShadow(color: ink, offset: const Offset(2, 2)),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.sports_esports_rounded,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GAMELEARN AI',
                                      style: TextStyle(
                                        fontFamily: AppTypography.displayFamily,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                        color: ink,
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontFamily: AppTypography.displayFamily,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.8,
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
                          ),
                          const SizedBox(width: 42), // Balance for back button
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Mascot Characters Header ──
                      Image.asset(
                        'assets/images/register_mascots.png',
                        height: 165,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 120,
                          alignment: Alignment.center,
                          child: const Icon(Icons.people_alt_rounded, size: 64, color: Color(0xFF2563EB)),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // ── Main Registration Card ──
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
                                'Create Your Player',
                                style: TextStyle(
                                  fontFamily: AppTypography.displayFamily,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tell us a bit about yourself to begin your journey.',
                                style: TextStyle(
                                  fontFamily: AppTypography.bodyFamily,
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // 1. Display Name Field
                              Text(
                                'Display Name',
                                style: TextStyle(
                                  fontFamily: AppTypography.displayFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _displayName,
                                style: TextStyle(
                                  fontFamily: AppTypography.bodyFamily,
                                  color: ink,
                                  fontSize: 14.5,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter your player name',
                                  hintStyle: TextStyle(
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.person_outline_rounded,
                                    size: 20,
                                    color: Color(0xFF64748B),
                                  ),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
                                  if (val.length < 2) return 'At least 2 characters';
                                  if (val.length > 100) return 'At most 100 characters';
                                  if (!_namePattern.hasMatch(val)) {
                                    return 'Letters, numbers, spaces, . - _ \' only';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'This will be your display name in the game.',
                                style: TextStyle(
                                  fontFamily: AppTypography.bodyFamily,
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // 2. Email Address Field
                              Text(
                                'Email Address',
                                style: TextStyle(
                                  fontFamily: AppTypography.displayFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: ink,
                                ),
                              ),
                              const SizedBox(height: 6),
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
                                  hintText: 'you@example.com',
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
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
                                  if (val.length > 255) return 'Email is too long';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // 3. Password Field
                              Text(
                                'Password',
                                style: TextStyle(
                                  fontFamily: AppTypography.displayFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                autofillHints: const [AutofillHints.newPassword],
                                style: TextStyle(
                                  fontFamily: AppTypography.bodyFamily,
                                  color: ink,
                                  fontSize: 14.5,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Create a password',
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
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
                                  final val = v ?? '';
                                  if (val.length < 8) return 'At least 8 characters';
                                  if (val.length > 72) return 'At most 72 characters';
                                  final hasLetter = val.contains(RegExp(r'[a-zA-Z]'));
                                  final hasDigit = val.contains(RegExp(r'[0-9]'));
                                  if (!hasLetter || !hasDigit) {
                                    return 'Needs at least 1 letter and 1 number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '8–72 characters, at least 1 letter and 1 number.',
                                style: TextStyle(
                                  fontFamily: AppTypography.bodyFamily,
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                ),
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
                              const SizedBox(height: 20),

                              // CREATE PLAYER Button
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
                                            Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 19),
                                            SizedBox(width: 8),
                                            Text(
                                              'CREATE PLAYER ➔',
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
                              const SizedBox(height: 16),

                              // OR Divider
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
                              const SizedBox(height: 14),

                              // Already have a player? Sign In Button
                              GestureDetector(
                                onTap: () => context.go(Routes.login),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: ink, width: 2),
                                    boxShadow: [
                                      BoxShadow(color: ink, offset: const Offset(2.5, 2.5)),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.person_outline_rounded,
                                        size: 20,
                                        color: Color(0xFF171923),
                                      ),
                                      const SizedBox(width: 8),
                                      RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontFamily: AppTypography.bodyFamily,
                                            fontSize: 13.5,
                                            color: isDark ? Colors.white : const Color(0xFF171923),
                                          ),
                                          children: const [
                                            TextSpan(text: 'Already have a player? '),
                                            TextSpan(
                                              text: 'Sign In ➔',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF2563EB),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Bottom Curiosity Banner ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2D2A1C) : const Color(0xFFFEF9C3),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: ink, width: 2),
                          boxShadow: [
                            BoxShadow(color: ink, offset: const Offset(3, 3)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDE047),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: ink, width: 1.8),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.lightbulb_rounded,
                                size: 22,
                                color: Color(0xFF171923),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Same doubts. Greater knowledge.',
                                    style: TextStyle(
                                      fontFamily: AppTypography.displayFamily,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Turn your curiosity into real skills.',
                                    style: TextStyle(
                                      fontFamily: AppTypography.bodyFamily,
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
