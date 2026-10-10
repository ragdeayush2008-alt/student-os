import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/app/app_router.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/intelligence/academic_intelligence_controller.dart';
import 'package:student_os/core/intelligence/autopilot_engine.dart';
import 'package:student_os/core/intelligence/student_os_intelligence_engine.dart';
import 'package:student_os/core/navigation/universal_action_executor.dart';
import 'package:student_os/core/services/course_catalog_service.dart';
import 'package:student_os/core/services/storage_service.dart';
import 'package:student_os/core/services/student_service.dart';
import 'package:student_os/data/models/catalog/course_category.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/planning/services/planning_engine.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Autopilot 2.0 Day Orchestration Integration Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      AuthIsolation.instance.setAuthenticatedUser('test_autopilot_user');
      // Storage hygiene: the shared-prefs instance is cached per isolate, so
      // clear this user's namespace every run for deterministic loads.
      await StorageService.instance.clearUser(userId: 'test_autopilot_user');
      CourseCatalogService.instance.ensureInitialized();
      CourseCatalogService.instance.loadDefaults();
      ControllerIsolation.instance.clearAllControllers();
      await TaskController.instance.load();
      await PlanningBlockController.instance.load();
      await SubjectController.instance.load();
      await ExamController.instance.load();
      await StudyController.instance.load();
      await FocusController.instance.load();
      await StudentService.instance.load();
    });

    tearDown(() {
      if (FocusController.instance.hasActiveSession) {
        FocusController.instance.cancelSession();
      }
      ControllerIsolation.instance.clearAllControllers();
      AuthIsolation.instance.clearSession();
    });

    testWidgets('FLOW 1: Subject -> Exam -> Task -> Plan -> Start My Day -> Focus -> Next Block', (tester) async {
      // Deterministic anchor: tomorrow, referenced explicitly, so this flow
      // is independent of wall-clock run time (including near midnight).
      final now = DateTime.now();
      final tomorrow =
          DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      final ref = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);

      // 1. Create subject, exam, task
      final sub = await SubjectController.instance.createSubject(name: 'Audit & Assurance');
      final exam = await ExamController.instance.createExam(
        title: 'CA Audit Exam',
        subject: 'Audit & Assurance',
        examDateTime: DateTime.now().add(const Duration(days: 7)),
      );
      final task = await TaskController.instance.createTask(
        title: 'Review Chapter 1',
        subjectId: sub.id,
        examId: exam.id,
        estimatedMinutes: 45,
      );

      // 2. Schedule planning blocks on the target day
      await PlanningBlockController.instance.scheduleBlock(
        task.id,
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0),
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 45), // 45 min
        subjectId: sub.id,
        customTitle: 'Review Chapter 1',
      );

      await PlanningBlockController.instance.scheduleSubjectBlock(
        sub.id,
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 11, 0),
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 11, 35), // 35 min
        customTitle: 'Audit Practice',
      );

      expect(PlanningBlockController.instance.blocks.length, 2);

      // 3. Start My Day execution through the real executor + router.
      final dayState = StudentOSAutopilotEngine.computeAutopilotDayState(
        targetDay: tomorrow,
        subjects: SubjectController.instance.activeSubjects,
        exams: ExamController.instance.upcomingExams,
        sessions: StudyController.instance.sessions,
        tasks: TaskController.instance.tasks,
        blocks: PlanningBlockController.instance.blocks,
        referenceTime: ref,
      );
      expect(dayState.startMyDayAction.suggestedDurationMinutes, 45);
      expect(dayState.startMyDayAction.title, contains('Review Chapter 1'));

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRouter.routes(),
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => UniversalActionExecutor.executeAction(
                  ctx,
                  dayState.startMyDayAction,
                ),
                child: const Text('Start My Day'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Start My Day'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final fc = FocusController.instance;
      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession!.plannedDuration.inMinutes, 45);
      expect(fc.activeSession!.subjectId, sub.id);

      // 4. Complete session and verify Next block derivation
      fc.completeSession();
      await TaskController.instance.completeTask(task.id);
      expect(fc.hasActiveSession, isFalse);

      final state2 = StudentOSAutopilotEngine.computeAutopilotDayState(
        targetDay: tomorrow,
        subjects: SubjectController.instance.activeSubjects,
        exams: ExamController.instance.upcomingExams,
        sessions: StudyController.instance.sessions,
        tasks: TaskController.instance.tasks,
        blocks: PlanningBlockController.instance.blocks,
        referenceTime: ref,
      );
      expect(state2.continueMyDayAction, isNotNull);
      expect(state2.continueMyDayAction!.title, contains('Audit Practice'));

      // Cleanup navigation + timers inside the body (binding invariant).
      final ctx = tester.element(find.byType(Scaffold).first);
      while (Navigator.of(ctx).canPop()) {
        Navigator.of(ctx).pop();
        await tester.pump();
      }
      fc.clearData();
    });

    test('FLOW 2: Miss Session -> Recovery -> Rebalance -> Updated Plan', () async {
      final sub = await SubjectController.instance.createSubject(name: 'Business Law');
      final today = DateTime.now();

      // Create a block scheduled in the past on today
      final start = DateTime(today.year, today.month, today.day, 8, 0);
      final end = DateTime(today.year, today.month, today.day, 8, 45);
      final refTime = DateTime(today.year, today.month, today.day, 10, 0);

      final missedBlock = await PlanningBlockController.instance.scheduleSubjectBlock(
        sub.id,
        start,
        end,
        customTitle: 'Law Case Studies',
      );

      final missedList = PlanningEngine.getMissedSessions(
        blocks: PlanningBlockController.instance.blocks,
        tasks: TaskController.instance.tasks,
        subjects: SubjectController.instance.activeSubjects,
        referenceTime: refTime,
      );

      expect(missedList.any((m) => m.block.id == missedBlock.id), isTrue);
      final missedSession = missedList.firstWhere((m) => m.block.id == missedBlock.id);

      // Recover missed session
      final aic = AcademicIntelligenceController.instance;
      final recovered = await aic.recoverMissedSession(
        missedSession,
        newStartTime: refTime.add(const Duration(minutes: 15)),
      );
      expect(recovered, isNotNull);
      expect(recovered!.id, missedBlock.id);
      expect(recovered.startAt.isAfter(missedBlock.startAt), isTrue);
    });

    test('FLOW 3: Available Time Budget (3h) -> Automatic allocation -> No Duplicates', () async {
      await SubjectController.instance.createSubject(name: 'Financial Accounting');
      await SubjectController.instance.createSubject(name: 'Direct Tax');

      final aic = AcademicIntelligenceController.instance;
      final preview = aic.generateAutopilotPlan(
        targetDay: DateTime.now(),
        budgetMinutes: 180,
      );

      expect(preview.hasItems, isTrue);
      expect(preview.availableBudgetMinutes, 180);

      final blocks = await aic.applyAutopilotPlan(preview);
      expect(blocks.isNotEmpty, isTrue);

      final countFirstApply = PlanningBlockController.instance.blocks.length;

      // Repeated apply must not create duplicate blocks
      await aic.applyAutopilotPlan(preview);
      expect(PlanningBlockController.instance.blocks.length, countFirstApply);
    });

    testWidgets('FLOW 4: Active Focus -> Home -> Continue -> Same session preserved', (tester) async {
      final fc = FocusController.instance;
      fc.startTimer(
        duration: const Duration(minutes: 40),
        objective: 'Deep Study Tax',
      );
      final originalSessionId = fc.activeSession!.id;

      final aic = AcademicIntelligenceController.instance;
      final state = aic.autopilotDayState;
      expect(state.hasActiveFocus, isTrue);
      expect(state.nextAction.type, StudentOSActionType.focusActive);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRouter.routes(),
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => aic.startMyDay(ctx),
                child: const Text('Start My Day'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Start My Day'));
      await tester.pumpAndSettle();

      expect(fc.hasActiveSession, isTrue);
      expect(fc.activeSession!.id, originalSessionId);

      fc.cancelSession();
      fc.clearData();
    });

    test('FLOW 5: User A (CA Foundation) -> Logout -> User B -> Isolation preserved', () async {
      final ss = StudentService.instance;
      AuthIsolation.instance.setAuthenticatedUser('user_a_flow5');

      await ss.updateDisplayName('CA Student');
      await ss.updateCatalogEducation(
        category: CourseCategory.professional,
        courseId: 'ca_foundation',
        courseName: 'CA Foundation',
      );
      await ss.completeOnboarding();

      final aic = AcademicIntelligenceController.instance;
      expect(aic.autopilotDayState.targetDay, isNotNull);

      // Logout User A
      ControllerIsolation.instance.clearAllControllers();
      AuthIsolation.instance.clearSession();

      // Login User B
      AuthIsolation.instance.setAuthenticatedUser('user_b_flow5');
      await StudentService.instance.load();

      expect(StudentService.instance.profile.isOnboardingComplete, isFalse);
      expect(StudentService.instance.profile.course, isEmpty);
      expect(PlanningBlockController.instance.blocks, isEmpty);
    });
  });
}
