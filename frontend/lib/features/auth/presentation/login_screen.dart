import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/session_controller.dart';
import '../../../shared/widgets/game_button.dart';
import '../../../shared/widgets/nova_companion.dart';

/// AUTH-001. Failures are always a generic message (anti-enumeration).
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
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NovaCompanion(size: 52, mood: NovaMood.idle),
                      SizedBox(width: 12),
                      Text(
                        'GAMELEARN AI',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFamily,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Welcome back, Player',
                    style: TextStyle(
                      fontFamily: AppTypography.displayFamily,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your adventure is waiting.',
                    style: AppTypography.bodySecondary(context),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email_rounded, size: 19),
                    ),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Enter your email';
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'That email does not look right';
                      }
                      if (value.length > 255) return 'Email is too long';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                      ),
                      suffixIcon: IconButton(
                        iconSize: 20,
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter your password' : null,
                  ),
                  if (session.error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.4),
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
                  const SizedBox(height: 28),
                  PrimaryGameButton(
                    label: 'Sign in',
                    onTap: _submit,
                    busy: session.busy,
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: session.busy
                        ? null
                        : () => context.go(Routes.register),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: AppTypography.bodyFamily,
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          TextSpan(text: "New here? "),
                          TextSpan(
                            text: 'Create your player',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryBright,
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
        ),
      ),
    );
  }
}
