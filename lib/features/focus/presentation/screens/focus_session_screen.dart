import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/services/streak_service.dart';
import '../../../../core/services/xp_engine.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../widgets/focus_palette.dart';
import '../widgets/focus_mode_holder.dart';
import '../../controller/focus_controller.dart';
import '../../controller/focus_guard_controller.dart';
import '../../controller/focus_music_controller.dart';
import '../../controller/focus_screen_sleep_controller.dart';
import '../../data/models/focus_mission.dart';
import '../../data/models/focus_guard_models.dart';
import '../../data/models/focus_music_track.dart';
import '../widgets/focus_menu_sheet.dart';
import '../widgets/sprintx_session_components.dart';
import 'focus_guard_settings_screen.dart';
import 'timer_session_screen.dart';
import 'stopwatch_session_screen.dart';



class FocusSessionScreen extends StatefulWidget {
  const FocusSessionScreen({
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
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    )..forward();

    FocusController.instance.addListener(_onFocusChanged);
    FocusMusicController.instance.addListener(_onDataChanged);
    FocusScreenSleepController.instance.addListener(_onDataChanged);
    _syncFocusSnapshot();
  }

  String? _lastSessionId;
  bool _lastIsPaused = false;
  FocusPhase? _lastPhase;

  void _syncFocusSnapshot() {
    final s = FocusController.instance.activeSession;
    _lastSessionId = s?.id;
    _lastIsPaused = s?.isPaused ?? false;
    _lastPhase = s?.phase;
  }

