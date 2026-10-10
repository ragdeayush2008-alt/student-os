import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/services/student_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_section_header.dart';
import '../../core/assistant/assistant_launch_context.dart';
import '../../core/widgets/student_os_assistant_visual.dart';
import '../../core/widgets/student_os_page_header.dart';
import '../../core/animations/animated_entrance.dart';
import '../../data/models/student_profile.dart';
import '../goals/goal_controller.dart';
import '../progression/progression_controller.dart';
import '../study/study_controller.dart';
import '../tasks/task_controller.dart';

/// Clean, well-grouped More / Profile Screen for Student OS.
class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  void initState() {
    super.initState();
    StudentService.instance.addListener(_onDataChanged);
    TaskController.instance.addListener(_onDataChanged);
    StudyController.instance.addListener(_onDataChanged);
    GoalController.instance.addListener(_onDataChanged);
    ProgressionController.instance.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    StudentService.instance.removeListener(_onDataChanged);
    TaskController.instance.removeListener(_onDataChanged);
    StudyController.instance.removeListener(_onDataChanged);
    GoalController.instance.removeListener(_onDataChanged);
    ProgressionController.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  void _openEditProfile() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EditProfileSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = StudentService.instance.profile;
    final prog = ProgressionController.instance;

    return AppScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: AppSpacing.sm,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Canonical sibling header: same DNA as Home/Plan/Tools ──
                const AnimatedEntrance(
                  child: StudentOSPageHeader(
                    eyebrow: 'Your command center',
                    title: 'Workspace',
                    subtitle: 'Profile, progress and system controls.',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
            // ── Profile Identity Hero ────────────────────────────────
            AnimatedEntrance(
              child: _ProfileHeroCard(
                profile: profile,
                level: prog.currentLevel.level,
                totalXp: prog.totalXp,
                onEdit: _openEditProfile,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // ── Canonical Assistant entry (same component as Home/Plan) ──
            AnimatedEntrance(
              child: StudentOSAssistantEntryCard(
                onTap: () => AppRouter.openAssistant(
                  context,
                  launchContext: const AssistantLaunchContext(
                    origin: AssistantOrigin.workspace,
                  ),
                ),
                title: 'Ask Student OS',
                subtitle: 'Guidance across profile, goals and progress.',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Progress & Gamification Group ────────────────────────
            AnimatedEntrance(
              child: _SettingsGroup(
                title: 'Progress & Rewards',
                icon: Icons.emoji_events_rounded,
                items: [
                  _SettingsRowItem(
                    icon: Icons.insights_rounded,
                    title: 'Progress & Analytics',
                    subtitle: 'Weekly consistency, study time & completion',
                    onTap: () => AppRouter.openProgress(context),
                  ),
                  _SettingsRowItem(
                    icon: Icons.stars_rounded,
                    title: 'Rewards Marketplace',
                    subtitle: 'Redeem XP for themes & student perks',
                    onTap: () => AppRouter.openRewards(context),
                  ),
                  _SettingsRowItem(
                    icon: Icons.military_tech_rounded,
                    title: 'Achievements & Milestones',
                    subtitle: 'Track earned badges & lifetime accomplishments',
                    onTap: () => AppRouter.openAchievements(context),
                  ),
                  _SettingsRowItem(
                    icon: Icons.leaderboard_rounded,
                    title: 'Leaderboard',
                    subtitle: 'Your ranking & peer study activity',
                    onTap: () => AppRouter.openLeaderboard(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Academic Setup Group ─────────────────────────────────
            AnimatedEntrance(
              child: _SettingsGroup(
                title: 'Academic Profile',
                icon: Icons.school_rounded,
                items: [
                  _SettingsRowItem(
                    icon: Icons.book_rounded,
                    title: 'Subjects & Syllabus',
                    subtitle: 'Your enrolled academic subjects & topics',
                    onTap: () => AppRouter.openSubjectList(context),
                  ),
                  _SettingsRowItem(
                    icon: Icons.school_rounded,
                    title: 'Course & Education Setup',
                    subtitle: 'Update your degree, grade level & institution',
                    onTap: () => AppRouter.openEducationSetup(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── App Configuration ────────────────────────────────────
            AnimatedEntrance(
              child: _SettingsGroup(
                title: 'Preferences & System',
                icon: Icons.tune_rounded,
                items: [
                  _SettingsRowItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'Appearance, themes & reminders',
                    onTap: () => AppRouter.openSettings(context),
                  ),
                  _SettingsRowItem(
                    icon: Icons.manage_accounts_outlined,
                    title: 'Account & Data',
                    subtitle: 'Cloud sync, backup & sign out',
                    onTap: () => AppRouter.openAccountData(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Footer ───────────────────────────────────────────────
            AnimatedEntrance(
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Student OS',
                      style: context.text.titleSmall!.copyWith(
                        color: AppTheme.colorsOf(context).onSurfaceMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Version 1.0.0',
                      style: context.text.bodySmall!.copyWith(
                        color: AppTheme.colorsOf(context).onSurfaceMuted
                            .withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// PROFILE HERO
// ══════════════════════════════════════════════════════════════════════════

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.profile,
    required this.level,
    required this.totalXp,
    required this.onEdit,
  });

  final StudentProfile profile;
  final int level;
  final int totalXp;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final name = profile.displayName.isNotEmpty
        ? profile.displayName
        : (profile.email.isNotEmpty
              ? profile.email.split('@').first
              : 'Student');

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: palette.accentGradient),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: context.text.headlineSmall!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: context.text.titleLarge!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (profile.course.isNotEmpty ||
                        profile.institution.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          profile.course,
                          profile.institution,
                        ].where((s) => s.isNotEmpty).join(' · '),
                        style: context.text.bodySmall!.copyWith(
                          color: palette.onSurfaceMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: palette.streak.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            'Level $level',
                            style: context.text.labelSmall!.copyWith(
                              fontWeight: FontWeight.w700,
                              color: palette.streak,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$totalXp XP',
                          style: context.text.labelSmall!.copyWith(
                            color: palette.onSurfaceMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.primary,
                side: BorderSide(color: palette.primary.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// SETTINGS GROUP & ROW ITEMS
// ══════════════════════════════════════════════════════════════════════════

class _SettingsRowItem {
  const _SettingsRowItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<_SettingsRowItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: title, icon: icon),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _SettingsTile(item: items[i]),
                if (i < items.length - 1)
                  Divider(
                    height: 1,
                    indent: 52,
                    color: AppTheme.colorsOf(context).outline
                        .withValues(alpha: 0.3),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.item});

  final _SettingsRowItem item;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(item.icon, size: 18, color: palette.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: context.text.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    item.subtitle,
                    style: context.text.labelSmall!.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: palette.onSurfaceMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// INLINE EDIT PROFILE SHEET
// ══════════════════════════════════════════════════════════════════════════

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _institutionCtrl;
  late final TextEditingController _courseCtrl;
  late final TextEditingController _yearCtrl;
  late EducationLevel? _educationLevel;
  late AcademicFocus? _academicFocus;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = StudentService.instance.profile;
    _nameCtrl = TextEditingController(text: profile.displayName);
    _institutionCtrl = TextEditingController(text: profile.institution);
    _courseCtrl = TextEditingController(text: profile.course);
    _yearCtrl = TextEditingController(text: profile.currentYear);
    _educationLevel = profile.educationLevel;
    _academicFocus = profile.academicFocus;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _institutionCtrl.dispose();
    _courseCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);

    final profile = StudentService.instance.profile;
    final updated = profile.copyWith(
      displayName: _nameCtrl.text.trim(),
      institution: _institutionCtrl.text.trim(),
      course: _courseCtrl.text.trim(),
      currentYear: _yearCtrl.text.trim(),
      educationLevel: _educationLevel,
      clearEducationLevel: _educationLevel == null,
      academicFocus: _academicFocus,
      clearAcademicFocus: _academicFocus == null,
    );

    await StudentService.instance.updateProfile(updated);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: palette.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('Edit Profile', style: context.text.titleLarge),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                bottom + AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(
                    controller: _nameCtrl,
                    label: 'Display Name',
                    hint: 'Your name',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Education Level', style: context.text.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  _buildDropdown<EducationLevel>(
                    value: _educationLevel,
                    items: EducationLevel.values,
                    labelBuilder: (e) => e.label,
                    onChanged: (v) => setState(() => _educationLevel = v),
                    hint: 'Select level',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    controller: _institutionCtrl,
                    label: 'Institution',
                    hint: 'College, university or self-study',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    controller: _courseCtrl,
                    label: 'Course / Program',
                    hint: 'e.g. Computer Science',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                    controller: _yearCtrl,
                    label: 'Year / Semester',
                    hint: 'e.g. 2nd Year',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Academic Focus', style: context.text.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  _buildDropdown<AcademicFocus>(
                    value: _academicFocus,
                    items: AcademicFocus.values,
                    labelBuilder: (e) => e.label,
                    onChanged: (v) => setState(() => _academicFocus = v),
                    hint: 'Select focus',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_canSave && !_saving) ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: palette.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: _saving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: palette.onPrimary,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    final palette = AppTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          style: context.text.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: context.text.bodyMedium!.copyWith(
              color: palette.onSurfaceMuted,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
    required String hint,
  }) {
    final palette = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.outline.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: context.text.bodyMedium!.copyWith(
              color: palette.onSurfaceMuted,
            ),
          ),
          style: context.text.bodyMedium,
          onChanged: onChanged,
          items: [
            for (final item in items)
              DropdownMenuItem(value: item, child: Text(labelBuilder(item))),
          ],
        ),
      ),
    );
  }
}
