import 'package:flutter/material.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_states.dart';
import '../../controller/focus_controller.dart';
import '../../controller/focus_guard_controller.dart';
import '../../data/models/focus_mission.dart';
import '../../services/focus_intelligence_service.dart';

enum HistoryFilter { today, thisWeek, thisMonth, allTime }

class FocusHistoryScreen extends StatefulWidget {
  const FocusHistoryScreen({super.key});

  @override
  State<FocusHistoryScreen> createState() => _FocusHistoryScreenState();
}

class _FocusHistoryScreenState extends State<FocusHistoryScreen> {
  HistoryFilter _filter = HistoryFilter.allTime;

  @override
  Widget build(BuildContext context) {
    final fc = FocusController.instance;
    final palette = AppTheme.colorsOf(context);
    final stats = FocusIntelligenceService.instance.computeStatistics();

    final filteredSessions = _filterSessions(fc.sessions, _filter);

    return AppScaffold(
      title: 'Focus History',
      onBack: () => Navigator.of(context).pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Summary Stats Header ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screen,
              vertical: AppSpacing.xs,
            ),
            child: _buildSummaryCard(stats, palette, context),
          ),
          const SizedBox(height: AppSpacing.xs),

          // ── Filter Chips ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screen,
              vertical: AppSpacing.xs,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All Time', HistoryFilter.allTime, palette),
                  const SizedBox(width: AppSpacing.xs),
                  _filterChip('Today', HistoryFilter.today, palette),
                  const SizedBox(width: AppSpacing.xs),
                  _filterChip('This Week', HistoryFilter.thisWeek, palette),
                  const SizedBox(width: AppSpacing.xs),
                  _filterChip('This Month', HistoryFilter.thisMonth, palette),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // ── Sessions List ────────────────────────────────────────
          if (filteredSessions.isEmpty)
            Expanded(
              child: AppEmptyState(
                title: 'No focus sessions found',
                icon: Icons.history_rounded,
                description: 'Complete focus sessions to build your study record.',
                compact: true,
                action: AppPressable(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: palette.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'Start Focus',
                      style: context.text.labelMedium?.copyWith(
                        color: palette.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                  vertical: AppSpacing.xs,
                ),
                itemCount: filteredSessions.length,
                itemBuilder: (context, index) {
                  final session = filteredSessions[index];
                  return _HistoryTile(session, palette);
                },
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    FocusStatistics stats,
    AppPalette palette,
    BuildContext context,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Focus & Distraction Stats',
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (stats.currentStreak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.primaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${stats.currentStreak}d Streak 🔥',
                    style: context.text.labelSmall?.copyWith(
                      color: palette.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statColumn('Total Time', '${stats.totalFocusedMinutes}m', palette, context),
              _statColumn('Completed', '${stats.completedSessionsCount}', palette, context),
              _statColumn('Blocked', '${stats.totalBlockedAttempts}', palette, context),
              _statColumn('Avg Session', '${stats.averageSessionDurationMinutes}m', palette, context),
            ],
          ),
          if (stats.mostFrequentlyBlockedApp != null) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.shield_rounded, size: 14, color: palette.warning),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Most blocked app: ${stats.mostFrequentlyBlockedApp}',
                    style: context.text.labelSmall?.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value, AppPalette palette, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: context.text.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: context.text.labelSmall?.copyWith(
            color: palette.onSurfaceMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, HistoryFilter filter, AppPalette palette) {
    final isSelected = _filter == filter;
    return AppPressable(
      onTap: () => setState(() => _filter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? palette.primary : palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? palette.primary : palette.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? palette.onPrimary : palette.onSurface,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  List<FocusSession> _filterSessions(List<FocusSession> sessions, HistoryFilter filter) {
    final now = DateTime.now();
    switch (filter) {
      case HistoryFilter.today:
        return sessions.where((s) =>
            s.startedAt.year == now.year &&
            s.startedAt.month == now.month &&
            s.startedAt.day == now.day).toList();
      case HistoryFilter.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final normalizedStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return sessions.where((s) => s.startedAt.isAfter(normalizedStart)).toList();
      case HistoryFilter.thisMonth:
        return sessions.where((s) =>
            s.startedAt.year == now.year &&
            s.startedAt.month == now.month).toList();
      case HistoryFilter.allTime:
        return sessions;
    }
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile(this.session, this.palette);
  final FocusSession session;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final blockedCount = FocusGuardController.instance.blockedAttempts
        .where((a) => a.sessionId == session.id)
        .length;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: palette.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                _modeIcon(session.mode),
                color: palette.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.objective,
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _outcomeBadge(session.outcome, palette, context),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${session.actualFocusedDuration.inMinutes} min • ${session.subjectName ?? 'General'}'
                    '${blockedCount > 0 ? ' • $blockedCount blocked' : ''}',
                    style: context.text.labelSmall?.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '+${session.sessionScore} pts',
              style: context.text.labelSmall?.copyWith(
                color: palette.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _outcomeBadge(SessionOutcome? outcome, AppPalette palette, BuildContext context) {
    final isComplete = outcome == SessionOutcome.completed;
    final color = isComplete ? palette.success : palette.onSurfaceMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        isComplete ? 'Complete' : 'Partial',
        style: context.text.labelSmall?.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  IconData _modeIcon(FocusMode mode) {
    switch (mode) {
      case FocusMode.timer:
        return Icons.timer_outlined;
      case FocusMode.stopwatch:
        return Icons.av_timer_rounded;
      case FocusMode.focusGuard:
        return Icons.shield_outlined;
    }
  }
}
