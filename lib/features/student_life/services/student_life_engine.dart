import 'package:flutter/foundation.dart';

import '../../../core/time/app_clock.dart';
import '../../../core/utils/app_week_utils.dart';
import '../../../data/models/academic_calendar_event.dart';
import '../../../features/calendar/academic_schedule_controller.dart';
import '../../../features/planning/controllers/planning_block_controller.dart';
import '../../../features/planning/models/planning_block.dart';
import '../models/daily_life_plan.dart';
import '../models/life_routine_item.dart';
import '../models/sleep_record.dart';
import '../models/sleep_summary.dart';
import '../models/student_life_preferences.dart';

@immutable
class _Interval {
  final int start;
  final int end;
  const _Interval(this.start, this.end);
}

abstract final class StudentLifeEngine {
  static const int _wakeItemMinutes = 5;
  static const int _mealMinutes = 30;
  static const int _hydrationItemMinutes = 5;
  static const int _consistencyWindowMinutes = 45;
  static const int _reflowStepMinutes = 15;

  static DailyLifePlan buildDailyPlan({
    required DateTime day,
    required StudentLifePreferences preferences,
    List<SleepRecord> sleepRecords = const [],
    List<PlanningBlock>? blocks,
    List<AcademicCalendarEvent>? calendarEvents,
    DateTime? referenceTime,
  }) {
    final now = referenceTime ?? AppClock.current;
    final target = AppWeekUtils.dateOnly(day);
    final dayBlocks = (blocks ?? PlanningBlockController.instance.blocksForDay(target))
        .where((b) => b.endAt.isAfter(b.startAt))
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    final dayEvents = (calendarEvents ??
            AcademicScheduleController.instance.eventsForDay(target))
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final busy = _busyIntervals(dayEvents);

    final studyBlocks = dayBlocks
        .where((b) => b.isTaskBlock || b.isSubjectBlock || b.isTopicBlock)
        .toList();

    final scheduledStudyMinutes = studyBlocks.fold<int>(
      0,
      (sum, b) => sum + b.endAt.difference(b.startAt).inMinutes,
    );

    DateTime? latestStudyEnd;
    for (final b in studyBlocks) {
      if (latestStudyEnd == null || b.endAt.isAfter(latestStudyEnd)) {
        latestStudyEnd = b.endAt;
      }
    }

    final bedtime = _atMinutes(target, preferences.targetBedtimeMinutes);
    final wake = _wakeFor(target, preferences);
    final sleepWindowMinutes = wake.difference(bedtime).inMinutes;
    final windDownStart = bedtime.subtract(
      Duration(minutes: preferences.windDownMinutes),
    );

    final warnings = <String>[];
    var reducedOptional = 0;

    final items = <LifeRoutineItem>[];
    final dayKey = _dayKey(target);

    items.add(
      LifeRoutineItem(
        id: 'sl_${dayKey}_wake',
        kind: LifeRoutineKind.wake,
        title: 'Wake up',
        startAt: wake,
        endAt: wake.add(const Duration(minutes: _wakeItemMinutes)),
        detail: '${StudentLifePreferences.formatClock(preferences.targetWakeMinutes)} goal',
      ),
    );

    if (preferences.mealRemindersEnabled) {
      items.addAll([
        _mealItem(dayKey, 'breakfast', 'Breakfast', target,
            preferences.breakfastMinutes),
        _mealItem(dayKey, 'lunch', 'Lunch', target, preferences.lunchMinutes),
        _mealItem(dayKey, 'dinner', 'Dinner', target, preferences.dinnerMinutes),
      ]);
    }

    if (preferences.exerciseEnabled && preferences.exerciseMinutes > 0) {
      final exerciseStart = _atMinutes(target, preferences.exerciseAtMinutes);
      items.add(
        LifeRoutineItem(
          id: 'sl_${dayKey}_exercise',
          kind: LifeRoutineKind.exercise,
          title: 'Exercise',
          startAt: exerciseStart,
          endAt: exerciseStart.add(
            Duration(minutes: preferences.exerciseMinutes),
          ),
          detail: '${preferences.exerciseMinutes}m',
          isOptional: true,
        ),
      );
    }

    items.addAll(_hydrationItems(preferences, target, wake, windDownStart));

    if (preferences.napEnabled && preferences.napDurationMinutes > 0) {
      final napStart = _atMinutes(target, 14 * 60);
      items.add(
        LifeRoutineItem(
          id: 'sl_${dayKey}_nap',
          kind: LifeRoutineKind.nap,
          title: 'Optional nap',
          startAt: napStart,
          endAt: napStart.add(Duration(minutes: preferences.napDurationMinutes)),
          detail: '${preferences.napDurationMinutes}m',
          isOptional: true,
        ),
      );
    }

    if (preferences.breakRemindersEnabled && scheduledStudyMinutes >= 90) {
      final first = studyBlocks.first.startAt;
      final last = studyBlocks.last.endAt;
      final mid = first.add(Duration(minutes: last.difference(first).inMinutes ~/ 2));
      items.add(
        LifeRoutineItem(
          id: 'sl_${dayKey}_break',
          kind: LifeRoutineKind.rest,
          title: 'Take a break',
          startAt: mid,
          endAt: mid.add(const Duration(minutes: 15)),
          detail: 'Step away for a few minutes',
          isOptional: true,
        ),
      );
    }

    final sleepWindow = _Interval(
      _minutesOfDay(bedtime),
      _minutesOfDay(bedtime) + (sleepWindowMinutes > 0 ? sleepWindowMinutes : 0),
    );
    final windDownWindow = _Interval(
      _minutesOfDay(windDownStart),
      _minutesOfDay(bedtime),
    );

    final kept = <LifeRoutineItem>[];
    var droppedEssential = 0;
    for (final item in items) {
      final isOptional = item.isOptional;
      final itemInterval = _intervalForItem(item);
      final overlapsSleep = _overlaps(itemInterval, sleepWindow);
      final overlapsWindDown = _overlaps(itemInterval, windDownWindow);

      final conflict = _firstConflict(busy, itemInterval);
      if (conflict != null) {
        if (isOptional) {
          reducedOptional++;
          continue;
        }
        final reflowed = _reflow(
          item,
          day: target,
          from: conflict,
          busy: busy,
          notBefore: wake,
          notAfter: windDownStart,
        );
        if (reflowed == null) {
          droppedEssential++;
          continue;
        }
        kept.add(reflowed);
        continue;
      }

      if (isOptional && (overlapsSleep || overlapsWindDown)) {
        reducedOptional++;
        continue;
      }
      kept.add(item);
    }

    final windDown = LifeRoutineItem(
      id: 'sl_${dayKey}_winddown',
      kind: LifeRoutineKind.windDown,
      title: 'Wind down',
      startAt: windDownStart,
      endAt: bedtime,
      detail: '${preferences.windDownMinutes}m before bed',
    );

    final bedtimeItem = LifeRoutineItem(
      id: 'sl_${dayKey}_bedtime',
      kind: LifeRoutineKind.bedtime,
      title: 'Bedtime',
      startAt: bedtime,
      endAt: bedtime.add(const Duration(minutes: 5)),
      detail: StudentLifePreferences.formatClock(preferences.targetBedtimeMinutes),
    );

    kept.addAll([windDown, bedtimeItem]);

    final studyTargetItem = LifeRoutineItem(
      id: 'sl_${dayKey}_studytarget',
      kind: LifeRoutineKind.studyTarget,
      title: 'Study target',
      startAt: target,
      endAt: target,
      detail: '${preferences.dailyStudyTargetMinutes}m goal',
    );
    kept.add(studyTargetItem);

    if (sleepWindowMinutes < preferences.targetSleepMinutes) {
      warnings.add(
        'Your sleep window is shorter than your ${preferences.targetSleepMinutes ~/ 60}h target.',
      );
    }

    if (latestStudyEnd != null && latestStudyEnd.isAfter(windDownStart)) {
      warnings.add('Study is planned past your wind-down. Protect your sleep.');
    }

    if (reducedOptional > 0) {
      warnings.add(
        'Reduced $reducedOptional optional routine item${reducedOptional == 1 ? '' : 's'} to protect sleep.',
      );
    }

    if (dayEvents.isNotEmpty) {
      final colliding = studyBlocks.where((b) {
        final interval = _Interval(
          _minutesOfDay(b.startAt),
          _minutesOfDay(b.endAt) +
              (b.endAt.hour * 60 + b.endAt.minute <= _minutesOfDay(b.startAt)
                  ? 1440
                  : 0),
        );
        return _firstConflict(busy, interval) != null;
      }).length;
      if (colliding > 0) {
        warnings.add(
          '$colliding study block${colliding == 1 ? '' : 's'} conflict${colliding == 1 ? 's' : ''} with a fixed commitment. Reschedule in Planning.',
        );
      }
    }

    if (droppedEssential > 0) {
      warnings.add(
        'Skipped $droppedEssential routine item${droppedEssential == 1 ? '' : 's'} to protect your fixed commitments.',
      );
    }

    final summary = summarize(
      sleepRecords,
      referenceTime: now,
      targetBedtimeMinutes: preferences.targetBedtimeMinutes,
    );
    final lastNight = summary.lastNightMinutes;
    if (lastNight != null && lastNight < preferences.targetSleepMinutes - 60) {
      warnings.add(
        'You slept less than your target last night. Consider an earlier wind-down.',
      );
    }

    kept.sort((a, b) {
      if (a.kind == LifeRoutineKind.studyTarget) return 1;
      if (b.kind == LifeRoutineKind.studyTarget) return -1;
      return a.startAt.compareTo(b.startAt);
    });

    return DailyLifePlan(
      day: target,
      sleepWindowStart: bedtime,
      sleepWindowEnd: wake,
      targetSleepMinutes: preferences.targetSleepMinutes,
      items: kept,
      studyTargetMinutes: preferences.dailyStudyTargetMinutes,
      scheduledStudyMinutes: scheduledStudyMinutes,
      generatedAt: now,
      latestStudyEnd: latestStudyEnd,
      warnings: warnings,
      reducedOptionalCount: reducedOptional,
      fixedCommitmentCount: dayEvents.length,
      fixedCommitmentTitles:
          dayEvents.take(3).map((e) => e.title).toList(growable: false),
      droppedEssentialCount: droppedEssential,
    );
  }

