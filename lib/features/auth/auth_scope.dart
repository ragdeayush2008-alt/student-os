import 'package:flutter/material.dart';

import 'auth_service.dart';

/// Provides the shared [AuthService] to descendant widgets.
///
/// Uses [InheritedNotifier] so dependents rebuild when auth state changes.
/// Do not access [AuthService] before Supabase is ready — in demo mode the
/// auth service still works but viewState is always [demoMode].
class AuthScope extends InheritedNotifier<AuthService> {
  const AuthScope({
    super.key,
    required AuthService authService,
    required super.child,
  }) : super(notifier: authService);

  static AuthService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found in widget tree');
    return scope!.notifier!;
  }
}
