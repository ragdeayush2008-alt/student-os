import 'package:flutter/material.dart';

import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../theme/app_theme.dart';

/// Primary action button with an animated scale-on-press and optional leading
/// icon. Uses the theme's primary color for a premium, energetic feel.
class AppPrimaryButton extends StatefulWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  State<AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<AppPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final enabled = widget.onPressed != null;

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: palette.onPrimary),
          const SizedBox(width: AppSpacing.xs),
        ],
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: context.text.labelLarge!.copyWith(
            color: palette.onPrimary,
            fontWeight: FontWeight.w700,
          ),
          child: Text(widget.label),
        ),
      ],
    );

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: enabled
            ? palette.primary
            : palette.onSurfaceMuted.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: enabled ? widget.onPressed : null,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 14,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// A secondary/outline button for non-primary actions.
class AppOutlineButton extends StatefulWidget {
  const AppOutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  State<AppOutlineButton> createState() => _AppOutlineButtonState();
}

class _AppOutlineButtonState extends State<AppOutlineButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: palette.outline),
        ),
        child: InkWell(
          onTap: widget.onPressed,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 14,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 18, color: palette.primary),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(widget.label, style: context.text.labelLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
