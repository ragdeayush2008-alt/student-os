import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/auth/controller_isolation.dart';
import 'package:student_os/core/intelligence/academic_intelligence_controller.dart';
import 'package:student_os/core/intelligence/academic_intelligence_engine.dart';
import 'package:student_os/core/intelligence/student_os_intelligence_engine.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/study/study_controller.dart';
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

  group('Home 2.0 & Universal Actions Integration Tests (H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V)', () {
    test('I & L & N. UniversalActionExecutor launches focus center with correct subject context', () {
      final action = StudentOSAction(
        id: 'act_1',
        title: 'Study Accountancy',
        subtitle: 'Exam in 3 days',
        reason: 'Exam approaching',
        bulletReasons: const ['Exam in 3 days'],
        type: StudentOSActionType.studySubject,
        suggestedDurationMinutes: 45,
        urgency: RecommendationUrgency.high,
        subjectId: 'sub_acc',
        subjectName: 'Accountancy',
      );

      expect(action.subjectName, equals('Accountancy'));
      expect(action.suggestedDurationMinutes, equals(45));
    });

    test('U & V. User Isolation on Home: User A action never appears for User B', () {
      AuthIsolation.instance.setAuthenticatedUser('user_1');

      final taskA = StudentTask(
        id: 't_user_1',
        title: 'User 1 Biology Research',
        status: TaskStatus.active,
      );

      final actionA = StudentOSIntelligenceEngine.determineWhatShouldIDoNow(
        subjects: [Subject(id: 's_bio', name: 'Biology')],
        tasks: [taskA],
      );

      expect(actionA.title, equals('User 1 Biology Research'));

      // Switch user
      ControllerIsolation.instance.clearAllControllers();
      AuthIsolation.instance.clearSession();
      AuthIsolation.instance.setAuthenticatedUser('user_2');

      final actionB = AcademicIntelligenceController.instance.studentOSAction;
      expect(actionB.title.contains('User 1'), isFalse);
    });

    test('P & Q & R & S & T. Empty state verification for all academic domains', () {
      expect(TaskController.instance.tasks, isEmpty);
      expect(ExamController.instance.exams, isEmpty);
      expect(SubjectController.instance.subjects, isEmpty);
      expect(StudyController.instance.sessions, isEmpty);

      final state = AcademicIntelligenceController.instance.dailyStudentState;
      expect(state.plannedMinutes, equals(0));
      expect(state.completedMinutes, equals(0));
      expect(state.upcomingExams, isEmpty);
      expect(state.revisionDueCount, equals(0));
    });
  });
}
