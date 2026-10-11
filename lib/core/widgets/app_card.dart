import 'package:flutter/material.dart';

import '../constants/app_elevation.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../design/glass/glass_surface.dart';
import '../theme/app_theme.dart';

/// A premium card used across Student OS.
///
/// SOLID surfaces — natural-white/dark surface, 1px subtle border, restrained
/// soft shadow, 20px radius, 16px padding. The green family supplies the
/// surrounding tonal context; cards themselves stay calm so foreground content
/// (and the small blue action accents) always reads clearly.
///
/// The legacy glass parameters ([isGlass], [level], [useBlur], [glowColor])
/// are retained for API compatibility but no longer produce translucency
/// or blur: the card always renders as a solid surface.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.color,
    this.borderColor,
    this.elevation = AppElevation.low,
    this.radius = AppRadius.lg,
    this.borderRadius,
    this.isGlass = false,
    this.glowColor,
    this.gradient,
    this.level = GlassLevel.standard,
    this.useBlur = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double elevation;
  final double radius;
  final BorderRadius? borderRadius;
  final bool isGlass;
  final Color? glowColor;
  final List<Color>? gradient;

  /// Material hierarchy of the card. Defaults to [GlassLevel.standard].
  final GlassLevel level;

  /// Whether the card applies bounded background frost. Small compact tiles
  /// may disable blur for performance and density.
  final bool useBlur;

  BorderRadius get _radius => borderRadius ?? BorderRadius.circular(radius);

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = palette.isDark;

    // SOLID rendering: opaque surface + 1px border + soft shadow.
    final Color effectiveSurface = color ?? scheme.surfaceContainerLow;
    final Color effectiveBorder =
        borderColor ?? scheme.outline.withValues(alpha: 0.7);

    // Restrained shadow: tinted with the surface ink rather than pure black so
    // light mode keeps a warm, calm feel instead of a grey cast.
    final Color shadowTint = scheme.shadow;
    List<BoxShadow>? effectiveShadows = const <BoxShadow>[];
    if (elevation > 0) {
      effectiveShadows = AppElevation.soft(shadowTint, isDark: isDark);
    }

    Widget inner = Padding(padding: padding, child: child);

    if (gradient != null) {
      inner = DecoratedBox(
        position: DecorationPosition.background,
        decoration: BoxDecoration(
          borderRadius: _radius,
          gradient: LinearGradient(
            colors: gradient!,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: inner,
      );
    }

    final surface = Container(
      decoration: BoxDecoration(
        color: gradient != null ? null : effectiveSurface,
        borderRadius: _radius,
        border: Border.all(color: effectiveBorder, width: 1),
        boxShadow: effectiveShadows,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        borderRadius: _radius,
        clipBehavior: onTap != null ? Clip.antiAlias : Clip.none,
        child: InkWell(
          onTap: onTap,
          borderRadius: onTap != null ? _radius : null,
          child: inner,
        ),
      ),
    );

    return surface;
  }
}