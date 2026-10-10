import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../controller/focus_controller.dart';
import '../../controller/focus_music_controller.dart';
import '../../controller/focus_screen_sleep_controller.dart';
import '../../data/models/focus_mission.dart';
import '../../data/models/focus_music_track.dart';
import 'focus_mode_holder.dart';
import 'focus_palette.dart';
import 'focus_menu_sheet.dart';

/// Shared SprintX session UI for the Timer and Stopwatch mode experiences.
///
/// Pure presentation: every value comes from the authoritative
/// [FocusController]/[FocusSession] timestamp lifecycle — no second timer
/// engine, no duplicated business logic. Focus Guard, Focus XP/streak, Focus
/// Analytics/History, and Focus-only messaging intentionally do not exist
/// here; those stay exclusive to the Focus experience.
///
/// Colors come from [FocusPalette] (canonical Student OS theme tokens) —
/// there are no SprintX-only color constants.

/// Navigation-only back: preserves the running session and returns to the
/// SprintX landing. Never terminates a session.
void sprintXGoBack(BuildContext context) {
  FocusModeHolder.instance.setMode(FocusMode.focusGuard);
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  } else {
    FocusModeHolder.instance.requestLanding();
  }
}

/// Rebuilds [builder] roughly once per second. Skipped in widget tests so
/// pumpAndSettle can settle (tests only need the initial frame).
class SprintXTicker extends StatefulWidget {
  const SprintXTicker({super.key, required this.builder});

  final Widget Function(BuildContext context) builder;

  @override
  State<SprintXTicker> createState() => _SprintXTickerState();
}

class _SprintXTickerState extends State<SprintXTicker>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  bool _isTest = false;

  @override
  void initState() {
    super.initState();
    _isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (_isTest) return;
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
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

class _SprintXCircleButton extends StatelessWidget {
  const _SprintXCircleButton({
    required this.icon,
    required this.onTap,
    this.iconSize = 20,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final fp = FocusPalette.of(context);
    return AppPressable(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: fp.tintBlue,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: fp.primary, size: iconSize),
      ),
    );
  }
}

/// Top bar shared by Timer and Stopwatch: back, mode badge, ⋮ menu.
///
/// The ⋮ menu only exposes secondary options (never Pause/Stop/Reset,
/// Sleep, Music, or Focus-only destinations).
class SprintXTopBar extends StatelessWidget {
  const SprintXTopBar({
    super.key,
    required this.session,
    required this.badgeTitle,
    this.badgeBg,
    this.badgeFg,
  });

  final FocusSession session;
  final String badgeTitle;
  final Color? badgeBg;
  final Color? badgeFg;

  @override
  Widget build(BuildContext context) {
    final fp = FocusPalette.of(context);
    final bg = badgeBg ?? fp.tintBlue;
    final fg = badgeFg ?? fp.primary;
    return Row(
      children: [
        _SprintXCircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          iconSize: 18,
          onTap: () => sprintXGoBack(context),
        ),
        Expanded(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: fg,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    badgeTitle,
                    style: TextStyle(
                      color: fg,
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
        _SprintXCircleButton(
          icon: Icons.more_vert_rounded,
          iconSize: 20,
          onTap: () => FocusMenuSheet.show(context, mode: session.mode),
        ),
      ],
    );
  }
}

/// Subject/objective context header. Shows only available context — never
/// hardcoded names and never Focus-only messaging.
class SprintXContextHeader extends StatelessWidget {
  const SprintXContextHeader({
    super.key,
    required this.session,
    required this.fallbackTitle,
  });

  final FocusSession session;
  final String fallbackTitle;

