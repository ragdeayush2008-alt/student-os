import 'package:flutter/material.dart';

/// Primary action button for authentication — Command Center system.
///
/// Solid Student OS blue, white text, 12px radius, comfortable 52dp height.
/// Subtle press feedback, clear disabled + loading states. No gradients,
/// no glow, no glass.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.loading = false,
    this.height = 52,
    this.radius = 12,
    this.prefixIcon,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool loading;
  final double height;
  final double radius;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bool enabled = onPressed != null && !loading;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            disabledBackgroundColor:
                scheme.surfaceContainerHighest.withValues(alpha: 0.7),
            disabledForegroundColor:
                scheme.onSurfaceVariant.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            elevation: 0,
          ),
          child: loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      scheme.onPrimary,
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (prefixIcon != null) ...[
                      Icon(prefixIcon, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: enabled
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
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
