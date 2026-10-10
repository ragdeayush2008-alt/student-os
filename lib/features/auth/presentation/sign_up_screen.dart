import 'package:flutter/material.dart';

import '../../../core/widgets/student_os_auth_shell.dart';
import '../auth_scope.dart';
import '../auth_service.dart';
import '../auth_state.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_shell.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_primary_button.dart';

/// Sign Up — Modern Academic Command Center.
///
/// Preserves all fields, validation, and account-creation behavior.
/// Presentation only: solid inputs, Command Center hierarchy.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _generalError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;

    setState(() {
      _emailError = null;
      _passwordError = null;
      _confirmError = null;
      _generalError = null;

      if (!AuthValidator.isValidEmail(_emailCtrl.text)) {
        _emailError = AuthError.invalidEmail.message;
        valid = false;
      }

      if (!AuthValidator.isStrongPassword(_passwordCtrl.text)) {
        _passwordError = AuthError.weakPassword.message;
        valid = false;
      }

      if (!AuthValidator.passwordsMatch(
        _passwordCtrl.text,
        _confirmCtrl.text,
      )) {
        _confirmError = AuthError.passwordsMismatch.message;
        valid = false;
      }
    });

    return valid;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    if (_loading) return;

    setState(() => _loading = true);

    final result = await AuthScope.of(context)
        .signUp(email: _emailCtrl.text, password: _passwordCtrl.text);

    if (!mounted) return;

    setState(() => _loading = false);

    if (result.isFailure) {
      setState(() => _generalError = result.error?.message);
      return;
    }

    if (result.isEmailConfirmationPending) {
      Navigator.of(context).pushReplacementNamed('/verification-pending');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: StudentOSBrandMark(size: 56, iconSize: 28)),
          const SizedBox(height: 16),
          Text(
            'Create your account',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Set up your Student OS',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          AuthTextField(
            label: 'Email',
            hint: 'you@example.com',
            prefixIcon: Icons.email_outlined,
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            errorText: _emailError,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: 'Password',
            prefixIcon: Icons.lock_outline,
            controller: _passwordCtrl,
            obscureText: true,
            textInputAction: TextInputAction.next,
            errorText: _passwordError,
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'At least 6 characters',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
          AuthTextField(
            label: 'Confirm Password',
            prefixIcon: Icons.lock_outline,
            controller: _confirmCtrl,
            obscureText: true,
            textInputAction: TextInputAction.done,
            errorText: _confirmError,
            autofillHints: const [AutofillHints.newPassword],
          ),
          if (_generalError != null) ...[
            const SizedBox(height: 12),
            AuthErrorBanner(message: _generalError!),
          ],
          const SizedBox(height: 24),
          AuthPrimaryButton(
            onPressed: _loading ? null : _submit,
            loading: _loading,
            label: 'Create Account',
          ),
          const SizedBox(height: 28),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              GestureDetector(
                onTap: () =>
                    Navigator.of(context).pushReplacementNamed('/sign-in'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Sign In',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
