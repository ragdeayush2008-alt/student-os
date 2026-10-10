import 'package:flutter/material.dart';

import '../../controller/focus_controller.dart';
import '../../data/models/focus_mission.dart';
import '../widgets/focus_palette.dart';
import '../widgets/sprintx_session_components.dart';
import 'timer_session_screen.dart' show AppBackFallback;

/// Dedicated premium Stopwatch experience (Phase 4 SprintX).
///
/// Elapsed-time identity: large count-up, violet progress accent, primary
/// Pause/Resume, Stop + Reset, and the four shared quick tools. No countdown
/// language, no "minutes left", no Focus Guard, no Focus XP/streak, no Focus
/// Analytics/History, no Focus messaging.
///
/// All state comes from the authoritative [FocusController]/[FocusSession]
/// timestamp lifecycle — no duplicate ticker engine, no drift.
class StopwatchSessionScreen extends StatefulWidget {
  const StopwatchSessionScreen({super.key});

  @override
  State<StopwatchSessionScreen> createState() => _StopwatchSessionScreenState();
}

class _StopwatchSessionScreenState extends State<StopwatchSessionScreen> {
  String? _lastSessionId;
  bool _lastIsPaused = false;
  FocusPhase? _lastPhase;

  @override
  void initState() {
    super.initState();
    FocusController.instance.addListener(_onFocusChanged);
    _syncSnapshot();
  }

  void _syncSnapshot() {
    final s = FocusController.instance.activeSession;
    _lastSessionId = s?.id;
    _lastIsPaused = s?.isPaused ?? false;
    _lastPhase = s?.phase;
  }

  void _onFocusChanged() {
    final s = FocusController.instance.activeSession;
    if (s?.id != _lastSessionId ||
        (s?.isPaused ?? false) != _lastIsPaused ||
        s?.phase != _lastPhase) {
      _syncSnapshot();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    FocusController.instance.removeListener(_onFocusChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fp = FocusPalette.of(context);
    final session = FocusController.instance.activeSession;

    if (session == null || session.mode != FocusMode.stopwatch) {
      return Scaffold(
        backgroundColor: fp.bgTop,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timelapse_rounded,
                  size: 48,
                  color: fp.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  'No active stopwatch',
                  style: TextStyle(
                    color: fp.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                AppBackFallback(onBack: () => sprintXGoBack(context)),
              ],
            ),
          ),
        ),
      );
    }

    final isPaused = session.isPaused;
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
                  SprintXTopBar(
                    session: session,
                    badgeTitle: 'STOPWATCH',
                    badgeBg: fp.tintViolet,
                    badgeFg: fp.tintVioletFg,
                  ),
                  const SizedBox(height: 18),
                  SprintXContextHeader(
                    session: session,
                    fallbackTitle: 'Stopwatch Session',
                  ),
                  const SizedBox(height: 22),
                  // Targeted rebuild: only the count-up repaints every second.
                  SprintXTicker(
                    builder: (_) => SprintXRing(
                      session: session,
                      countUp: true,
                      accent: fp.secondary,
                      badgeBg: fp.tintViolet,
                      icon: Icons.timelapse_rounded,
                    ),
                  ),
                  const SizedBox(height: 26),
                  SprintXPrimaryControl(isPaused: isPaused),
                  const SizedBox(height: 12),
                  const SprintXStopResetRow(),
                  const SizedBox(height: 30),
                  const SprintXQuickTools(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
