import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import '../../../core/auth/auth_isolation.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../auth/auth_gate.dart';
import '../../auth/auth_service.dart';
import '../../premium/services/entitlement_service.dart';
import '../../premium/widgets/premium_widgets.dart';
import '../../exams/exam_controller.dart';
import '../../focus/controller/focus_controller.dart';
import '../../goals/goal_controller.dart';
import '../../progression/progression_controller.dart';
import '../../resources/resource_controller.dart';
import '../../study/study_controller.dart';
import '../../subjects/subject_controller.dart';
import '../../tasks/task_controller.dart';
import '../../../core/intelligence/academic_intelligence_controller.dart';

/// Dedicated Account & Data management screen.
///
/// Shows real sync/account status, data management actions, and sign out.
/// Destructive actions require careful confirmation.
class AccountDataScreen extends StatefulWidget {
  const AccountDataScreen({super.key});

  @override
  State<AccountDataScreen> createState() => _AccountDataScreenState();
}

class _AccountDataScreenState extends State<AccountDataScreen> {
  @override
  void initState() {
    super.initState();
    AuthService.instance.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    AuthService.instance.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supaReady =
        SupabaseService.instance.currentState == SupabaseInitState.ready;
    final user = supaReady ? AuthService.instance.user : null;
    final isDemo = !supaReady || user == null;

    return AppScaffold(
      title: 'Account & Data',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sync status
            AppSectionHeader(title: 'Sync status', icon: Icons.cloud_outlined),
            const SizedBox(height: AppSpacing.md),
            _SyncStatusCard(isDemo: isDemo, email: user?.email),
            const SizedBox(height: AppSpacing.xl),

            // Membership
            AppSectionHeader(
              title: 'Membership',
              icon: Icons.workspace_premium_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            const _MembershipSection(),
            const SizedBox(height: AppSpacing.xl),

            // Data management
            AppSectionHeader(
              title: 'Data management',
              icon: Icons.storage_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            _DataManagementSection(isDemo: isDemo),
            const SizedBox(height: AppSpacing.xl),

            // Account
            if (!isDemo) ...[
              AppSectionHeader(
                title: 'Account',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: AppSpacing.md),
              _AccountSection(email: user.email),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

/// Membership entry: live FREE/PRO status with a badge, opening the
/// Membership screen. Listens to the entitlement service for updates.
class _MembershipSection extends StatelessWidget {
  const _MembershipSection();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EntitlementService.instance,
      builder: (context, _) {
        final entitlement = EntitlementService.instance;
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: InkWell(
            onTap: () => AppRouter.openMembership(context),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            entitlement.isPro
                                ? 'Student OS Pro'
                                : 'Student OS Free',
                            style: context.text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (entitlement.isPro) ...[
                            const SizedBox(width: 6),
                            const PremiumBadge(),
                          ],
                        ],
                      ),
                      Text(
                        entitlement.isPro
                            ? entitlement.status.label
                            : 'Explore what Pro can unlock',
                        style: context.text.bodySmall?.copyWith(
                          color: AppTheme.colorsOf(context).onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SyncStatusCard extends StatelessWidget {  const _SyncStatusCard({required this.isDemo, this.email});

  final bool isDemo;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDemo ? palette.onSurfaceMuted : palette.success)
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDemo ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
              size: 20,
              color: isDemo ? palette.onSurfaceMuted : palette.success,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDemo ? 'Local mode' : 'Synced',
                  style: context.text.titleSmall,
                ),
                Text(
                  isDemo
                      ? 'Running in local demo mode — data stays on device'
                      : (email ?? 'Signed in'),
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DataManagementSection extends StatelessWidget {
  const _DataManagementSection({required this.isDemo});

  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DataTile(
          icon: Icons.refresh_rounded,
          title: 'Refresh data',
          subtitle: 'Reload all local data from storage',
          onTap: () => _refreshData(context),
        ),
        const SizedBox(height: AppSpacing.xs),
        _DataTile(
          icon: Icons.delete_outline_rounded,
          title: 'Clear all local data',
          subtitle: 'Remove all Student OS data from this device',
          iconColor: AppColors.error,
          onTap: () => _confirmClearData(context),
        ),
      ],
    );
  }

  void _refreshData(BuildContext context) async {
    await TaskController.instance.load();
    await StudyController.instance.load();
    await GoalController.instance.load();
    await ExamController.instance.load();
    await SubjectController.instance.load();
    await FocusController.instance.load();
    await ResourceController.instance.load();
    await ProgressionController.instance.load();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Data refreshed')));
    }
  }

  void _confirmClearData(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear all local data'),
        content: const Text(
          'This will permanently delete all your tasks, study sessions, '
          'goals, preferences and profile data from this device. '
          'This action cannot be undone.',
        ),
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
              await _clearAllData(context);
            },
            child: const Text('Clear data'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData(BuildContext context) async {
    // Scope the wipe to the resolved user only; never wipe a shared
    // fallback namespace, and refuse when identity is unknown.
    final userId = AuthIsolation.resolveUserId(
      AuthService.instance.user?.id,
    );
    if (userId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to manage local data')),
        );
      }
      return;
    }
    await StorageService.instance.clearUser(userId: userId);
    // Reload ALL user-scoped controllers after clearing storage
    await TaskController.instance.load();
    await StudyController.instance.load();
    await GoalController.instance.load();
    await ExamController.instance.load();
    await SubjectController.instance.load();
    await FocusController.instance.load();
    await ResourceController.instance.load();
    await ProgressionController.instance.load();
    // Refresh does not need await — it's synchronous notify
    AcademicIntelligenceController.instance.refresh();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All local data cleared')));
    }
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    return _DataTile(
      icon: Icons.logout_rounded,
      title: 'Sign out',
      subtitle: email ?? 'Sign out of your account',
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
              if (!context.mounted) return;
              // Clear user-scoped controllers/state and navigate back to auth
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthGate()),
                (route) => false,
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _DataTile extends StatelessWidget {
  const _DataTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final fill = iconColor ?? palette.primary;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: fill.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 20, color: fill),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleSmall),
                Text(subtitle, style: context.text.bodySmall),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: palette.onSurfaceMuted,
          ),
        ],
      ),
    );
  }
}
