import 'package:flutter/material.dart';

import '../../../../app/app_router.dart';
import '../../../guides/guide_controller.dart';
import '../../../guides/guide_overlay.dart';
import '../../../guides/guide_targets.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/services/streak_service.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../features/subjects/presentation/subject_creation_sheet.dart';
import '../../../../features/subjects/subject_controller.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/student_os_segmented_control.dart';
import '../../../../core/widgets/student_os_icon_glow.dart';
import '../../controller/focus_controller.dart';
import '../../data/models/focus_mission.dart';
import '../../data/models/focus_preset.dart';
import '../widgets/focus_menu_sheet.dart';
import '../widgets/focus_palette.dart';
import '../widgets/focus_mode_holder.dart';
import '../widgets/focus_direct_controls.dart';
import 'focus_history_screen.dart';
import 'focus_session_screen.dart';

class FocusCenterScreen extends StatefulWidget {
  const FocusCenterScreen({
    super.key,
    this.taskId,
    this.focusTitle,
    this.subjectName,
    this.subjectId,
    this.examId,
  });

  final String? taskId;
  final String? focusTitle;
  final String? subjectName;
  final String? subjectId;
  final String? examId;

  @override
  State<FocusCenterScreen> createState() => _FocusCenterScreenState();
}

class _FocusCenterScreenState extends State<FocusCenterScreen> {
  int _timerMinutes = 30;

  /// Marks a session that was already running when the Focus tab was opened, so
  /// it is auto-shown on entry (mode is whatever is actually running) without
  /// contaminating the authoritative selected mode. Cleared when the user
  /// backs out of the session HUD to the landing.
  bool _resumeActiveSession = false;

  FocusMode get _selectedMode => FocusModeHolder.instance.mode;

  // Per-second focus ticks are filtered out: the running HUD's timer is driven
  // by its own _PerSecondBuilder, so the surrounding landing/HUD must not
  // rebuild every second.
  String? _lastSessionId;
  bool _lastIsPaused = false;
  FocusPhase? _lastPhase;

  @override
  void initState() {
    super.initState();
    _resumeActiveSession = FocusController.instance.hasActiveSession;
    FocusModeHolder.instance.addListener(_onModeChanged);
    FocusController.instance.addListener(_onFocusDataChanged);
    SubjectController.instance.addListener(_onDataChanged);
    StreakService.instance.addListener(_onDataChanged);
    _syncFocusSnapshot();
  }

