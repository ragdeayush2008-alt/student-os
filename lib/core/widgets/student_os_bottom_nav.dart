import 'package:flutter/material.dart';

import '../design/tokens/student_os_tokens.dart';
import '../navigation/shell_destinations.dart';

/// Premium flat bottom navigation — exactly 5 destinations, locked order:
/// Home, Plan & Study, SprintX, Tools Hub, Workspace.
///
/// Selected state is communicated through:
/// - Forest/green color (the product's identity)
/// - slightly larger icon (~1.08x scale)
/// - subtle upward lift (~3dp)
/// - slightly stronger label weight
/// - smooth color transition
///
/// No background shape, no pill, no dot, no glow, no top divider — the surface
/// stays clean and solid. Uses one coherent modern icon family with rounded
/// geometry.
class StudentOSBottomNavigation extends StatelessWidget {
  const StudentOSBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.destinations = ShellDestinations.all,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<ShellDestination> destinations;

  static const double _barHeight = 64;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: bottomInset > 0 ? 0 : 4),
        child: SizedBox(
          height: _barHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < destinations.length; i++)
                _Item(
                  destination: destinations[i],
                  selected: i == selectedIndex,
                  onTap: () => onDestinationSelected(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  static const double _iconSize = 22;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    // Forest defines the product; sage provides the readable selected state on
    // both light and dark surfaces.
    final activeColor = isDark ? StudentOSColors.sageDark : StudentOSColors.forest;
    final iconColor = selected ? activeColor : scheme.onSurfaceVariant;

    return Expanded(
      child: Semantics(
        label: '${destination.title} tab',
        button: true,
        selected: selected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: activeColor.withValues(alpha: 0.08),
            highlightColor: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _SelectedIconTransition(
                  selected: selected,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: selected
                          ? activeColor.withValues(
                              alpha: isDark ? 0.22 : 0.12)
                          : Colors.transparent,
                    ),
                    child: Icon(
                      selected
                          ? destination.selectedIcon
                          : destination.icon,
                      size: _iconSize,
                      color: iconColor,
                      semanticLabel: '${destination.title} icon',
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  destination.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: iconColor,
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

/// Reusable selected-icon transition: the icon lifts ~3dp and scales ~8%,
/// settling smoothly. Label and bar stay stable; only the icon moves.
///
/// TCC: 180ms easeOutCubic — no bounce, no jump, no bar animation.
/// Uses implicit [AnimatedScale]/[AnimatedSlide] pattern with static child
/// via TweenAnimationBuilder with child param (no subtree rebuilds).
class _SelectedIconTransition extends StatelessWidget {
  const _SelectedIconTransition({
    required this.selected,
    required this.child,
  });

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: selected ? 1 : 0),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, icon) {
        return Transform.translate(
          offset: Offset(0, -3 * t),
          child: Transform.scale(
            scale: 1 + 0.08 * t,
            child: icon,
          ),
        );
      },
    );
  }
}
