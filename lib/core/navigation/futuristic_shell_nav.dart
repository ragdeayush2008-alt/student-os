import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_durations.dart';
import '../../core/design/glass/glass_surface.dart';
import '../../core/theme/app_theme.dart';
import 'shell_destinations.dart';

/// Premium floating Liquid Glass bottom navigation for the Student OS shell.
///
/// The bar is a rounded, translucent, frosted glass object that sits above the
/// background with soft elevation and a subtle upper reflection. The selected
/// tab receives a small elevated translucent capsule with an accent glow —
/// never a full-width colored rectangle.
///
/// The five-tab architecture (Home · Plan & Study · Focus · Tools · Workspace)
/// remains locked for a later phase; only the material foundation is provided.
class FuturisticShellNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<ShellDestination> destinations;

  const FuturisticShellNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.destinations = ShellDestinations.all,
  });

  static const double _barHeight = 60.0;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset > 0 ? 10 : 8),
      child: GlassSurface(
        level: GlassLevel.elevated,
        radius: AppRadius.lg,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        // A subtle, crisp upper reflection so the floating surface reads
        // separated from the environment without dominating it.
        edgeLightBoost: 1.15,
        child: SizedBox(
          height: _barHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < destinations.length; i++)
                _ShellNavItem(
                  destination: destinations[i],
                  selected: i == selectedIndex,
                  colors: colors,
                  onTap: () => onDestinationSelected(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single bottom-navigation destination item.
class _ShellNavItem extends StatelessWidget {
  const _ShellNavItem({
    required this.destination,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final AppPalette colors;
  final VoidCallback onTap;

  static const double _iconSize = 22.0;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Expanded(
      child: Semantics(
        label: '${destination.title} tab',
        button: true,
        selected: selected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            splashColor: colors.primary.withValues(alpha: 0.10),
            highlightColor: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: selected ? 1 : 0),
              duration:
                  reduceMotion ? Duration.zero : AppDurations.fast,
              curve: AppCurves.standard,
              child: null,
              builder: (context, t, _) {
                final activeLerp = Curves.easeOutCubic.transform(t);
                final iconColor = Color.lerp(
                  colors.onSurfaceMuted,
                  Colors.white,
                  activeLerp,
                )!;
                final textColor = Color.lerp(
                  colors.onSurfaceMuted,
                  colors.primary,
                  activeLerp,
                )!;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Compact selected island — static shadow, tiny tactile.
                    Container(
                      width: 34,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                        gradient: selected
                            ? const LinearGradient(
                                colors: [
                                  AppColors.rewardStart,
                                  AppColors.rewardEnd,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: selected ? null : Colors.transparent,
                        border: selected
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.30),
                                width: 0.8,
                              )
                            : null,
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.14),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: 0.10),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : const [],
                      ),
                      child: Center(
                        child: Icon(
                          selected
                              ? destination.selectedIcon
                              : destination.icon,
                          size: _iconSize,
                          color: iconColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      destination.title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        letterSpacing: 0.1,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}