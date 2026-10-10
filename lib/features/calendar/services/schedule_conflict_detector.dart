import '../models/schedule_models.dart';

/// Detects overlaps and scheduling conflicts across academic commitments and planned blocks.
abstract final class ScheduleConflictDetector {
  /// Detects all schedule conflicts for the given [day].
  static List<ScheduleConflict> detectConflictsForDay(
    DateTime day, {
    required List<UnifiedScheduleItem> items,
  }) {
    final conflicts = <ScheduleConflict>[];
    if (items.length < 2) return conflicts;

    // Filter to items that have active time ranges (exclude all-day or task deadlines with no duration)
    final timedItems = items
        .where((it) =>
            !it.allDay &&
            it.type != UnifiedScheduleItemType.taskDeadline &&
            it.type != UnifiedScheduleItemType.freeSlot &&
            it.endAt.isAfter(it.startAt))
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    for (int i = 0; i < timedItems.length; i++) {
      final itemA = timedItems[i];
      final intervalA = TimeInterval(start: itemA.startAt, end: itemA.endAt);

      for (int j = i + 1; j < timedItems.length; j++) {
        final itemB = timedItems[j];

        // Since sorted by startAt, if itemB starts after itemA ends, no subsequent items can overlap itemA
        if (itemB.startAt.isAfter(itemA.endAt) ||
            itemB.startAt.isAtSameMomentAs(itemA.endAt)) {
          break;
        }

        final intervalB = TimeInterval(start: itemB.startAt, end: itemB.endAt);
        final overlap = intervalA.overlap(intervalB);

        if (overlap != null && overlap.durationMinutes > 0) {
          final conflict = _classifyConflict(itemA, itemB, overlap);
          conflicts.add(conflict);
        }
      }
    }

    return conflicts;
  }

  static ScheduleConflict _classifyConflict(
    UnifiedScheduleItem a,
    UnifiedScheduleItem b,
    TimeInterval overlap,
  ) {
    final isAFixed = a.isFixed;
    final isBFixed = b.isFixed;
    final id = 'conflict_${a.id}_${b.id}_${overlap.start.millisecondsSinceEpoch}';

    if (isAFixed && isBFixed) {
      return ScheduleConflict(
        id: id,
        severity: ConflictSeverity.conflict,
        title: 'Overlapping Commitments',
        description:
            '${a.title} overlaps with ${b.title} for ${overlap.durationMinutes} min.',
        itemA: a,
        itemB: b,
        overlapInterval: overlap,
        canAutoReschedule: false,
      );
    } else if (isAFixed && !isBFixed) {
      return ScheduleConflict(
        id: id,
        severity: ConflictSeverity.warning,
        title: 'Planned Study Overlaps Commitment',
        description:
            'Planned session "${b.title}" overlaps with ${a.title} (${overlap.durationMinutes} min).',
        itemA: a,
        itemB: b,
        overlapInterval: overlap,
        canAutoReschedule: true,
      );
    } else if (!isAFixed && isBFixed) {
      return ScheduleConflict(
        id: id,
        severity: ConflictSeverity.warning,
        title: 'Planned Study Overlaps Commitment',
        description:
            'Planned session "${a.title}" overlaps with ${b.title} (${overlap.durationMinutes} min).',
        itemA: a,
        itemB: b,
        overlapInterval: overlap,
        canAutoReschedule: true,
      );
    } else {
      return ScheduleConflict(
        id: id,
        severity: ConflictSeverity.warning,
        title: 'Overlapping Study Sessions',
        description:
            'Planned "${a.title}" overlaps with planned "${b.title}" (${overlap.durationMinutes} min).',
        itemA: a,
        itemB: b,
        overlapInterval: overlap,
        canAutoReschedule: true,
      );
    }
  }
}
