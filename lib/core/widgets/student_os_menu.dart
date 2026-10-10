import 'package:flutter/material.dart';

import '../design/tokens/student_os_tokens.dart';

/// Solid Student OS navigation menu surface.
///
/// Primary: Home, Plan & Study, SprintX, Tools Hub, Workspace.
/// Secondary (below divider): Progress, Ask Student OS, Settings.
/// Bottom: Logout.
///
/// The surface is Deep Forest (emerald), not blue — the green family is the
/// product's visual identity. Light text/icons, restrained sage selected
/// state. SOLID — no frosted glass.
class StudentOSMenu extends StatelessWidget {
  const StudentOSMenu({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.onClose,
    required this.onProgress,
    required this.onAssistant,
    required this.onSettings,
    required this.onLogout,
    required this.itemAnimation,
    this.userGreeting,
    this.userName,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;
  final VoidCallback onProgress;
  final VoidCallback onAssistant;
  final VoidCallback onSettings;
  final VoidCallback onLogout;
  final Animation<double> itemAnimation;
  final String? userGreeting;
  final String? userName;

  /// Deep Forest menu surface (the hamburger/contextual menu identity).
  static const Color menuSurface = StudentOSColors.deepForest;

  /// Retained alias — now deep forest rather than blue.
  static const Color menuBlue = menuSurface;

  /// Restrained sage accent for the selected/pressed item.
  static const Color menuAccent = StudentOSColors.sage;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      color: menuBlue,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            top: topInset + 8,
            bottom: bottomInset + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Student OS + compact identity + X
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Student OS',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: Colors.white,
                            ),
                          ),
                          if (userName != null && userName!.isNotEmpty)
                            Text(
                              '${userGreeting ?? 'Hello'}\n$userName',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Semantics(
                      label: 'Close navigation',
                      button: true,
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: onClose,
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: Icon(Icons.close_rounded,
                                  color: Colors.white, size: 26),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Primary destinations with staggered fade/slide.
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: [
                    for (var i = 0; i < 5; i++)
                      _Staggered(
                        animation: itemAnimation,
                        index: i,
                        child: _PrimaryItem(
                          index: i,
                          selected: i == selectedIndex,
                          onTap: () => onSelect(i),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    for (var j = 0; j < 3; j++)
                      _Staggered(
                        animation: itemAnimation,
                        index: 5 + j,
                        child: _SecondaryItem(
                          index: j,
                          onProgress: onProgress,
                          onAssistant: onAssistant,
                          onSettings: onSettings,
                        ),
                      ),
                  ],
                ),
              ),
              // Bottom: Logout
              _Staggered(
                animation: itemAnimation,
                index: 8,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                  child: Semantics(
                    label: 'Log out',
                    button: true,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: onLogout,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.logout_rounded,
                                  size: 20,
                                  color: Colors.white
                                      .withValues(alpha: 0.9)),
                              const SizedBox(width: 12),
                              const Text(
                                'Logout',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryItem extends StatelessWidget {
  const _PrimaryItem({
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final VoidCallback onTap;

  static const _labels = [
    'Home',
    'Plan & Study',
    'SprintX',
    'Tools Hub',
    'Workspace',
  ];
  static const _icons = [
    Icons.home_outlined,
    Icons.calendar_today_outlined,
    Icons.bolt_outlined,
    Icons.widgets_outlined,
    Icons.grid_view_outlined,
  ];
  static const _selectedIcons = [
    Icons.home_rounded,
    Icons.calendar_today_rounded,
    Icons.bolt_rounded,
    Icons.widgets_rounded,
    Icons.grid_view_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Semantics(
        label: '${_labels[index]} navigation item',
        button: true,
        selected: selected,
        child: Material(
          // Restrained sage selected state (not a heavy white wash).
          color: selected
              ? StudentOSColors.sage.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 13),
              child: Row(
                children: [
                  Icon(
                    selected ? _selectedIcons[index] : _icons[index],
                    size: 22,
                    color: selected
                        ? StudentOSColors.paleSage
                        : Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _labels[index],
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: StudentOSColors.softSage,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryItem extends StatelessWidget {
  const _SecondaryItem({
    required this.index,
    required this.onProgress,
    required this.onAssistant,
    required this.onSettings,
  });

  final int index;
  final VoidCallback onProgress;
  final VoidCallback onAssistant;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final data = [
      ('Progress', Icons.bar_chart_rounded, onProgress),
      ('Ask Student OS', Icons.smart_toy_outlined, onAssistant),
      ('Settings', Icons.settings_outlined, onSettings),
    ][index];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Semantics(
        label: '${data.$1} navigation item',
        button: true,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: data.$3,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(data.$2,
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.9)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data.$1,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Staggered fade/slide entrance for menu items.
class _Staggered extends StatelessWidget {
  const _Staggered({
    required this.animation,
    required this.index,
    required this.child,
  });

  final Animation<double> animation;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) return child;
    final start = (index * 0.06).clamp(0.0, 0.6);
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.25, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
