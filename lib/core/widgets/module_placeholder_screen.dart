import 'package:flutter/material.dart';

import '../animations/animated_entrance.dart';
import '../constants/app_icon_size.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'app_scaffold.dart';

/// A premium, reusable placeholder screen for future modules.
///
/// Ensures no future module opens a blank or ugly page. It presents the module
/// identity, a short description, a visual and the intended capabilities, all
/// with a smooth entrance. These are **visual foundations only** — the module
/// features are not implemented.
class ModulePlaceholderScreen extends StatelessWidget {
  const ModulePlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    this.capabilities = const [],
  });

  final String title;
  final IconData icon;
  final String description;
  final List<String> capabilities;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppScaffold(
      title: title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedEntrance(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: palette.accentGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.xlAll,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: AppIconSize.xl,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    title,
                    style: context.text.headlineSmall!.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: context.text.bodyMedium!.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _StatusPill(status: 'Coming in a future phase'),
          const SizedBox(height: AppSpacing.xl),
          if (capabilities.isNotEmpty) ...[
            Text('Planned capabilities', style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            for (final cap in capabilities)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 20,
                        color: palette.success,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(cap, style: context.text.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, size: 16, color: palette.info),
        const SizedBox(width: 6),
        Text(
          status,
          style: context.text.labelMedium!.copyWith(color: palette.info),
        ),
      ],
    );
  }
}