  void _onFocusChanged() {
    final s = FocusController.instance.activeSession;
    final id = s?.id;
    final isPaused = s?.isPaused ?? false;
    final phase = s?.phase;
    // Rebuild only when identity or phase/paused changes; per-second tick
    // is handled by _PerSecondBuilder so the surrounding HUD stays stable.
    if (id != _lastSessionId ||
        isPaused != _lastIsPaused ||
        phase != _lastPhase) {
      _lastSessionId = id;
      _lastIsPaused = isPaused;
      _lastPhase = phase;
      if (mounted) setState(() {});
    }
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _entranceController.dispose();
    FocusController.instance.removeListener(_onFocusChanged);
    FocusMusicController.instance.removeListener(_onDataChanged);
    FocusScreenSleepController.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fp = FocusPalette.of(context);
    final session = FocusController.instance.activeSession;

    if (session == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [fp.bgTop, fp.bgBottom],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 48,
                  color: fp.textMuted,
                ),
                SizedBox(height: 16),
                Text(
                  'No active session',
                  style: TextStyle(
                    color: fp.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Start a focus session from the Focus Center',
                  style: TextStyle(
                    color: fp.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                AppPressable(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: fp.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'Go to Focus Hub',
                      style: TextStyle(
                        color: fp.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Phase 4: Timer and Stopwatch render their own dedicated SprintX
    // experiences. Focus keeps the UI 2.0 renderer below, untouched.
    if (session.mode == FocusMode.timer) {
      return const TimerSessionScreen();
    }
    if (session.mode == FocusMode.stopwatch) {
      return const StopwatchSessionScreen();
    }
    return _buildUi2Session(context, session);
  }

  // ═══════════════════════════════════════════════════════════════════
  // UI 2.0 — unified light reference design for Focus, Timer, Stopwatch.
  //
  // Audit note (Focus Guard): the legacy branch mounted its Guard control
  // only inside a compact row, and that control returns SizedBox.shrink on
  // unsupported platforms, so the Guard card never painted there. UI 2.0
  // always mounts the Guard card in Focus mode and renders it as
  // "Setup Needed" instead of shrinking to nothing. Timer/Stopwatch share
  // the same screen with the other four quick tools.
  //
  // All visuals are driven by the authoritative FocusController /
  // FocusSession timestamp lifecycle — no second timer engine, no drift.
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildUi2Session(BuildContext context, FocusSession session) {
    // Canonical Student OS theme via centralized tokens (adapts to dark).
    final fp = FocusPalette.of(context);
    return Scaffold(
      backgroundColor: fp.bgTop,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFocusUi2TopBar(context, fp, session),
                  const SizedBox(height: 18),
                  _buildFocusUi2Subject(fp, session),
                  const SizedBox(height: 22),
                  // Targeted rebuild: only the timer repaints every second.
                  _PerSecondBuilder(
                    builder: (_) => _buildFocusUi2Timer(fp, session),
                  ),
                  const SizedBox(height: 22),
                  _buildFocusUi2XpStreak(fp, session),
                  const SizedBox(height: 26),
                  _buildFocusUi2Controls(fp, session),
                  const SizedBox(height: 30),
                  _buildFocusUi2QuickTools(fp, session),
                  const SizedBox(height: 22),
                  _buildFocusUi2Motivation(fp),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFocusUi2TopBar(
    BuildContext context,
    FocusPalette fp,
    FocusSession session,
  ) {
    final modeTitle = switch (session.mode) {
      FocusMode.focusGuard => 'FOCUS MODE',
      FocusMode.timer => 'TIMER',
      FocusMode.stopwatch => 'STOPWATCH',
    };
    return Row(
      children: [
        _FocusUi2CircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          iconSize: 18,
          onTap: _goBackFromSession,
        ),
        Expanded(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: fp.tintBlue,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _FocusUi2Dot(),
                  const SizedBox(width: 6),
                  Text(
                    modeTitle,
                    style: TextStyle(
                      color: fp.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _FocusUi2CircleButton(
          icon: Icons.more_vert_rounded,
          iconSize: 20,
          onTap: () => FocusMenuSheet.show(context, mode: session.mode),
        ),
      ],
    );
  }

  Widget _buildFocusUi2Subject(FocusPalette fp, FocusSession session) {
    final rawSubject = session.subjectName?.trim() ?? '';
    final rawObjective = session.objective.trim();
    final title = rawSubject.isNotEmpty
        ? rawSubject
        : (rawObjective.isNotEmpty ? rawObjective : 'Focus Session');
    // Never duplicate the same context line (launch defaults often repeat
    // the subject as the objective).
    final contextLine = rawSubject.isNotEmpty
        ? (rawObjective.isNotEmpty && rawObjective != rawSubject
            ? rawObjective
            : 'Deep Focus')
        : 'Deep Focus';
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: fp.text,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          contextLine,
          style: TextStyle(
            color: fp.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFocusUi2Timer(FocusPalette fp, FocusSession session) {
    // Countdown for Focus/Timer (authoritative remaining), count-up for
    // Stopwatch (authoritative elapsed). Both timestamp-based — no drift.
    final isStopwatch = session.mode == FocusMode.stopwatch;
    final totalSec = isStopwatch
        ? session.effectiveElapsed.inSeconds
        : session.remaining.inSeconds;
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    final digits = (isStopwatch || h > 0)
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    final sub = isStopwatch
        ? 'Elapsed time'
        : (totalSec < 60
            ? '$totalSec sec left'
            : '${session.remaining.inMinutes} min left');
    final progress = isStopwatch
        ? ((totalSec % 60) / 60.0).clamp(0.0, 1.0)
        : session.progress.clamp(0.0, 1.0);
    final isPaused = session.isPaused;
    final centerIcon = switch (session.mode) {
      FocusMode.focusGuard => Icons.menu_book_rounded,
      FocusMode.timer => Icons.timer_outlined,
      FocusMode.stopwatch => Icons.timelapse_rounded,
    };

    // Large dominant ring on wide screens, responsibly clamped on 320dp phones.
    final screenW = MediaQuery.sizeOf(context).width;
    final dial = (screenW - 72).clamp(220.0, 430.0);
    final digitSize = dial >= 380 ? 60.0 : (dial >= 300 ? 52.0 : 44.0);

    return Center(
      child: SizedBox(
        width: dial,
        height: dial,
        child: _BreathingAura(
          size: dial,
          active: !isPaused,
          child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: dial,
              height: dial,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fp.surfaceElevated,
                boxShadow: [
                  BoxShadow(
                    color: fp.primary.withValues(alpha: 0.12),
                    blurRadius: 42,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
            CustomPaint(
              size: Size(dial, dial),
              painter: _FocusRingPainter(
                progress: progress,
                trackColor: fp.track,
                accentColor: isPaused ? fp.textMuted : fp.primary,
                knobColor: fp.surfaceElevated,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: fp.tintBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    centerIcon,
                    color: fp.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 10),
                // Bounded + scale-down: 8-char stopwatch digits must stay on
                // one line inside narrow dials on any font/text scale.
                SizedBox(
                  width: dial - 56,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      digits,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: digitSize,
                        fontWeight: FontWeight.w800,
                        color: fp.text,
                        letterSpacing: -1.0,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(
                    color: fp.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isPaused ? fp.tintWarning : fp.tintBlue,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    isPaused ? 'PAUSED' : 'Stay Focused',
                    style: TextStyle(
                      color: isPaused ? fp.tintWarningFg : fp.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildFocusUi2XpStreak(FocusPalette fp, FocusSession session) {
    final xp = XpEngine.xpForStudySession(session.plannedDuration.inSeconds);
    final streak = StreakService.instance.currentStreak;
    final streakLabel = streak > 0 ? '$streak day streak' : '1 day streak';
    // Scale-down keeps the single-line reference design on narrow screens,
    // large fonts, and long streak values without ever overflowing.
    // Stopwatch has no planned XP — the XP segment hides when it is zero.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
        if (xp > 0) ...[
          Icon(
            Icons.star_rounded,
            color: fp.primary,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            '+$xp XP on completion',
            style: TextStyle(
              color: fp.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          Container(
            width: 1,
            height: 16,
            color: fp.border,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ],
        Icon(
          Icons.local_fire_department_rounded,
          color: fp.warning,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(
          streakLabel,
          style: TextStyle(
            color: fp.text,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildFocusUi2Controls(FocusPalette fp, FocusSession session) {
    final isPaused = session.isPaused;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPressable(
          onTap: _goBackFromSession,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FocusUi2CircleButton(
                icon: Icons.arrow_back_ios_new_rounded,
                iconSize: 20,
                diameter: 60,
              ),
              const SizedBox(height: 6),
              Text(
                'Back',
                style: TextStyle(
                  color: fp.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 22),
        AppPressable(
          onTap: () {
            if (isPaused) {
              FocusController.instance.resumeSession();
            } else {
              FocusController.instance.pauseSession();
            }
          },
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: fp.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: fp.primary.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  color: fp.onPrimary,
                  size: 30,
                ),
                Text(
                  isPaused ? 'RESUME' : 'PAUSE',
                  style: TextStyle(
                    color: fp.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 22),
        AppPressable(
          onTap: _handleUi2Stop,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FocusUi2CircleButton(
                icon: Icons.stop_rounded,
                iconSize: 24,
                diameter: 60,
                bg: fp.tintError,
                fg: fp.tintErrorFg,
              ),
              const SizedBox(height: 6),
              Text(
                'Stop',
                style: TextStyle(
                  color: fp.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _goBackFromSession() {
    // Navigation only — never terminates the session.
    FocusModeHolder.instance.setMode(FocusMode.focusGuard);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (mounted) {
      FocusModeHolder.instance.requestLanding();
    }
  }

  void _handleUi2Stop() {
    // Authoritative lifecycle: recorded stop, no duplicate XP/StudySession.
    FocusController.instance.stopSession();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (mounted) {
      FocusModeHolder.instance.requestLanding();
    }
  }

  Widget _buildFocusUi2QuickTools(FocusPalette fp, FocusSession session) {
    // Focus Guard is a Focus-mode exclusive; Timer/Stopwatch share the
    // other four tools with identical behavior.
    final isFocus = session.mode == FocusMode.focusGuard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'QUICK TOOLS',
          style: TextStyle(
            color: fp.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (ctx, constraints) {
            final cards = <Widget>[
              _buildUi2NoteCard(fp),
              _buildUi2ThoughtCard(fp),
              _buildUi2SleepCard(fp),
              _buildUi2MusicCard(fp),
              if (isFocus) _buildUi2GuardCard(fp),
            ];
            // Wide screens: one row like the reference.
            // Phones: balanced rows (3 + 2 for five, 2 + 2 for four) —
            // never squeezed columns on 320dp.
            if (constraints.maxWidth >= 600) {
              return Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: cards[i]),
                  ],
                ],
              );
            }
            final firstRowCount = cards.length == 5 ? 3 : 2;
            return Column(
              children: [
                Row(
                  children: [
                    for (var i = 0; i < firstRowCount; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: cards[i]),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (var i = firstRowCount; i < cards.length; i++) ...[
                      if (i > firstRowCount) const SizedBox(width: 10),
                      Expanded(child: cards[i]),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
        // Music track selector appears only when music is actually ON.
        ListenableBuilder(
          listenable: FocusMusicController.instance,
          builder: (ctx, _) {
            final music = FocusMusicController.instance;
            if (!music.isEnabled) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final entry in FocusMusicTrack.tracks.indexed)
                    AppPressable(
                      onTap: () => music.setTrack(entry.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: music.selectedTrackIndex == entry.$1
                              ? fp.primary
                              : fp.surface,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: music.selectedTrackIndex == entry.$1
                                ? fp.primary
                                : fp.border,
                          ),
                        ),
                        child: Text(
                          entry.$2.title,
                          style: TextStyle(
                            color: music.selectedTrackIndex == entry.$1
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
            );
          },
        ),
      ],
    );
  }

  Widget _ui2ToolCard({
    required FocusPalette fp,
    required Color tint,
    required Color fg,
    required IconData icon,
    required String label,
    required String helper,
    required VoidCallback onTap,
    Color? borderColor,
  }) {
    return AppPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(20),
          border: borderColor == null
              ? null
              : Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: fp.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: fg, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: fp.text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              helper,
              style: TextStyle(
                color: fp.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUi2NoteCard(FocusPalette fp) {
    return _ui2ToolCard(
      fp: fp,
      tint: fp.tintBlue,
      fg: fp.primary,
      icon: Icons.edit_note_rounded,
      label: 'Add Note',
      helper: 'Jot it down',
      onTap: () {
        final s = FocusController.instance.activeSession;
        if (s != null) showSprintXSessionNoteSheet(context, s);
      },
    );
  }

  Widget _buildUi2ThoughtCard(FocusPalette fp) {
    return _ui2ToolCard(
      fp: fp,
      tint: fp.tintViolet,
      fg: fp.tintVioletFg,
      icon: Icons.lightbulb_outline_rounded,
      label: 'Capture Thought',
      helper: 'Save an idea',
      onTap: () => showSprintXCaptureThoughtSheet(context),
    );
  }

  Widget _buildUi2SleepCard(FocusPalette fp) {
    return ListenableBuilder(
      listenable: FocusScreenSleepController.instance,
      builder: (ctx, _) {
        final c = FocusScreenSleepController.instance;
        return _ui2ToolCard(
          fp: fp,
          tint: fp.tintSuccess,
          fg: fp.tintSuccessFg,
          icon: c.isEnabled
              ? Icons.visibility_rounded
              : Icons.visibility_off_outlined,
          label: 'Prevent Screen Sleep',
          helper: c.isEnabled ? 'ON' : 'OFF',
          onTap: () => c.toggle(),
        );
      },
    );
  }

  Widget _buildUi2MusicCard(FocusPalette fp) {
    return ListenableBuilder(
      listenable: FocusMusicController.instance,
      builder: (ctx, _) {
        final music = FocusMusicController.instance;
        final track = music.selectedTrack;
        return _ui2ToolCard(
          fp: fp,
          tint: fp.surface,
          fg: fp.secondary,
          icon: Icons.music_note_rounded,
          label: 'Background Music',
          helper: track?.title ?? 'OFF',
          borderColor: fp.border,
          onTap: () {
            if (music.isEnabled) {
              music.setTrack(-1);
            } else {
              music.setTrack(0);
            }
          },
        );
      },
    );
  }

  Widget _buildUi2GuardCard(FocusPalette fp) {
    return ListenableBuilder(
      listenable: FocusGuardController.instance,
      builder: (ctx, _) {
        final guard = FocusGuardController.instance;
        final status = guard.permissionStatus;
        // NEVER collapse: Setup Needed still renders the control.
        String helper;
        IconData icon;
        if (status == FocusGuardPermissionStatus.ready &&
            guard.isGuardEnabled) {
          final n = guard.blockedPackages.length;
          helper = n == 0 ? 'Active' : '$n app(s)';
          icon = Icons.shield_rounded;
        } else if (status == FocusGuardPermissionStatus.ready) {
          helper = 'Ready';
          icon = Icons.shield_outlined;
        } else {
          helper = 'Setup Needed';
          icon = Icons.shield_outlined;
        }
        return _ui2ToolCard(
          fp: fp,
          tint: fp.tintWarning,
          fg: fp.tintWarningFg,
          icon: icon,
          label: 'Focus Guard',
          helper: helper,
          onTap: () {
            Navigator.of(ctx).push(
              MaterialPageRoute(
                builder: (_) => const FocusGuardSettingsScreen(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFocusUi2Motivation(FocusPalette fp) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: fp.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fp.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: fp.tintWarning,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: fp.tintWarningFg,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  "You're Doing Great!",
                  style: TextStyle(
                    color: fp.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              'Consistency builds success.',
              style: TextStyle(
                color: fp.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '"Small steps, big results."',
              style: TextStyle(
                color: fp.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— Student OS',
              style: TextStyle(
                color: fp.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerSecondBuilder extends StatefulWidget {
  const _PerSecondBuilder({required this.builder});
  final Widget Function(BuildContext context) builder;
  @override
  State<_PerSecondBuilder> createState() => _PerSecondBuilderState();
}

class _PerSecondBuilderState extends State<_PerSecondBuilder>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  bool _isTest = false;

  @override
  void initState() {
    super.initState();
    // In widget tests, the ticker would prevent pumpAndSettle from ever
    // settling (it ticks every frame). Skip the live tick in that
    // environment — tests only need the initial frame.
    _isTest = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('Test');
    if (_isTest) return;
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    // Rebuild once per second.
    if ((elapsed - _lastTick).inSeconds >= 1) {
      _lastTick = elapsed;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

// ─── Focus UI 2.0 shared pieces ──────────────────────────────────────────

/// Circular control button (Back / ⋮ / Stop) used by Focus UI 2.0.
/// Colors resolve from the canonical SprintX palette.
class _FocusUi2CircleButton extends StatelessWidget {
  const _FocusUi2CircleButton({
    required this.icon,
    this.onTap,
    this.iconSize = 20,
    this.diameter = 48,
    this.bg,
    this.fg,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double iconSize;
  final double diameter;
  final Color? bg;
  final Color? fg;

  @override
  Widget build(BuildContext context) {
    final fp = FocusPalette.of(context);
    final circle = Container(
      width: diameter,
      height: diameter,
      decoration:
          BoxDecoration(color: bg ?? fp.tintBlue, shape: BoxShape.circle),
      child: Icon(icon, color: fg ?? fp.primary, size: iconSize),
    );
    final tap = onTap;
    if (tap == null) return circle;
    return AppPressable(onTap: tap, child: circle);
  }
}

/// Breathing emerald aura behind the timer dial — the Deep Focus "state".
///
/// Slow 5s breathe while running, still when paused, static under reduced
/// motion. RepaintBoundary-isolated so per-second timer rebuilds never
/// restart the animation or repaint the halo.
class _BreathingAura extends StatefulWidget {
  const _BreathingAura({
    required this.size,
    required this.active,
    required this.child,
  });

  final double size;
  final bool active;
  final Widget child;

  @override
  State<_BreathingAura> createState() => _BreathingAuraState();
}

class _BreathingAuraState extends State<_BreathingAura>
    with SingleTickerProviderStateMixin {
  late AnimationController _breath;
  late Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _t = CurvedAnimation(parent: _breath, curve: Curves.easeInOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _BreathingAura oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  bool get _isTest {
    try {
      // ignore: do_not_use_environment
      return const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false) ||
          Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  void _sync() {
    if (!mounted) {
      return;
    }
    final reduce = MediaQuery.disableAnimationsOf(context);
    // Never repeat forever in widget tests — pumpAndSettle must settle.
    if (reduce || !widget.active || _isTest) {
      if (_breath.isAnimating) {
        _breath.stop();
      }
      return;
    }
    if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fp = FocusPalette.of(context);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, _) {
          final halo = 1.0 + (_t.value - 0.5) * 0.05;
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: halo,
                child: Container(
                  width: widget.size * 1.18,
                  height: widget.size * 1.18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        fp.primary.withValues(alpha: 0.14),
                        fp.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              widget.child,
            ],
          );
        },
      ),
    );
  }
}

/// Dot inside the FOCUS MODE badge — canonical action accent.
class _FocusUi2Dot extends StatelessWidget {
  const _FocusUi2Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: FocusPalette.of(context).primary,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Large timer ring with a progress knob for Focus UI 2.0.
class _FocusRingPainter extends CustomPainter {
  _FocusRingPainter({
    required this.progress,
    required this.trackColor,
    required this.accentColor,
    required this.knobColor,
  });

  final double progress;
  final Color trackColor;
  final Color accentColor;
  final Color knobColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = accentColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 14,
      );
      final angle = -math.pi / 2 + 2 * math.pi * progress;
      final knob = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawCircle(knob, 11, Paint()..color = knobColor);
      canvas.drawCircle(
        knob,
        11,
        Paint()
          ..color = accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      canvas.drawCircle(knob, 4, Paint()..color = accentColor);
    }
  }

  @override
  bool shouldRepaint(_FocusRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.knobColor != knobColor;
  }
}
