import 'package:flutter/material.dart';

/// Solid error banner for authentication — Command Center system.
///
/// Light red tinted surface, clear border, error icon. No glass.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bg =
        isDark ? scheme.errorContainer.withValues(alpha: 0.35) : const Color(0xFFFEE4E2);
    final border =
        isDark ? scheme.error.withValues(alpha: 0.5) : const Color(0xFFFECDC2);
    final fg = isDark ? scheme.errorContainer : const Color(0xFFB42318);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.error_outline_rounded,
              color: isDark ? scheme.error : const Color(0xFFD92D20),
              size: 18,
              semanticLabel: 'Error',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
