import 'package:flutter/material.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../academic_schedule_controller.dart';
import '../../models/schedule_models.dart';
import 'add_edit_event_sheet.dart';

/// Dialog surfacing schedule conflicts and offering 1-tap smart resolution.
class ScheduleConflictDialog extends StatefulWidget {
  const ScheduleConflictDialog({
    super.key,
    required this.conflict,
  });

  final ScheduleConflict conflict;

  @override
  State<ScheduleConflictDialog> createState() => _ScheduleConflictDialogState();
}

class _ScheduleConflictDialogState extends State<ScheduleConflictDialog> {
  bool _isResolving = false;

  Future<void> _autoReschedule() async {
    setState(() => _isResolving = true);
    final success = await AcademicScheduleController.instance
        .reschedulePlanningConflict(widget.conflict);

    if (mounted) {
      setState(() => _isResolving = false);
      Navigator.of(context).pop(success);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Planned study session rescheduled to next free slot.'
                : 'Could not find a free slot today to fit the full session.',
          ),
        ),
      );
    }
  }

  void _editEvent(BuildContext context) {
    Navigator.of(context).pop();
    if (widget.conflict.itemA.rawEvent != null) {
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddEditEventSheet(
          initialEvent: widget.conflict.itemA.rawEvent,
        ),
      );
    } else if (widget.conflict.itemB.rawEvent != null) {
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddEditEventSheet(
          initialEvent: widget.conflict.itemB.rawEvent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final conflict = widget.conflict;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Row(
        children: [
          Icon(conflict.severity.icon, color: conflict.severity.color, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              conflict.title,
              style: context.text.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              conflict.description,
              style: context.text.bodyMedium!.copyWith(
                color: palette.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Item A Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: conflict.itemA.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: conflict.itemA.color.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: conflict.itemA.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          conflict.itemA.statusLabel ?? 'ITEM',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          conflict.itemA.title,
                          style: context.text.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatTime(conflict.itemA.startAt)} – ${_formatTime(conflict.itemA.endAt)} (${conflict.itemA.durationMinutes}m)',
                    style: context.text.bodySmall!.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            Center(
              child: Icon(Icons.swap_vert_rounded,
                  size: 20, color: conflict.severity.color),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Item B Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: conflict.itemB.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: conflict.itemB.color.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: conflict.itemB.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          conflict.itemB.statusLabel ?? 'ITEM',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          conflict.itemB.title,
                          style: context.text.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatTime(conflict.itemB.startAt)} – ${_formatTime(conflict.itemB.endAt)} (${conflict.itemB.durationMinutes}m)',
                    style: context.text.bodySmall!.copyWith(
                      color: palette.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            if (conflict.canAutoReschedule)
              Text(
                'Student OS can automatically find the next available free window today and move the flexible study block.',
                style: context.text.bodySmall!.copyWith(
                  color: palette.onSurfaceMuted,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Keep Overlap'),
        ),
        if (conflict.itemA.rawEvent != null || conflict.itemB.rawEvent != null)
          TextButton(
            onPressed: () => _editEvent(context),
            child: const Text('Edit Event'),
          ),
        if (conflict.canAutoReschedule)
          FilledButton.icon(
            icon: _isResolving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_fix_high_rounded, size: 18),
            label: Text(_isResolving ? 'Moving...' : 'Reschedule Study'),
            onPressed: _isResolving ? null : _autoReschedule,
          ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
