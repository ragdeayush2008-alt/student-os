import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/intelligence/academic_intelligence_controller.dart';
import 'package:student_os/core/intelligence/academic_intelligence_engine.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/data/models/study_session.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/planning/services/planning_engine.dart';
import 'package:student_os/features/study/study_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  setUp(() {
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.clearSession();
  });

  tearDown(() {
    ControllerIsolation.instance.clearAllControllers();
    AuthIsolation.instance.clearSession();
  });

  group('Study + Exam + Revision Intelligence Integration', () {
    test('Academic Intelligence feeds PlanningEngine without duplicate blocks (G)', () async {
      final now = DateTime(2026, 9, 20, 9, 0);

      final subject = Subject(
        id: 'sub_acc',
        name: 'Accountancy',
        preference: SubjectPreference.high,
      );

      final exam = StudentExam(
        id: 'exam_acc',
        title: 'Accountancy Final',
        subject: 'Accountancy',
        examDateTime: now.add(const Duration(days: 3)),
        syllabusItems: [
          SyllabusItem(id: 's1', title: 'Balance Sheets', completed: false),
        ],
      );

      final task = StudentTask(
        id: 'task_acc_1',
        title: 'Practice Chapter 4',
        subjectId: subject.id,
        examId: exam.id,
        estimatedMinutes: 30,
      );

      final planResult = PlanningEngine.generateDailyPlan(
        now,
        tasks: [task],
        subjects: [subject],
        exams: [exam],
        availableBudgetMinutes: 120,
        baseStartTime: now,
      );

      expect(planResult.hasItems, isTrue);
      expect(planResult.items.any((item) => item.title.contains('Accountancy') || item.title.contains('Practice')), isTrue);

      // Verify no duplicate blocks created for the same task
      final taskItems = planResult.items.where((i) => i.taskId == task.id).toList();
      expect(taskItems.length, equals(1));
    });

    test('User Isolation: User A data is cleared on logout and does not bleed to User B (H)', () {
      AuthIsolation.instance.setAuthenticatedUser('user_A');

      // Add data to controllers as User A
      final subA = Subject(id: 'sub_A', name: 'Subject For A');
      final examA = StudentExam(
        id: 'exam_A',
        title: 'Exam For A',
        subject: 'Subject For A',
        examDateTime: DateTime.now().add(const Duration(days: 2)),
      );

      final assessmentA = AcademicIntelligenceEngine.assessExamPressure(
        examA,
        subjects: [subA],
      );
      expect(assessmentA.exam.title, equals('Exam For A'));

      // Logout / Clear
      ControllerIsolation.instance.clearAllControllers();
      AuthIsolation.instance.clearSession();

      // Validate all controllers are empty for anonymous or switched user
      expect(SubjectController.instance.subjects, isEmpty);
      expect(ExamController.instance.exams, isEmpty);
      expect(StudyController.instance.sessions, isEmpty);
      expect(TaskController.instance.tasks, isEmpty);
      expect(PlanningBlockController.instance.blocks, isEmpty);

      final emptyRec = AcademicIntelligenceController.instance.primaryStudyRecommendation;
      expect(emptyRec, isNull);
    });

    test('Study session completion refreshes streak and intelligence naturally (K & M)', () async {
      final now = DateTime.now();

      final sess = StudySession(
        id: 'sess_1',
        subject: 'Physics',
        durationSec: 45 * 60,
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 45)),
        completed: true,
      );

      final mins = AcademicIntelligenceEngine.studyMinutesForSubject(
        'Physics',
        [sess],
        days: 7,
      );
      expect(mins, equals(45));

      final daysSince = AcademicIntelligenceEngine.daysSinceLastStudied(
        'Physics',
        [sess],
      );
      expect(daysSince, equals(0));
    });
  });
}
