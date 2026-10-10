import 'package:flutter/material.dart';

/// A bottom-navigation destination shell item.
@immutable
class ShellDestination {
  const ShellDestination({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });

  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
}

/// The primary destinations shown in the bottom navigation.
///
/// Five-tab locked architecture:
/// 1. Home
/// 2. Plan & Study
/// 3. SprintX
/// 4. Tools Hub
/// 5. Workspace
abstract final class ShellDestinations {
  static const home = ShellDestination(
    title: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    route: '/home',
  );
  static const plan = ShellDestination(
    title: 'Plan & Study',
    icon: Icons.event_available_outlined,
    selectedIcon: Icons.event_available_rounded,
    route: '/plan',
  );
  static const sprintx = ShellDestination(
    title: 'SprintX',
    icon: Icons.bolt_outlined,
    selectedIcon: Icons.bolt_rounded,
    route: '/focus-center',
  );
  static const tools = ShellDestination(
    title: 'Tools Hub',
    icon: Icons.grid_view_outlined,
    selectedIcon: Icons.grid_view_rounded,
    route: '/tools',
  );
  static const workspace = ShellDestination(
    title: 'Workspace',
    icon: Icons.workspaces_outlined,
    selectedIcon: Icons.workspaces_rounded,
    route: '/more',
  );

  /// Backward-compatibility aliases
  static const study = sprintx;
  static const focus = sprintx;
  static const more = workspace;

  static const List<ShellDestination> all = [
    home,
    plan,
    sprintx,
    tools,
    workspace,
  ];
}
