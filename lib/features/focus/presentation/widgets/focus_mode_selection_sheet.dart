import 'package:flutter/material.dart';

import '../../../../app/app_router.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../widgets/focus_palette.dart';
import '../../controller/focus_controller.dart';
import '../../data/models/focus_mission.dart';

/// Maximum custom focus duration in minutes (6 hours — consistent with the
/// existing Focus design ceiling for single sessions).
const kMaxCustomFocusMinutes = 360;

class FocusModeSelectionSheet extends StatefulWidget {
  const FocusModeSelectionSheet({
    super.key,
    this.subjectId,
    this.subjectName,
    this.chapterId,
    this.topicId,
    this.topicName,
    this.taskId,
    this.taskTitle,
    this.examId,
    this.examTitle,
    this.planningBlockId,
    this.focusTitle,
    this.suggestedDuration = const Duration(minutes: 25),
    this.fixedDuration,
  });

  final String? subjectId;
  final String? subjectName;
  final String? chapterId;
  final String? topicId;
  final String? topicName;
  final String? taskId;
  final String? taskTitle;
  final String? examId;
  final String? examTitle;
  final String? planningBlockId;
  final String? focusTitle;
  final Duration suggestedDuration;

  /// When set (e.g. a PlanningBlock's assigned duration), the target-duration
  /// picker is hidden and Focus/Timer start with exactly this duration. The
  /// user is never asked to re-enter it. Stopwatch remains open-ended.
  final Duration? fixedDuration;

  static Future<void> show(
    BuildContext context, {
    String? subjectId,
    String? subjectName,
    String? chapterId,
    String? topicId,
    String? topicName,
    String? taskId,
    String? taskTitle,
    String? examId,
    String? examTitle,
    String? planningBlockId,
    String? focusTitle,
    Duration suggestedDuration = const Duration(minutes: 25),
    Duration? fixedDuration,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FocusModeSelectionSheet(
        subjectId: subjectId,
        subjectName: subjectName,
        chapterId: chapterId,
        topicId: topicId,
        topicName: topicName,
        taskId: taskId,
        taskTitle: taskTitle,
        examId: examId,
        examTitle: examTitle,
        planningBlockId: planningBlockId,
        focusTitle: focusTitle,
        suggestedDuration: suggestedDuration,
        fixedDuration: fixedDuration,
      ),
    );
  }

  @override
  State<FocusModeSelectionSheet> createState() =>
      _FocusModeSelectionSheetState();
}

class _FocusModeSelectionSheetState extends State<FocusModeSelectionSheet> {
  late int _selectedMinutes;
  final List<int> _presetMinutes = [15, 25, 35, 45, 60];

  @override
  void initState() {
    super.initState();
    final initialMins =
        widget.fixedDuration?.inMinutes ?? widget.suggestedDuration.inMinutes;
    _selectedMinutes = initialMins > 0 ? initialMins : 25;
  }

  String get _contextTitle {
    if (widget.focusTitle != null && widget.focusTitle!.isNotEmpty) {
      return widget.focusTitle!;
    }
    if (widget.taskTitle != null && widget.taskTitle!.isNotEmpty) {
      return widget.taskTitle!;
    }
    if (widget.topicName != null && widget.topicName!.isNotEmpty) {
      return widget.topicName!;
    }
    if (widget.examTitle != null && widget.examTitle!.isNotEmpty) {
      return widget.examTitle!;
    }
    if (widget.subjectName != null && widget.subjectName!.isNotEmpty) {
      return widget.subjectName!;
    }
    return 'Focus Session';
  }

  String? get _contextSubtitle {
    final parts = <String>[];
    if (widget.subjectName != null && widget.subjectName != _contextTitle) {
      parts.add(widget.subjectName!);
    }
    if (widget.topicName != null && widget.topicName != _contextTitle) {
      parts.add(widget.topicName!);
    }
    if (widget.examTitle != null && widget.examTitle != _contextTitle) {
      parts.add(widget.examTitle!);
    }
    return parts.isNotEmpty ? parts.join(' · ') : null;
  }

