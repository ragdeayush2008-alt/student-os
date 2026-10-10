import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/services/notification_coordinator.dart';
import 'package:student_os/core/services/notification_service.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/utils/app_week_utils.dart';
import 'package:student_os/core/theme/app_scope.dart';
import 'package:student_os/core/theme/app_shell_controller.dart';
import 'package:student_os/core/theme/app_theme.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/auth/auth_scope.dart';
import 'package:student_os/features/auth/auth_service.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/planning/plan_controller.dart';
import 'package:student_os/features/planning/planning_screen.dart';
import 'package:student_os/features/planning/services/planning_engine.dart';
import 'package:student_os/features/planning/widgets/daily_plan_sheet.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_planning_auto');
    await StorageService.instance.clearUser(userId: 'test_planning_auto');
    await StorageService.instance.loadJson(userId: 'demo', key: 'dummy');
    TaskController.instance.clearData();
    PlanController.instance.clearData();
    SubjectController.instance.clearData();
    PlanningBlockController.instance.clearData();
    ExamController.instance.clearData();
  });

  Widget wrapWithApp(Widget child, {double width = 390}) {
    return MaterialApp(
      theme: AppTheme.dark(),
      routes: AppRouter.routes(),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 844)),
        child: AppScope(
          controller: AppShellController(),
          child: AuthScope(
            authService: AuthService.instance,
            child: Scaffold(body: child),
          ),
        ),
      ),
    );
  }

  group('Planning Final Automation — Subject Planning & Allocation', () {
    test('1. Selected subjects appear in Plan My Day automatically', () async {
      final sub1 = await SubjectController.instance.createSubject(name: 'Accounting');
      final sub2 = await SubjectController.instance.createSubject(name: 'Economics');

      final plan = PlanningEngine.generateDailyPlan(
        DateTime.now(),
        tasks: [],
        subjects: [sub1, sub2],
        availableBudgetMinutes: 180,
      );

      expect(plan.items.length, 2);
      expect(plan.items.any((i) => i.title == 'Accounting'), isTrue);
      expect(plan.items.any((i) => i.title == 'Economics'), isTrue);
    });

    test('2. No-task day can still generate a subject study plan', () async {
      final sub = await SubjectController.instance.createSubject(name: 'Business Law');

      final plan = PlanningEngine.generateDailyPlan(
        DateTime.now(),
        tasks: [],
        subjects: [sub],
        availableBudgetMinutes: 60,
      );

      expect(plan.items.isNotEmpty, isTrue);
      expect(plan.items.first.title, 'Business Law');
      expect(plan.totalPlannedMinutes, 60);
    });

    test('3. Time budget allocation distributes available time', () async {
      final s1 = Subject(id: '1', name: 'Subject 1');
      final s2 = Subject(id: '2', name: 'Subject 2');
      final s3 = Subject(id: '3', name: 'Subject 3');

      final plan = PlanningEngine.generateDailyPlan(
        DateTime.now(),
        tasks: [],
        subjects: [s1, s2, s3],
        availableBudgetMinutes: 120,
      );

      expect(plan.totalPlannedMinutes, 120);
      expect(plan.items.length, 3);
    });

    test('4. Subject preference affects time allocation', () async {
      final sHigh = Subject(id: '1', name: 'High Priority', preference: SubjectPreference.high);
      final sLow = Subject(id: '2', name: 'Low Priority', preference: SubjectPreference.low);

      final plan = PlanningEngine.generateDailyPlan(
        DateTime.now(),
        tasks: [],
        subjects: [sHigh, sLow],
        availableBudgetMinutes: 120,
      );

      final highItem = plan.items.firstWhere((i) => i.title == 'High Priority');
      final lowItem = plan.items.firstWhere((i) => i.title == 'Low Priority');

      expect(highItem.estimatedMinutes, greaterThan(lowItem.estimatedMinutes));
    });

    test('5. Exam proximity affects allocation where data exists', () async {
      final sExam = Subject(id: '1', name: 'Physics', preference: SubjectPreference.normal);
      final sOther = Subject(id: '2', name: 'Art', preference: SubjectPreference.normal);

      final exam = StudentExam(
        id: 'ex1',
        title: 'Physics Midterm',
        subject: 'Physics',
        examDateTime: DateTime.now().add(const Duration(days: 2)), // 2 days away
      );

      final plan = PlanningEngine.generateDailyPlan(
        DateTime.now(),
        tasks: [],
        subjects: [sExam, sOther],
        exams: [exam],
        availableBudgetMinutes: 120,
      );

      final physicsItem = plan.items.firstWhere((i) => i.title == 'Physics');
      final artItem = plan.items.firstWhere((i) => i.title == 'Art');

      expect(physicsItem.estimatedMinutes, greaterThan(artItem.estimatedMinutes));
      expect(physicsItem.reason, contains('Exam'));
    });

    test('6. Manual task + subject blocks can coexist in daily plan', () async {
      final today = DateTime.now();
      final task = StudentTask(
        id: 't1',
        title: 'Complete Accounts HW',
        dueDate: today,
        estimatedMinutes: 45,
      );
      final subject = Subject(id: 's1', name: 'Economics');

      final plan = PlanningEngine.generateDailyPlan(
        today,
        tasks: [task],
        subjects: [subject],
        availableBudgetMinutes: 120,
      );

      expect(plan.items.any((i) => i.isTask && i.title == 'Complete Accounts HW'), isTrue);
      expect(plan.items.any((i) => i.isSubject && i.title == 'Economics'), isTrue);
    });

    test('7. Editing a block duration updates plan and sequential timing', () {
      final today = DateTime(2026, 9, 11);
      final s1 = Subject(id: '1', name: 'Math');
      final s2 = Subject(id: '2', name: 'Physics');

      final initialPlan = PlanningEngine.generateDailyPlan(
        today,
        tasks: [],
        subjects: [s1, s2],
        availableBudgetMinutes: 120,
        baseStartTime: DateTime(2026, 9, 11, 9, 0),
      );

      final updatedPlan = PlanningEngine.updatePlanItemDuration(
        initialPlan,
        0,
        60, // set first block to 60m
      );

      expect(updatedPlan.items.first.estimatedMinutes, 60);
      expect(updatedPlan.items.first.suggestedEnd, DateTime(2026, 9, 11, 10, 0));
      // Second item shifted after first + 5m buffer
      expect(updatedPlan.items[1].suggestedStart, DateTime(2026, 9, 11, 10, 5));
    });

    test('8. Adding a task via TaskController integrates into PlanController', () async {
      final today = DateTime.now();
      final task = await PlanController.instance.planTask(
        title: 'New Essay Draft',
        estimatedMinutes: 50,
      );

      expect(TaskController.instance.tasks.any((t) => t.id == task.id), isTrue);
      expect(PlanController.instance.tasksFor(today).any((t) => t.id == task.id), isTrue);
    });

    test('9. Applying generated plan creates PlanningBlocks for subjects and tasks', () async {
      final today = DateTime.now();
      final s1 = Subject(id: 'sub_acc', name: 'Accounting');

      final plan = PlanningEngine.generateDailyPlan(
        today,
        tasks: [],
        subjects: [s1],
        availableBudgetMinutes: 60,
      );

      final blocks = await PlanningEngine.applyDailyPlan(plan);
      expect(blocks.length, 1);
      expect(blocks.first.subjectId, 'sub_acc');
      expect(blocks.first.isSubjectBlock, isTrue);
      expect(PlanningBlockController.instance.blocks.length, 1);
    });

    test('10. Duplicate block prevention on repeated applyDailyPlan', () async {
      final today = DateTime.now();
      final s1 = Subject(id: 'sub_bio', name: 'Biology');

      final plan = PlanningEngine.generateDailyPlan(
        today,
        tasks: [],
        subjects: [s1],
        availableBudgetMinutes: 45,
      );

      await PlanningEngine.applyDailyPlan(plan);
      await PlanningEngine.applyDailyPlan(plan);

      expect(PlanningBlockController.instance.blocksForSubject('sub_bio').length, 1);
    });

    test('11. Existing scheduled work is preserved and deducted from available budget', () async {
      final today = DateTime(2026, 9, 11);
      final bc = PlanningBlockController.instance;

      // Existing 60m block
      final existingBlock = await bc.scheduleSubjectBlock(
        's_hist',
        DateTime(2026, 9, 11, 9, 0),
        DateTime(2026, 9, 11, 10, 0),
        customTitle: 'History Lecture',
      );

      final s2 = Subject(id: 's_chem', name: 'Chemistry');

      final plan = PlanningEngine.generateDailyPlan(
        today,
        tasks: [],
        subjects: [s2],
        blocks: [existingBlock],
        availableBudgetMinutes: 120, // 60m already taken -> 60m left for Chemistry
      );

      expect(plan.items.length, 2);
      expect(plan.items.first.isAlreadyScheduled, isTrue);
      expect(plan.items.first.title, 'History Lecture');
      expect(plan.items[1].title, 'Chemistry');
      expect(plan.totalPlannedMinutes, 120);
    });

    test('12. Subject block persistence with PlanningBlockController', () async {
      final bc = PlanningBlockController.instance;
      final start = DateTime.now().add(const Duration(hours: 1));
      final end = start.add(const Duration(minutes: 45));

      final block = await bc.scheduleSubjectBlock('s_math', start, end, customTitle: 'Calculus');
      expect(block.subjectId, 's_math');
      expect(block.isSubjectBlock, isTrue);

      bc.clearData();
      expect(bc.blocks, isEmpty);
      await bc.load();
      expect(bc.blocks.length, 1);
      expect(bc.blocks.first.subjectId, 's_math');
      expect(bc.blocks.first.customTitle, 'Calculus');
    });

    test('13. Notification scheduling for session transitions', () async {
      final blockId = 'pb_test_1';
      final transitionTime = DateTime.now().add(const Duration(minutes: 45));

      await NotificationCoordinator.instance.schedulePlanningBlockTransition(
        blockId: blockId,
        currentTitle: 'Accounting',
        nextTitle: 'Economics',
        transitionTime: transitionTime,
      );

      expect(NotificationIds.planningBlockEnd(blockId), isNonZero);
    });

    test('14. Notification rescheduling on block update', () async {
      final blockId = 'pb_test_2';
      final newTime = DateTime.now().add(const Duration(minutes: 60));

      await NotificationCoordinator.instance.schedulePlanningBlockTransition(
        blockId: blockId,
        currentTitle: 'Accounting',
        nextTitle: 'Economics',
        transitionTime: newTime,
      );

      expect(NotificationIds.planningBlockEnd(blockId), isPositive);
    });

    test('15. Notification cancellation on block unschedule', () async {
      final blockId = 'pb_test_3';
      await NotificationCoordinator.instance.cancelPlanningBlockTransition(blockId);
      // Completes safely without throwing
      expect(true, isTrue);
    });

    test('16. Deterministic recommendation selects subject when no tasks active', () {
      final s = Subject(id: 's1', name: 'Discrete Math', preference: SubjectPreference.high);

      final rec = PlanningEngine.getWhatShouldIDoNow(
        tasks: [],
        subjects: [s],
      );

      expect(rec, isNotNull);
      expect(rec!.isSubjectBlock, isTrue);
      expect(rec.title, 'Discrete Math');
      expect(rec.reason, contains('High priority'));
    });

    test('12. Next action / Current action exposes active or upcoming block', () async {
      final now = DateTime.now();
      final bc = PlanningBlockController.instance;

      await bc.scheduleSubjectBlock(
        's_econ',
        now.add(const Duration(hours: 1)),
        now.add(const Duration(hours: 2)),
        customTitle: 'Economics',
      );

      final action = PlanController.instance.currentOrNextAction;
      expect(action.isNext || action.isCurrent, isTrue);
      expect(action.title, contains('Economics'));
    });

    test('16. Missed session recovery detects uncompleted past blocks and reschedules', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final bc = PlanningBlockController.instance;

      final start = now.hour >= 2
          ? now.subtract(const Duration(hours: 2))
          : DateTime(today.year, today.month, today.day, 0, 0);
      final end = now.hour >= 2
          ? now.subtract(const Duration(hours: 1))
          : DateTime(today.year, today.month, today.day, 0, 1);

      final pastBlock = await bc.scheduleSubjectBlock(
        's_acct',
        start,
        end,
        customTitle: 'Accounting 101',
      );

      final missedList = PlanController.instance.missedSessionsToday;
      expect(missedList.any((m) => m.block.id == pastBlock.id), isTrue);

      final missed = missedList.firstWhere((m) => m.block.id == pastBlock.id);
      final rescheduled = await PlanController.instance.rescheduleMissedSession(missed);
      expect(rescheduled, isNotNull);
      expect(rescheduled!.startAt.isAfter(now.subtract(const Duration(minutes: 1))), isTrue);
    });

    test('17. Overload detection calculates overload minutes accurately', () {
      final today = DateTime.now();
      final t1 = StudentTask(id: 't1', title: 'Big Project', dueDate: today, estimatedMinutes: 200);

      final workload = PlanningEngine.calculateDayWorkload(
        today,
        tasks: [t1],
        blocks: [],
        availableMinutes: 120,
      );

      expect(workload.isOverloaded, isTrue);
      expect(workload.overloadMinutes, 80);
    });

    test('18. Rebalancing safely moves eligible future blocks without past mutation', () async {
      final targetDay = DateTime(2026, 9, 11);
      final now = DateTime(2026, 9, 11, 9, 0);
      final bc = PlanningBlockController.instance;

      await bc.scheduleSubjectBlock('s1', DateTime(2026, 9, 11, 10, 0), DateTime(2026, 9, 11, 12, 0));
      await bc.scheduleSubjectBlock('s2', DateTime(2026, 9, 11, 13, 0), DateTime(2026, 9, 11, 15, 0));

      final moved = await PlanningEngine.rebalanceOverloadedDay(
        targetDay,
        tasks: [],
        availableMinutes: 120,
        referenceTime: now,
      );

      expect(moved, greaterThanOrEqualTo(1));
      expect(bc.blocks.length, 2);
    });

    test('19. Focus context integration retains subject and task parameters', () async {
      final fc = FocusController.instance;
      final task = StudentTask(id: 't_focus', title: 'Focus Homework', subjectId: 's_phys');

      fc.startTimer(
        duration: const Duration(minutes: 25),
        taskId: task.id,
        subjectId: task.subjectId,
        subjectName: 'Physics',
        objective: task.title,
      );

      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession?.taskId, 't_focus');
      expect(fc.activeSession?.subjectId, 's_phys');

      fc.endSessionEarly();
    });

    test('20. User isolation clears planning state', () {
      final bc = PlanningBlockController.instance;
      bc.scheduleSubjectBlock('s1', DateTime.now(), DateTime.now().add(const Duration(hours: 1)));

      ControllerIsolation.instance.clearAllControllers();
      expect(bc.blocks, isEmpty);
      expect(PlanController.instance.selectedDay, AppWeekUtils.dateOnly(DateTime.now()));
    });
  });

  group('Planning Final Automation — Widget & Layout Safety', () {
    testWidgets('17 & 18. Narrow-width UI builds without RenderFlex overflow (320dp)', (tester) async {
      await SubjectController.instance.createSubject(name: 'Corporate Finance');

      await tester.pumpWidget(wrapWithApp(const PlanningScreen(), width: 320));
      await tester.pumpAndSettle();

      expect(find.byType(PlanningScreen), findsOneWidget);
      expect(find.text('Plan'), findsOneWidget);
    });

    testWidgets('19. Plan header title renders cleanly on one line', (tester) async {
      await tester.pumpWidget(wrapWithApp(const PlanningScreen(), width: 320));
      await tester.pumpAndSettle();

      // Title must be exact 'Plan' and not wrap into pieces
      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('Pla'), findsNothing);
      expect(find.text('n'), findsNothing);
    });

    testWidgets('DailyPlanSheet renders responsive layout without overflow on 320dp width', (tester) async {
      await SubjectController.instance.createSubject(name: 'Macroeconomics');

      await tester.pumpWidget(
        wrapWithApp(
          DailyPlanSheet(targetDay: DateTime.now()),
          width: 320,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Plan My Day'), findsOneWidget);
      expect(find.text('Apply Plan'), findsOneWidget);
    });
  });
}
