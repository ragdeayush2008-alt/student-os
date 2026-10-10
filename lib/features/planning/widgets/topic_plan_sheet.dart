import 'package:flutter/material.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../data/models/topic.dart';
import '../../subjects/subject_controller.dart';
import '../controllers/planning_block_controller.dart';
import '../services/planning_engine.dart';

/// §26 — STUDY → PLAN: turn a topic into a real [PlanningBlock].
///
/// Writes only through [PlanningBlockController.scheduleTopicBlock], which is
/// the same authoritative store PLAN renders. There is no separate "study
/// schedule" — so a topic planned here immediately appears in the PLAN tab,
/// Home, and Focus context.
class TopicPlanSheet extends StatefulWidget {
  const TopicPlanSheet({
    super.key,
    required this.topic,
    this.initialDay,
  });

  final Topic topic;
  final DateTime? initialDay;

  /// Returns the created block id, or null when the user cancelled.
  static Future<String?> show(
    BuildContext context, {
    required Topic topic,
    DateTime? initialDay,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TopicPlanSheet(topic: topic, initialDay: initialDay),
    );
  }

  @override
  State<TopicPlanSheet> createState() => _TopicPlanSheetState();
}

class _TopicPlanSheetState extends State<TopicPlanSheet> {
  static const List<int> _durations = [15, 30, 45, 60, 90];

  late int _minutes;
  late DateTime _day;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _minutes = widget.topic.estimatedMinutes > 0
        ? widget.topic.estimatedMinutes
        : 30;
    if (!_durations.contains(_minutes)) _minutes = 30;
    _day = widget.initialDay ?? DateTime.now();
    _advanceToFirstOpenDay();
  }

  /// Defaults to the first day that can actually hold the block.
  ///
  /// Late in the evening (or once the daily budget is spent) "today" has no
  /// free window, so opening the sheet on an unschedulable day would be a dead
  /// end. The user can still step back to any listed day.
  void _advanceToFirstOpenDay() {
    for (int i = 0; i < 7; i++) {
      final candidate = _day.add(Duration(days: i));
      final slot = PlanningEngine.findNextAvailableSlot(
        candidate,
        durationMinutes: _minutes,
      );
      if (slot != null) {
        _day = candidate;
        return;
      }
    }
  }

  DateTime? get _slot => PlanningEngine.findNextAvailableSlot(
        _day,
        durationMinutes: _minutes,
        availableMinutes: null,
      );

  Future<void> _save() async {
    final slot = _slot;
    if (slot == null) {
      setState(() => _error = 'No free slot on this day. Try another day.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final subjectId = widget.topic.subjectId.isEmpty
          ? null
          : widget.topic.subjectId;
      final block = await PlanningBlockController.instance.scheduleTopicBlock(
        widget.topic.id,
        slot,
        slot.add(Duration(minutes: _minutes)),
        subjectId: subjectId,
        chapterId: widget.topic.chapterId,
        customTitle: widget.topic.title,
      );
      if (!mounted) return;
      Navigator.of(context).pop(block.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not schedule this topic. Please try again.';
      });
    }
  }

  String _dayLabel(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 0) return '${months[d.month - 1]} ${d.day}';
    return 'In $diff days';
  }

  String _timeLabel(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final subjectName = SubjectController.instance
        .subjectById(widget.topic.subjectId)
        ?.displayName;
    final slot = _slot;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.screen,
        right: AppSpacing.screen,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: palette.onSurfaceMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Plan this topic',
            style: context.text.titleLarge!.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            [
              subjectName,
              widget.topic.title,
            ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
            style: context.text.bodySmall!.copyWith(
              color: palette.onSurfaceMuted,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Day ──
          Text(
            'WHEN',
            style: context.text.labelSmall!.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: palette.mutedGreen,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (int i = 0; i < 7; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _Choice(
                      label: _dayLabel(
                        DateTime.now().add(Duration(days: i)),
                      ),
                      selected: _day.day == DateTime.now().add(Duration(days: i)).day,
                      onTap: () => setState(() {
                        _day = DateTime.now().add(Duration(days: i));
                        _error = null;
                      }),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Duration ──
          Text(
            'HOW LONG',
            style: context.text.labelSmall!.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: palette.mutedGreen,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final d in _durations)
                _Choice(
                  label: '${d}m',
                  selected: _minutes == d,
                  onTap: () => setState(() {
                    _minutes = d;
                    _error = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Slot preview (real, computed by the planning engine) ──
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  slot == null
                      ? Icons.event_busy_rounded
                      : Icons.schedule_rounded,
                  size: 18,
                  color: slot == null ? palette.warning : palette.forest,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    slot == null
                        ? 'No free $_minutes min slot on ${_dayLabel(_day).toLowerCase()}'
                        : '$_dayLabel · ${_timeLabel(slot)} – '
                            '${_timeLabel(slot.add(Duration(minutes: _minutes)))}',
                    style: context.text.bodySmall!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: slot == null ? palette.warning : palette.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _error!,
              style: context.text.bodySmall!.copyWith(color: palette.error),
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    foregroundColor: palette.onSurfaceMuted,
                  ),
                  onPressed:
                      _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.onPrimary,
                    minimumSize: const Size(0, 44),
                  ),
                  icon: _saving
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: palette.onPrimary,
                          ),
                        )
                      : const Icon(Icons.event_available_rounded, size: 17),
                  label: Text(_saving ? 'Scheduling' : 'Add to plan'),
                  onPressed: _saving || slot == null ? null : _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);

    return AppPressable(
      onTap: onTap,
      semanticLabel: label,
      pressedScale: 0.97,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? palette.forest : palette.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          label,
          style: context.text.labelMedium!.copyWith(
            color: selected ? palette.naturalWhite : palette.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