  static SleepSummary summarize(
    List<SleepRecord> records, {
    DateTime? referenceTime,
    int targetBedtimeMinutes = 1380,
  }) {
    final now = referenceTime ?? AppClock.current;
    final nights = records.where((r) => r.isNightSleep).toList()
      ..sort((a, b) => b.bedtime.compareTo(a.bedtime));
    if (nights.isEmpty) return SleepSummary.empty;

    final last = nights.first;
    final windowStart = now.subtract(const Duration(days: 7));
    final recent = nights
        .where((r) => r.bedtime.isAfter(windowStart))
        .toList();
    final pool = recent.isEmpty ? nights.take(7).toList() : recent;

    final total = pool.fold<int>(0, (sum, r) => sum + r.durationMinutes);
    final average = pool.isEmpty ? null : (total / pool.length).round();

    var consistency = 0;
    for (final r in pool) {
      final diff = _circularMinuteDiff(
        _minutesOfDay(r.bedtime),
        targetBedtimeMinutes,
      );
      if (diff <= _consistencyWindowMinutes) consistency++;
    }

    return SleepSummary(
      hasData: true,
      lastNightMinutes: last.durationMinutes,
      lastNightBedtime: last.bedtime,
      lastNightWake: last.wakeTime,
      averageNightMinutes: average,
      nightsLogged: nights.length,
      consistencyDays: consistency,
    );
  }

