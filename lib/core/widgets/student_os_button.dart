import 'package:flutter/material.dart';

import '../design/tokens/student_os_tokens.dart';
import 'student_os_icon_glow.dart';

/// Consistent Student OS button system (solid, no glass).
///
/// Primary: solid Student OS Blue. Secondary: white/neutral + border.
/// Tertiary: text. Danger: red, destructive only.
enum StudentOSButtonVariant { primary, secondary, tertiary, danger }

/// Canonical button sizes — one language for every CTA.
enum StudentOSButtonSize { compact, regular, large }

class StudentOSButton extends StatelessWidget {
  const StudentOSButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = StudentOSButtonVariant.primary,
    this.icon,
    this.expand = false,
    this.isLoading = false,
    this.semanticLabel,
    this.size = StudentOSButtonSize.regular,
    this.pill = false,
  });

  const StudentOSButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = false,
    this.isLoading = false,
    this.semanticLabel,
    this.size = StudentOSButtonSize.regular,
    this.pill = false,
  }) : variant = StudentOSButtonVariant.primary;

  const StudentOSButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = false,
    this.isLoading = false,
    this.semanticLabel,
    this.size = StudentOSButtonSize.regular,
    this.pill = false,
  }) : variant = StudentOSButtonVariant.secondary;

  const StudentOSButton.tertiary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = false,
    this.isLoading = false,
    this.semanticLabel,
    this.size = StudentOSButtonSize.regular,
    this.pill = false,
  }) : variant = StudentOSButtonVariant.tertiary;

  const StudentOSButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = false,
    this.isLoading = false,
    this.semanticLabel,
    this.size = StudentOSButtonSize.regular,
    this.pill = false,
  }) : variant = StudentOSButtonVariant.danger;

  /// Large full-width call-to-action for onboarding / key conversions.
  const StudentOSButton.largeCTA({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.semanticLabel,
    this.variant = StudentOSButtonVariant.primary,
  })  : expand = true,
        size = StudentOSButtonSize.large,
        pill = true;

  /// Compact button for inline / dense placements.
  const StudentOSButton.compact({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.semanticLabel,
    this.variant = StudentOSButtonVariant.secondary,
  })  : expand = false,
        size = StudentOSButtonSize.compact,
        pill = false;

  final String label;
  final VoidCallback? onPressed;
  final StudentOSButtonVariant variant;
  final IconData? icon;
  final bool expand;
  final bool isLoading;
  final String? semanticLabel;
  final StudentOSButtonSize size;
  final bool pill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = onPressed != null && !isLoading;

    Color bg;
    Color fg;
    Color? border;
    switch (variant) {
      case StudentOSButtonVariant.primary:
        bg = scheme.primary;
        fg = scheme.onPrimary;
        break;
      case StudentOSButtonVariant.secondary:
        bg = scheme.surface;
        fg = scheme.onSurface;
        border = scheme.outline;
        break;
      case StudentOSButtonVariant.tertiary:
        bg = Colors.transparent;
        fg = scheme.primary;
        break;
      case StudentOSButtonVariant.danger:
        bg = scheme.error;
        fg = scheme.onError;
        break;
    }

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        else if (icon != null) ...[
          // Icons inside solid primary/danger buttons carry a very subtle
          // luminous edge; the button itself never glows. Disabled: none.
          StudentOSIconGlow(
            glowColor: fg,
            intensity: StudentOSGlowIntensity.minimal,
            radius: StudentOSGlowRadius.small,
            enabled: enabled &&
                (variant == StudentOSButtonVariant.primary ||
                    variant == StudentOSButtonVariant.danger),
            child: Icon(
              icon,
              size: 18,
              color: enabled ? fg : fg.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: enabled ? fg : fg.withValues(alpha: 0.4),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    final EdgeInsetsGeometry padding;
    switch (size) {
      case StudentOSButtonSize.compact:
        padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10);
        break;
      case StudentOSButtonSize.regular:
        padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
        break;
      case StudentOSButtonSize.large:
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 18);
        break;
    }
    final borderRadius =
        BorderRadius.circular(pill ? StudentOSRadius.pill : StudentOSRadius.medium);

    if (variant == StudentOSButtonVariant.tertiary) {
      return Semantics(
        button: true,
        enabled: enabled,
        label: semanticLabel ?? label,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: TextButton(
            onPressed: enabled ? onPressed : null,
            style: TextButton.styleFrom(padding: padding),
            child: content,
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? label,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: FilledButton(
            onPressed: enabled ? onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              disabledBackgroundColor: bg,
              disabledForegroundColor: fg,
              side: border != null ? BorderSide(color: border) : null,
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
              padding: padding,
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Circular icon button with solid surface + border.
class StudentOSIconButton extends StatelessWidget {
  const StudentOSIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.semanticLabel,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: scheme.surface,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Center(
              child: Icon(icon, size: 22, color: scheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}
