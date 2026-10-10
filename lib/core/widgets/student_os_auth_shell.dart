import 'package:flutter/material.dart';

import 'student_os_button.dart';
import 'student_os_icon_glow.dart';

/// Unified Student OS Auth/Onboarding shell — Modern Academic Command Center.
///
/// Provides a consistent, bright, calm container for:
/// Welcome, Sign In, Sign Up, Forgot Password, Verification,
/// Update Password, and onboarding steps that opt into a card layout.
///
/// - Light: #F6F8FC background with white solid cards.
/// - Dark: deep neutral background with elevated dark surfaces (via Theme).
/// - Responsive: centered content, max-width capped (default 520 for auth).
/// - Keyboard-safe: scrollable, bottom padding respects viewInsets.
/// - No glass, no blur, no neon glow — solid surfaces only.
class StudentOSAuthShell extends StatelessWidget {
  const StudentOSAuthShell({
    super.key,
    required this.child,
    this.showBack = true,
    this.maxWidth = 520,
    this.onBack,
  });

  final Widget child;
  final bool showBack;
  final double maxWidth;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              children: [
                if (showBack)
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Semantics(
                        button: true,
                        label: 'Back',
                        child: Material(
                          color: scheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: scheme.outline),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap:
                                onBack ?? () => Navigator.of(context).maybePop(),
                            child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Center(
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      24 + bottomInset,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: scheme.outline),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.shadow.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 28,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small brand mark used across auth/onboarding — solid, no glass.
class StudentOSBrandMark extends StatelessWidget {
  const StudentOSBrandMark({super.key, this.size = 64, this.iconSize = 32});

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.18),
        ),
        // Calm auth intensity (~60% of Home interactive glow): the glow
        // sits behind the solid container and extends only slightly out.
        boxShadow: StudentOSGlow.tone(
          tone: StudentOSGlowTone.primary,
          intensity: StudentOSGlowIntensity.minimal,
          radius: StudentOSGlowRadius.medium,
          isDark: theme.brightness == Brightness.dark,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.school_outlined,
          size: iconSize,
          color: scheme.primary,
          semanticLabel: 'Student OS logo',
        ),
      ),
    );
  }
}

/// Re-export for convenience so auth screens can use the canonical icon button.
typedef AuthBackButton = StudentOSIconButton;
