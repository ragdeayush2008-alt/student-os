import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../core/assistant/assistant_launch_context.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_scope.dart';
import '../../core/theme/app_shell_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_theme_mode.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/app_settings_tiles.dart';
import '../preferences/user_preferences_controller.dart';
import '../rewards/rewards_screen.dart';
import '../rewards/theme_manager.dart';
import '../../core/assistant/assistant_daily_state.dart';
import '../../core/assistant/daily_assistant_controller.dart';
import '../premium/services/entitlement_service.dart';

/// Premium Settings center.
///
/// Real, functional toggles that actually affect the Student OS experience:
/// - Theme mode (System / Light / Dark) — persists via [AppShellController]
/// - Theme variants (Default, Focus Dark, Academic Light, Midnight Scholar)
/// - Default focus duration — preselects when opening a focus session
/// - Week start day — stored preference for week-boundary calculations
/// - Study/planning reminder preferences — architecture-ready, persisted
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    UserPreferencesController.instance.addListener(_onChanged);
    ThemeManager.instance.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    UserPreferencesController.instance.removeListener(_onChanged);
    ThemeManager.instance.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final prefs = UserPreferencesController.instance;
    final themeManager = ThemeManager.instance;

    return AppScaffold(
      title: 'Settings',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Personalization
            AppSettingsGroup(
              title: 'Appearance Mode',
              children: [
                for (final mode in AppThemeMode.values)
                  AppSettingsSelectTile(
                    icon: _iconFor(mode),
                    title: mode.label,
                    selected: controller.themeMode == mode,
                    onTap: () => controller.setThemeMode(mode),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Color Themes / Variants
            AppSettingsGroup(
              title: 'Cosmetic Themes',
              children: [
                for (final variant in ThemeVariantId.values)
                  AppSettingsSelectTile(
                    icon: Icons.palette_outlined,
                    title: variant.displayName,
                    subtitle: themeManager.isThemeUnlocked(variant)
                        ? null
                        : 'Locked · Redeem with XP in Marketplace',
                    selected: themeManager.activeVariant == variant,
                    trailing: themeManager.isThemeUnlocked(variant)
                        ? null
                        : TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const RewardsScreen(),
                                ),
                              );
                            },
                            child: const Text('Unlock'),
                          ),
                    onTap: () async {
                      if (themeManager.isThemeUnlocked(variant)) {
                        await themeManager.setThemeVariant(variant);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${variant.displayName} is locked. Unlock it with XP in the Marketplace!',
                            ),
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Study experience
            AppSettingsGroup(
              title: 'Study experience',
              children: [
                _DurationSetting(
                  title: 'Default focus duration',
                  subtitle: _formatDuration(prefs.defaultFocusDuration),
                  icon: Icons.timer_outlined,
                  currentMinutes: prefs.defaultFocusDuration.inMinutes,
                  onChanged: (mins) =>
                      prefs.setDefaultFocusDuration(Duration(minutes: mins)),
                ),
                const SizedBox(height: AppSpacing.xs),
                _WeekStartSetting(
                  current: prefs.weekStartDay,
                  onChanged: prefs.setWeekStartDay,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Autopilot Mode
            AppSettingsGroup(
              title: 'Autopilot Mode',
              children: [
                for (final mode in AutopilotMode.values)
                  AppSettingsSelectTile(
                    icon: mode == AutopilotMode.autopilot
                        ? Icons.auto_awesome_rounded
                        : (mode == AutopilotMode.suggest
                            ? Icons.lightbulb_outline_rounded
                            : Icons.pan_tool_outlined),
                    title: mode.label,
                    subtitle: mode.description,
                    selected: prefs.autopilotMode == mode,
                    onTap: () => prefs.setAutopilotMode(mode),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Notifications & Reminders
            AppSettingsGroup(
              title: 'Notifications & Reminders',
              children: [
                AppSettingsTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Notification Center',
                  subtitle: 'View your alerts, updates, and activity history',
                  onTap: () => Navigator.of(context).pushNamed('/notifications'),
                ),
                const SizedBox(height: AppSpacing.xs),
                _ReminderToggle(
                  icon: Icons.menu_book_outlined,
                  title: 'Study reminder',
                  enabled: prefs.studyReminderEnabled,
                  time: prefs.studyReminderTime,
                  onChanged: (enabled, time) =>
                      prefs.setStudyReminder(enabled: enabled, time: time),
                ),
                const SizedBox(height: AppSpacing.xs),
                _ReminderToggle(
                  icon: Icons.calendar_today_outlined,
                  title: 'Planning reminder',
                  enabled: prefs.planningReminderEnabled,
                  time: prefs.planningReminderTime,
                  onChanged: (enabled, time) =>
                      prefs.setPlanningReminder(enabled: enabled, time: time),
                ),
                const SizedBox(height: AppSpacing.sm),
                _SwitchSettingTile(
                  icon: Icons.assignment_outlined,
                  title: 'Task reminders & alerts',
                  value: prefs.taskNotificationsEnabled,
                  onChanged: (v) => prefs.setNotificationCategoryEnabled(
                    category: 'tasks',
                    enabled: v,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _SwitchSettingTile(
                  icon: Icons.school_outlined,
                  title: 'Exam countdowns & milestones',
                  value: prefs.examNotificationsEnabled,
                  onChanged: (v) => prefs.setNotificationCategoryEnabled(
                    category: 'exams',
                    enabled: v,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _SwitchSettingTile(
                  icon: Icons.timer_outlined,
                  title: 'Focus & study completions',
                  value: prefs.focusNotificationsEnabled,
                  onChanged: (v) => prefs.setNotificationCategoryEnabled(
                    category: 'focus',
                    enabled: v,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _SwitchSettingTile(
                  icon: Icons.emoji_events_outlined,
                  title: 'Achievements & milestones',
                  value: prefs.achievementNotificationsEnabled,
                  onChanged: (v) => prefs.setNotificationCategoryEnabled(
                    category: 'achievements',
                    enabled: v,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _SwitchSettingTile(
                  icon: Icons.local_fire_department_outlined,
                  title: 'Streak warnings & celebrations',
                  value: prefs.streakNotificationsEnabled,
                  onChanged: (v) => prefs.setNotificationCategoryEnabled(
                    category: 'streak',
                    enabled: v,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _SwitchSettingTile(
                  icon: Icons.leaderboard_outlined,
                  title: 'Leaderboard rank updates',
                  value: prefs.leaderboardNotificationsEnabled,
                  onChanged: (v) => prefs.setNotificationCategoryEnabled(
                    category: 'leaderboard',
                    enabled: v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Assistant (P3: every toggle maps to real functionality)
            const _AssistantSettingsGroup(),
            const SizedBox(height: AppSpacing.xl),

            // Developer Tools: debug builds ONLY. Compiled out of release
            // by the kDebugMode gate below — never shippable UI.
            if (kDebugMode) ...[
              const _DeveloperToolsGroup(),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Learn Student OS (interactive guides) + canonical Assistant.
            AppSettingsGroup(
              title: 'Learn',
              children: [
                AppSettingsTile(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Ask Student OS',
                  subtitle:
                      'The same Assistant, with Settings context',
                  onTap: () => AppRouter.openAssistant(
                    context,
                    launchContext: const AssistantLaunchContext(
                      origin: AssistantOrigin.settings,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                AppSettingsTile(
                  icon: Icons.school_outlined,
                  title: 'Learn Student OS',
                  subtitle:
                      'Interactive guides that teach by doing',
                  onTap: () =>
                      AppRouter.openLearnCenter(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // About
            AppSettingsGroup(
              title: 'About',
              children: [
                const AppSettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Student OS',
                  subtitle: 'Version 0.1.0 · Phase 10B',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(AppThemeMode mode) => switch (mode) {
    AppThemeMode.light => Icons.light_mode_outlined,
    AppThemeMode.dark => Icons.dark_mode_outlined,
    AppThemeMode.system => Icons.brightness_auto_outlined,
  };

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return m > 0 ? '$h h $m m' : '$h hours';
    return '$m m';
  }
}

/// Assistant preferences (P3 §23). Each toggle gates real behavior in
/// [DailyAssistantController] (proactive cards, briefings, sleep-aware
/// planning, reminder notifications).
class _AssistantSettingsGroup extends StatefulWidget {
  const _AssistantSettingsGroup();

  @override
  State<_AssistantSettingsGroup> createState() =>
      _AssistantSettingsGroupState();
}

class _AssistantSettingsGroupState extends State<_AssistantSettingsGroup> {
  @override
  void initState() {
    super.initState();
    DailyAssistantController.instance.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DailyAssistantController.instance.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = DailyAssistantController.instance;
    final prefs = controller.preferences;

    Widget toggle({
      required IconData icon,
      required String title,
      required String subtitle,
      required bool value,
      required ValueChanged<bool> onChanged,
    }) {
      return AppSettingsTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        trailing: Switch(value: value, onChanged: onChanged),
        onTap: () => onChanged(!value),
      );
    }

    Future<void> update(AssistantPreferences next) =>
        controller.updatePreferences(next);

    return AppSettingsGroup(
      title: 'Assistant',
      children: [
        toggle(
          icon: Icons.auto_awesome_rounded,
          title: 'Proactive recommendations',
          subtitle: 'Attention cards in the Command Center',
          value: prefs.proactiveEnabled,
          onChanged: (v) =>
              update(prefs.copyWith(proactiveEnabled: v)),
        ),
        toggle(
          icon: Icons.wb_sunny_rounded,
          title: 'Morning briefing',
          subtitle: 'Prepared day summary each morning',
          value: prefs.morningBriefing,
          onChanged: (v) =>
              update(prefs.copyWith(morningBriefing: v)),
        ),
        toggle(
          icon: Icons.bedtime_rounded,
          title: 'Evening review',
          subtitle: 'Day summary once the day winds down',
          value: prefs.eveningReview,
          onChanged: (v) =>
              update(prefs.copyWith(eveningReview: v)),
        ),
        toggle(
          icon: Icons.bedtime_outlined,
          title: 'Sleep-aware planning',
          subtitle: 'Keep plans clear of the sleep window',
          value: prefs.sleepAwarePlanning,
          onChanged: (v) =>
              update(prefs.copyWith(sleepAwarePlanning: v)),
        ),
        toggle(
          icon: Icons.notifications_outlined,
          title: 'Morning briefing reminder',
          subtitle: 'Daily notification when the briefing is ready',
          value: prefs.briefingNotification,
          onChanged: (v) =>
              update(prefs.copyWith(briefingNotification: v)),
        ),
        toggle(
          icon: Icons.nights_stay_outlined,
          title: 'Evening review reminder',
          subtitle: 'Daily notification at 9 PM',
          value: prefs.eveningNotification,
          onChanged: (v) =>
              update(prefs.copyWith(eveningNotification: v)),
        ),
      ],
    );
  }
}

/// Temporary developer-only Premium preview (DEV ONLY — REMOVE BEFORE
/// PRODUCTION BILLING). Grants local Pro through the same EntitlementService
/// used by real subscriptions. Never a purchase, never verified, never
/// counted. The enclosing `if (kDebugMode)` keeps it out of release builds.
class _DeveloperToolsGroup extends StatefulWidget {
  const _DeveloperToolsGroup();

  @override
  State<_DeveloperToolsGroup> createState() => _DeveloperToolsGroupState();
}

class _DeveloperToolsGroupState extends State<_DeveloperToolsGroup> {
  @override
  void initState() {
    super.initState();
    EntitlementService.instance.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    EntitlementService.instance.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entitlement = EntitlementService.instance;
    final isPro = entitlement.isPro;
    return AppSettingsGroup(
      title: 'Developer Tools',
      children: [
        AppSettingsTile(
          icon: Icons.bug_report_outlined,
          title: isPro
              ? 'DEV ONLY — RESET TO FREE'
              : 'DEV ONLY — UNLOCK PRO',
          subtitle: isPro
              ? 'Local preview active (not a purchase)'
              : 'Local Pro preview for testing (not a purchase)',
          trailing: Switch(
            value: isPro,
            onChanged: (v) => entitlement.setDevOverride(v),
          ),
          onTap: () => entitlement.setDevOverride(!isPro),
        ),
      ],
    );
  }
}

/// A settings tile that opens a duration picker.
class _DurationSetting extends StatelessWidget {
  const _DurationSetting({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.currentMinutes,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final int currentMinutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppSettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () => _showDurationPicker(context),
    );
  }

  void _showDurationPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DurationPickerSheet(
        currentMinutes: currentMinutes,
        onSelect: onChanged,
      ),
    );
  }
}

class _DurationPickerSheet extends StatefulWidget {
  const _DurationPickerSheet({
    required this.currentMinutes,
    required this.onSelect,
  });

  final int currentMinutes;
  final ValueChanged<int> onSelect;

  @override
  State<_DurationPickerSheet> createState() => _DurationPickerSheetState();
}

class _DurationPickerSheetState extends State<_DurationPickerSheet> {
  late int _selectedMinutes;

  static const _presets = [15, 25, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _selectedMinutes = widget.currentMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Default focus duration', style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Preselected when opening a focus session',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _presets.map((m) {
              final selected = m == _selectedMinutes;
              return GestureDetector(
                onTap: () => setState(() => _selectedMinutes = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? palette.primary.withValues(alpha: 0.15)
                        : palette.surfaceVariant,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: selected ? palette.primary : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    _format(m),
                    style: context.text.labelMedium!.copyWith(
                      color: selected ? palette.primary : palette.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                widget.onSelect(_selectedMinutes);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: palette.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Save',
                style: context.text.titleMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _format(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0) return m > 0 ? '${h}h ${m}m' : '${h}h';
    return '${m}m';
  }
}

/// Week start day selector.
class _WeekStartSetting extends StatelessWidget {
  const _WeekStartSetting({required this.current, required this.onChanged});

  final WeekStartDay current;
  final ValueChanged<WeekStartDay> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppSettingsTile(
      icon: Icons.view_week_outlined,
      title: 'Week starts on',
      subtitle: current.label,
      onTap: () => _showPicker(context),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _WeekStartPickerSheet(current: current, onSelect: onChanged),
    );
  }
}

class _WeekStartPickerSheet extends StatelessWidget {
  const _WeekStartPickerSheet({required this.current, required this.onSelect});

  final WeekStartDay current;
  final ValueChanged<WeekStartDay> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Week starts on', style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          for (final day in WeekStartDay.values) ...[
            _WeekOption(
              day: day,
              selected: day == current,
              onTap: () {
                onSelect(day);
                Navigator.of(context).pop();
              },
            ),
            if (day != WeekStartDay.values.last)
              const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _WeekOption extends StatelessWidget {
  const _WeekOption({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final WeekStartDay day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: selected
              ? palette.primary.withValues(alpha: 0.12)
              : palette.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? palette.primary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 20,
              color: selected ? palette.primary : palette.onSurfaceMuted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              day.label,
              style: context.text.titleSmall!.copyWith(
                color: selected ? palette.primary : palette.onSurface,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reminder toggle with time picker.
class _ReminderToggle extends StatelessWidget {
  const _ReminderToggle({
    required this.icon,
    required this.title,
    required this.enabled,
    required this.time,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool enabled;
  final TimeOfDay time;
  final void Function(bool enabled, TimeOfDay? time) onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final formatted = formatTimeOfDay(time);

    return AppSettingsTile(
      icon: icon,
      title: title,
      subtitle: enabled ? formatted : 'Off',
      trailing: Switch(
        value: enabled,
        onChanged: (v) => onChanged(v, null),
        activeThumbColor: palette.primary,
      ),
      onTap: () async {
        if (!enabled) {
          onChanged(true, null);
          return;
        }
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onChanged(true, picked);
      },
    );
  }
}

/// Simple switch tile for boolean settings.
class _SwitchSettingTile extends StatelessWidget {
  const _SwitchSettingTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppSettingsTile(
      icon: icon,
      title: title,
      subtitle: value ? 'Enabled' : 'Disabled',
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: palette.primary,
      ),
      onTap: () => onChanged(!value),
    );
  }
}
