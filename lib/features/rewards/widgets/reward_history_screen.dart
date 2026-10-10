import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../data/models/reward_transaction.dart';
import '../../../data/models/xp_event.dart';
import '../../progression/progression_controller.dart';
import '../redemption_controller.dart';

/// Full screen displaying the student's complete reward redemption & XP ledger history.
class RewardHistoryScreen extends StatefulWidget {
  const RewardHistoryScreen({super.key});

  @override
  State<RewardHistoryScreen> createState() => _RewardHistoryScreenState();
}

class _RewardHistoryScreenState extends State<RewardHistoryScreen> {
  int _tabIndex = 0; // 0 = Redemptions, 1 = XP History

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppScaffold(
      title: 'History & Activity',
      body: ListenableBuilder(
        listenable: Listenable.merge([
          RedemptionController.instance,
          ProgressionController.instance,
        ]),
        builder: (context, _) {
          final redemption = RedemptionController.instance;
          final progression = ProgressionController.instance;

          final transactions = redemption.transactions;
          final xpEvents = progression.recentEvents;

          return Column(
            children: [
              // Tab Selector
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Center(
                          child: Text(
                            'Redemptions (${transactions.length})',
                          ),
                        ),
                        selected: _tabIndex == 0,
                        selectedColor: palette.primary,
                        labelStyle: TextStyle(
                          color:
                              _tabIndex == 0 ? palette.onPrimary : palette.onSurface,
                          fontWeight:
                              _tabIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                        ),
                        onSelected: (_) => setState(() => _tabIndex = 0),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ChoiceChip(
                        label: Center(
                          child: Text(
                            'XP Ledger (${xpEvents.length})',
                          ),
                        ),
                        selected: _tabIndex == 1,
                        selectedColor: palette.primary,
                        labelStyle: TextStyle(
                          color:
                              _tabIndex == 1 ? palette.onPrimary : palette.onSurface,
                          fontWeight:
                              _tabIndex == 1 ? FontWeight.w700 : FontWeight.w500,
                        ),
                        onSelected: (_) => setState(() => _tabIndex = 1),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _tabIndex == 0
                    ? _buildRedemptionsList(transactions, palette)
                    : _buildXpLedgerList(xpEvents, palette),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRedemptionsList(
    List<RewardTransaction> transactions,
    AppPalette palette,
  ) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 48,
              color: palette.onSurfaceMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No redemptions yet',
              style: context.text.titleMedium!.copyWith(
                color: palette.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Redeem rewards using your earned XP.',
              style: context.text.bodyMedium!.copyWith(
                color: palette.onSurfaceMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return _TransactionCard(transaction: tx);
      },
    );
  }

  Widget _buildXpLedgerList(List<XpEvent> events, AppPalette palette) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.stars_outlined,
              size: 48,
              color: palette.onSurfaceMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No XP events recorded yet',
              style: context.text.titleMedium!.copyWith(
                color: palette.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Complete tasks, study sessions, and practice questions to earn XP.',
              style: context.text.bodyMedium!.copyWith(
                color: palette.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final event = events[index];
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  _getXpEventIcon(event.type),
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
                      event.reason.isNotEmpty
                          ? event.reason
                          : event.type.label,
                      style: context.text.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTimestamp(event.timestamp),
                      style: context.text.bodySmall!.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '+${event.amount} XP',
                style: context.text.labelLarge!.copyWith(
                  fontWeight: FontWeight.w800,
                  color: palette.streak,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getXpEventIcon(XpEventType type) {
    return switch (type) {
      XpEventType.studySessionCompleted => Icons.menu_book_rounded,
      XpEventType.taskCompleted => Icons.check_circle_rounded,
      XpEventType.syllabusTopicCompleted => Icons.school_rounded,
      XpEventType.examCompleted => Icons.quiz_rounded,
      XpEventType.streakMilestone => Icons.local_fire_department_rounded,
      XpEventType.weeklyConsistency => Icons.calendar_month_rounded,
      XpEventType.goalMilestone => Icons.flag_rounded,
    };
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction});

  final RewardTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: palette.streak.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              color: palette.streak,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.rewardTitle ?? 'Reward Redeemed',
                  style: context.text.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimestamp(transaction.timestamp),
                  style: context.text.bodySmall!.copyWith(
                    color: palette.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-${transaction.xpSpent} XP',
                style: context.text.labelMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.error,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: palette.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  transaction.status.label,
                  style: context.text.labelSmall!.copyWith(
                    color: palette.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
