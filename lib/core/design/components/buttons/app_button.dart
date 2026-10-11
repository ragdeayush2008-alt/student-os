import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

/// Style variants for unified [AppButton].
enum AppButtonVariant {
  /// Solid forest emerald (#285C4D) — primary actions.
  primary,

  /// Solid white/neutral surface with border — secondary actions.
  secondary,

  /// Minimal text button — tertiary actions.
  tertiary,

  /// Compact button — for layout-constrained areas.
  compact,

  /// Deep forest destructive accent (#2F453D) — delete / cancel actions.
  destructive,
}

/// Unified button component for Student OS Academic Command Center.
///
/// Provides:
/// - Tactile scale-on-press feedback
/// - Consistent height (44-48px) meeting touch-target standards
/// - Normal, pressed, disabled, and loading states
/// - Full accessibility semantics
/// - Solid surfaces (no glass)
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    this.isLoading = false,
    this.radius = LiquidRadius.md,
    this.padding,
    this.semanticLabel,
  });

  /// Factory for Primary button (Strong forest accent #285C4D).
  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    this.isLoading = false,
    this.radius = LiquidRadius.md,
    this.padding,
    this.semanticLabel,
  }) : variant = AppButtonVariant.primary;

  /// Factory for Secondary button (Translucent Glass).
  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    this.isLoading = false,
    this.radius = LiquidRadius.md,
    this.padding,
    this.semanticLabel,
  }) : variant = AppButtonVariant.secondary;

  /// Factory for Tertiary button (Minimal Text).
  const AppButton.tertiary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    this.isLoading = false,
    this.radius = LiquidRadius.md,
    this.padding,
    this.semanticLabel,
  }) : variant = AppButtonVariant.tertiary;

  /// Factory for Destructive button (Deep forest #2F453D).
  const AppButton.destructive({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    this.isLoading = false,
    this.radius = LiquidRadius.md,
    this.padding,
    this.semanticLabel,
  }) : variant = AppButtonVariant.destructive;

  /// Factory for Compact button (Dense touch areas).
  const AppButton.compact({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    this.isLoading = false,
    this.radius = LiquidRadius.sm,
    this.padding,
    this.semanticLabel,
  }) : variant = AppButtonVariant.compact;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool expand;
  final bool isLoading;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color bg;
    Color fg;
    Color? border;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        bg = LiquidColors.primary;
        fg = Colors.white;
        border = null;
        break;
      case AppButtonVariant.secondary:
        // Solid secondary: white (light) / dark surface + subtle border.
        bg = isDark ? const Color(0xFF161B22) : Colors.white;
        fg = isDark ? LiquidColors.textPrimaryDark : LiquidColors.textPrimaryLight;
        border = isDark ? const Color(0xFF2A3342) : const Color(0xFFE4E7EC);
        break;
      case AppButtonVariant.tertiary:
        bg = Colors.transparent;
        fg = LiquidColors.primary;
        border = null;
        break;
      case AppButtonVariant.destructive:
        bg = LiquidColors.error;
        fg = Colors.white;
        border = null;
        break;
      case AppButtonVariant.compact:
        bg = isDark ? const Color(0xFF161B22) : Colors.white;
        fg = isDark ? LiquidColors.textPrimaryDark : LiquidColors.textPrimaryLight;
        border = isDark ? const Color(0xFF2A3342) : const Color(0xFFE4E7EC);
        break;
    }

    final effectivePadding = widget.padding ??
        (widget.variant == AppButtonVariant.compact
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: LiquidSpacing.lg, vertical: 13));

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: LiquidSpacing.xs),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: fg),
          const SizedBox(width: LiquidSpacing.xs),
        ],
        Text(
          widget.label,
          style: (widget.variant == AppButtonVariant.compact
                  ? theme.textTheme.labelSmall
                  : theme.textTheme.labelLarge)
              ?.copyWith(
            color: isEnabled ? fg : fg.withValues(alpha: 0.4),
            fontWeight: FontWeight.w700,
          ),
        ),
        if (widget.trailingIcon != null && !widget.isLoading) ...[
          const SizedBox(width: LiquidSpacing.xs),
          Icon(widget.trailingIcon, size: 18, color: fg),
        ],
      ],
    );

    Widget buttonSurface;
    buttonSurface = Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: isEnabled ? bg : bg.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(widget.radius),
        border: border != null ? Border.all(color: border) : null,
        boxShadow: widget.variant == AppButtonVariant.primary && isEnabled
            ? [
                BoxShadow(
                  color: LiquidColors.primary.withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: content,
    );

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.semanticLabel ?? widget.label,
      child: AnimatedScale(
        scale: _isPressed && isEnabled ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.radius),
          child: InkWell(
            onTap: isEnabled ? widget.onPressed : null,
            onHighlightChanged: (v) => setState(() => _isPressed = v),
            borderRadius: BorderRadius.circular(widget.radius),
            child: buttonSurface,
          ),
        ),
      ),
    );
  }
}