  static LifeRoutineItem _mealItem(
    String dayKey,
    String slot,
    String title,
    DateTime day,
    int minutesOfDay,
  ) {
    final start = _atMinutes(day, minutesOfDay);
    return LifeRoutineItem(
      id: 'sl_${dayKey}_$slot',
      kind: LifeRoutineKind.meal,
      title: title,
      startAt: start,
      endAt: start.add(const Duration(minutes: _mealMinutes)),
    );
  }

  static List<LifeRoutineItem> _hydrationItems(
    StudentLifePreferences preferences,
    DateTime day,
    DateTime wake,
    DateTime windDownStart,
  ) {
    if (preferences.hydration == HydrationFrequency.off) return const [];
    final dayKey = _dayKey(day);
    final anchors = <int>[];
    if (preferences.hydration == HydrationFrequency.normal) {
      anchors.addAll([
        _minutesOfDay(wake) + 90,
        _minutesOfDay(wake) + 300,
        _minutesOfDay(wake) + 540,
      ]);
    } else {
      var m = _minutesOfDay(wake) + 60;
      final limit = _minutesOfDay(windDownStart) - 60;
      var count = 0;
      while (m <= limit && count < 6) {
        anchors.add(m);
        m += 120;
        count++;
      }
    }
    final result = <LifeRoutineItem>[];
    for (var i = 0; i < anchors.length; i++) {
      final start = _atMinutes(day, anchors[i]);
      result.add(
        LifeRoutineItem(
          id: 'sl_${dayKey}_hydration_$i',
          kind: LifeRoutineKind.hydration,
          title: 'Hydration',
          startAt: start,
          endAt: start.add(const Duration(minutes: _hydrationItemMinutes)),
          detail: 'Water break',
          isOptional: true,
        ),
      );
    }
    return result;
  }

