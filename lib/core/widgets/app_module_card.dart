import 'package:flutter/material.dart';

import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../theme/app_theme.dart';
import '../../data/mock/app_module.dart';
import 'app_card.dart';

/// A premium card representing a future module. Used in the Explore/More
/// browser and navigation module lists. Tapping navigates to a placeholder.
class AppModuleCard extends StatelessWidget {
  const AppModuleCard({super.key, required this.module, this.onTap});

  final AppModule module;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final open = onTap != null;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      color: palette.surface,
      radius: AppRadius.lg,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: palette.accentGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(module.icon, size: 26, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          module.title,
                          style: context.text.titleMedium,
                        ),
                      ),
                      _StatusChip(status: module.status),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(module.subtitle, style: context.text.bodySmall),
                ],
              ),
            ),
            if (open) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.chevron_right_rounded, color: palette.onSurfaceMuted),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: palette.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status,
        style: context.text.labelSmall!.copyWith(color: palette.warning),
      ),
    );
  }
}
