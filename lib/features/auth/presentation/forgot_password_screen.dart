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

/// Forgot Password — Modern Academic Command Center.
///
/// Presentation only. Supabase `resetPasswordForEmail` preserved.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();

  bool _loading = false;
  bool _sent = false;
  String? _emailError;
  String? _generalError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _emailError = null;
      _generalError = null;

      if (!AuthValidator.isValidEmail(_emailCtrl.text)) {
        _emailError = AuthError.invalidEmail.message;
        return;
      }
    });

    return _emailError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    if (_loading) return;

    setState(() => _loading = true);

    final result = await AuthScope.of(context)
        .resetPassword(email: _emailCtrl.text);

    if (!mounted) return;

    setState(() => _loading = false);

    if (result.isFailure) {
      setState(() => _generalError = result.error?.message);
      return;
    }

    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: _sent
          ? _SuccessState(email: _emailCtrl.text.trim())
          : _RequestForm(
              emailCtrl: _emailCtrl,
              loading: _loading,
              emailError: _emailError,
              generalError: _generalError,
              onSubmit: _submit,
            ),
    );
  }
}

class _RequestForm extends StatelessWidget {
  const _RequestForm({
    required this.emailCtrl,
    required this.loading,
    required this.emailError,
    required this.generalError,
    required this.onSubmit,
  });

  final TextEditingController emailCtrl;
  final bool loading;
  final String? emailError;
  final String? generalError;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: StudentOSBrandMark(size: 56, iconSize: 28)),
        const SizedBox(height: 16),
        Text(
          'Forgot password?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Enter the email associated with your account.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        AuthTextField(
          label: 'Email',
          hint: 'you@example.com',
          prefixIcon: Icons.email_outlined,
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          errorText: emailError,
          autofillHints: const [AutofillHints.email],
        ),
        if (generalError != null) ...[
          const SizedBox(height: 12),
          AuthErrorBanner(message: generalError!),
        ],
        const SizedBox(height: 24),
        AuthPrimaryButton(
          onPressed: loading ? null : onSubmit,
          loading: loading,
          label: 'Send reset link',
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Remember your password? ',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Back to Sign In',
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
    );
  }
}

class _SuccessState extends StatelessWidget {
  const _SuccessState({required this.email});

  final String email;

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
                tone: StudentOSGlowTone.primary,
                intensity: StudentOSGlowIntensity.minimal,
                radius: StudentOSGlowRadius.medium,
                isDark: theme.brightness == Brightness.dark,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.mark_email_read_outlined,
              size: 36,
              color: scheme.primary,
              semanticLabel: 'Email sent',
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Check your email',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "We've sent a password reset link to",
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        AuthPrimaryButton(
          onPressed: () => Navigator.of(context).maybePop(),
          label: 'Back to Sign In',
        ),
      ],
    );
  }
}