  @override
  Widget build(BuildContext context) {
    final fp = FocusPalette.of(context);
    final fc = FocusController.instance;

    return Container(
      decoration: BoxDecoration(
        color: fp.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: fp.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: fp.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.center_focus_strong_rounded,
                      color: fp.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _contextTitle,
                          style: TextStyle(
                            color: fp.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_contextSubtitle != null) ...[
                          SizedBox(height: 2),
                          Text(
                            _contextSubtitle!,
                            style: TextStyle(
                              color: fp.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (fc.hasActiveSession) ...[
                _buildActiveSessionWarning(context, fc.activeSession!),
                SizedBox(height: 16),
              ] else ...[
                Text(
                  'What do you want to do?',
                  style: TextStyle(
                    color: fp.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),

                _buildModeCard(context,
                  icon: Icons.local_fire_department_rounded,
                  title: 'Focus',
                  badge: widget.fixedDuration != null
                      ? '${widget.fixedDuration!.inMinutes} min scheduled'
                      : '${widget.suggestedDuration.inMinutes}m suggested',
                  subtitle: 'Deep study + distraction protection',
                  isHighlighted: true,
                  onTap: () => _startMode(FocusMode.focusGuard),
                ),
                const SizedBox(height: 8),

                _buildModeCard(context,
                  icon: Icons.timer_outlined,
                  title: 'Timer',
                  badge: widget.fixedDuration != null
                      ? '${widget.fixedDuration!.inMinutes} min'
                      : '$_selectedMinutes min',
                  subtitle: 'Study for a set duration',
                  isHighlighted: false,
                  onTap: () => _startMode(FocusMode.timer),
                ),
                const SizedBox(height: 8),

                _buildModeCard(context,
                  icon: Icons.all_inclusive_rounded,
                  title: 'Stopwatch',
                  badge: 'Open-ended',
                  subtitle: 'Track time without a limit',
                  isHighlighted: false,
                  onTap: () => _startMode(FocusMode.stopwatch),
                ),
                SizedBox(height: 20),

                if (widget.fixedDuration == null) ...[
                  Text(
                    'Target Duration',
                    style: TextStyle(
                      color: fp.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._presetMinutes.map((m) {
                      final isSelected = _selectedMinutes == m;
                      return AppPressable(
                        onTap: () => setState(() => _selectedMinutes = m),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? fp.primary
                                : fp.surfaceElevated,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: isSelected
                                  ? fp.primary
                                  : fp.border,
                            ),
                          ),
                          child: Text(
                            '$m min',
                            style: TextStyle(
                              color: isSelected
                                  ? fp.onPrimary
                                  : fp.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }),
                    AppPressable(
                      onTap: _pickCustomDuration,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: !_presetMinutes.contains(_selectedMinutes)
                              ? fp.primary
                              : fp.surfaceElevated,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: !_presetMinutes.contains(_selectedMinutes)
                                ? fp.primary
                                : fp.border,
                          ),
                        ),
                        child: Text(
                          !_presetMinutes.contains(_selectedMinutes)
                              ? '$_selectedMinutes min'
                              : 'Custom',
                          style: TextStyle(
                            color: !_presetMinutes.contains(_selectedMinutes)
                                ? fp.onPrimary
                                : fp.textSecondary,
                            fontWeight: !_presetMinutes.contains(_selectedMinutes)
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required bool isHighlighted,
    required VoidCallback onTap,
  }) {
    final fp = FocusPalette.of(context);
    return AppPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isHighlighted
              ? fp.primary.withValues(alpha: 0.08)
              : fp.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isHighlighted
                ? fp.primary.withValues(alpha: 0.4)
                : fp.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? fp.primary.withValues(alpha: 0.18)
                    : fp.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                icon,
                color: isHighlighted
                    ? fp.primary
                    : fp.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: fp.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? fp.primary.withValues(alpha: 0.15)
                              : fp.surface,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: isHighlighted
                                ? fp.primary
                                : fp.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: fp.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: fp.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSessionWarning(BuildContext context, FocusSession session) {
    final fp = FocusPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fp.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: fp.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle_filled_rounded,
                color: fp.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Focus is already active.',
                style: TextStyle(
                  color: fp.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            '${session.subjectName ?? session.objective} is running. Continue your current session rather than starting a new one.',
            style: TextStyle(
              color: fp.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          AppPressable(
            onTap: () {
              Navigator.of(context).pop();
              AppRouter.openActiveFocusSession(context);
            },
            child: Container(
              height: 42,
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
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Continue Focus',
                      style: TextStyle(
                        color: fp.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startMode(FocusMode mode) {
    final fc = FocusController.instance;
    if (fc.hasActiveSession) {
      Navigator.of(context).pop();
      AppRouter.openActiveFocusSession(context);
      return;
    }

    final duration =
        widget.fixedDuration ?? Duration(minutes: _selectedMinutes);
    final objective = _contextTitle;

    Navigator.of(context).pop();

    switch (mode) {
      case FocusMode.focusGuard:
        fc.startFocusGuard(
          duration: duration,
          subjectId: widget.subjectId,
          subjectName: widget.subjectName,
          taskId: widget.taskId,
          examId: widget.examId,
          topicId: widget.topicId,
          chapterId: widget.chapterId,
          planningBlockId: widget.planningBlockId,
          objective: objective,
        );
        break;
      case FocusMode.timer:
        fc.startTimer(
          duration: duration,
          subjectId: widget.subjectId,
          subjectName: widget.subjectName,
          taskId: widget.taskId,
          examId: widget.examId,
          topicId: widget.topicId,
          chapterId: widget.chapterId,
          planningBlockId: widget.planningBlockId,
          objective: objective,
        );
        break;
      case FocusMode.stopwatch:
        fc.startStopwatch(
          subjectId: widget.subjectId,
          subjectName: widget.subjectName,
          taskId: widget.taskId,
          examId: widget.examId,
          topicId: widget.topicId,
          chapterId: widget.chapterId,
          planningBlockId: widget.planningBlockId,
          objective: objective,
        );
        break;
    }

    AppRouter.openActiveFocusSession(context);
  }

  Future<void> _pickCustomDuration() async {
    final fp = FocusPalette.of(context);
    final controller = TextEditingController(text: '$_selectedMinutes');
    String? error;
    final minutes = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: fp.surface,
          title: Text(
            'Custom Duration',
            style: TextStyle(color: fp.text),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: TextStyle(color: fp.text),
                decoration: InputDecoration(
                  labelText: 'Duration in minutes',
                  labelStyle: TextStyle(color: fp.textSecondary),
                  suffixText: 'min',
                  suffixStyle: TextStyle(color: fp.textSecondary),
                  errorText: error,
                ),
                autofocus: true,
                onSubmitted: (_) => _submitCustom(
                  ctx,
                  controller,
                  (e) => setDialogState(() => error = e),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Between 1 and $kMaxCustomFocusMinutes minutes.',
                style: TextStyle(color: fp.textMuted, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _submitCustom(
                ctx,
                controller,
                (e) => setDialogState(() => error = e),
              ),
              child: const Text('Set'),
            ),
          ],
        ),
      ),
    );

    if (minutes != null && mounted) {
      setState(() => _selectedMinutes = minutes);
    }
  }

  /// Validates custom-duration input. Returns the minutes, or null after
  /// showing an explicit error (never silently ignores bad input).
  static int? _parseCustomMinutes(String raw) {
    final val = int.tryParse(raw.trim());
    if (val == null || val < 1 || val > kMaxCustomFocusMinutes) return null;
    return val;
  }

  void _submitCustom(
    BuildContext ctx,
    TextEditingController controller,
    ValueChanged<String?> setError,
  ) {
    final minutes =
        _parseCustomMinutes(controller.text);
    if (minutes == null) {
      setError(
        'Enter a whole number of minutes between 1 and $kMaxCustomFocusMinutes.',
      );
      return;
    }
    Navigator.pop(ctx, minutes);
  }
}
