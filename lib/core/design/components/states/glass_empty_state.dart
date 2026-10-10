import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../glass/glass_card.dart';

/// Unified Empty State component for Student OS.
class GlassEmptyState extends StatelessWidget {
  const GlassEmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon = Icons.inbox_outlined,
    this.iconColor,
    this.primaryAction,
    this.secondaryAction,
    this.compact = false,
    this.wrapInCard = false,
  });

  final String title;
  final String? description;
  final IconData icon;
  final Color? iconColor;
  final Widget? primaryAction;
  final Widget? secondaryAction;
  final bool compact;
  final bool wrapInCard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = iconColor ?? theme.colorScheme.primary;

    Widget body = Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? LiquidSpacing.md : LiquidSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(
                compact ? LiquidSpacing.sm : LiquidSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: isDark ? 0.16 : 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: compact ? 24 : 36,
                color: primary,
              ),
            ),
            SizedBox(height: compact ? LiquidSpacing.sm : LiquidSpacing.md),
            Text(
              title,
              style: (compact
                      ? theme.textTheme.titleSmall
                      : theme.textTheme.titleMedium)
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: LiquidSpacing.xs),
              Text(
                description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? LiquidColors.textSecondaryDark
                      : LiquidColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (primaryAction != null || secondaryAction != null) ...[
              SizedBox(height: compact ? LiquidSpacing.md : LiquidSpacing.lg),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (secondaryAction != null) ...[
                    secondaryAction!,
                    const SizedBox(width: LiquidSpacing.xs),
                  ],
                  ...?primaryAction != null ? [primaryAction!] : null,
                ],
              ),
            ],
          ],
        ),
      ),
    );

    if (wrapInCard) {
      return GlassCard(
        padding: EdgeInsets.zero,
        radius: LiquidRadius.xl,
        child: body,
      );
    }

    return body;
  }
}
