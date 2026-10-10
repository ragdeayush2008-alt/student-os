import 'package:flutter/material.dart';

import '../../tokens/app_borders.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_radius.dart';
import '../../glass/glass_surface.dart';

/// Style variants for [AppIconButton].
enum AppIconButtonVariant {
  /// Glass translucent surface.
  glass,

  /// Solid primary/secondary background.
  solid,

  /// Minimal ghost button without background.
  ghost,
}

/// Unified Icon Button for Student OS.
class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = AppIconButtonVariant.glass,
    this.size = 40,
    this.iconSize = 20,
    this.color,
    this.backgroundColor,
    this.isCircle = true,
    this.radius = LiquidRadius.sm,
    this.badge,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final AppIconButtonVariant variant;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? backgroundColor;
  final bool isCircle;
  final double radius;
  final Widget? badge;
  final String? semanticLabel;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnabled = widget.onPressed != null;

    final effectiveColor = widget.color ??
        (isDark ? LiquidColors.textPrimaryDark : LiquidColors.textPrimaryLight);

    final borderRadius = widget.isCircle
        ? BorderRadius.circular(widget.size / 2)
        : BorderRadius.circular(widget.radius);

    Widget iconWidget = Icon(
      widget.icon,
      size: widget.iconSize,
      color: isEnabled ? effectiveColor : effectiveColor.withValues(alpha: 0.35),
    );

    if (widget.badge != null) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            right: -4,
            top: -4,
            child: widget.badge!,
          ),
        ],
      );
    }

    Widget buttonSurface;
    switch (widget.variant) {
      case AppIconButtonVariant.glass:
        buttonSurface = GlassSurface(
          level: GlassLevel.standard,
          width: widget.size,
          height: widget.size,
          borderRadius: borderRadius,
          padding: EdgeInsets.zero,
          backgroundColor: widget.backgroundColor,
          child: Center(child: iconWidget),
        );
        break;
      case AppIconButtonVariant.solid:
        buttonSurface = Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? theme.colorScheme.primary,
            borderRadius: borderRadius,
          ),
          child: Center(child: iconWidget),
        );
        break;
      case AppIconButtonVariant.ghost:
        buttonSurface = Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: LiquidBorders.allHair(
              isDark ? LiquidColors.borderDark : LiquidColors.borderLight,
            ),
          ),
          child: Center(child: iconWidget),
        );
        break;
    }

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.semanticLabel,
      child: AnimatedScale(
        scale: _isPressed && isEnabled ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            onTap: isEnabled ? widget.onPressed : null,
            onHighlightChanged: (v) => setState(() => _isPressed = v),
            borderRadius: borderRadius,
            child: buttonSurface,
          ),
        ),
      ),
    );
  }
}
