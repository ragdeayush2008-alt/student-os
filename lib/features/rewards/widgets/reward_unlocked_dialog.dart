import 'package:flutter/material.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/reward.dart';
import '../../../data/models/reward_transaction.dart';
import '../../progression/progression_controller.dart';

/// Celebration dialog shown after a successful reward redemption.
///
/// Features:
/// - Mature, academic celebration style (not childish/casino-like)
/// - Reward title, type, and icon
/// - XP spent and remaining spendable XP balance
/// - Respects `MediaQuery.disableAnimationsOf(context)`
class RewardUnlockedDialog extends StatefulWidget {
  const RewardUnlockedDialog({
    super.key,
    required this.reward,
    required this.transaction,
  });

  final Reward reward;
  final RewardTransaction transaction;

  @override
  State<RewardUnlockedDialog> createState() => _RewardUnlockedDialogState();
}

class _RewardUnlockedDialogState extends State<RewardUnlockedDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : AppDurations.slow;

    _controller = AnimationController(vsync: this, duration: duration);
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: AppCurves.standard,
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final progression = ProgressionController.instance;
    final reward = widget.reward;
    final transaction = widget.transaction;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with celebration glow
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        palette.success.withValues(alpha: 0.15),
                        palette.streak.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Badge / Icon Circle
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.surface,
                          border: Border.all(
                            color: palette.success,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: palette.success.withValues(alpha: 0.2),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _getRewardIcon(reward.type),
                          size: 38,
                          color: palette.success,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Reward Unlocked!',
                        style: context.text.headlineSmall!.copyWith(
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
                    ],
                  ),
                ),

                // Body with transaction details
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: palette.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'XP Spent',
                                  style: context.text.bodySmall!.copyWith(
                                    color: palette.onSurfaceMuted,
                                  ),
                                ),
                                Text(
                                  '-${transaction.xpSpent} XP',
                                  style: context.text.titleSmall!.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: palette.error,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Remaining XP',
                                  style: context.text.bodySmall!.copyWith(
                                    color: palette.onSurfaceMuted,
                                  ),
                                ),
                                Text(
                                  '${progression.spendableXp} XP',
                                  style: context.text.titleSmall!.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: palette.streak,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: palette.primary,
                            foregroundColor: palette.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Done',
                            style: context.text.titleSmall!.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getRewardIcon(String type) {
    return switch (type) {
      'theme' => Icons.palette_outlined,
      'badge' => Icons.workspace_premium_outlined,
      'feature' => Icons.auto_awesome_outlined,
      'discount' => Icons.local_offer_outlined,
      _ => Icons.stars_rounded,
    };
  }
}

/// Helper function to show the reward unlocked dialog.
void showRewardUnlockedDialog(
  BuildContext context, {
  required Reward reward,
  required RewardTransaction transaction,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) =>
        RewardUnlockedDialog(reward: reward, transaction: transaction),
  );
}
