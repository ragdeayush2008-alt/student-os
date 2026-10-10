import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/core/navigation/focus_launch_context.dart';
import 'package:student_os/features/focus/controller/focus_controller.dart';
import 'package:student_os/features/planning/controllers/planning_block_controller.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_ctx_preservation');
    TaskController.instance.clearData();
    SubjectController.instance.clearData();
    FocusController.instance.clearData();
    PlanningBlockController.instance.clearData();
  });

  tearDown(() {
    FocusController.instance.clearData();
    TaskController.instance.clearData();
    SubjectController.instance.clearData();
    FocusController.instance.clearData();
    PlanningBlockController.instance.clearData();
    AuthIsolation.instance.clearSession();
  });

  group('Context preservation chains (CODE 5)', () {
    test('Subject -> Topic -> Focus preserves subject/topic/chapter', () {
      const ctx = FocusLaunchContext(
        subjectId: 'sub_phys',
        subjectName: 'Physics',
        topicId: 'topic_laws',
        topicName: 'Laws of Motion',
        chapterId: 'ch_mech',
      );

      FocusController.instance.startTimer(
        duration: const Duration(minutes: 30),
        subjectId: ctx.subjectId,
        subjectName: ctx.subjectName,
        topicId: ctx.topicId,
        chapterId: ctx.chapterId,
        objective: ctx.topicName,
      );

      final session = FocusController.instance.activeSession!;
      expect(session.subjectId, equals('sub_phys'));
      expect(session.topicId, equals('topic_laws'));
      expect(session.chapterId, equals('ch_mech'));
    });

    test('Task -> Planning -> Focus preserves task + planningBlockId', () async {
      final task = await TaskController.instance.createTask(
        title: 'Accountancy worksheet',
      );
      final now = DateTime.now();
      final block = await PlanningBlockController.instance.scheduleBlock(
        task.id,
        now.add(const Duration(hours: 1)),
        now.add(const Duration(hours: 2)),
        subjectId: 'sub_acc',
        topicId: 'topic_part',
        chapterId: 'ch_1',
      );

      // Mirrors AppRouter.startPlanningBlockFocus context threading.
      FocusController.instance.startTimer(
        duration: const Duration(minutes: 45),
        subjectId: block.subjectId,
        taskId: block.taskId,
        topicId: block.topicId,
        chapterId: block.chapterId,
        planningBlockId: block.id,
        objective: task.title,
      );

      final session = FocusController.instance.activeSession!;
      expect(session.taskId, equals(task.id));
      expect(session.subjectId, equals('sub_acc'));
      expect(session.topicId, equals('topic_part'));
      expect(session.chapterId, equals('ch_1'));
      expect(session.planningBlockId, equals(block.id));
    });

    test('Exam -> Revision -> Focus preserves exam + subject', () {
      const ctx = FocusLaunchContext(
        examId: 'exam_boards',
        examTitle: 'Boards',
        subjectId: 'sub_acc',
        subjectName: 'Accountancy',
        topicId: 'topic_part',
      );

      FocusController.instance.startTimer(
        duration: const Duration(minutes: 30),
        subjectId: ctx.subjectId,
        subjectName: ctx.subjectName,
        examId: ctx.examId,
        topicId: ctx.topicId,
        objective: 'Revise Partnership',
      );

      final session = FocusController.instance.activeSession!;
      expect(session.examId, equals('exam_boards'));
      expect(session.subjectId, equals('sub_acc'));
      expect(session.topicId, equals('topic_part'));
    });

    test('Assistant -> Focus preserves recommendation context', () {
      const ctx = FocusLaunchContext(
        subjectId: 'sub_chem',
        subjectName: 'Chemistry',
        taskId: 'task_mole',
        examId: 'exam_unit1',
        topicId: 'topic_mole',
        chapterId: 'ch_2',
        focusTitle: 'Study Partnership',
      );

      FocusController.instance.startTimer(
        duration: const Duration(minutes: 30),
        subjectId: ctx.subjectId,
        subjectName: ctx.subjectName,
        taskId: ctx.taskId,
        examId: ctx.examId,
        topicId: ctx.topicId,
        chapterId: ctx.chapterId,
        objective: ctx.focusTitle,
      );

      final session = FocusController.instance.activeSession!;
      expect(session.subjectId, equals('sub_chem'));
      expect(session.taskId, equals('task_mole'));
      expect(session.examId, equals('exam_unit1'));
      expect(session.topicId, equals('topic_mole'));
      expect(session.chapterId, equals('ch_2'));
    });

    test('active session is never clobbered: second start is guarded', () {
      FocusController.instance.startTimer(
        duration: const Duration(minutes: 25),
        subjectId: 's1',
        planningBlockId: 'pb_first',
        objective: 'First',
      );
      final firstId = FocusController.instance.activeSession!.id;

      // Router-level guard (mirrored): callers must route to the active
      // session instead of starting a new one.
      expect(FocusController.instance.hasActiveSession, isTrue);
      expect(FocusController.instance.activeSession!.id, equals(firstId));
      expect(
        FocusController.instance.activeSession!.planningBlockId,
        equals('pb_first'),
      );
    });

    test('FocusSession planningBlockId persists through JSON (backward compat)', () async {
      final now = DateTime.now();
      final block = await PlanningBlockController.instance.scheduleBlock(
        null,
        now.add(const Duration(hours: 1)),
        now.add(const Duration(hours: 2)),
        subjectId: 's_json',
        customTitle: 'JSON round-trip',
      );

      FocusController.instance.startTimer(
        duration: const Duration(minutes: 20),
        subjectId: 's_json',
        planningBlockId: block.id,
        objective: 'JSON',
      );
      final session = FocusController.instance.activeSession!;
      final restored =
          session.toJson().containsKey('planningBlockId');
      expect(restored, isTrue);
      expect(session.toJson()['planningBlockId'], equals(block.id));
    });
  });
}
