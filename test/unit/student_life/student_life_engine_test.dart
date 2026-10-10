import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/data/models/academic_calendar_event.dart';
import 'package:student_os/features/planning/models/planning_block.dart';
import 'package:student_os/features/student_life/models/life_routine_item.dart';
import 'package:student_os/features/student_life/models/sleep_record.dart';
import 'package:student_os/features/student_life/models/student_life_preferences.dart';
import 'package:student_os/features/student_life/services/student_life_engine.dart';

void main() {
  final day = DateTime(2026, 9, 30);
  final now = DateTime(2026, 9, 30, 9);

  PlanningBlock block({
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    String? taskId = 'task_default',
  }) {
    return PlanningBlock(
      id: 'pb_$startHour$startMinute',
      userId: 'engine_user',
      taskId: taskId,
      startAt: DateTime(2026, 9, 30, startHour, startMinute),
      endAt: DateTime(2026, 9, 30, endHour, endMinute),
    );
  }

  group('StudentLifeEngine — daily plan derivation', () {
    test('A1. derives the sleep window from preferences', () {
      final plan = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(),
        blocks: const [],
        referenceTime: now,
      );

      expect(plan.sleepWindowStart, DateTime(2026, 9, 30, 23));
      expect(plan.sleepWindowEnd, DateTime(2026, 10, 1, 7));
      expect(plan.sleepWindowMinutes, 480);
      expect(plan.sleepDeficitMinutes, 0);
    });

    test('A2. is deterministic for identical inputs', () {
      final prefs = StudentLifePreferences(
        mealRemindersEnabled: true,
        exerciseEnabled: true,
      );
      final first = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: prefs,
        blocks: [block(startHour: 10, startMinute: 0, endHour: 11, endMinute: 0)],
        referenceTime: now,
      );
      final second = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: prefs,
        blocks: [block(startHour: 10, startMinute: 0, endHour: 11, endMinute: 0)],
        referenceTime: now,
      );

      expect(
        first.items.map((i) => '${i.id}@${i.startAt}').toList(),
        second.items.map((i) => '${i.id}@${i.startAt}').toList(),
      );
    });

    test('A3. always includes wake, wind-down and bedtime anchors', () {
      final plan = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(),
        blocks: const [],
        referenceTime: now,
      );

      final kinds = plan.items.map((i) => i.kind).toSet();
      expect(kinds, contains(LifeRoutineKind.wake));
      expect(kinds, contains(LifeRoutineKind.windDown));
      expect(kinds, contains(LifeRoutineKind.bedtime));
    });

    test('A4. study target is a goal derived from preferences only', () {
      final plan = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(dailyStudyTargetMinutes: 150),
        blocks: const [],
        referenceTime: now,
      );

      expect(plan.studyTargetMinutes, 150);
      expect(plan.scheduledStudyMinutes, 0);
    });

    test('A5. scheduled study minutes come from existing planning blocks', () {
      final plan = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(),
        blocks: [
          block(startHour: 10, startMinute: 0, endHour: 11, endMinute: 0),
          block(startHour: 14, startMinute: 0, endHour: 15, endMinute: 30),
        ],
        referenceTime: now,
      );

      expect(plan.scheduledStudyMinutes, 150);
      expect(plan.latestStudyEnd, DateTime(2026, 9, 30, 15, 30));
      expect(plan.studiesIntoSleep, isFalse);
    });
  });

  group('StudentLifeEngine — sleep protection', () {
    test('B1. flags study planned past wind-down', () {
      final plan = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(),
        blocks: [block(startHour: 22, startMinute: 30, endHour: 23, endMinute: 30)],
        referenceTime: now,
      );

      expect(
        plan.warnings,
        contains('Study is planned past your wind-down. Protect your sleep.'),
      );
      expect(plan.studiesIntoSleep, isTrue);
    });

    test('B2. warns when the sleep window is shorter than the target', () {
      final plan = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(targetSleepMinutes: 540),
        blocks: const [],
        referenceTime: now,
      );

      expect(plan.sleepDeficitMinutes, 60);
      expect(plan.warnings.first, contains('shorter than your 9h target'));
    });

    test('B3. never invents sleep when nothing is logged', () {
      final plan = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(),
        blocks: const [],
        referenceTime: now,
      );

      expect(plan.warnings.where((w) => w.contains('last night')), isEmpty);
    });

    test('B4. warns after a short night against the target', () {
      final plan = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(targetSleepMinutes: 480),
        sleepRecords: [
          SleepRecord(
            id: 's1',
            bedtime: DateTime(2026, 9, 29, 23, 30),
            wakeTime: DateTime(2026, 9, 30, 5, 30),
          ),
        ],
        blocks: const [],
        referenceTime: now,
      );

      expect(
        plan.warnings,
        contains(
          'You slept less than your target last night. Consider an earlier wind-down.',
        ),
      );
    });
  });

  group('StudentLifeEngine — routine items', () {
    test('C1. hydration OFF produces no hydration items', () {
      final plan = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(hydration: HydrationFrequency.off),
        blocks: const [],
        referenceTime: now,
      );

      expect(
        plan.items.where((i) => i.kind == LifeRoutineKind.hydration),
        isEmpty,
      );
    });

    test('C2. hydration NORMAL produces three anchors', () {
      final plan = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(
          hydration: HydrationFrequency.normal,
        ),
        blocks: const [],
        referenceTime: now,
      );

      expect(
        plan.items.where((i) => i.kind == LifeRoutineKind.hydration).length,
        3,
      );
    });

    test('C3. hydration FREQUENT adds more anchors than NORMAL', () {
      final normal = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(
          hydration: HydrationFrequency.normal,
        ),
        blocks: const [],
        referenceTime: now,
      );
      final frequent = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(
          hydration: HydrationFrequency.frequent,
        ),
        blocks: const [],
        referenceTime: now,
      );

      expect(
        frequent.items.where((i) => i.kind == LifeRoutineKind.hydration).length,
        greaterThan(
          normal.items.where((i) => i.kind == LifeRoutineKind.hydration).length,
        ),
      );
    });

    test('C4. meals appear only when meal reminders are enabled', () {
      final without = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(),
        blocks: const [],
        referenceTime: now,
      );
      final withMeals = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(mealRemindersEnabled: true),
        blocks: const [],
        referenceTime: now,
      );

      expect(without.items.where((i) => i.kind == LifeRoutineKind.meal), isEmpty);
      expect(
        withMeals.items.where((i) => i.kind == LifeRoutineKind.meal).length,
        3,
      );
    });

    test('C5. optional exercise inside the sleep window is dropped', () {
      final plan = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(
          exerciseEnabled: true,
          exerciseAtMinutes: 1400,
          exerciseMinutes: 60,
        ),
        blocks: const [],
        referenceTime: now,
      );

      expect(plan.items.where((i) => i.kind == LifeRoutineKind.exercise), isEmpty);
      expect(plan.reducedOptionalCount, 1);
      expect(
        plan.warnings,
        contains('Reduced 1 optional routine item to protect sleep.'),
      );
    });

    test('C6. optional exercise during the day is kept', () {
      final plan = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(
          exerciseEnabled: true,
          exerciseAtMinutes: 1080,
        ),
        blocks: const [],
        referenceTime: now,
      );

      expect(plan.items.where((i) => i.kind == LifeRoutineKind.exercise).length, 1);
      expect(plan.reducedOptionalCount, 0);
    });

    test('C7. break anchor appears only for a substantial study day', () {
      final light = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(),
        blocks: [block(startHour: 10, startMinute: 0, endHour: 10, endMinute: 45)],
        referenceTime: now,
      );
      final heavy = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(),
        blocks: [block(startHour: 10, startMinute: 0, endHour: 11, endMinute: 30)],
        referenceTime: now,
      );

      expect(light.items.where((i) => i.kind == LifeRoutineKind.rest), isEmpty);
      expect(heavy.items.where((i) => i.kind == LifeRoutineKind.rest).length, 1);
    });

    test('C8. nap is optional and absent unless enabled', () {
      final plan = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(napEnabled: true),
        blocks: const [],
        referenceTime: now,
      );
      final nap = plan.items.firstWhere((i) => i.kind == LifeRoutineKind.nap);

      expect(nap.isOptional, isTrue);
      expect(nap.durationMinutes, 25);
    });
  });

  group('StudentLifeEngine — sleep summary', () {
    SleepRecord night(DateTime bedtime, DateTime wake) => SleepRecord(
      id: bedtime.toIso8601String(),
      bedtime: bedtime,
      wakeTime: wake,
    );

    test('D1. empty input returns the empty summary', () {
      final summary = StudentLifeEngine.summarize(
        const [],
        referenceTime: now,
      );

      expect(summary.hasData, isFalse);
      expect(summary.lastNightLabel, 'No sleep logged');
    });

    test('D2. reports the most recent night', () {
      final summary = StudentLifeEngine.summarize(
        [
          night(DateTime(2026, 9, 20, 23), DateTime(2026, 9, 21, 7)),
          night(DateTime(2026, 9, 29, 23), DateTime(2026, 9, 30, 7, 30)),
        ],
        referenceTime: now,
      );

      expect(summary.lastNightMinutes, 510);
      expect(summary.lastNightLabel, '8h 30m');
    });

    test('D3. averages only nights inside the trailing window', () {
      final summary = StudentLifeEngine.summarize(
        [
          night(DateTime(2026, 1, 1, 23), DateTime(2026, 1, 2, 5)),
          night(DateTime(2026, 9, 28, 23), DateTime(2026, 9, 29, 7)),
          night(DateTime(2026, 9, 29, 23), DateTime(2026, 9, 30, 7)),
        ],
        referenceTime: now,
      );

      expect(summary.averageNightMinutes, 480);
      expect(summary.nightsLogged, 3);
    });

    test('D4. consistency counts nights near the target bedtime', () {
      final summary = StudentLifeEngine.summarize(
        [
          night(DateTime(2026, 9, 28, 23, 5), DateTime(2026, 9, 29, 7)),
          night(DateTime(2026, 9, 29, 20), DateTime(2026, 9, 30, 4)),
        ],
        referenceTime: now,
        targetBedtimeMinutes: 1380,
      );

      expect(summary.consistencyDays, 1);
    });

    test('D5. naps never count as night sleep', () {
      final summary = StudentLifeEngine.summarize(
        [
          SleepRecord(
            id: 'nap',
            bedtime: DateTime(2026, 9, 29, 14),
            wakeTime: DateTime(2026, 9, 29, 14, 25),
            type: SleepEntryType.nap,
          ),
        ],
        referenceTime: now,
      );

      expect(summary.hasData, isFalse);
    });
  });

  group('StudentLifeEngine — fixed commitments', () {
    AcademicCalendarEvent event({
      required String id,
      required int startHour,
      required int startMinute,
      required int endHour,
      required int endMinute,
      bool allDay = false,
    }) {
      return AcademicCalendarEvent(
        id: id,
        userId: 'engine_user',
        title: 'Lecture $id',
        startAt: DateTime(2026, 9, 30, startHour, startMinute),
        endAt: DateTime(2026, 9, 30, endHour, endMinute),
        allDay: allDay,
      );
    }

    test('J1. exposes the fixed commitments for the day', () {
      final plan = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(),
        blocks: const [],
        calendarEvents: [
          event(id: 'a', startHour: 10, startMinute: 0, endHour: 11, endMinute: 0),
          event(id: 'b', startHour: 14, startMinute: 0, endHour: 15, endMinute: 0),
        ],
        referenceTime: now,
      );

      expect(plan.fixedCommitmentCount, 2);
      expect(plan.fixedCommitmentTitles, ['Lecture a', 'Lecture b']);
    });

    test('J2. drops optional items that clash with a fixed commitment', () {
      final baseline = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(),
        blocks: const [],
        calendarEvents: const [],
        referenceTime: now,
      );
      final hydrationBefore = baseline.items
          .where((i) => i.kind == LifeRoutineKind.hydration)
          .length;

      final plan = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(),
        blocks: const [],
        calendarEvents: [
          event(id: 'clash', startHour: 8, startMinute: 30, endHour: 12, endMinute: 0),
        ],
        referenceTime: now,
      );

      final hydrationAfter = plan.items
          .where((i) => i.kind == LifeRoutineKind.hydration)
          .length;

      expect(hydrationBefore, greaterThan(0));
      expect(hydrationAfter, lessThan(hydrationBefore));
      expect(plan.reducedOptionalCount, greaterThan(0));
    });

    test('J3. moves an essential item to the next free slot', () {
      final prefs = StudentLifePreferences(mealRemindersEnabled: true);
      final plan = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: prefs,
        blocks: const [],
        calendarEvents: [
          event(id: 'lecture', startHour: 12, startMinute: 30, endHour: 13, endMinute: 30),
        ],
        referenceTime: now,
      );

      final lunch = plan.items.firstWhere((i) => i.title == 'Lunch');

      expect(lunch.startAt, DateTime(2026, 9, 30, 13, 30));
      expect(lunch.detail, contains('Moved'));
    });

    test('J4. drops an essential item with no room and warns', () {
      final prefs = StudentLifePreferences(mealRemindersEnabled: true);
      final plan = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: prefs,
        blocks: const [],
        calendarEvents: [
          event(
            id: 'long',
            startHour: 12,
            startMinute: 0,
            endHour: 23,
            endMinute: 0,
          ),
        ],
        referenceTime: now,
      );

      expect(plan.items.any((i) => i.title == 'Dinner'), isFalse);
      expect(plan.droppedEssentialCount, greaterThan(0));
      expect(
        plan.warnings.any((w) => w.contains('fixed commitments')),
        isTrue,
      );
    });

    test('J5. flags study blocks that clash without mutating them', () {
      final blocks = [
        block(startHour: 12, startMinute: 0, endHour: 13, endMinute: 0),
      ];
      final snapshot = blocks.first;

      final plan = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(),
        blocks: blocks,
        calendarEvents: [
          event(id: 'lecture', startHour: 12, startMinute: 0, endHour: 13, endMinute: 0),
        ],
        referenceTime: now,
      );

      expect(
        plan.warnings.any((w) => w.contains('with a fixed commitment')),
        isTrue,
      );
      expect(plan.scheduledStudyMinutes, 60);
      expect(blocks.first.startAt, snapshot.startAt);
      expect(blocks.first.endAt, snapshot.endAt);
    });

    test('J6. an all-day event keeps sleep and drops the rest', () {
      final plan = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(mealRemindersEnabled: true),
        blocks: const [],
        calendarEvents: [
          event(
            id: 'fest',
            startHour: 0,
            startMinute: 0,
            endHour: 23,
            endMinute: 59,
            allDay: true,
          ),
        ],
        referenceTime: now,
      );

      expect(plan.items.any((i) => i.kind == LifeRoutineKind.bedtime), isTrue);
      expect(plan.items.any((i) => i.kind == LifeRoutineKind.windDown), isTrue);
      expect(plan.items.any((i) => i.kind == LifeRoutineKind.wake), isFalse);
      expect(plan.droppedEssentialCount, greaterThan(0));
    });

    test('J7. a class in the morning leaves the evening routine intact', () {
      final plan = StudentLifeEngine.buildDailyPlan(
        day: day,
        preferences: const StudentLifePreferences(),
        blocks: const [],
        calendarEvents: [
          event(id: 'early', startHour: 8, startMinute: 0, endHour: 9, endMinute: 0),
        ],
        referenceTime: now,
      );

      final windDown = plan.items.firstWhere((i) => i.kind == LifeRoutineKind.windDown);
      final bedtime = plan.items.firstWhere((i) => i.kind == LifeRoutineKind.bedtime);

      expect(windDown.startAt, DateTime(2026, 9, 30, 22, 30));
      expect(bedtime.startAt, DateTime(2026, 9, 30, 23));
      expect(plan.droppedEssentialCount, 0);
    });
  });
}
