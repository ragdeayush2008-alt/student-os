import 'package:flutter/material.dart';

import '../../../core/widgets/student_os_auth_shell.dart';
import '../auth_scope.dart';
import '../auth_service.dart';
import '../auth_state.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_shell.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/google_sign_in_button.dart';

/// Sign In — Modern Academic Command Center.
///
/// Calls real Supabase `signInWithPassword`. Validation, loading, and error
/// handling preserved. Presentation only: solid surfaces, clear hierarchy.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  bool _googleLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;

    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;

      if (!AuthValidator.isValidEmail(_emailCtrl.text)) {
        _emailError = AuthError.invalidEmail.message;
        valid = false;
      }

      if (_passwordCtrl.text.isEmpty) {
        _passwordError = 'Please enter your password.';
        valid = false;
      }
    });

    return valid;
  }

  Future<void> _googleSignIn() async {
    if (_googleLoading) return;
    setState(() {
      _googleLoading = true;
      _generalError = null;
    });
    try {
      final result = await AuthScope.of(context).signInWithGoogle();
      if (!mounted) return;
      if (result.isFailure && result.error != null) {
        setState(() => _generalError = result.error!.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _generalError = AuthError.unknown.message);
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    if (_loading) return;

    setState(() => _loading = true);

    final result = await AuthScope.of(context)
        .signIn(email: _emailCtrl.text, password: _passwordCtrl.text);

    if (!mounted) return;

    setState(() => _loading = false);

    if (result.isFailure) {
      setState(() => _generalError = result.error?.message);
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
            'Welcome back',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Continue your journey',
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
            textInputAction: TextInputAction.done,
            errorText: _passwordError,
            autofillHints: const [AutofillHints.password],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/forgot-password'),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                minimumSize: const Size(44, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: scheme.primary,
              ),
              child: Text(
                'Forgot password?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
          if (_generalError != null) ...[
            const SizedBox(height: 8),
            AuthErrorBanner(message: _generalError!),
          ],
          const SizedBox(height: 20),
          AuthPrimaryButton(
            onPressed: _loading ? null : _submit,
            loading: _loading,
            label: 'Sign In',
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Divider(color: scheme.outline)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(child: Divider(color: scheme.outline)),
            ],
          ),
          const SizedBox(height: 20),
          GoogleSignInButton(
            onPressed: _googleSignIn,
            isLoading: _googleLoading,
          ),
          const SizedBox(height: 28),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              GestureDetector(
                onTap: () =>
                    Navigator.of(context).pushReplacementNamed('/sign-up'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Create Account',
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
