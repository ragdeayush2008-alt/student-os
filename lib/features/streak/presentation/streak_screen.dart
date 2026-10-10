import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/streak_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';

/// Detail screen showing the student's streak information.
///
/// Displays current streak, best streak, today's activity status, and
/// explains what counts toward the streak. All data is derived from
/// existing task and study records — nothing is fabricated.
class StreakScreen extends StatelessWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return AppScaffold(
      title: 'Streak',
      body: ListenableBuilder(
        listenable: StreakService.instance,
        builder: (context, _) {
          final streak = StreakService.instance;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StreakHero(
                  currentStreak: streak.currentStreak,
                  bestStreak: streak.bestStreak,
                  activityToday: streak.activityToday,
                  colors: colors,
                ),
                const SizedBox(height: AppSpacing.xl),
                _ActivityStatus(
                  activityToday: streak.activityToday,
                  colors: colors,
                ),
                const SizedBox(height: AppSpacing.xl),
                _StreakRules(colors: colors),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Streak Hero ───────────────────────────────────────────────────────

class _StreakHero extends StatelessWidget {
  const _StreakHero({
    required this.currentStreak,
    required this.bestStreak,
    required this.activityToday,
    required this.colors,
  });

  final int currentStreak;
  final int bestStreak;
  final bool activityToday;
  final AppPalette colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.streak.withValues(alpha: 0.1),
            AppColors.streak.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.streak.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text('\u{1F525}', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            currentStreak > 0 ? '$currentStreak' : '0',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              color: currentStreak > 0
                  ? AppColors.streak
                  : colors.onSurfaceMuted,
              height: 1.1,
            ),
          ),
          Text(
            currentStreak > 0 ? 'day streak' : 'Start your streak',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: currentStreak > 0
                  ? AppColors.streak.withValues(alpha: 0.8)
                  : colors.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatChip(
                label: 'Best',
                value: '$bestStreak days',
                color: colors,
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatChip(
                label: 'Today',
                value: activityToday ? 'Active' : 'No activity',
                color: colors,
                isActive: activityToday,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    this.isActive = false,
  });

  final String label;
  final String value;
  final AppPalette color;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withValues(alpha: 0.1)
            : color.surface,
        borderRadius: AppRadius.smAll,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isActive ? AppColors.success : color.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Activity Status ───────────────────────────────────────────────────

class _ActivityStatus extends StatelessWidget {
  const _ActivityStatus({required this.activityToday, required this.colors});

  final bool activityToday;
  final AppPalette colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: colors.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            activityToday
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            color: activityToday ? AppColors.success : colors.onSurfaceMuted,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activityToday
                      ? 'Activity completed today'
                      : 'No activity yet today',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  activityToday ? 'Great work! Keep it going.' : 'Complete a task or study session to maintain your streak.',
                  style: TextStyle(fontSize: 13, color: colors.onSurfaceMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Streak Rules ──────────────────────────────────────────────────────

class _StreakRules extends StatelessWidget {
  const _StreakRules({required this.colors});

  final AppPalette colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: colors.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What counts toward your streak?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _RuleRow(
            icon: Icons.check_circle_outline_rounded,
            text: 'Complete a task',
            colors: colors,
          ),
          _RuleRow(
            icon: Icons.headphones_rounded,
            text: 'Complete a study session (5+ min)',
            colors: colors,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Complete at least one of these each day to keep your streak going. '
            'Multiple activities on the same day count as one streak day.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: colors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.icon,
    required this.text,
    required this.colors,
  });

  final IconData icon;
  final String text;
  final AppPalette colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.success),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
