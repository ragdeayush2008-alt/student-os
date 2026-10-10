import 'package:flutter/material.dart';

import '../../controller/focus_controller.dart';
import '../../data/models/focus_mission.dart';
import '../widgets/focus_palette.dart';
import '../widgets/sprintx_session_components.dart';

/// Dedicated premium Timer experience (Phase 4 SprintX).
///
/// Countdown identity: large ring, remaining time, primary Pause/Resume,
/// Stop + Reset, and the four shared quick tools. No Focus Guard, no Focus
/// XP/streak, no Focus Analytics/History, no Focus messaging.
///
/// All state comes from the authoritative [FocusController]/[FocusSession]
/// timestamp lifecycle — no duplicate timer engine, no drift.
class TimerSessionScreen extends StatefulWidget {
  const TimerSessionScreen({super.key});

  @override
  State<TimerSessionScreen> createState() => _TimerSessionScreenState();
}

class _TimerSessionScreenState extends State<TimerSessionScreen> {
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

    if (session == null || session.mode != FocusMode.timer) {
      return Scaffold(
        backgroundColor: fp.bgTop,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 48,
                  color: fp.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  'No active timer',
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
                  SprintXTopBar(session: session, badgeTitle: 'TIMER'),
                  const SizedBox(height: 18),
                  SprintXContextHeader(
                    session: session,
                    fallbackTitle: 'Timer Session',
                  ),
                  const SizedBox(height: 22),
                  // Targeted rebuild: only the ring repaints every second.
                  SprintXTicker(
                    builder: (_) => SprintXRing(
                      session: session,
                      countUp: false,
                      icon: Icons.timer_outlined,
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

/// Small helper used by the empty states of the SprintX session screens.
class AppBackFallback extends StatelessWidget {
  const AppBackFallback({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final fp = FocusPalette.of(context);
    return GestureDetector(
      onTap: onBack,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: fp.primary,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'Back',
          style: TextStyle(
            color: fp.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
