import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'glass_surface.dart';

/// Translucent Liquid Glass Button.
class GlassButton extends StatefulWidget {
  const GlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    this.level = GlassLevel.standard,
    this.isLoading = false,
    this.tintColor,
    this.padding,
    this.radius = LiquidRadius.md,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool expand;
  final GlassLevel level;
  final bool isLoading;
  final Color? tintColor;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final String? semanticLabel;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    final Color textColor = widget.tintColor ??
        (isDark ? LiquidColors.textPrimaryDark : LiquidColors.textPrimaryLight);

    final Widget content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: LiquidSpacing.xs),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: textColor),
          const SizedBox(width: LiquidSpacing.xs),
        ],
        Text(
          widget.label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isEnabled
                ? textColor
                : textColor.withValues(alpha: 0.4),
            fontWeight: FontWeight.w600,
          ),
        ),
        if (widget.trailingIcon != null && !widget.isLoading) ...[
          const SizedBox(width: LiquidSpacing.xs),
          Icon(widget.trailingIcon, size: 18, color: textColor),
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.semanticLabel ?? widget.label,
      child: AnimatedScale(
        scale: _isPressed && isEnabled ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: GlassSurface(
            level: widget.level,
            radius: widget.radius,
            padding: widget.padding ??
                const EdgeInsets.symmetric(
                  horizontal: LiquidSpacing.md,
                  vertical: 12,
                ),
            backgroundColor: widget.tintColor?.withValues(
              alpha: isDark ? 0.18 : 0.12,
            ),
            borderColor: widget.tintColor?.withValues(
              alpha: isDark ? 0.35 : 0.25,
            ),
            onTap: isEnabled
                ? () {
                    widget.onPressed?.call();
                  }
                : null,
            child: Listener(
              onPointerDown: isEnabled
                  ? (_) => setState(() => _isPressed = true)
                  : null,
              onPointerUp: isEnabled
                  ? (_) => setState(() => _isPressed = false)
                  : null,
              onPointerCancel: isEnabled
                  ? (_) => setState(() => _isPressed = false)
                  : null,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
