import 'package:flutter/material.dart';

import 'app_shell_controller.dart';

/// Provides the shared [AppShellController] to descendant widgets without an
/// external state-management package. Uses [InheritedNotifier] so dependents
/// rebuild when the controller notifies (theme/navigation changes).
class AppScope extends InheritedNotifier<AppShellController> {
  const AppScope({
    super.key,
    required AppShellController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppShellController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }
}