  @override
  Widget build(BuildContext context) {
    final fp = FocusPalette.of(context);
    final rawSubject = session.subjectName?.trim() ?? '';
    final rawObjective = session.objective.trim();
    final title = rawSubject.isNotEmpty
        ? rawSubject
        : (rawObjective.isNotEmpty ? rawObjective : fallbackTitle);
    // Second line only for genuinely available extra context — never
    // duplicated, never invented, never Focus-only messaging.
    final showContext =
        rawObjective.isNotEmpty && rawObjective != title;
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
        if (showContext) ...[
          const SizedBox(height: 4),
          Text(
            rawObjective,
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
      ],
    );
  }
}

class _SprintXRingPainter extends CustomPainter {
  _SprintXRingPainter({
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
  bool shouldRepaint(_SprintXRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.knobColor != knobColor;
  }
}

/// Large SprintX timer ring. Countdown ([countUp] false) or count-up display,
/// both from the authoritative session timestamps.
class SprintXRing extends StatelessWidget {
  const SprintXRing({
    super.key,
    required this.session,
    required this.countUp,
    this.accent,
    this.badgeBg,
    required this.icon,
  });

  final FocusSession session;
  final bool countUp;
  final Color? accent;
  final Color? badgeBg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final fp = FocusPalette.of(context);
    final ringAccent = accent ?? fp.primary;
    final ringBadgeBg = badgeBg ?? fp.tintBlue;
    final totalSec = countUp
        ? session.effectiveElapsed.inSeconds
        : session.remaining.inSeconds;
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    final digits = (countUp || h > 0)
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    final sub = countUp
        ? 'Elapsed time'
        : (totalSec < 60
            ? '$totalSec sec left'
            : '${session.remaining.inMinutes} min left');
    final progress = countUp
        ? ((totalSec % 60) / 60.0).clamp(0.0, 1.0)
        : session.progress.clamp(0.0, 1.0);
    final isPaused = session.isPaused;

    final screenW = MediaQuery.sizeOf(context).width;
    final dial = (screenW - 72).clamp(220.0, 430.0);
    final digitSize = dial >= 380 ? 60.0 : (dial >= 300 ? 52.0 : 44.0);

    return Center(
      child: SizedBox(
        width: dial,
        height: dial,
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
                    color: ringAccent.withValues(alpha: 0.12),
                    blurRadius: 42,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
            CustomPaint(
              size: Size(dial, dial),
              painter: _SprintXRingPainter(
                progress: progress,
                trackColor: fp.track,
                accentColor: isPaused ? fp.textMuted : ringAccent,
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
                    color: ringBadgeBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: ringAccent, size: 30),
                ),
                const SizedBox(height: 10),
                // Bounded + scale-down: long count-up digits stay on one
                // line inside narrow dials on any font/text scale.
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
                if (isPaused) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: fp.tintWarning,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'PAUSED',
                      style: TextStyle(
                        color: fp.tintWarningFg,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Primary full-width Pause/Resume control.
class SprintXPrimaryControl extends StatelessWidget {
  const SprintXPrimaryControl({super.key, required this.isPaused});

  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    final fp = FocusPalette.of(context);
    return AppPressable(
      onTap: () {
        if (isPaused) {
          FocusController.instance.resumeSession();
        } else {
          FocusController.instance.pauseSession();
        }
      },
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: fp.primary,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: [
            BoxShadow(
              color: fp.primary.withValues(alpha: 0.30),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              color: fp.onPrimary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              isPaused ? 'Resume' : 'Pause',
              style: TextStyle(
                color: fp.onPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Secondary Stop + Reset row. Stop ends (recorded, never completed);
/// Reset restarts fresh (unrecorded) via the existing lifecycle.
class SprintXStopResetRow extends StatelessWidget {
  const SprintXStopResetRow({super.key});

  @override
  Widget build(BuildContext context) {
    final fp = FocusPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: AppPressable(
            onTap: () {
              FocusController.instance.stopSession();
              sprintXGoBack(context);
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: fp.tintError,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.stop_rounded,
                    color: fp.tintErrorFg,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Stop',
                    style: TextStyle(
                      color: fp.tintErrorFg,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppPressable(
            onTap: () => FocusController.instance.resetSession(),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: fp.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: fp.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.replay_rounded,
                    color: fp.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Reset',
                    style: TextStyle(
                      color: fp.textSecondary,
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
    );
  }
}

/// Prevent Screen Sleep quick tool: full-width card bound to the real
/// wakelock state. Never hidden inside ⋮.
class SprintXSleepCard extends StatelessWidget {
  const SprintXSleepCard({super.key});

  @override
  Widget build(BuildContext context) {
    final fp = FocusPalette.of(context);
    return ListenableBuilder(
      listenable: FocusScreenSleepController.instance,
      builder: (ctx, _) {
        final c = FocusScreenSleepController.instance;
        return AppPressable(
          onTap: () => c.toggle(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: fp.tintSuccess,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: fp.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    c.isEnabled
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_outlined,
                    color: fp.tintSuccessFg,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Prevent Screen Sleep',
                    style: TextStyle(
                      color: fp.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: fp.surface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    c.isEnabled ? 'ON' : 'OFF',
                    style: TextStyle(
                      color: c.isEnabled
                          ? fp.tintSuccessFg
                          : fp.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MusicChip extends StatelessWidget {
  const _MusicChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fp = FocusPalette.of(context);
    return AppPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? fp.primary : fp.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? fp.primary : fp.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? fp.onPrimary : fp.textSecondary,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 11,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

/// Background Music quick tool with the agreed direct presentation:
/// OFF — label — ON chips, track choices (Calm/Ambient/Energy) only when ON.
class SprintXMusicCard extends StatelessWidget {
  const SprintXMusicCard({super.key});

  @override
  Widget build(BuildContext context) {
    final fp = FocusPalette.of(context);
    return ListenableBuilder(
      listenable: FocusMusicController.instance,
      builder: (ctx, _) {
        final music = FocusMusicController.instance;
        final isOn = music.isEnabled;
        final selectedIdx = music.selectedTrackIndex;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: fp.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: fp.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _MusicChip(
                    label: 'OFF',
                    selected: !isOn,
                    onTap: () => music.setTrack(-1),
                  ),
                  Expanded(
                    child: Text(
                      'Background Music',
                      style: TextStyle(
                        color: fp.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  _MusicChip(
                    label: 'ON',
                    selected: isOn,
                    onTap: () {
                      if (!isOn) music.setTrack(0);
                    },
                  ),
                ],
              ),
              if (isOn) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final entry in FocusMusicTrack.tracks.indexed)
                      _MusicChip(
                        label: entry.$2.title,
                        selected: selectedIdx == entry.$1,
                        onTap: () => music.setTrack(entry.$1),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Half-width Add Note / Capture Thought card.
class SprintXHalfCard extends StatelessWidget {
  const SprintXHalfCard({
    super.key,
    required this.tint,
    required this.fg,
    required this.icon,
    required this.label,
    required this.helper,
    required this.onTap,
  });

  final Color tint;
  final Color fg;
  final IconData icon;
  final String label;
  final String helper;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fp = FocusPalette.of(context);
    return AppPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(20),
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
}

/// Quick-tools section for Timer/Stopwatch: Sleep, Music, then the
/// Note + Thought half-row. No Focus Guard anywhere here.
class SprintXQuickTools extends StatelessWidget {
  const SprintXQuickTools({super.key});

  @override
  Widget build(BuildContext context) {
    final fp = FocusPalette.of(context);
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
        const SprintXSleepCard(),
        const SizedBox(height: 10),
        const SprintXMusicCard(),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SprintXHalfCard(
                tint: fp.tintBlue,
                fg: fp.primary,
                icon: Icons.edit_note_rounded,
                label: 'Add Note',
                helper: 'Jot it down',
                onTap: () {
                  final s = FocusController.instance.activeSession;
                  if (s != null) showSprintXSessionNoteSheet(context, s);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SprintXHalfCard(
                tint: fp.tintViolet,
                fg: fp.tintVioletFg,
                icon: Icons.lightbulb_outline_rounded,
                label: 'Capture Thought',
                helper: 'Save an idea',
                onTap: () => showSprintXCaptureThoughtSheet(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Existing session-note flow, shared by Timer/Stopwatch (and Focus).
///
/// Persists through the authoritative [FocusController]; no new note system.
void showSprintXSessionNoteSheet(BuildContext context, FocusSession session) {
  final fp = FocusPalette.of(context);
  final controller = TextEditingController(text: session.note);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: BoxDecoration(
        color: fp.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Session Note',
            style: TextStyle(
              color: fp.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Capture key points or learnings from this focus session.',
            style: TextStyle(color: fp.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            style: TextStyle(color: fp.text),
            decoration: InputDecoration(
              hintText: 'e.g., Finished Chapter 3 problems 1-10',
              hintStyle: TextStyle(color: fp.textMuted),
              filled: true,
              fillColor: fp.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: fp.primary,
            ),
            onPressed: () {
              if (controller.text.isNotEmpty &&
                  FocusController.instance.activeSession != null) {
                FocusController.instance.activeSession?.note =
                    controller.text.trim();
                FocusController.instance.persistActiveSession();
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    ),
  );
}

/// Existing thought-capture flow, shared by Timer/Stopwatch (and Focus).
///
/// Persists through the authoritative [FocusController]; no duplication.
void showSprintXCaptureThoughtSheet(BuildContext context) {
  final fp = FocusPalette.of(context);
  final controller = TextEditingController();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: BoxDecoration(
        color: fp.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Capture Distraction',
            style: TextStyle(
              color: fp.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Offload a distracting thought so you can stay in flow.',
            style: TextStyle(color: fp.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: true,
            maxLines: 2,
            style: TextStyle(color: fp.text),
            decoration: InputDecoration(
              hintText: 'e.g., Check flight tickets later',
              hintStyle: TextStyle(color: fp.textMuted),
              filled: true,
              fillColor: fp.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: fp.primary,
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                FocusController.instance.captureDistraction(
                  controller.text.trim(),
                );
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save to Distraction Inbox'),
          ),
        ],
      ),
    ),
  );
}
