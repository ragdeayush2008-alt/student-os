import 'package:flutter/material.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../controller/focus_guard_controller.dart';
import '../../data/models/focus_guard_models.dart';
import '../screens/focus_guard_settings_screen.dart';

class FocusGuardCard extends StatelessWidget {
  const FocusGuardCard({super.key});

  @override
  Widget build(BuildContext context) {
    final guard = FocusGuardController.instance;
    return AnimatedBuilder(
      animation: guard,
      builder: (context, _) {
        final palette = AppTheme.colorsOf(context);
        final status = guard.permissionStatus;

        if (status == FocusGuardPermissionStatus.unsupported) {
          return const SizedBox.shrink();
        }

        if (status == FocusGuardPermissionStatus.ready) {
          return _buildReadyCard(context, palette, guard);
        }

        return _buildSetupCard(context, palette, guard);
      },
    );
  }

  Widget _buildReadyCard(
    BuildContext context,
    AppPalette palette,
    FocusGuardController guard,
  ) {
    return AppPressable(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const FocusGuardSettingsScreen(),
          ),
        );
      },
      child: AppCard(
        color: palette.surface,
        borderColor: palette.outline,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: palette.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                Icons.shield_rounded,
                color: palette.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: palette.success,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Focus Guard Ready',
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    guard.isGuardEnabled
                        ? '${guard.blockedPackages.length} apps blocked • ${guard.mode.label} Mode'
                        : 'Protection paused • Tap to configure',
                    style: context.text.bodySmall?.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: palette.onSurfaceMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupCard(
    BuildContext context,
    AppPalette palette,
    FocusGuardController guard,
  ) {
    final hasUsage = guard.hasUsageAccess;
    final hasOverlay = guard.hasOverlayPermission;

    return AppCard(
      color: palette.surface,
      borderColor: palette.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: palette.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: palette.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Focus Guard',
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'To protect your focus, Android permissions are required.',
                      style: context.text.bodySmall?.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          _permissionRow(
            context: context,
            palette: palette,
            title: 'Usage Access',
            isGranted: hasUsage,
            buttonLabel: 'Grant Usage Access',
            onTap: () => _showUsageAccessExplanation(context, guard),
          ),
          const SizedBox(height: AppSpacing.sm),
          _permissionRow(
            context: context,
            palette: palette,
            title: 'Display over other apps',
            isGranted: hasOverlay,
            buttonLabel: 'Grant Overlay Permission',
            onTap: () => _showOverlayExplanation(context, guard),
          ),
        ],
      ),
    );
  }

  Widget _permissionRow({
    required BuildContext context,
    required AppPalette palette,
    required String title,
    required bool isGranted,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Icon(
          isGranted ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: isGranted ? palette.success : palette.onSurfaceMuted,
          size: 18,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            style: context.text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (!isGranted)
          AppPressable(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                buttonLabel,
                style: context.text.labelSmall?.copyWith(
                  color: palette.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
        else
          Text(
            'Granted',
            style: context.text.labelSmall?.copyWith(
              color: palette.success,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  void _showUsageAccessExplanation(
    BuildContext context,
    FocusGuardController guard,
  ) {
    final palette = AppTheme.colorsOf(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        title: Text(
          'Usage Access Permission',
          style: ctx.text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Focus Guard needs Usage Access to detect when distracting apps are opened during your active focus sessions.\n\nYou will be taken to Android settings to grant this permission.',
          style: ctx.text.bodyMedium?.copyWith(color: palette.onSurfaceMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: palette.onSurfaceMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: palette.onPrimary,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              guard.requestUsageAccess();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showOverlayExplanation(
    BuildContext context,
    FocusGuardController guard,
  ) {
    final palette = AppTheme.colorsOf(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        title: Text(
          'Display Over Other Apps',
          style: ctx.text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Focus Guard uses this permission to show a Focus screen when a blocked app is opened.\n\nYou will be taken to Android settings to grant this permission.',
          style: ctx.text.bodyMedium?.copyWith(color: palette.onSurfaceMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: palette.onSurfaceMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: palette.onPrimary,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              guard.requestOverlayPermission();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
