import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../data/models/student_profile.dart';
import '../../goals/goal_controller.dart';

/// A derived, lightweight snapshot of profile completeness (0.0–1.0).
///
/// Computed from real profile fields and goal configuration — never persisted
/// as a meaningless percentage.
double profileCompleteness(StudentProfile profile, GoalController goals) {
  var filled = 0;
  const total = 8;
  if (profile.displayName.isNotEmpty) filled++;
  if (profile.educationLevel != null) filled++;
  if (profile.institution.isNotEmpty) filled++;
  if (profile.course.isNotEmpty) filled++;
  if (profile.currentYear.isNotEmpty) filled++;
  if (profile.academicFocus != null) filled++;
  if (profile.goals.isNotEmpty) filled++;
  if (goals.weeklyStudyTarget.inMinutes > 0 ||
      goals.weeklyTaskTarget > 0 ||
      goals.personalGoal.isNotEmpty) {
    filled++;
  }
  return filled / total;
}

/// Section A — the premium Profile Hero shown at the top of the More hub.
///
/// Uses real [StudentProfile] data with an elegant gradient avatar, name,
/// academic context, and a live profile-completeness indicator.
class ProfileHero extends StatelessWidget {
  const ProfileHero({
    super.key,
    required this.profile,
    required this.completeness,
    required this.onEdit,
  });

  final StudentProfile profile;
  final double completeness;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final pct = (completeness * 100).round();
    final displayLabel = profile.displayLabel;
    final academic = profile.academicSummary;
    final initials = profile.initials;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              _Avatar(initials: initials, palette: palette, size: 60),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayLabel,
                      style: context.text.headlineSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (academic.isNotEmpty)
                      Text(
                        academic,
                        style: context.text.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        'Set up your academic context',
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
          _CompletenessBar(fraction: completeness, pct: pct, palette: palette),
          const SizedBox(height: AppSpacing.sm),
          AppPressable(
            onTap: onEdit,
            pressedScale: 0.97,
            semanticLabel: 'Edit profile',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_rounded, size: 17, color: palette.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Edit profile',
                    style: context.text.labelMedium!.copyWith(
                      color: palette.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initials,
    required this.palette,
    required this.size,
  });

  final String initials;
  final AppPalette palette;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.accentGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        initials,
        style: context.text.headlineSmall!.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CompletenessBar extends StatelessWidget {
  const _CompletenessBar({
    required this.fraction,
    required this.pct,
    required this.palette,
  });

  final double fraction;
  final int pct;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 450);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Profile personalization',
                style: context.text.bodySmall,
              ),
            ),
            Text(
              '$pct%',
              style: context.text.labelMedium!.copyWith(
                color: fraction >= 0.7
                    ? palette.success
                    : fraction >= 0.4
                    ? palette.warning
                    : palette.onSurfaceMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction),
            duration: duration,
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 5,
                backgroundColor: palette.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  fraction >= 0.7
                      ? palette.success
                      : fraction >= 0.4
                      ? palette.warning
                      : palette.primary,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
