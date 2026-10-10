import 'package:flutter/material.dart';

import '../../../core/animations/animated_entrance.dart';
import '../../../core/widgets/student_os_auth_shell.dart';
import '../../../core/widgets/student_os_card.dart';
import '../../../core/widgets/student_os_icon_glow.dart';
import '../auth_scope.dart';
import '../auth_state.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_shell.dart';
import '../widgets/google_sign_in_button.dart';

/// Welcome / landing screen — Modern Academic Command Center.
///
/// Preserves: Sign In, Create Account, Google sign-in, routes, auth behavior.
/// Visuals: bright clean surface, solid cards, restrained blue identity.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _googleLoading = false;
  String? _generalError;

  void _go(String route) => Navigator.of(context).pushNamed(route);

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AuthShell(
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Branding ──
          const AnimatedEntrance(
            child: Center(child: StudentOSBrandMark(size: 72, iconSize: 36)),
          ),
          const SizedBox(height: 20),
          AnimatedEntrance(
            delay: const Duration(milliseconds: 60),
            child: Column(
              children: [
                Text(
                  'Student OS',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Your complete student operating system',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Compact feature preview (not selectable pills) ──
          const AnimatedEntrance(
            delay: Duration(milliseconds: 120),
            child: _FeaturePreview(),
          ),
          const SizedBox(height: 24),

          if (_generalError != null) ...[
            AuthErrorBanner(message: _generalError!),
            const SizedBox(height: 12),
          ],

          // ── CTAs ──
          AnimatedEntrance(
            delay: const Duration(milliseconds: 160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthPrimaryButton(
                  onPressed: () => _go('/sign-in'),
                  label: 'Sign In',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => _go('/sign-up'),
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
                      textStyle: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_add_alt_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Create Account'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GoogleSignInButton(
                  onPressed: _googleSignIn,
                  isLoading: _googleLoading,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Organization · Focus · Growth · Achievement',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Compact, non-interactive product preview: icon + title + one-line support.
class _FeaturePreview extends StatelessWidget {
  const _FeaturePreview();

  static const _items = [
    (Icons.calendar_month_outlined, 'PLAN', 'Organise tasks'),
    (Icons.bolt_outlined, 'FOCUS', 'Deep work sessions'),
    (Icons.menu_book_outlined, 'STUDY', 'Master topics'),
    (Icons.trending_up_rounded, 'PROGRESS', 'Track growth'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return StudentOSCard.section(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          mainAxisExtent: 96,
        ),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final item = _items[i];
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(9),
                    // Calm onboarding-level glow behind the preview icons.
                    boxShadow: StudentOSGlow.tone(
                      tone: StudentOSGlowTone.primary,
                      intensity: StudentOSGlowIntensity.minimal,
                      radius: StudentOSGlowRadius.small,
                      isDark: theme.brightness == Brightness.dark,
                    ),
                  ),
                  child: Icon(item.$1, size: 17, color: scheme.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  item.$2,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.$3,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
