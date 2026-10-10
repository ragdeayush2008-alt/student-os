import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../focus/controller/focus_controller.dart';
import '../../focus/controller/focus_guard_controller.dart';
import '../../focus/presentation/screens/focus_guard_settings_screen.dart';
import '../../study/study_controller.dart';

/// Student Wellness & Study Balance Workspace.
///
/// Provides study-life balance metrics, digital wellbeing insights from Focus Guard,
/// break rhythm recommendations, and lightweight daily wellness reflections.
class WellnessScreen extends StatefulWidget {
  const WellnessScreen({super.key});

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  int _selectedEnergyRating = 3; // 1 to 5 scale
  bool _tookWaterBreak = false;
  bool _tookStretchBreak = false;

  @override
  void initState() {
    super.initState();
    StudyController.instance.addListener(_onDataChanged);
    FocusController.instance.addListener(_onDataChanged);
    FocusGuardController.instance.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    StudyController.instance.removeListener(_onDataChanged);
    FocusController.instance.removeListener(_onDataChanged);
    FocusGuardController.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final sc = StudyController.instance;
    final fc = FocusController.instance;
    final fgc = FocusGuardController.instance;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStudyMinutes = sc.todayDuration.inMinutes;
    final todayFocusMinutes = fc.sessions
        .where((s) => s.isComplete && DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day) == today)
        .fold<int>(0, (sum, s) => sum + s.effectiveElapsed.inMinutes);

    // Recommended breaks based on completed study time (1 break per 45 min)
    final recommendedBreaks = (todayStudyMinutes / 45).ceil();

    return AppScaffold(
      title: 'Student Wellness',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Study Balance Card ──
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: palette.success.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.spa_rounded, color: palette.success, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Study & Rhythm Balance',
                              style: context.text.titleMedium!.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Sustainable study habits prevent burnout',
                              style: context.text.bodySmall!.copyWith(color: palette.onSurfaceMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          label: 'Study Today',
                          value: '${todayStudyMinutes}m',
                          icon: Icons.timer_outlined,
                          color: palette.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _StatBox(
                          label: 'Deep Focus',
                          value: '${todayFocusMinutes}m',
                          icon: Icons.bolt_rounded,
                          color: palette.streak,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _StatBox(
                          label: 'Break Target',
                          value: '$recommendedBreaks take(s)',
                          icon: Icons.coffee_outlined,
                          color: palette.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Daily Energy Check-in ──
            AppSectionHeader(title: 'Daily Energy & Reflection', icon: Icons.sentiment_satisfied_alt_rounded),
            const SizedBox(height: AppSpacing.xs),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How is your mental focus & energy today?',
                    style: context.text.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (int rating = 1; rating <= 5; rating++) ...[
                        InkWell(
                          onTap: () => setState(() => _selectedEnergyRating = rating),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedEnergyRating == rating
                                  ? palette.primary
                                  : palette.surfaceVariant,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              _ratingLabel(rating),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _selectedEnergyRating == rating
                                    ? Colors.white
                                    : palette.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Checkbox(
                        value: _tookWaterBreak,
                        onChanged: (v) => setState(() => _tookWaterBreak = v ?? false),
                        activeColor: palette.primary,
                      ),
                      const Expanded(
                        child: Text('Hydration break taken', style: TextStyle(fontSize: 13)),
                      ),
                      Checkbox(
                        value: _tookStretchBreak,
                        onChanged: (v) => setState(() => _tookStretchBreak = v ?? false),
                        activeColor: palette.primary,
                      ),
                      const Expanded(
                        child: Text('Stand & stretch break', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Digital Wellbeing & App Blocking ──
            AppSectionHeader(title: 'Digital Wellbeing', icon: Icons.shield_outlined),
            const SizedBox(height: AppSpacing.xs),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.app_blocking_rounded, color: palette.primary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Focus Guard is ${fgc.isGuardEnabled ? "Ready" : "Disabled"}',
                          style: context.text.bodyMedium!.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const FocusGuardSettingsScreen(),
                            ),
                          );
                        },
                        child: const Text('Manage Guard'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${fgc.blockedPackages.length} application(s) configured for distraction-free study.',
                    style: context.text.bodySmall!.copyWith(color: palette.onSurfaceMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Pacing Guidelines ──
            AppSectionHeader(title: 'Pacing Guidelines', icon: Icons.lightbulb_outline_rounded),
            const SizedBox(height: AppSpacing.xs),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GuidelineRow(
                    icon: Icons.timer_outlined,
                    title: 'The 45 / 10 Rule',
                    description: 'Study deeply for 45 minutes, then take a full 10-minute mental break.',
                    palette: palette,
                  ),
                  const Divider(height: AppSpacing.lg),
                  _GuidelineRow(
                    icon: Icons.nightlight_round,
                    title: 'Consistent Sleep Windows',
                    description: 'Memory consolidation peaks when sleep schedule remains consistent.',
                    palette: palette,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1:
        return 'Low';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'High';
      case 5:
        return 'Peak';
      default:
        return '$r';
    }
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.colorsOf(context).onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidelineRow extends StatelessWidget {
  const _GuidelineRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.palette,
  });

  final IconData icon;
  final String title;
  final String description;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: palette.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(fontSize: 11.5, color: palette.onSurfaceMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
