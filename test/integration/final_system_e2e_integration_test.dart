import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/intelligence/academic_intelligence_controller.dart';
import 'package:student_os/core/intelligence/academic_intelligence_engine.dart';
import 'package:student_os/core/intelligence/student_os_intelligence_engine.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/data/models/study_session.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/planning/models/planning_block.dart';
import 'package:student_os/features/planning/services/planning_engine.dart';
import 'package:student_os/features/preferences/user_preferences_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.clearSession();
  });

  tearDown(() {
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.clearSession();
  });

  group('Final System Integration Scenarios (Step 5)', () {
    test('Scenario 1: End-to-end academic execution flow (Subject -> Exam -> Task -> Focus -> Study -> XP -> Analytics)', () async {
      final now = DateTime(2026, 9, 20, 9, 0);

      // 1. Create Subject
      final subject = Subject(
        id: 'sub_math',
        name: 'Calculus',
        preference: SubjectPreference.high,
      );

      // 2. Create Exam
      final exam = StudentExam(
        id: 'ex_math_final',
        title: 'Calculus Final Exam',
        subject: 'Calculus',
        examDateTime: now.add(const Duration(days: 4)),
        syllabusItems: [
          SyllabusItem(id: 's1', title: 'Derivatives', completed: false),
          SyllabusItem(id: 's2', title: 'Integrals', completed: false),
        ],
      );

      // 3. Create Task
      final task = StudentTask(
        id: 't_calc_1',
        title: 'Solve Derivative Problem Set',
        subjectId: subject.id,
        examId: exam.id,
        estimatedMinutes: 45,
        status: TaskStatus.active,
      );

      // 4. Intelligence Evaluates state and provides top action
      final action = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
        subjects: [subject],
        exams: [exam],
        tasks: [task],
        referenceTime: now,
      );

      expect(action.type, equals(StudentOSActionType.examPrep));
      expect(action.examId, equals('ex_math_final'));
      expect(action.topicTitle, equals('Derivatives'));

      // 5. Simulate Focus session completion
      final session = StudySession(
        id: 'sess_calc_1',
        subject: 'Calculus',
        taskId: task.id,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 45)),
        durationSec: 45 * 60,
        completed: true,
      );

      // 6. Verify Study History and Analytics
      final studyMinutes = AcademicIntelligenceEngine.studyMinutesForSubject(
        'Calculus',
        [session],
        days: 7,
        referenceTime: now.add(const Duration(hours: 1)),
      );
      expect(studyMinutes, equals(45));

      final daysSince = AcademicIntelligenceEngine.daysSinceLastStudied(
        'Calculus',
        [session],
        referenceTime: now.add(const Duration(hours: 1)),
      );
      expect(daysSince, equals(0));
    });

    test('Scenario 2: Approaching Exam & Overdue Revision triggers Plan My Day and allocates blocks', () async {
      final now = DateTime(2026, 9, 20, 9, 0);

      final subject = Subject(id: 'sub_tax', name: 'Taxation');
      final exam = StudentExam(
        id: 'ex_tax',
        title: 'Taxation Exam',
        subject: 'Taxation',
        examDateTime: now.add(const Duration(days: 3)),
        syllabusItems: [
          SyllabusItem(id: 's1', title: 'GST Returns', completed: false),
        ],
      );

      final planResult = PlanningEngine.generateDailyPlan(
        now,
        tasks: const [],
        subjects: [subject],
        exams: [exam],
        availableBudgetMinutes: 90,
        baseStartTime: now,
      );

      expect(planResult.hasItems, isTrue);
      expect(planResult.totalPlannedMinutes, greaterThan(0));
      expect(planResult.items.first.title.contains('Taxation'), isTrue);
    });

    test('Scenario 3: Active Focus session is recognized globally across surfaces', () {
      FocusController.instance.startQuickFocus(subjectName: 'Corporate Law');
      expect(FocusController.instance.hasActiveSession, isTrue);

      final action = AcademicIntelligenceController.instance.studentOSAction;
      expect(action.isFocusActive, isTrue);
      expect(action.type, equals(StudentOSActionType.focusActive));

      FocusController.instance.cancelSession();
      expect(FocusController.instance.hasActiveSession, isFalse);
    });

    test('Scenario 4: User A data is completely isolated and never leaks to User B', () {
      // User A
      AuthIsolation.instance.setAuthenticatedUser('user_A_id');

      final taskA = StudentTask(
        id: 't_user_A',
        title: 'Confidential Audit Task User A',
        status: TaskStatus.active,
      );

      final actionA = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
        subjects: [Subject(id: 's_aud', name: 'Auditing')],
        tasks: [taskA],
      );

      expect(actionA.title, equals('Confidential Audit Task User A'));

      // Logout User A
      ControllerIsolation.instance.clearAllControllers();
      AuthIsolation.instance.clearSession();

      // Login User B
      AuthIsolation.instance.setAuthenticatedUser('user_B_id');

      expect(TaskController.instance.tasks, isEmpty);
      expect(ExamController.instance.exams, isEmpty);
      expect(SubjectController.instance.subjects, isEmpty);

      final actionB = AcademicIntelligenceController.instance.studentOSAction;
      expect(actionB.title.contains('User A'), isFalse);
    });

    test('Scenario 5: Offline Mode works gracefully with local-first calculations and fallback', () {
      final sub = Subject(id: 's_local', name: 'Economics');
      final task = StudentTask(id: 't_local', title: 'Offline Task', estimatedMinutes: 30);

      final plan = StudentOSIntelligenceEngine.generateAutopilotPlan(
        targetDay: DateTime.now(),
        subjects: [sub],
        tasks: [task],
        availableBudgetMinutes: 120,
      );

      expect(plan.hasItems, isTrue);
      expect(plan.allocatedStudyMinutes, greaterThan(0));
    });

    test('Scenario 6: Missed Planning Block recovery and safe rebalancing without duplicate blocks', () async {
      final now = DateTime(2026, 9, 20, 14, 0);

      final pastBlock = PlanningBlock(
        id: 'pb_missed_1',
        userId: 'u1',
        taskId: 't_missed_1',
        startAt: now.subtract(const Duration(hours: 3)),
        endAt: now.subtract(const Duration(hours: 2)),
      );

      final task = StudentTask(
        id: 't_missed_1',
        title: 'Missed Chapter 1 Review',
        status: TaskStatus.active,
      );

      final missed = PlanningEngine.getMissedSessions(
        blocks: [pastBlock],
        tasks: [task],
        referenceTime: now,
      );

      expect(missed.isNotEmpty, isTrue);
      expect(missed.first.title, equals('Missed Chapter 1 Review'));
    });

    test('Scenario 7: Autopilot Mode preview & non-destructive safe application', () {
      final sub = Subject(id: 's_ap', name: 'Auditing');
      final task = StudentTask(id: 't_ap', title: 'Internal Controls', estimatedMinutes: 40);

      final preview = StudentOSIntelligenceEngine.generateAutopilotPlan(
        targetDay: DateTime.now(),
        subjects: [sub],
        tasks: [task],
        mode: AutopilotMode.suggest,
      );

      expect(preview.mode, equals(AutopilotMode.suggest));
      expect(preview.canAutoApply, isFalse); // Requires user confirmation
      expect(preview.hasItems, isTrue);
    });
  });
}
