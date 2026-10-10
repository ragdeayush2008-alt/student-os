import 'package:flutter/material.dart';

import '../../../core/widgets/student_os_auth_shell.dart';

/// Standard screen wrapper for all authentication screens.
///
/// Thin backwards-compatible wrapper around [StudentOSAuthShell] so existing
/// imports (`AuthShell(child: ...)`) keep working. Visual system is now the
/// Modern Academic Command Center: solid surfaces, no glass, theme-aware
/// light/dark, responsive centered content.
class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.child, this.showBack = true});

  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return StudentOSAuthShell(showBack: showBack, child: child);
  }
}
