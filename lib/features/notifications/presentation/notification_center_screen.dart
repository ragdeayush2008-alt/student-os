import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../data/models/app_notification.dart';
import '../../exams/exam_controller.dart';
import '../../tasks/task_controller.dart';
import '../notification_controller.dart';

/// Full-featured Notification & Activity Center 2.0 for Student OS.
///
/// Features:
/// - Activity summary with unread badge and quick actions
/// - Filter chips (All, Unread, Tasks, Exams, Focus & Study, Progression)
/// - Grouped sections (Today, Yesterday, Older)
/// - Actionable deep navigation with safe fallback for missing entities
/// - Swipe-to-dismiss notification rows
/// - Mark one read / mark all read / clear all
/// - Strict Black/White/Grey monochrome visual language (Zero purple)
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationController _controller = NotificationController.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _controller.load();
    // Run derived evaluation safely
    _controller.evaluateTasks(TaskController.instance.tasks);
    _controller.evaluateUpcomingExams(ExamController.instance.exams);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _handleNotificationTap(AppNotification item) {
    _controller.markAsRead(item.id);
    _navigateToDestination(item);
  }

  void _navigateToDestination(AppNotification item) {
    if (!mounted) return;

    // 1. Task navigation
    if (item.isTask && item.entityId != null) {
      final taskExists = TaskController.instance.tasks.any(
        (t) => t.id == item.entityId,
      );
      if (taskExists) {
        AppRouter.openTaskDetail(context, item.entityId!);
      } else {
        _showFallbackMessage('This task is no longer available.');
      }
      return;
    }

    // 2. Exam navigation
    if (item.isExam && item.entityId != null) {
      final examExists = ExamController.instance.exams.any(
        (e) => e.id == item.entityId,
      );
      if (examExists) {
        AppRouter.openExamDetail(context, item.entityId!);
      } else {
        _showFallbackMessage('This exam is no longer available.');
      }
      return;
    }

    // 3. Focus & Study navigation
    if (item.type == NotificationType.focusCompleted) {
      AppRouter.openFocusCenter(context);
      return;
    }
    if (item.type == NotificationType.studyCompleted) {
      AppRouter.openStudy(context);
      return;
    }

    // 4. Progression & Achievements
    if (item.isAchievement) {
      AppRouter.openAchievements(context);
      return;
    }
    if (item.type == NotificationType.levelUp ||
        item.type == NotificationType.xpMilestone) {
      AppRouter.openProgress(context);
      return;
    }

    // 5. Streaks
    if (item.isStreak) {
      AppRouter.openStreak(context);
      return;
    }

    // 6. Leaderboard
    if (item.isLeaderboard) {
      AppRouter.openLeaderboard(context);
      return;
    }

    // 7. Rewards
    if (item.isReward) {
      AppRouter.openRewards(context);
      return;
    }

    // 8. Planning & Goals
    if (item.type == NotificationType.dailyPlan) {
      AppRouter.openPlan(context);
      return;
    }
    if (item.type == NotificationType.goalReached) {
      AppRouter.openGoals(context);
      return;
    }

    // Default route fallback
    if (item.route != null && item.route!.isNotEmpty) {
      try {
        Navigator.of(context).pushNamed(item.route!);
      } catch (_) {
        // Safe no-op
      }
    }
  }

  void _showFallbackMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final unreadCount = _controller.unreadCount;
    final totalCount = _controller.totalCount;
    final selectedFilter = _controller.selectedFilter;

    final todayItems = _controller.todayNotifications;
    final yesterdayItems = _controller.yesterdayNotifications;
    final olderItems = _controller.olderNotifications;
    final hasItems = _controller.filteredNotifications.isNotEmpty;

    return AppScaffold(
      title: 'Notifications',
      actions: [
        if (unreadCount > 0)
          TextButton(
            onPressed: () => _controller.markAllAsRead(),
            style: TextButton.styleFrom(
              foregroundColor: palette.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
            child: const Text(
              'Mark all read',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: palette.onSurface, size: 20),
          onSelected: (val) {
            if (val == 'clear') {
              _controller.clearAllNotifications();
            } else if (val == 'settings') {
              AppRouter.openSettings(context);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep_outlined, size: 18),
                  SizedBox(width: AppSpacing.sm),
                  Text('Clear all notifications'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.tune_outlined, size: 18),
                  SizedBox(width: AppSpacing.sm),
                  Text('Notification settings'),
                ],
              ),
            ),
          ],
        ),
      ],
      body: _controller.isLoading && !_controller.isLoaded
          ? _buildLoadingState(palette)
          : _controller.errorMessage != null && !_controller.isLoaded
              ? _buildErrorState(palette)
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Activity Summary
                      _buildActivitySummary(palette, unreadCount, totalCount),
                      const SizedBox(height: AppSpacing.md),

                      // Filter Chips
                      _buildFilterChips(palette, selectedFilter, unreadCount),
                      const SizedBox(height: AppSpacing.lg),

                      // Notification Sections
                      if (!hasItems)
                        _buildEmptyState(palette)
                      else ...[
                        if (todayItems.isNotEmpty) ...[
                          _buildSectionHeader(
                            'TODAY',
                            todayItems.length,
                            palette,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          ...todayItems
                              .map((n) => _buildNotificationRow(n, palette)),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        if (yesterdayItems.isNotEmpty) ...[
                          _buildSectionHeader(
                            'YESTERDAY',
                            yesterdayItems.length,
                            palette,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          ...yesterdayItems
                              .map((n) => _buildNotificationRow(n, palette)),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        if (olderItems.isNotEmpty) ...[
                          _buildSectionHeader(
                            'OLDER',
                            olderItems.length,
                            palette,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          ...olderItems
                              .map((n) => _buildNotificationRow(n, palette)),
                        ],
                      ],
                    ],
                  ),
                ),
    );
  }

  // ─── Activity Summary Card ───────────────────────────────────────────────

  Widget _buildActivitySummary(
    AppPalette palette,
    int unreadCount,
    int totalCount,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: palette.surfaceVariant.withValues(alpha: 0.5),
      borderColor: palette.outline.withValues(alpha: 0.4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color: palette.onSurface,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$unreadCount unread',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.onSurface,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '· $totalCount total',
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  unreadCount > 0
                      ? 'Stay on top of deadlines, sessions & milestones'
                      : 'You are completely caught up!',
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter Chips ────────────────────────────────────────────────────────

  Widget _buildFilterChips(
    AppPalette palette,
    NotificationFilter selected,
    int unreadCount,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: NotificationFilter.values.map((filter) {
          final isSelected = selected == filter;
          var label = filter.label;
          if (filter == NotificationFilter.unread && unreadCount > 0) {
            label = '$label ($unreadCount)';
          }

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: AppPressable(
              onTap: () => _controller.setFilter(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? palette.onSurface : palette.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isSelected
                        ? palette.onSurface
                        : palette.outline.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? palette.surface : palette.onSurface,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Section Header ──────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, int count, AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.xxs,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: palette.onSurfaceMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: palette.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: palette.onSurfaceMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Notification Row ────────────────────────────────────────────────────

  Widget _buildNotificationRow(AppNotification item, AppPalette palette) {
    final isUnread = !item.isRead;
    final isHighPriority = item.priority == NotificationPriority.high;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Dismissible(
        key: Key(item.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _controller.deleteNotification(item.id),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.md),
          decoration: BoxDecoration(
            color: palette.onSurface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(Icons.delete_outline, color: palette.onSurface, size: 20),
        ),
        child: AppCard(
          onTap: () => _handleNotificationTap(item),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          color: isUnread
              ? palette.surface
              : palette.surfaceVariant.withValues(alpha: 0.3),
          borderColor: isUnread
              ? palette.onSurface.withValues(alpha: 0.25)
              : palette.outline.withValues(alpha: 0.3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isUnread
                      ? palette.onSurface.withValues(alpha: 0.08)
                      : palette.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  _iconForType(item.type),
                  size: 18,
                  color: palette.onSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Title, Body & Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (isHighPriority) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            margin: const EdgeInsets.only(right: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: palette.onSurface,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              'URGENT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: palette.surface,
                              ),
                            ),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isUnread ? FontWeight.w700 : FontWeight.w500,
                              color: palette.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _formatTimeAgo(item.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: palette.onSurfaceMuted,
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: palette.onSurface,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.body,
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.onSurfaceMuted,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.taskDue:
        return Icons.assignment_late_outlined;
      case NotificationType.taskOverdue:
        return Icons.warning_amber_rounded;
      case NotificationType.taskCompleted:
        return Icons.check_circle_outline;
      case NotificationType.examUpcoming:
        return Icons.school_outlined;
      case NotificationType.examPreparation:
        return Icons.menu_book_outlined;
      case NotificationType.examCompleted:
        return Icons.verified_outlined;
      case NotificationType.studyCompleted:
        return Icons.local_library_outlined;
      case NotificationType.focusCompleted:
        return Icons.timer_outlined;
      case NotificationType.achievementUnlocked:
        return Icons.emoji_events_outlined;
      case NotificationType.levelUp:
        return Icons.military_tech_outlined;
      case NotificationType.xpMilestone:
        return Icons.bolt_outlined;
      case NotificationType.streakMilestone:
        return Icons.local_fire_department_outlined;
      case NotificationType.streakRisk:
        return Icons.error_outline;
      case NotificationType.leaderboardMovement:
        return Icons.leaderboard_outlined;
      case NotificationType.rewardUnlocked:
        return Icons.card_giftcard_outlined;
      case NotificationType.rewardAvailable:
        return Icons.redeem_outlined;
      case NotificationType.dailyPlan:
        return Icons.calendar_today_outlined;
      case NotificationType.goalReached:
        return Icons.flag_outlined;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }

  // ─── States ──────────────────────────────────────────────────────────────

  Widget _buildEmptyState(AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: palette.onSurface.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_outlined,
                size: 28,
                color: palette.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: palette.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Updates from your tasks, exams, focus sessions, and achievements will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: palette.onSurfaceMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppPalette palette) {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(palette.onSurface),
      ),
    );
  }

  Widget _buildErrorState(AppPalette palette) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 36, color: palette.onSurfaceMuted),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _controller.errorMessage ?? 'An error occurred',
            style: TextStyle(color: palette.onSurfaceMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => _controller.load(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
