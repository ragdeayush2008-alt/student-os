import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/assistant/student_assistant_action.dart';
import 'package:student_os/core/assistant/student_assistant_engine.dart';
import 'package:student_os/core/assistant/student_assistant_intent.dart';
import 'package:student_os/core/assistant/student_assistant_parser.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/data/models/academic_calendar_event.dart';
import 'package:student_os/features/calendar/academic_schedule_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Student Assistant Schedule & Calendar Intent Tests', () {
    const parser = DeterministicStudentIntentParser();
    const engine = StudentAssistantEngine(parser: parser);
    final now = DateTime(2026, 9, 22, 10, 0); // Tuesday

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AuthIsolation.instance.setAuthenticatedUser('test_assistant_cal');
      AcademicScheduleController.instance.clearData();
      PlanningBlockController.instance.clearData();
    });

    tearDown(() {
      AcademicScheduleController.instance.clearData();
      AuthIsolation.instance.clearSession();
    });

    test('1. Parser accurately classifies schedule queries', () {
      expect(
        parser.parse("What do I have today?").intentType,
        AssistantIntentType.showScheduleToday,
      );
      expect(
        parser.parse("What's on my schedule?").intentType,
        AssistantIntentType.showScheduleToday,
      );
      expect(
        parser.parse("What do I have tomorrow?").intentType,
        AssistantIntentType.showScheduleTomorrow,
      );
      expect(
        parser.parse("Show my week").intentType,
        AssistantIntentType.showWeekSchedule,
      );
      expect(
        parser.parse("When is my next class?").intentType,
        AssistantIntentType.showNextClass,
      );
      expect(
        parser.parse("How much free time do I have today?").intentType,
        AssistantIntentType.checkFreeTime,
      );
      expect(
        parser.parse("What's conflicting today?").intentType,
        AssistantIntentType.showScheduleConflicts,
      );
      expect(
        parser.parse("What's my busiest day this week?").intentType,
        AssistantIntentType.showBusiestDay,
      );
    });

    test('2. "What do I have today?" returns clear state when no events exist', () {
      final res = engine.process("What do I have today?", referenceTime: now);

      expect(res.success, isTrue);
      expect(res.title, "Today's Schedule is Clear");
      expect(res.message, contains('no classes, exams, or study blocks'));
      expect(res.primaryAction?.type, AssistantActionType.openCalendar);
    });

    test('3. "What do I have today?" surfaces classes and free time when schedule exists', () async {
      await AcademicScheduleController.instance.createEvent(
        title: 'Accountancy Class',
        startAt: DateTime(2026, 9, 22, 11, 0),
        endAt: DateTime(2026, 9, 22, 12, 0),
      );

      final res = engine.process("What do I have today?", referenceTime: now);

      expect(res.success, isTrue);
      expect(res.title, "Today's Schedule");
      expect(res.message, contains('1 class'));
      expect(res.previewItems, isNotEmpty);
      expect(res.previewItems.first, contains('Accountancy Class'));
    });

    test('4. "When is my next class?" finds upcoming class and reports time & room', () async {
      await AcademicScheduleController.instance.createEvent(
        title: 'Physics Lecture',
        type: AcademicEventType.lecture,
        startAt: DateTime(2026, 9, 22, 14, 0),
        endAt: DateTime(2026, 9, 22, 15, 30),
        location: 'Hall 302',
      );

      final res = engine.process("When is my next class?", referenceTime: now);

      expect(res.success, isTrue);
      expect(res.title, 'Next Class: Physics Lecture');
      expect(res.message, contains('starts today at 14:00 in Hall 302'));
      expect(res.message, contains('90 min'));
      expect(res.primaryAction?.type, AssistantActionType.openCalendar);
    });

    test('5. "How much free time do I have today?" returns accurate remaining hours and windows', () async {
      await AcademicScheduleController.instance.createEvent(
        title: 'Class 1',
        startAt: DateTime(2026, 9, 22, 11, 0),
        endAt: DateTime(2026, 9, 22, 12, 0),
      );

      final res = engine.process("How much free time do I have today?", referenceTime: now);

      expect(res.success, isTrue);
      expect(res.title, 'Free Time Availability');
      expect(res.message, contains('free time remaining today'));
      expect(res.previewItems, isNotEmpty);
    });

    test('6. "What\'s conflicting today?" identifies overlaps and proposes resolution', () async {
      await AcademicScheduleController.instance.createEvent(
        title: 'Math Class',
        startAt: DateTime(2026, 9, 22, 14, 0),
        endAt: DateTime(2026, 9, 22, 15, 0),
      );

      await PlanningBlockController.instance.scheduleBlock(
        null,
        DateTime(2026, 9, 22, 14, 30),
        DateTime(2026, 9, 22, 15, 30),
        customTitle: 'Study Economics',
      );

      final res = engine.process("What's conflicting today?", referenceTime: now);

      expect(res.success, isTrue);
      expect(res.title, contains('Conflict'));
      expect(res.primaryAction?.type, AssistantActionType.resolveConflict);
      expect(res.primaryAction?.requiresConfirmation, isTrue);
    });

    test('7. "What\'s my busiest day this week?" identifies day with maximum commitments', () async {
      // Create 3 classes on Thursday (Sep 24)
      await AcademicScheduleController.instance.createEvent(
        title: 'Lecture 1',
        startAt: DateTime(2026, 9, 24, 9, 0),
        endAt: DateTime(2026, 9, 24, 11, 0),
      );
      await AcademicScheduleController.instance.createEvent(
        title: 'Lecture 2',
        startAt: DateTime(2026, 9, 24, 12, 0),
        endAt: DateTime(2026, 9, 24, 14, 0),
      );

      final res = engine.process("What's my busiest day this week?", referenceTime: now);

      expect(res.success, isTrue);
      expect(res.title, 'Busiest Day: Thursday');
      expect(res.message, contains('Thursday (24/9) is your busiest day'));
    });
  });
}