  void _syncFocusSnapshot() {
    final s = FocusController.instance.activeSession;
    _lastSessionId = s?.id;
    _lastIsPaused = s?.isPaused ?? false;
    _lastPhase = s?.phase;
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  void _onFocusDataChanged() {
    final s = FocusController.instance.activeSession;
    final id = s?.id;
    final isPaused = s?.isPaused ?? false;
    final phase = s?.phase;
    if (id != _lastSessionId ||
        isPaused != _lastIsPaused ||
        phase != _lastPhase) {
      _lastSessionId = id;
      _lastIsPaused = isPaused;
      _lastPhase = phase;
      if (mounted) setState(() {});
    }
  }

  void _onModeChanged() {
    // Any mode/landing signal ends the entry auto-show: once the user has
    // navigated (back out of a HUD, or switched segments), the landing is
    // authoritative again. The running session itself stays untouched.
    _resumeActiveSession = false;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    FocusModeHolder.instance.removeListener(_onModeChanged);
    FocusModeHolder.instance.setMode(FocusMode.focusGuard);
    FocusController.instance.removeListener(_onFocusDataChanged);
    SubjectController.instance.removeListener(_onDataChanged);
    StreakService.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fc = FocusController.instance;
    final fp = FocusPalette.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // A session that was already running when this tab was entered is shown on
    // entry (its real mode). Separately, an in-tab start whose selected mode
    // matches the active session's mode auto-shows the HUD. In both cases the
    // selected mode itself always stays authoritative for the landing UI.
    final activeSession = fc.activeSession;
    if (activeSession != null &&
        (_resumeActiveSession || activeSession.mode == _selectedMode)) {
      return FocusSessionScreen(
        taskId: widget.taskId,
        focusTitle: widget.focusTitle,
        subjectName: widget.subjectName,
        subjectId: widget.subjectId,
        examId: widget.examId,
      );
    }

    return AppScaffold(
      title: 'SprintX',
      onBack: _handleBack,
      actions: [
        IconButton(
          icon: Icon(
            Icons.history_rounded,
            color: fp.textSecondary,
          ),
          tooltip: 'SprintX History',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const FocusHistoryScreen(),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(
            Icons.help_outline_rounded,
            color: fp.textSecondary,
          ),
          tooltip: 'How does SprintX work?',
          onPressed: () {
            GuideOverlayManager.ensureListening();
            GuideController.instance.startGuide('sprintx');
          },
        ),
        IconButton(
          icon: Icon(
            Icons.more_vert_rounded,
            color: fp.textSecondary,
          ),
          tooltip: 'SprintX Menu',
          onPressed: () => FocusMenuSheet.show(
            context,
            mode: _selectedMode,
          ),
        ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildModeSegmentedControl(),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Smooth mode transitions: fade + slight vertical
                      // movement. Segmented control stays stable.
                      AnimatedSwitcher(
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          final offset = Tween<Offset>(
                            begin: const Offset(0, 0.04),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offset,
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey(_selectedMode),
                          child: _buildModeContent(context),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBack() {
    if (_selectedMode == FocusMode.timer ||
        _selectedMode == FocusMode.stopwatch) {
      FocusModeHolder.instance.setMode(FocusMode.focusGuard);
      return;
    }
    Navigator.of(context).maybePop();
  }

  Widget _buildModeContent(BuildContext context) {
    return switch (_selectedMode) {
      FocusMode.focusGuard => _buildFocusModeContent(context),
      FocusMode.timer => _buildTimerModeContent(context),
      FocusMode.stopwatch => _buildStopwatchModeContent(context),
    };
  }

  /// Clean 3-mode segmented control: neutral track, solid selected segment
  /// with primary icon emphasis — never a dominating filled pill.
  Widget _buildModeSegmentedControl() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GuideTargetAnchor(
        id: 'sprintx.modeControl',
        child: StudentOSSegmentedControl<FocusMode>(
        segments: const [
          StudentOSSegment(
            value: FocusMode.focusGuard,
            label: 'Focus',
            icon: Icons.center_focus_strong_rounded,
          ),
          StudentOSSegment(
            value: FocusMode.timer,
            label: 'Timer',
            icon: Icons.timer_outlined,
          ),
          StudentOSSegment(
            value: FocusMode.stopwatch,
            label: 'Stopwatch',
            icon: Icons.av_timer_outlined,
          ),
        ],
        selected: _selectedMode,
        onChanged: (mode) {
          FocusModeHolder.instance.setMode(mode);
          // Ensure mode switch is explicit — never infer from stale timer/stopwatch
        },
        semanticLabel: 'SprintX mode selector: FOCUS | TIMER | STOPWATCH',
        ),
      ),
    );
  }

  Widget _buildFocusModeContent(BuildContext context) {
    final fp = FocusPalette.of(context);
    final sc = SubjectController.instance;
    final fc = FocusController.instance;
    final activeSubjects = sc.activeSubjects;
    final recommendedSubject =
        activeSubjects.isNotEmpty ? activeSubjects.first : null;
    final currentStreak = StreakService.instance.currentStreak;

    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day).subtract(
      Duration(days: now.weekday - 1),
    );
    final thisWeekSessions = fc.sessions
        .where(
          (s) =>
              s.isComplete &&
              s.startedAt.isAfter(weekStart) &&
              s.mode == FocusMode.focusGuard,
        )
        .toList();
    final totalWeeklyMinutes = thisWeekSessions.fold<int>(
      0,
      (sum, s) => sum + s.actualFocusedDuration.inMinutes,
    );
    final weeklyHoursStr = totalWeeklyMinutes >= 60
        ? '${totalWeeklyMinutes ~/ 60}h ${totalWeeklyMinutes % 60}m'
        : '${totalWeeklyMinutes}m';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_fire_department_rounded,
                // Streak carries the strongest emerald tone (intensity via
                // typography + glow lives in the card, never orange).
                iconColor: fp.primary,
                title: 'Streak',
                value: '$currentStreak days',
                subtitle:
                    currentStreak > 0 ? 'Daily momentum' : 'Start your streak',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.timer_outlined,
                iconColor: fp.secondary,
                title: 'This Week',
                value: weeklyHoursStr,
                subtitle:
                    '${thisWeekSessions.length} session${thisWeekSessions.length == 1 ? '' : 's'} done',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (recommendedSubject != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: fp.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: fp.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: fp.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'READY TO FOCUS',
                        style: TextStyle(
                          color: fp.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      '35 min suggested',
                      style: TextStyle(
                        color: fp.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  recommendedSubject.displayName,
                  style: TextStyle(
                    color: fp.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (recommendedSubject.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    recommendedSubject.description,
                    style: TextStyle(
                      color: fp.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                AppPressable(
                  onTap: () {
                    FocusController.instance.startFocusGuard(
                      duration: const Duration(minutes: 35),
                      subjectId: recommendedSubject.id,
                      subjectName: recommendedSubject.displayName,
                      objective: recommendedSubject.displayName,
                    );
                    FocusModeHolder.instance
                        .setMode(FocusMode.focusGuard);
                    AppRouter.openActiveFocusSession(context);
                  },
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: fp.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            color: fp.onPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Start Focus',
                            style: TextStyle(
                              color: fp.onPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: fp.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: fp.border),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.center_focus_strong_rounded,
                  size: 32,
                  color: fp.textMuted,
                ),
                const SizedBox(height: 8),
                Text(
                  'Nothing to focus on yet.',
                  style: TextStyle(
                    color: fp.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add a subject to unlock smart focus recommendations.',
                  style: TextStyle(
                    color: fp.textSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: fp.primary,
                  ),
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const SubjectCreationSheet(),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Subject'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),

        Text(
          'Quick Start',
          style: TextStyle(
            color: fp.text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPresetChip(FocusPreset.sprint),
            _buildPresetChip(FocusPreset.pomodoro),
            _buildPresetChip(FocusPreset.deepFocus),
            _buildPresetChip(FocusPreset.deepWork),
          ],
        ),
        const SizedBox(height: 16),
        const DirectFocusGuardControl(),
        const SizedBox(height: 8),
        const DirectScreenSleepControl(),
        const SizedBox(height: 8),
        const DirectBgMusicControl(),
      ],
    );
  }

  Widget _buildTimerModeContent(BuildContext context) {
    final fp = FocusPalette.of(context);
    final presets = [15, 25, 30, 45, 60];

    return Column(
      children: [
        const SizedBox(height: 24),
        // Responsive dial: scales with available width, capped so it never
        // dominates large screens or clips small ones.
        LayoutBuilder(
          builder: (context, constraints) {
            final dial =
                (constraints.maxWidth * 0.62).clamp(190.0, 250.0);
            return SizedBox(
              width: dial,
              height: dial,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: dial * 0.9,
                    height: dial * 0.9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Restrained localized glow — no large halo.
                      boxShadow: StudentOSGlow.tone(
                        tone: StudentOSGlowTone.primary,
                        intensity: StudentOSGlowIntensity.subtle,
                        radius: StudentOSGlowRadius.medium,
                        isDark: fp.isDark,
                      ),
                    ),
                  ),
                  CustomPaint(
                    size: Size(dial * 0.95, dial * 0.95),
                    painter: _RadialTimerPainter(
                      progress: 1.0,
                      accentColor: fp.primary,
                      trackColor: fp.border,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_timerMinutes.toString().padLeft(2, '0')}:00',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: fp.text,
                          letterSpacing: -1.0,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Set duration',
                        style: TextStyle(
                          color: fp.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 32),

        GuideTargetAnchor(
          id: 'sprintx.durationPicker',
          child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            ...presets.map((m) {
              final isSelected = _timerMinutes == m;
              return AppPressable(
                onTap: () => setState(() => _timerMinutes = m),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? fp.primary
                        : fp.surface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: isSelected
                          ? fp.primary
                          : fp.border,
                    ),
                  ),
                  child: Text(
                    '$m MIN',
                    style: TextStyle(
                      color: isSelected
                          ? fp.onPrimary
                          : fp.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }),
            AppPressable(
              onTap: () => _pickCustomTimerDuration(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: !presets.contains(_timerMinutes)
                      ? fp.primary
                      : fp.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: !presets.contains(_timerMinutes)
                        ? fp.primary
                        : fp.border,
                  ),
                ),
                child: Text(
                  !presets.contains(_timerMinutes)
                      ? '$_timerMinutes MIN'
                      : 'CUSTOM',
                  style: TextStyle(
                    color: !presets.contains(_timerMinutes)
                        ? fp.onPrimary
                        : fp.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
          ),
        ),
        const SizedBox(height: 32),

        GuideTargetAnchor(
          id: 'sprintx.startTimer',
          child: AppPressable(
          onTap: () {
            FocusModeHolder.instance.setMode(FocusMode.timer);
            FocusController.instance.startTimer(
              duration: Duration(minutes: _timerMinutes),
              objective: widget.focusTitle ?? widget.subjectName ?? 'Timer',
            );
            AppRouter.openActiveFocusSession(context);
          },
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: fp.primary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    color: fp.onPrimary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'START TIMER',
                    style: TextStyle(
                      color: fp.onPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        ),
        const SizedBox(height: 16),
        const DirectScreenSleepControl(),
        const SizedBox(height: 8),
        const DirectBgMusicControl(),
      ],
    );
  }

  Widget _buildStopwatchModeContent(BuildContext context) {
    final fp = FocusPalette.of(context);
    return Column(
      children: [
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final dial =
                (constraints.maxWidth * 0.62).clamp(190.0, 250.0);
            return SizedBox(
              width: dial,
              height: dial,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: dial * 0.9,
                    height: dial * 0.9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: StudentOSGlow.tone(
                        tone: StudentOSGlowTone.secondary,
                        intensity: StudentOSGlowIntensity.subtle,
                        radius: StudentOSGlowRadius.medium,
                        isDark: fp.isDark,
                      ),
                    ),
                  ),
                  CustomPaint(
                    size: Size(dial * 0.95, dial * 0.95),
                    painter: _RadialTimerPainter(
                      progress: 0.0,
                      accentColor: fp.secondary,
                      trackColor: fp.border,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '00:00:00',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: fp.text,
                          letterSpacing: -0.5,
                          fontFeatures: const [
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Count-up timer',
                        style: TextStyle(
                          color: fp.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 48),

        GuideTargetAnchor(
          id: 'sprintx.startStopwatch',
          child: AppPressable(
          onTap: () {
            FocusModeHolder.instance.setMode(FocusMode.stopwatch);
            FocusController.instance.startStopwatch(
              objective: widget.focusTitle ?? widget.subjectName ?? 'Stopwatch',
            );
            AppRouter.openActiveFocusSession(context);
          },
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: fp.secondary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    color: fp.onPrimary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'START STOPWATCH',
                    style: TextStyle(
                      color: fp.onPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        ),
        const SizedBox(height: 16),
        const DirectScreenSleepControl(),
        const SizedBox(height: 8),
        const DirectBgMusicControl(),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    final fp = FocusPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fp.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: fp.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: fp.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: fp.text,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: fp.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(FocusPreset preset) {
    final fp = FocusPalette.of(context);
    return AppPressable(
      onTap: () {
        FocusController.instance.startFocusGuard(
          duration: preset.duration,
          subjectId: widget.subjectId,
          subjectName: widget.subjectName,
          taskId: widget.taskId,
          examId: widget.examId,
          objective: '${preset.label} Focus',
        );
        FocusModeHolder.instance.setMode(FocusMode.focusGuard);
        AppRouter.openActiveFocusSession(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: fp.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: fp.border),
        ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Monochromatic emerald icon — no multicolor emoji.
              Icon(preset.iconData, size: 15, color: fp.primary),
              const SizedBox(width: 6),
            Text(
              preset.label,
              style: TextStyle(
                color: fp.text,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${preset.durationMinutes}m',
              style: TextStyle(
                color: fp.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomTimerDuration(BuildContext context) async {
    final fp = FocusPalette.of(context);
    final controller = TextEditingController(text: '$_timerMinutes');
    final minutes = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: fp.surface,
        title: Text(
          'Custom Duration',
          style: TextStyle(color: fp.text),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: fp.text),
          decoration: InputDecoration(
            labelText: 'Duration in minutes',
            labelStyle: TextStyle(color: fp.textSecondary),
            suffixText: 'min',
            suffixStyle: TextStyle(color: fp.textSecondary),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val > 0 && val <= 360) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );

    if (minutes != null && mounted) {
      setState(() => _timerMinutes = minutes);
    }
  }
}

// ── Direct compact controls for Focus 2.0 ───────────────────────────────

class _RadialTimerPainter extends CustomPainter {
  _RadialTimerPainter({
    required this.progress,
    required this.accentColor,
    required this.trackColor,
  });

  final double progress;
  final Color accentColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 8;

      final startAngle = -3.1415926535 / 2;
      final sweepAngle = 2 * 3.1415926535 * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RadialTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.trackColor != trackColor;
  }
}
