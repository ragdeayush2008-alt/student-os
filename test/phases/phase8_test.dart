import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:student_os/core/intelligence/planning_intelligence_engine.dart';
import 'package:student_os/core/intelligence/student_snapshot.dart';
import 'package:student_os/core/intelligence/today_intelligence_engine.dart';
import 'package:student_os/data/models/academic_resource.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/resources/resource_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 8 — StudentSnapshot Aggregation', () {
    test('derives clean snapshot from empty controllers', () {
      final snapshot = StudentSnapshot.fromControllers();
      expect(snapshot.hasOverdueTasks, isFalse);
      expect(snapshot.hasTodayTasks, isFalse);
      expect(snapshot.hasUpcomingExams, isFalse);
      expect(snapshot.hasRecentResources, isFalse);
    });

    test('snapshot reflects updated task and exam data', () async {
      final task = await TaskController.instance.createTask(
        title: 'Complete math assignment',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      final exam = await ExamController.instance.createExam(
        title: 'Math Exam',
        subject: 'Math',
        examDateTime: DateTime.now().add(const Duration(days: 2)),
      );

      final snapshot = StudentSnapshot.fromControllers();

      expect(snapshot.hasOverdueTasks, isTrue);
      expect(snapshot.overdueTasks.first.id, task.id);
      expect(snapshot.hasUpcomingExams, isTrue);
      expect(snapshot.nextExam?.id, exam.id);

      // Cleanup
      await TaskController.instance.deleteTask(task.id);
      await ExamController.instance.deleteExam(exam.id);
    });
  });

  group('Phase 8 — TodayIntelligenceEngine', () {
    const engine = TodayIntelligenceEngine();

    test('identifies overdue task as critical focus item', () async {
      final task = await TaskController.instance.createTask(
        title: 'Late physics report',
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
      );

      final snapshot = StudentSnapshot.fromControllers();
      final focusItems = engine.deriveFocusItems(snapshot);

      expect(focusItems.isNotEmpty, isTrue);
      expect(focusItems.first.taskId, task.id);
      expect(focusItems.first.urgency, FocusUrgency.critical);

      await TaskController.instance.deleteTask(task.id);
    });

    test('identifies close upcoming exam as focus item', () async {
      final exam = await ExamController.instance.createExam(
        title: 'Chemistry Midterm',
        subject: 'Chemistry',
        examDateTime: DateTime.now().add(const Duration(days: 1)),
      );

      final snapshot = StudentSnapshot.fromControllers();
      final focusItems = engine.deriveFocusItems(snapshot);

      final examItem = focusItems.where((i) => i.examId == exam.id).firstOrNull;
      expect(examItem, isNotNull);
      expect(examItem!.urgency, FocusUrgency.critical);

      await ExamController.instance.deleteExam(exam.id);
    });

    test('prioritizes smart resources based on upcoming exam', () async {
      final exam = await ExamController.instance.createExam(
        title: 'History Quiz',
        subject: 'History',
        examDateTime: DateTime.now().add(const Duration(days: 2)),
      );

      final resource = await ResourceController.instance.createResource(
        title: 'World War II Summary',
        resourceType: ResourceType.note,
        examId: exam.id,
      );

      final snapshot = StudentSnapshot.fromControllers();
      final recommendations = engine.deriveSmartResources(snapshot);

      expect(recommendations.isNotEmpty, isTrue);
      expect(recommendations.first.resource.id, resource.id);
      expect(recommendations.first.reason, contains('History Quiz'));

      await ResourceController.instance.deleteResource(resource.id);
      await ExamController.instance.deleteExam(exam.id);
    });
  });

  group('Phase 8 — PlanningIntelligenceEngine', () {
    const engine = PlanningIntelligenceEngine();

    test('flags overloaded days when tasks >= 5', () async {
      final today = DateTime.now();
      final createdIds = <String>[];

      for (var i = 0; i < 5; i++) {
        final task = await TaskController.instance.createTask(
          title: 'Busy task $i',
          dueDate: today,
        );
        createdIds.add(task.id);
      }

      final snapshot = StudentSnapshot.fromControllers();
      final suggestions = engine.deriveSuggestions(snapshot, today);

      expect(
        suggestions.any((s) => s.title.contains('Heavy workload')),
        isTrue,
      );

      for (final id in createdIds) {
        await TaskController.instance.deleteTask(id);
      }
    });

    test('identifies exam preparation gaps', () async {
      final exam = await ExamController.instance.createExam(
        title: 'Biology Test',
        subject: 'Biology',
        examDateTime: DateTime.now().add(const Duration(days: 4)),
      );

      final task = await TaskController.instance.createTask(
        title: 'Read cells chapter',
        examId: exam.id,
      );

      final snapshot = StudentSnapshot.fromControllers();
      final suggestions = engine.deriveSuggestions(snapshot, DateTime.now());

      final examSuggestion = suggestions
          .where((s) => s.examId == exam.id)
          .firstOrNull;
      expect(examSuggestion, isNotNull);
      expect(examSuggestion!.title, contains('Biology Test'));

      await TaskController.instance.deleteTask(task.id);
      await ExamController.instance.deleteExam(exam.id);
    });
  });
}
