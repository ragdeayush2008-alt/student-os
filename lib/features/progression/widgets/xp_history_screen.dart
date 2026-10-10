import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/xp_event.dart';
import '../progression_controller.dart';

/// Full screen displaying the student's complete XP earning history.
class XpHistoryScreen extends StatefulWidget {
  const XpHistoryScreen({super.key});

  @override
  State<XpHistoryScreen> createState() => _XpHistoryScreenState();
}

class _XpHistoryScreenState extends State<XpHistoryScreen> {
  XpEventType? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Scaffold(
      appBar: AppBar(title: const Text('XP History'), elevation: 0),
      body: ListenableBuilder(
        listenable: ProgressionController.instance,
        builder: (context, _) {
          final controller = ProgressionController.instance;
          final allEvents = controller.recentEvents;

          final filteredEvents = _selectedFilter == null
              ? allEvents
              : allEvents.where((e) => e.type == _selectedFilter).toList();

          return CustomScrollView(
            slivers: [
              // Summary header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _XpSummaryCard(controller: controller),
                ),
              ),

              // Filter chips
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedFilter == null,
                        onSelected: (_) =>
                            setState(() => _selectedFilter = null),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      for (final type in XpEventType.values) ...[
                        FilterChip(
                          label: Text(type.label),
                          selected: _selectedFilter == type,
                          onSelected: (_) =>
                              setState(() => _selectedFilter = type),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              // Events list
              if (filteredEvents.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
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
                          'No XP events yet',
                          style: context.text.titleMedium!.copyWith(
                            color: palette.onSurfaceMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Complete tasks or study sessions to earn XP',
                          style: context.text.bodyMedium!.copyWith(
                            color: palette.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final event = filteredEvents[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _XpEventCard(event: event),
                      );
                    }, childCount: filteredEvents.length),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
          );
        },
      ),
    );
  }
}

class _XpSummaryCard extends StatelessWidget {
  const _XpSummaryCard({required this.controller});

  final ProgressionController controller;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final level = controller.currentLevel;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.streak.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    '${level.level}',
                    style: context.text.titleLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.streak,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${controller.totalXp} Total XP',
                      style: context.text.titleLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${level.xpToNextLevel} XP to Level ${level.level + 1}',
                      style: context.text.bodySmall!.copyWith(
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: level.progressInLevel,
              minHeight: 8,
              backgroundColor: palette.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(palette.streak),
            ),
          ),
        ],
      ),
    );
  }
}

class _XpEventCard extends StatelessWidget {
  const _XpEventCard({required this.event});

  final XpEvent event;

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
              _iconForType(event.type),
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
                  event.reason,
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
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: palette.streak.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '+${event.amount} XP',
              style: context.text.labelMedium!.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.streak,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(XpEventType type) {
    return switch (type) {
      XpEventType.taskCompleted => Icons.task_alt_rounded,
      XpEventType.studySessionCompleted => Icons.timer_rounded,
      XpEventType.syllabusTopicCompleted => Icons.menu_book_rounded,
      XpEventType.examCompleted => Icons.school_rounded,
      XpEventType.goalMilestone => Icons.flag_rounded,
      XpEventType.weeklyConsistency => Icons.auto_graph_rounded,
      XpEventType.streakMilestone => Icons.local_fire_department_rounded,
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