  static _Interval _intervalForItem(LifeRoutineItem item) => _Interval(
        _minutesOfDay(item.startAt),
        _minutesOfDay(item.startAt) + (item.durationMinutes > 0 ? item.durationMinutes : 1),
      );

  static List<_Interval> _busyIntervals(List<AcademicCalendarEvent> events) {
    final result = <_Interval>[];
    for (final event in events) {
      if (event.allDay) {
        result.add(const _Interval(0, 1440));
        continue;
      }
      final start = _minutesOfDay(event.startAt);
      var end = _minutesOfDay(event.endAt);
      if (end <= start) end += 1440;
      result.add(_Interval(start, end > 1440 ? 1440 : end));
    }
    return result;
  }

  static _Interval? _firstConflict(List<_Interval> busy, _Interval item) {
    for (final slot in busy) {
      if (_overlaps(item, slot)) return slot;
    }
    return null;
  }

  static LifeRoutineItem? _reflow(
    LifeRoutineItem item, {
    required DateTime day,
    required _Interval from,
    required List<_Interval> busy,
    required DateTime notBefore,
    required DateTime notAfter,
  }) {
    final duration = item.durationMinutes > 0 ? item.durationMinutes : 1;
    final earliest = _minutesOfDay(notBefore);
    final latest = _minutesOfDay(notAfter);
    var candidate = from.end < earliest ? earliest : from.end;
    candidate = _roundUp(candidate);

    while (candidate + duration <= latest) {
      final interval = _Interval(candidate, candidate + duration);
      if (_firstConflict(busy, interval) == null) {
        final start = _atMinutes(day, candidate);
        return item.copyWith(
          startAt: start,
          endAt: start.add(Duration(minutes: duration)),
          detail: item.detail == null
              ? 'Moved for a fixed commitment'
              : '${item.detail} · moved',
        );
      }
      candidate += _reflowStepMinutes;
    }
    return null;
  }

  static int _roundUp(int minutes) {
    final remainder = minutes % _reflowStepMinutes;
    return remainder == 0 ? minutes : minutes + (_reflowStepMinutes - remainder);
  }


  static bool _overlaps(_Interval a, _Interval b) =>
      a.start < b.end && b.start < a.end;

  static DateTime _atMinutes(DateTime day, int minutes) {
    final normalised = ((minutes % 1440) + 1440) % 1440;
    return DateTime(
      day.year,
      day.month,
      day.day,
      normalised ~/ 60,
      normalised % 60,
    );
  }

  static DateTime _wakeFor(DateTime day, StudentLifePreferences prefs) {
    final wake = _atMinutes(day, prefs.targetWakeMinutes);
    if (wake.isAfter(_atMinutes(day, prefs.targetBedtimeMinutes))) {
      return wake;
    }
    return wake.add(const Duration(days: 1));
  }

  static int _minutesOfDay(DateTime t) => t.hour * 60 + t.minute;

  static int _circularMinuteDiff(int a, int b) {
    final diff = (a - b).abs() % 1440;
    return diff > 720 ? 1440 - diff : diff;
  }

  static String _dayKey(DateTime day) =>
      '${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}';
}
