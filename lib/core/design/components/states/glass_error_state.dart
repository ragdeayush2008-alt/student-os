import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../buttons/app_button.dart';
import '../../glass/glass_card.dart';
import 'glass_empty_state.dart';

/// Full-view Error State with retry action.
class GlassErrorState extends StatelessWidget {
  const GlassErrorState({
    super.key,
    required this.message,
    this.title = 'Something went wrong',
    this.onRetry,
    this.compact = false,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GlassEmptyState(
      icon: Icons.error_outline_rounded,
      iconColor: LiquidColors.error,
      title: title,
      description: message,
      compact: compact,
      primaryAction: onRetry != null
          ? AppButton.secondary(
              label: 'Try Again',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            )
          : null,
    );
  }
}

/// Compact Error Banner / Card.
class AppErrorCard extends StatelessWidget {
  const AppErrorCard({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.margin,
  });

  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      margin: margin,
      backgroundColor: LiquidColors.error.withValues(alpha: isDark ? 0.15 : 0.08),
      borderColor: LiquidColors.error.withValues(alpha: isDark ? 0.35 : 0.25),
      radius: LiquidRadius.lg,
      padding: LiquidSpacing.cardPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: LiquidColors.error,
          ),
          const SizedBox(width: LiquidSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: LiquidColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? LiquidColors.textSecondaryDark
                        : LiquidColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: LiquidSpacing.xs),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              color: LiquidColors.error,
              onPressed: onRetry,
              tooltip: 'Retry',
            ),
          ],
        ],
      ),
    );
  }
}
