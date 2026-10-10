import 'package:flutter/material.dart';

import '../theme/app_scope.dart';
import 'student_os_menu.dart';
import '../../app/app_router.dart';
import '../../features/auth/auth_service.dart';
import '../services/student_service.dart';

/// Opens the Student OS command menu as a solid overlay route.
///
/// The menu surface is Deep Forest (emerald) with light text — the green
/// family is the product identity. Used by deep screens (via [AppHeader]);
/// the shell itself hosts the transforming menu inline.
void openHamburgerMenu(BuildContext context) {
  Navigator.of(context).push(_StudentOSMenuRoute());
}

class _StudentOSMenuRoute extends PageRouteBuilder<void> {
  _StudentOSMenuRoute()
      : super(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black.withValues(alpha: 0.35),
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) {
            return const _MenuRouteContent();
          },
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeIn,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.35, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

class _MenuRouteContent extends StatelessWidget {
  const _MenuRouteContent();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final menuWidth = (width * 0.78).clamp(260.0, 340.0);
    int selected = 0;
    try {
      selected = AppScope.of(context).selectedIndex;
    } catch (_) {
      selected = 0;
    }
    String? userName;
    try {
      final name = StudentService.instance.profile.displayName;
      userName = name.isNotEmpty ? name : null;
    } catch (_) {
      userName = null;
    }
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () {},
          child: SizedBox(
            width: menuWidth,
            height: double.infinity,
            child: Material(
              color: StudentOSMenu.menuBlue,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: StudentOSMenu(
                selectedIndex: selected,
                onSelect: (i) {
                  Navigator.of(context).pop();
                  try {
                    AppScope.of(context).setSelectedIndex(i);
                  } catch (_) {}
                },
                onClose: () => Navigator.of(context).pop(),
                onProgress: () {
                  Navigator.of(context).pop();
                  AppRouter.openProgress(context);
                },
                onAssistant: () {
                  Navigator.of(context).pop();
                  AppRouter.openAssistant(context);
                },
                onSettings: () {
                  Navigator.of(context).pop();
                  AppRouter.openSettings(context);
                },
                onLogout: () async {
                  Navigator.of(context).pop();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Log out'),
                      content:
                          const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Log out'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await AuthService.instance.signOut();
                  }
                },
                itemAnimation: const AlwaysStoppedAnimation(1.0),
                userGreeting: _greeting(),
                userName: userName,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
