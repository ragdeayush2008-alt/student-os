import 'package:flutter/material.dart';

import '../core/design/tokens/student_os_tokens.dart';
import '../core/services/student_service.dart';
import '../core/theme/app_scope.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_pressable.dart';
import '../core/widgets/student_os_bottom_nav.dart';
import '../core/widgets/student_os_menu.dart';
import '../features/auth/auth_service.dart';
import '../features/focus/presentation/screens/focus_center_screen.dart';
import '../features/home/home_screen.dart';
import '../features/more/more_screen.dart';
import '../features/planning/planning_screen.dart';
import '../features/progression/progression_controller.dart';
import '../features/progression/widgets/level_up_dialog.dart';
import '../features/tools/presentation/tools_hub_screen.dart';
import 'app_router.dart';

/// Student OS shell: solid surfaces, transforming deep-forest menu.
///
/// Hamburger tap: the Deep Forest menu surface enters from the left while
/// home content shifts right + scales slightly + gains corner radius, leaving
/// a visible Home strip on the right. ~380ms easeOut. No glass.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  int? _lastLevel;
  bool _menuOpen = false;
  late final AnimationController _menuController;
  late final Animation<double> _menuAnimation;
  late final Animation<double> _itemAnimation;

  static const _destinations = <Widget>[
    HomeScreen(),
    PlanningScreen(),
    FocusCenterScreen(),
    ToolsHubScreen(),
    MoreScreen(),
  ];

  static const Duration _menuDuration = StudentOSMotion.navigation;

  @override
  void initState() {
    super.initState();
    _lastLevel = ProgressionController.instance.currentLevel.level;
    ProgressionController.instance.addListener(_onProgressionChanged);
    // Widget tap while logged out parks here; consume once the shell
    // (authenticated home) is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppRouter.consumePendingWidgetLink();
    });
    _menuController = AnimationController(
      vsync: this,
      duration: _menuDuration,
      reverseDuration: const Duration(milliseconds: 300),
    );
    _menuAnimation = CurvedAnimation(
      parent: _menuController,
      curve: StudentOSMotion.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _itemAnimation = CurvedAnimation(
      parent: _menuController,
      curve: StudentOSMotion.easeOut,
    );
  }

  @override
  void dispose() {
    ProgressionController.instance.removeListener(_onProgressionChanged);
    _menuController.dispose();
    super.dispose();
  }

  void _onProgressionChanged() {
    if (!mounted) return;
    final currentLevel = ProgressionController.instance.currentLevel.level;
    final last = _lastLevel;
    if (last != null && currentLevel > last) {
      showLevelUpDialog(context, last, currentLevel);
    }
    _lastLevel = currentLevel;
  }

  void _toggleMenu() {
    if (_menuOpen) {
      _closeMenu();
    } else {
      setState(() => _menuOpen = true);
      _menuController.forward();
    }
  }

  void _closeMenu() {
    if (!_menuOpen) return;
    _menuController.reverse().then((_) {
      if (mounted) setState(() => _menuOpen = false);
    });
    // Hide items immediately on close start for snappiness; the state flips
    // off when the reverse animation completes.
  }

  void _selectDestination(int index) {
    AppScope.of(context).setSelectedIndex(index);
    _closeMenu();
  }

  Future<void> _handleLogout() async {
    final shouldClose = _menuOpen;
    if (shouldClose) {
      _menuController.reverse();
      setState(() => _menuOpen = false);
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
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
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final index = controller.selectedIndex;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return PopScope(
      canPop: !_menuOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _menuOpen) _closeMenu();
      },
      child: Scaffold(
        backgroundColor: StudentOSMenu.menuBlue,
        body: Stack(
          children: [
            // Menu surface (behind content) — lightweight FadeTransition with static child.
            if (_menuOpen || _menuController.value > 0)
              Positioned.fill(
                child: reduceMotion
                    ? _MenuHost(
                        selectedIndex: index,
                        itemAnimation: _itemAnimation,
                        onSelect: _selectDestination,
                        onClose: _closeMenu,
                        onProgress: () {
                          _closeMenu();
                          AppRouter.openProgress(context);
                        },
                        onAssistant: () {
                          _closeMenu();
                          AppRouter.openAssistant(context);
                        },
                        onSettings: () {
                          _closeMenu();
                          AppRouter.openSettings(context);
                        },
                        onLogout: _handleLogout,
                      )
                    : FadeTransition(
                        opacity: _menuAnimation,
                        child: _MenuHost(
                          selectedIndex: index,
                          itemAnimation: _itemAnimation,
                          onSelect: _selectDestination,
                          onClose: _closeMenu,
                          onProgress: () {
                            _closeMenu();
                            AppRouter.openProgress(context);
                          },
                          onAssistant: () {
                            _closeMenu();
                            AppRouter.openAssistant(context);
                          },
                          onSettings: () {
                            _closeMenu();
                            AppRouter.openSettings(context);
                          },
                          onLogout: _handleLogout,
                        ),
                      ),
              ),
            // Main content: shifts right + scales + rounds when menu opens.
            AnimatedBuilder(
              animation: _menuAnimation,
              builder: (context, child) {
                final t = reduceMotion
                    ? (_menuOpen ? 1.0 : 0.0)
                    : _menuAnimation.value;
                final width = MediaQuery.sizeOf(context).width;
                final shift = t * (width * 0.78).clamp(260.0, 340.0);
                final scale = 1.0 - (t * 0.08);
                final radius = t * 20.0;
                return Transform.translate(
                  offset: Offset(shift, 0),
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: child,
                    ),
                  ),
                );
              },
              child: Container(
                color: scheme.surface,
                child: Column(
                  children: [
                    _ShellHeader(
                      menuOpen: _menuOpen,
                      menuProgress: _menuController.value,
                      onMenuTap: _toggleMenu,
                      showHomeActions: index == 0,
                      onProfileTap: () => AppRouter.openProfile(context),
                    ),
                    Expanded(
                      child: MediaQuery.removePadding(
                        context: context,
                        removeTop: true,
                        child: IndexedStack(
                          index: index,
                          children: [
                            for (var i = 0; i < _destinations.length; i++)
                              _FadeThroughPage(
                                  active: i == index,
                                  child: _destinations[i]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Tap outside (exposed Home strip) closes menu.
            if (_menuOpen)
              AnimatedBuilder(
                animation: _menuAnimation,
                builder: (context, _) {
                  final width = MediaQuery.sizeOf(context).width;
                  final shift =
                      _menuAnimation.value * (width * 0.78).clamp(260.0, 340.0);
                  return Positioned(
                    left: shift + (width - shift) * 0.0,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _closeMenu,
                      child: Container(
                        margin: EdgeInsets.only(left: width - shift - 0),
                        width: double.infinity,
                        color: Colors.transparent,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        bottomNavigationBar: StudentOSBottomNavigation(
          selectedIndex: index,
          onDestinationSelected: (i) {
            if (_menuOpen) {
              _closeMenu();
              Future.delayed(const Duration(milliseconds: 120), () {
                if (mounted) controller.setSelectedIndex(i);
              });
            } else {
              controller.setSelectedIndex(i);
            }
          },
        ),
      ),
    );
  }
}

/// Compact premium shell header: bold hamburger + Student OS title + a unified
/// right-side action group. On Home the group is the full [XP · Bell · Profile];
/// every other destination keeps a single compact Notification bell. All items
/// share one vertical center, one visual height and one spacing rhythm.
class _ShellHeader extends StatelessWidget {
  const _ShellHeader({
    required this.menuOpen,
    required this.menuProgress,
    required this.onMenuTap,
    this.showHomeActions = false,
    this.onProfileTap,
  });

  final bool menuOpen;
  final double menuProgress;
  final VoidCallback onMenuTap;

  /// Home exposes the full [XP · Bell · Profile] action group.
  final bool showHomeActions;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final topInset = MediaQuery.paddingOf(context).top;
    final compact = MediaQuery.sizeOf(context).width < 360;

    return Container(
      padding: EdgeInsets.only(
        top: topInset + 4,
        left: compact ? 8 : 10,
        right: compact ? 10 : 16,
        bottom: 4,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outline, width: 1)),
      ),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Semantics(
              label: menuOpen ? 'Close navigation' : 'Open navigation',
              button: true,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onMenuTap,
                  child: SizedBox(
                    width: 40,
                    height: 44,
                    child: Center(
                      child: CustomPaint(
                        size: const Size(30, 30),
                        painter: _ShellMenuPainter(
                          progress: menuProgress.clamp(0.0, 1.0),
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Student OS',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
            SizedBox(width: compact ? 10 : 14),
            if (showHomeActions) ...[
              const _ShellXpPill(),
              SizedBox(width: compact ? 8 : 10),
              _ShellActionButton(
                semanticLabel: 'Notifications',
                onTap: () => AppRouter.openNotifications(context),
                child: Icon(
                  Icons.notifications_outlined,
                  size: 19,
                  color: scheme.onSurface,
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              _ShellProfileButton(onTap: onProfileTap ?? () {}),
            ] else
              _ShellActionButton(
                semanticLabel: 'Notifications',
                onTap: () => AppRouter.openNotifications(context),
                child: Icon(
                  Icons.notifications_outlined,
                  size: 19,
                  color: scheme.onSurface,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact premium XP status chip: forest identity on a soft sage tint.
/// Follows the global ProgressionController so the value stays live.
class _ShellXpPill extends StatelessWidget {
  const _ShellXpPill();

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return ListenableBuilder(
      listenable: ProgressionController.instance,
      builder: (context, _) {
        final xp = ProgressionController.instance.totalXp;
        return Semantics(
          label: '$xp XP',
          container: true,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(StudentOSRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 13, color: palette.primary),
                const SizedBox(width: 4),
                Text(
                  '$xp XP',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Compact icon action (notification bell) — grouped and standalone variants
/// share the same 32dp touch surface for a consistent action-group rhythm.
class _ShellActionButton extends StatelessWidget {
  const _ShellActionButton({
    required this.semanticLabel,
    required this.onTap,
    required this.child,
  });

  final String semanticLabel;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Compact circular profile shortcut — the final, rightmost primary action,
/// aligned perfectly with the XP chip and notification bell.
class _ShellProfileButton extends StatelessWidget {
  const _ShellProfileButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppPressable(
      onTap: onTap,
      semanticLabel: 'Profile',
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.primary.withValues(alpha: 0.08),
          border: Border.all(
            color: palette.primary.withValues(alpha: 0.28),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.person_outline_rounded,
          size: 16,
          color: palette.primary,
        ),
      ),
    );
  }
}

class _ShellMenuPainter extends CustomPainter {
  _ShellMenuPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  static const double _strokeWidth = 4.0;
  static const double _gap = 6.0;
  static const double _startX = 2.0;
  static const double _long = 26.0;
  static const double _medium = 18.0;
  static const double _short = 11.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _strokeWidth;
    final totalH = _strokeWidth * 3 + _gap * 2;
    final startY = (size.height - totalH) / 2 + _strokeWidth / 2;
    final midY = startY + _strokeWidth + _gap;
    final botY = midY + _strokeWidth + _gap;
    if (progress <= 0.001) {
      canvas.drawLine(
          Offset(_startX, startY), Offset(_startX + _long, startY), paint);
      canvas.drawLine(
          Offset(_startX, midY), Offset(_startX + _medium, midY), paint);
      canvas.drawLine(
          Offset(_startX, botY), Offset(_startX + _short, botY), paint);
      return;
    }
    final c = Offset(_startX + _long / 2, startY + (totalH - _strokeWidth) / 2);
    final angle = progress * 0.785398;
    const len = 26.0;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    canvas.drawLine(const Offset(-len / 2, 0), const Offset(len / 2, 0), paint);
    canvas.restore();
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-angle);
    canvas.drawLine(const Offset(-len / 2, 0), const Offset(len / 2, 0), paint);
    canvas.restore();
    if (progress < 0.7) {
      final p = Paint()
        ..color = color.withValues(alpha: (1 - progress / 0.7))
        ..strokeCap = StrokeCap.round
        ..strokeWidth = _strokeWidth;
      canvas.drawLine(Offset(_startX, midY),
          Offset(_startX + _medium * (1 - progress * 0.6), midY), p);
    }
  }

  @override
  bool shouldRepaint(covariant _ShellMenuPainter old) =>
      old.progress != progress || old.color != color;
}

class _MenuHost extends StatelessWidget {
  const _MenuHost({
    required this.selectedIndex,
    required this.itemAnimation,
    required this.onSelect,
    required this.onClose,
    required this.onProgress,
    required this.onAssistant,
    required this.onSettings,
    required this.onLogout,
  });

  final int selectedIndex;
  final Animation<double> itemAnimation;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;
  final VoidCallback onProgress;
  final VoidCallback onAssistant;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StudentService.instance,
      builder: (context, _) {
        final profile = StudentService.instance.profile;
        final hour = DateTime.now().hour;
        final greeting =
            hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
        final name = profile.displayName.isNotEmpty
            ? profile.displayName
            : null;
        // Constrain menu width so Home strip stays visible on the right.
        final width = MediaQuery.sizeOf(context).width;
        final menuWidth = (width * 0.78).clamp(260.0, 340.0);
        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: menuWidth,
            height: double.infinity,
            child: StudentOSMenu(
              selectedIndex: selectedIndex,
              onSelect: onSelect,
              onClose: onClose,
              onProgress: onProgress,
              onAssistant: onAssistant,
              onSettings: onSettings,
              onLogout: onLogout,
              itemAnimation: itemAnimation,
              userGreeting: greeting,
              userName: name,
            ),
          ),
        );
      },
    );
  }
}

class _FadeThroughPage extends StatefulWidget {
  const _FadeThroughPage({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_FadeThroughPage> createState() => _FadeThroughPageState();
}

class _FadeThroughPageState extends State<_FadeThroughPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: widget.active ? 1 : 0,
    );
    _opacity =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(covariant _FadeThroughPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active &&
        !oldWidget.active &&
        !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    // Lightweight 180ms viewport fade only — IndexedStack retains state.
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}
