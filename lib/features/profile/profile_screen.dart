import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/services/course_catalog_service.dart';
import '../../core/services/student_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_settings_tiles.dart';
import '../../data/models/student_profile.dart';
import '../auth/auth_service.dart';
import '../onboarding/presentation/onboarding_screen.dart';
import '../rewards/entitlement_manager.dart';
import '../rewards/premium_entitlement.dart';
import '../rewards/reward_catalog.dart';
import '../rewards/rewards_screen.dart';

/// Profile / account foundation.
///
/// Shows real student profile data when available; shows demo data when in
/// local/demo mode. Includes academic context, goals, primary badge showcase,
/// premium status indicator, and sign out.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    StudentService.instance.addListener(_onProfileChanged);
    CourseCatalogService.instance.addListener(_onProfileChanged);
    PremiumEntitlement.instance.addListener(_onProfileChanged);
  }

  void _onProfileChanged() => setState(() {});

  @override
  void dispose() {
    StudentService.instance.removeListener(_onProfileChanged);
    CourseCatalogService.instance.removeListener(_onProfileChanged);
    PremiumEntitlement.instance.removeListener(_onProfileChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final profile = StudentService.instance.profile;
    final supaReady =
        SupabaseService.instance.currentState == SupabaseInitState.ready;
    final user = supaReady ? AuthService.instance.user : null;
    final isDemo = !supaReady || user == null;
    final premium = PremiumEntitlement.instance;
    final badgeCount = EntitlementManager.instance.unlockedBadges.length;

    return AppScaffold(
      title: 'Profile',
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
          onPressed: () => AppRouter.openSettings(context),
        ),
      ],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _IdentityCard(palette: palette, profile: profile, isDemo: isDemo),
            const SizedBox(height: AppSpacing.lg),

            // Premium status indicator if active
            if (premium.isPremiumActive) ...[
              _PremiumBadgeCard(
                status: premium.status,
                daysRemaining: premium.trialDaysRemaining,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Academic summary from authoritative active-course state
            _AcademicSummaryAuthoritative(),
            const SizedBox(height: AppSpacing.sm),

            // ── Change Course Main Action — same UI as initial setup ──
            Builder(builder: (context) {
              final activeCourse = CourseCatalogService.instance.getActiveCourse();
              final activeYear = CourseCatalogService.instance.getActiveYear();
              final display = activeCourse != null && activeCourse.isNotEmpty
                  ? (activeYear != null && activeYear.isNotEmpty ? '$activeCourse · $activeYear' : activeCourse)
                  : null;
              return AppSettingsTile(
                icon: Icons.swap_horiz_rounded,
                title: 'Change Course',
                subtitle: display != null
                    ? '$display · Choose a different course or exam'
                    : 'Choose your academic goal or exam',
                onTap: () => AppRouter.openCourseSelection(context),
              );
            }),
            const SizedBox(height: AppSpacing.lg),

            if (profile.goals.isNotEmpty) ...[
              _GoalsSummary(goals: profile.goals),
              const SizedBox(height: AppSpacing.lg),
            ],
            AppSettingsTile(
              icon: Icons.emoji_events_rounded,
              title: 'Achievements',
              subtitle: 'View unlocked milestones & progress',
              onTap: () => AppRouter.openAchievements(context),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppSettingsTile(
              icon: Icons.military_tech_outlined,
              title: 'Earned Badges & Rewards',
              subtitle: '$badgeCount badges unlocked',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RewardsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            AppSettingsTile(
              icon: Icons.task_alt_rounded,
              title: 'Tasks',
              subtitle: 'Manage your tasks',
              onTap: () => AppRouter.openTasks(context),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (!isDemo && !profile.isOnboardingComplete)
              AppSettingsTile(
                icon: Icons.rocket_launch_rounded,
                title: 'Complete course setup',
                subtitle: 'Set up your curriculum and subjects',
                onTap: () => _openEducationSetup(context),
              ),
            if (!isDemo && profile.isOnboardingComplete)
              AppSettingsTile(
                icon: Icons.school_outlined,
                title: 'Education & Subjects',
                subtitle: profile.course.isNotEmpty
                    ? '${profile.course} · Tap to edit or change'
                    : 'Manage course and enrolled subjects',
                onTap: () => _openEducationSetup(context),
              ),
            const SizedBox(height: AppSpacing.xs),
            const AppSettingsTile(
              icon: Icons.lock_outline_rounded,
              title: 'Privacy',
              subtitle: 'Data management & controls',
            ),
            if (supaReady && !isDemo) ...[
              const SizedBox(height: AppSpacing.xl),
              const _SignOutTile(),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  void _openEducationSetup(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const OnboardingScreen(isEditMode: true),
      ),
    );
  }
}

class _PremiumBadgeCard extends StatelessWidget {
  const _PremiumBadgeCard({required this.status, required this.daysRemaining});

  final PremiumStatus status;
  final int daysRemaining;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppCard(
      color: palette.primary.withValues(alpha: 0.08),
      borderColor: palette.primary.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: palette.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: palette.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student OS Premium (${status.label})',
                  style: context.text.titleSmall!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  daysRemaining > 0
                      ? '$daysRemaining days remaining on your trial'
                      : 'All premium features unlocked',
                  style: context.text.bodySmall!.copyWith(
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
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.palette,
    required this.profile,
    required this.isDemo,
  });

  final AppPalette palette;
  final StudentProfile profile;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final displayName = profile.displayLabel;
    final initials = profile.initials;
    final journey = profile.academicSummary.isNotEmpty
        ? profile.academicSummary
        : (isDemo ? 'Student OS demo' : 'Student OS account');

    // Check for equipped primary badge
    String? equippedBadgeTitle;
    IconData? equippedBadgeIcon;
    Color? equippedBadgeColor;

    if (profile.importantDateLabel.startsWith('primary_badge:')) {
      final rewardId = profile.importantDateLabel.replaceFirst(
        'primary_badge:',
        '',
      );
      final reward = RewardCatalog.instance.findById(rewardId);
      if (reward != null) {
        equippedBadgeTitle = reward.title;
        final hex = reward.metadata?['badgeColor'] as String? ?? '#3B82F6';
        equippedBadgeColor = _parseHex(hex);
        equippedBadgeIcon = switch (reward.iconName) {
          'star' => Icons.star_rounded,
          'local_fire_department' => Icons.local_fire_department_rounded,
          'school' => Icons.school_rounded,
          'emoji_events' => Icons.emoji_events_rounded,
          _ => Icons.workspace_premium_rounded,
        };
      }
    }

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: palette.accentGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Text(
              initials,
              style: context.text.headlineMedium!.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName.length > 28
                            ? '${displayName.substring(0, 25)}…'
                            : displayName,
                        style: context.text.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (equippedBadgeTitle != null) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (equippedBadgeColor ?? palette.primary)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: equippedBadgeColor ?? palette.primary,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              equippedBadgeIcon ??
                                  Icons.workspace_premium_rounded,
                              size: 12,
                              color: equippedBadgeColor ?? palette.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              equippedBadgeTitle,
                              style: context.text.labelSmall!.copyWith(
                                color: equippedBadgeColor ?? palette.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  journey,
                  style: context.text.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (profile.educationLevel != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.school_rounded,
                        size: 14,
                        color: palette.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        profile.educationLevel!.label,
                        style: context.text.labelMedium!.copyWith(
                          color: palette.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _parseHex(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return AppColors.forest;
    }
  }
}

class _AcademicSummaryAuthoritative extends StatelessWidget {
  const _AcademicSummaryAuthoritative();

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final catalog = CourseCatalogService.instance;
    final active = catalog.activeCourseSelection;
    final profile = StudentService.instance.profile;

    // Prefer authoritative active-course, fallback to legacy profile fields
    final displayCourse = catalog.getActiveCourse() ?? profile.course;
    final displayLevel = catalog.getActiveLevel() ?? profile.currentYear;
    final displayYear = catalog.getActiveYear();
    final authority = active?.authority ?? profile.catalogAuthority;

    if (displayCourse.isEmpty && displayLevel.isEmpty && authority == null) {
      // Nothing to show
      return const SizedBox.shrink();
    }

    // Resolve category title from catalog if available
    String? categoryTitle;
    if (active != null && active.categoryId.isNotEmpty) {
      categoryTitle = catalog.getCategoryById(active.categoryId)?.title;
    }
    categoryTitle ??= profile.catalogCategory?.label;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, size: 18, color: palette.primary),
              const SizedBox(width: AppSpacing.xs),
              Text('Education Profile', style: context.text.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (categoryTitle != null && categoryTitle.isNotEmpty)
            _InfoRow(label: 'Category', value: categoryTitle),
          if (displayCourse.isNotEmpty) _InfoRow(label: 'Course', value: displayCourse),
          if (authority != null && authority.isNotEmpty) _InfoRow(label: 'Board / Authority', value: authority),
          if (displayLevel.isNotEmpty) _InfoRow(label: 'Level / Stage', value: displayLevel),
          if (displayYear != null && displayYear.isNotEmpty && displayYear != displayLevel) _InfoRow(label: 'Syllabus', value: displayYear),
          if (profile.institution.isNotEmpty) _InfoRow(label: 'Institution', value: profile.institution),
          if (profile.academicFocus != null) _InfoRow(label: 'Current focus', value: profile.academicFocus!.label),
        ],
      ),
    );
  }
}

// Legacy summary kept for reference — authoritative version is _AcademicSummaryAuthoritative
// ignore: unused_element
class _AcademicSummary extends StatelessWidget {
  const _AcademicSummary({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, size: 18, color: palette.primary),
              const SizedBox(width: AppSpacing.xs),
              Text('Education Profile', style: context.text.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (profile.catalogCategory != null)
            _InfoRow(label: 'Category', value: profile.catalogCategory!.label),
          if (profile.course.isNotEmpty)
            _InfoRow(label: 'Course', value: profile.course),
          if (profile.catalogAuthority != null && profile.catalogAuthority!.isNotEmpty)
            _InfoRow(label: 'Board / Authority', value: profile.catalogAuthority!),
          if (profile.currentYear.isNotEmpty)
            _InfoRow(label: 'Level / Stage', value: profile.currentYear),
          if (profile.institution.isNotEmpty)
            _InfoRow(label: 'Institution', value: profile.institution),
          if (profile.academicFocus != null)
            _InfoRow(
              label: 'Current focus',
              value: profile.academicFocus!.label,
            ),
        ],
      ),
    );
  }
}

class _GoalsSummary extends StatelessWidget {
  const _GoalsSummary({required this.goals});

  final List<StudentGoal> goals;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 18, color: palette.primary),
              const SizedBox(width: AppSpacing.xs),
              Text('Goals', style: context.text.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: goals.map((g) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: palette.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(g.icon, size: 14, color: palette.primary),
                    const SizedBox(width: 4),
                    Text(
                      g.label,
                      style: context.text.labelSmall!.copyWith(
                        color: palette.primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: context.text.bodySmall!.copyWith(
              color: palette.onSurfaceMuted,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: context.text.bodySmall!.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOutTile extends StatelessWidget {
  const _SignOutTile();

  @override
  Widget build(BuildContext context) {
    return AppSettingsTile(
      icon: Icons.logout_rounded,
      title: 'Sign Out',
      subtitle: 'Sign out of your Student OS account',
      iconColor: AppColors.error,
      onTap: () => _confirmSignOut(context),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AuthService.instance.signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
