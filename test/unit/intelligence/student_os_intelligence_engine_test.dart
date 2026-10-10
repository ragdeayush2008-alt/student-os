import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/intelligence/academic_intelligence_engine.dart';
import 'package:student_os/core/intelligence/student_os_intelligence_engine.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/data/models/study_session.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/goals/goal_controller.dart';
import 'package:student_os/features/planning/models/planning_block.dart';
import 'package:student_os/features/planning/services/planning_engine.dart';
import 'package:student_os/features/preferences/user_preferences_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 9, 15, 10, 0);

  group('StudentOSIntelligenceEngine — Primary Action (A, B, C, D, E, L, AA)', () {
    test('A & L. Active focus session takes top priority over other recommendations', () {
      final action = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
        subjects: [Subject(id: 's1', name: 'Law')],
        hasActiveFocus: true,
        activeFocusObjective: 'Review Contracts',
        activeFocusRemaining: const Duration(minutes: 22),
        referenceTime: now,
      );

      expect(action.type, equals(StudentOSActionType.focusActive));
      expect(action.title, equals('Review Contracts'));
      expect(action.subtitle, contains('22 min remaining'));
    });

    test('B & E. Overdue critical task is prioritized over regular tasks', () {
      final task1 = StudentTask(
        id: 't1',
        title: 'Submit Assignment',
        dueDate: now.subtract(const Duration(days: 2)),
        priority: TaskPriority.critical,
      );

      final task2 = StudentTask(
        id: 't2',
        title: 'Read Book Chapter',
        dueDate: now.add(const Duration(days: 5)),
        priority: TaskPriority.low,
      );

      final action = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
        subjects: const [],
        tasks: [task1, task2],
        referenceTime: now,
      );

      expect(action.type, equals(StudentOSActionType.completeTask));
      expect(action.taskId, equals('t1'));
      expect(action.urgency, equals(RecommendationUrgency.critical));
      expect(action.bulletReasons, isNotEmpty);
    });

    test('C. High exam pressure triggers exam prep priority with transparent reasons (AA)', () {
      final exam = StudentExam(
        id: 'ex1',
        title: 'Accountancy Final',
        subject: 'Accountancy',
        examDateTime: now.add(const Duration(days: 2)),
        syllabusItems: [
          SyllabusItem(id: 's1', title: 'Balance Sheets', completed: false),
        ],
      );

      final action = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
        subjects: [Subject(id: 'sub_acc', name: 'Accountancy')],
        exams: [exam],
        referenceTime: now,
      );

      expect(action.type, equals(StudentOSActionType.examPrep));
      expect(action.examId, equals('ex1'));
      expect(action.topicTitle, equals('Balance Sheets'));
      expect(action.reason, isNotEmpty);
      expect(action.bulletReasons.isNotEmpty, isTrue);
    });

    test('D. Overdue revision topic is prioritized when no active exam or overdue task', () {
      final exam = StudentExam(
        id: 'ex2',
        title: 'Taxation Midterm',
        subject: 'Taxation',
        examDateTime: now.add(const Duration(days: 4)),
        syllabusItems: [
          SyllabusItem(
            id: 'top1',
            title: 'Direct Taxes',
            completed: true,
            completedAt: now.subtract(const Duration(days: 10)),
          ),
        ],
      );

      final action = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
        subjects: [Subject(id: 'sub_tax', name: 'Taxation')],
        exams: [exam],
        sessions: [
          StudySession(
            id: 'sess1',
            subject: 'Taxation',
            startedAt: now.subtract(const Duration(days: 10)),
            durationSec: 30 * 60,
          ),
        ],
        referenceTime: now,
      );

      expect(action.type, equals(StudentOSActionType.reviseTopic));
      expect(action.topicTitle, equals('Direct Taxes'));
    });
  });

  group('StudentOSIntelligenceEngine — Available Time & Scenarios (G, H, I, J, K)', () {
    final sub1 = Subject(id: 's1', name: 'Accountancy', preference: SubjectPreference.high);
    final sub2 = Subject(id: 's2', name: 'Business Law', preference: SubjectPreference.normal);

    test('H. 30-minute scenario selects single best action within 30 min budget', () {
      final task = StudentTask(
        id: 't_burst',
        title: 'Solve 5 problems',
        dueDate: now,
        estimatedMinutes: 25,
      );

      final burst = StudentOSIntelligenceEngine.generateThirtyMinuteBurst(
        subjects: [sub1, sub2],
        tasks: [task],
        referenceTime: now,
      );

      expect(burst.suggestedDurationMinutes, lessThanOrEqualTo(30));
      expect(burst.taskId, equals('t_burst'));
    });

    test('I. 2-hour scenario generates multi-subject allocation with breaks', () {
      final alloc = AcademicIntelligenceEngine.allocateStudyTime(
        availableMinutes: 120,
        subjects: [sub1, sub2],
        referenceTime: now,
      );

      expect(alloc.totalAvailableMinutes, equals(120));
      expect(alloc.blocks.any((b) => b.isBreak), isTrue);
      expect(alloc.studyBlocks.length, greaterThanOrEqualTo(2));
    });

    test('J. Overloaded day is detected when scheduled blocks exceed daily budget', () {
      final block1 = PlanningBlock(
        id: 'b1',
        userId: 'u1',
        customTitle: 'Block 1',
        startAt: DateTime(2026, 9, 15, 9, 0),
        endAt: DateTime(2026, 9, 15, 11, 0),
      );
      final block2 = PlanningBlock(
        id: 'b2',
        userId: 'u1',
        customTitle: 'Block 2',
        startAt: DateTime(2026, 9, 15, 11, 30),
        endAt: DateTime(2026, 9, 15, 13, 0),
      );

      final state = StudentOSIntelligenceEngine.computeDailyStudentState(
        subjects: [sub1],
        blocks: [block1, block2],
        availableBudgetMinutes: 120, // 2h budget vs 3.5h scheduled
        referenceTime: now,
      );

      expect(state.workloadState, equals(WorkloadState.overloaded));
      expect(state.overloadMinutes, equals(90));
    });

    test('K. Missed-day / missed session recovery identifies past uncompleted blocks', () {
      final pastBlock = PlanningBlock(
        id: 'b_past',
        userId: 'u1',
        taskId: 't_missed',
        startAt: now.subtract(const Duration(hours: 3)),
        endAt: now.subtract(const Duration(hours: 2)),
      );

      final missedTask = StudentTask(
        id: 't_missed',
        title: 'Missed Accountancy Homework',
        status: TaskStatus.active,
      );

      final missed = PlanningEngine.getMissedSessions(
        blocks: [pastBlock],
        tasks: [missedTask],
        referenceTime: now,
      );

      expect(missed.isNotEmpty, isTrue);
      expect(missed.first.title, equals('Missed Accountancy Homework'));
    });
  });

  group('StudentOSIntelligenceEngine — Sparse & Empty Data (M, N, O, P, Q)', () {
    test('M & N & O & P & Q. Empty state produces safe graceful result without throwing', () {
      final action = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
        subjects: const [],
        exams: const [],
        sessions: const [],
        tasks: const [],
        resources: const [],
        blocks: const [],
        referenceTime: now,
      );

      expect(action.type, equals(StudentOSActionType.empty));
      expect(action.title, equals('All Caught Up'));

      final state = StudentOSIntelligenceEngine.computeDailyStudentState(
        subjects: const [],
        referenceTime: now,
      );

      expect(state.plannedMinutes, equals(0));
      expect(state.completedMinutes, equals(0));
      expect(state.upcomingExams, isEmpty);
      expect(state.workloadState, equals(WorkloadState.balanced));

      final briefing = StudentOSIntelligenceEngine.generateDailyBriefing(
        subjects: const [],
        referenceTime: now,
      );

      expect(briefing.todayBulletSummaries, isNotEmpty);
      expect(briefing.recommendedPriorities, isEmpty);

      final risks = StudentOSIntelligenceEngine.detectAcademicRisks(
        subjects: const [],
        referenceTime: now,
      );

      expect(risks, isEmpty);
    });
  });

  group('StudentOSIntelligenceEngine — Autopilot Modes & Safety (R, S, T, U, V, W)', () {
    final sub = Subject(id: 'sub_ap', name: 'Economics');
    final task = StudentTask(id: 't_ap', title: 'Read Ch 2', estimatedMinutes: 30);

    test('R. Autopilot OFF does not allow auto-apply', () {
      final preview = StudentOSIntelligenceEngine.generateAutopilotPlan(
        targetDay: now,
        subjects: [sub],
        tasks: [task],
        mode: AutopilotMode.off,
      );

      expect(preview.mode, equals(AutopilotMode.off));
      expect(preview.canAutoApply, isFalse);
    });

    test('S. Autopilot SUGGEST prepares preview requiring user 1-tap confirmation', () {
      final preview = StudentOSIntelligenceEngine.generateAutopilotPlan(
        targetDay: now,
        subjects: [sub],
        tasks: [task],
        mode: AutopilotMode.suggest,
      );

      expect(preview.mode, equals(AutopilotMode.suggest));
      expect(preview.canAutoApply, isFalse);
      expect(preview.hasItems, isTrue);
    });

    test('T & U & V. Autopilot AUTOPILOT allows safe auto-apply only within budget and is non-destructive', () {
      final preview = StudentOSIntelligenceEngine.generateAutopilotPlan(
        targetDay: now,
        subjects: [sub],
        tasks: [task],
        availableBudgetMinutes: 180,
        mode: AutopilotMode.autopilot,
      );

      expect(preview.mode, equals(AutopilotMode.autopilot));
      expect(preview.canAutoApply, isTrue);
      expect(preview.isOverloaded, isFalse);
    });
  });

  group('StudentOSIntelligenceEngine — Goal Integration & Backward Compatibility (F, Z)', () {
    test('Goal Intelligence accurately calculates progress fraction and work requirement', () {
      final goalCtrl = GoalController.instance;
      goalCtrl.setDailyStudyTarget(const Duration(minutes: 60));
      goalCtrl.setWeeklyStudyTarget(const Duration(hours: 10));
      goalCtrl.setWeeklyTaskTarget(10);
      goalCtrl.setPersonalGoal('Pass Foundation');

      final sessions = [
        StudySession(
          id: 's_g1',
          subject: 'General',
          startedAt: now,
          durationSec: 120 * 60,
          completed: true,
        ),
      ];

      final summary = StudentOSIntelligenceEngine.assessGoalIntelligence(
        goalController: goalCtrl,
        sessions: sessions,
        tasks: const [],
        referenceTime: now,
      );

      expect(summary, isNotNull);
      expect(summary!.personalGoal, equals('Pass Foundation'));
      expect(summary.weeklyStudyActualMinutes, equals(120));
      expect(summary.studyProgressFraction, equals(0.2));
    });

    test('Backward compatibility with AutopilotMode serialization in UserPreferencesController', () {
      expect(AutopilotMode.values.length, equals(3));
      expect(AutopilotMode.suggest.name, equals('suggest'));
      expect(AutopilotMode.autopilot.name, equals('autopilot'));
      expect(AutopilotMode.off.name, equals('off'));
    });
  });
}
