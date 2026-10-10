import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/reward.dart';
import '../../progression/progression_controller.dart';

/// Confirmation dialog displayed before spending XP to redeem a reward.
///
/// Ensures full transparency:
/// - Clear item title and icon
/// - XP cost
/// - Current spendable XP
/// - XP remaining after redemption
/// - Explicit Cancel / Redeem buttons
class RedemptionConfirmationDialog extends StatelessWidget {
  const RedemptionConfirmationDialog({
    super.key,
    required this.reward,
    required this.onConfirm,
  });

  final Reward reward;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final progression = ProgressionController.instance;
    final currentXp = progression.spendableXp;
    final remainingXp = currentXp - reward.xpCost;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.streak.withValues(alpha: 0.15),
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: palette.streak,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Title
              Text(
                'Redeem Reward?',
                style: context.text.titleLarge!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                reward.title,
                style: context.text.bodyMedium!.copyWith(
                  color: palette.onSurfaceMuted,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.lg),

              // XP Calculation Breakdown
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: palette.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    _RowItem(
                      label: 'Reward Cost',
                      value: '-${reward.xpCost} XP',
                      valueColor: palette.error,
                      isBold: true,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _RowItem(
                      label: 'Current Spendable XP',
                      value: '$currentXp XP',
                    ),
                    const Divider(height: AppSpacing.md),
                    _RowItem(
                      label: 'Remaining Balance',
                      value: '$remainingXp XP',
                      valueColor: palette.streak,
                      isBold: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: context.text.titleSmall!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: palette.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Redeem',
                        style: context.text.titleSmall!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: context.text.bodySmall!.copyWith(
            color: palette.onSurfaceMuted,
          ),
        ),
        Text(
          value,
          style: context.text.bodyMedium!.copyWith(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? palette.onSurface,
          ),
        ),
      ],
    );
  }
}
