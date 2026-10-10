import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/student_os_icon_glow.dart';
import '../auth_scope.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_shell.dart';

/// Verification — Modern Academic Command Center.
///
/// Preserves verification flow, routes, loading/error behavior.
/// Shows the pending email when available, supports resend via Supabase,
/// never fakes verification status.
class VerificationPendingScreen extends StatefulWidget {
  const VerificationPendingScreen({super.key, this.email});

  final String? email;

  @override
  State<VerificationPendingScreen> createState() =>
      _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends State<VerificationPendingScreen> {
  bool _resending = false;
  bool _resent = false;
  String? _error;

  String get _displayEmail {
    if (widget.email != null && widget.email!.isNotEmpty) {
      return widget.email!;
    }
    final userEmail = AuthScope.of(context).user?.email;
    if (userEmail != null && userEmail.isNotEmpty) return userEmail;
    return '';
  }

  Future<void> _resend() async {
    if (_resending) return;
    final email = _displayEmail;
    setState(() {
      _resending = true;
      _error = null;
      _resent = false;
    });
    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        setState(() => _error = 'Service unavailable. Please try again.');
        return;
      }
      if (email.isEmpty) {
        setState(() => _error = 'No email found. Please sign up again.');
        return;
      }
      await client.auth.resend(type: OtpType.signup, email: email);
      if (mounted) setState(() => _resent = true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not resend email. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final email = _displayEmail;

    return AuthShell(
      showBack: true,
      child: Column(
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
              child: Icon(
                Icons.mark_email_read_outlined,
                size: 36,
                color: scheme.primary,
                semanticLabel: 'Verification email',
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Check your inbox',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Verify your email',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (email.isNotEmpty) ...[
            Text(
              'We sent a verification link to:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ] else ...[
            Text(
              "We've sent a verification link to your email address.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          Text(
            'Open your email and follow the link to continue.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            AuthErrorBanner(message: _error!),
          ],
          if (_resent) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: scheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Verification email resent.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          AuthPrimaryButton(
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed('/sign-in'),
            label: "I've verified — Go to Sign In",
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: _resending ? null : _resend,
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.onSurface,
                side: BorderSide(color: scheme.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              child: _resending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : const Text('Resend email'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'After verifying, sign in with your new account.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
