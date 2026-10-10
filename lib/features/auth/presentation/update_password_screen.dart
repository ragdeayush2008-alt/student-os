import 'package:flutter/material.dart';

import '../../../core/widgets/student_os_auth_shell.dart';
import '../../../core/widgets/student_os_icon_glow.dart';
import '../auth_scope.dart';
import '../auth_service.dart';
import '../auth_state.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_shell.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_primary_button.dart';

/// Update Password — Modern Academic Command Center. Logic preserved.
class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _success = false;
  String? _passwordError;
  String? _confirmError;
  String? _generalError;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;

    setState(() {
      _passwordError = null;
      _confirmError = null;
      _generalError = null;

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

    final result = await AuthScope.of(context).updatePassword(
      newPassword: _passwordCtrl.text,
    );

    if (!mounted) return;

    setState(() => _loading = false);

    if (result.isFailure) {
      setState(() => _generalError = result.error?.message);
      return;
    }

    setState(() => _success = true);
  }

  Future<void> _continueToSignIn() async {
    await AuthScope.of(context).signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/sign-in', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      showBack: !_success,
      child: _success
          ? _SuccessState(onContinue: _continueToSignIn)
          : _FormState(
              passwordCtrl: _passwordCtrl,
              confirmCtrl: _confirmCtrl,
              loading: _loading,
              passwordError: _passwordError,
              confirmError: _confirmError,
              generalError: _generalError,
              onSubmit: _submit,
            ),
    );
  }
}

class _FormState extends StatelessWidget {
  const _FormState({
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.loading,
    required this.passwordError,
    required this.confirmError,
    required this.generalError,
    required this.onSubmit,
  });

  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool loading;
  final String? passwordError;
  final String? confirmError;
  final String? generalError;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: StudentOSBrandMark(size: 56, iconSize: 28)),
        const SizedBox(height: 16),
        Text(
          'Reset Password',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your new password below.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        if (generalError != null) ...[
          AuthErrorBanner(message: generalError!),
          const SizedBox(height: 12),
        ],
        AuthTextField(
          label: 'New password',
          hint: 'At least 6 characters',
          controller: passwordCtrl,
          obscureText: true,
          prefixIcon: Icons.lock_outline_rounded,
          textInputAction: TextInputAction.next,
          errorText: passwordError,
          enabled: !loading,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Confirm password',
          hint: 'Repeat your new password',
          controller: confirmCtrl,
          obscureText: true,
          prefixIcon: Icons.lock_outline_rounded,
          textInputAction: TextInputAction.done,
          errorText: confirmError,
          enabled: !loading,
        ),
        const SizedBox(height: 24),
        AuthPrimaryButton(
          onPressed: loading ? null : onSubmit,
          loading: loading,
          label: 'Update Password',
        ),
      ],
    );
  }
}

class _SuccessState extends StatelessWidget {
  const _SuccessState({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.2),
              ),
              boxShadow: StudentOSGlow.tone(
                tone: StudentOSGlowTone.success,
                intensity: StudentOSGlowIntensity.minimal,
                radius: StudentOSGlowRadius.medium,
                isDark: theme.brightness == Brightness.dark,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 36,
              color: scheme.primary,
              semanticLabel: 'Success',
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Password updated successfully',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'You can now sign in with your new password.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        AuthPrimaryButton(
          onPressed: onContinue,
          label: 'Continue to Sign In',
        ),
      ],
    );
  }
}
