import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/intelligence/daily_os_coordinator.dart';
import 'package:student_os/core/intelligence/smart_recommendation_engine.dart';
import 'package:student_os/data/models/exam.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/task.dart';
import 'package:student_os/features/exams/exam_controller.dart';
import 'package:student_os/features/home/home_navigation.dart';
import 'package:student_os/features/subjects/subject_controller.dart';
import 'package:student_os/features/tasks/task_controller.dart';
import 'package:student_os/core/intelligence/adaptive_priority_engine.dart';

/// Phase 5 — Academic workspace data-safety regression.
///
/// Deleting subjects/exams must preserve user data (tasks/resources survive
/// with cleared references), never crash lookups, never leak into NOW/NEXT,
/// and never cross user boundaries. Legacy JSON must keep deserializing.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DailyOsCoordinator.instance.init();
    await _clean();
  });

  tearDown(() async {
    await _clean();
  });

  group('deletion preserves data and stability', () {
    test('subject delete: tasks survive unlinked, lookups stay safe', () async {
      final subject = await SubjectController.instance.createSubject(
        name: 'Fragile',
      );
      final t1 = await TaskController.instance.createTask(
        title: 'Linked A',
        subjectId: subject.id,
      );
      final t2 = await TaskController.instance.createTask(
        title: 'Linked B',
        subjectId: subject.id,
      );

      await SubjectController.instance.deleteSubject(subject.id);

      for (final id in [t1.id, t2.id]) {
        final remaining = TaskController.instance.tasks
            .where((t) => t.id == id)
            .toList();
        expect(remaining.length, 1, reason: 'task $id must survive');
        expect(remaining.single.subjectId, isNull);
      }
      expect(TaskController.instance.tasksForSubject(subject.id), isEmpty);
      expect(SubjectController.instance.subjectById(subject.id), isNull);

      // Daily OS stays valid with no dangling ids.
      const engine = SmartRecommendationEngine();
      expect(
        engine.orderRecommendations().any((a) => a.subjectId == subject.id),
        isFalse,
      );
    });

    test(
      'exam delete: tasks survive unlinked, exam lookups stay safe',
      () async {
        final exam = await ExamController.instance.createExam(
          title: 'Fragile exam',
          examDateTime: DateTime.now().add(const Duration(days: 3)),
        );
        final task = await TaskController.instance.createTask(
          title: 'Exam prep',
          examId: exam.id,
        );

        await ExamController.instance.deleteExam(exam.id);

        final remaining = TaskController.instance.tasks
            .where((t) => t.id == task.id)
            .toList();
        expect(remaining.length, 1);
        expect(remaining.single.examId, isNull);
        expect(TaskController.instance.tasksForExam(exam.id), isEmpty);
        expect(
          ExamController.instance.exams.any((e) => e.id == exam.id),
          isFalse,
        );

        const engine = SmartRecommendationEngine();
        expect(
          engine.orderRecommendations().any((a) => a.examId == exam.id),
          isFalse,
        );
        expect(
          HomeNavigation.resolveDestination(
            PrioritizedAction(
              id: 'exam_${exam.id}',
              title: 'stale',
              reason: 'stale',
              estimatedMinutes: 35,
              type: AcademicActionType.examPreparation,
              priorityScore: 200,
              examId: exam.id,
            ),
          ),
          isNull,
        );
      },
    );

    test(
      'task delete removes it from exam linkage and recommendations',
      () async {
        final exam = await ExamController.instance.createExam(
          title: 'Link exam',
        );
        final task = await TaskController.instance.createTask(
          title: 'Doomed prep',
          examId: exam.id,
        );

        await TaskController.instance.deleteTask(task.id);

        expect(TaskController.instance.tasksForExam(exam.id), isEmpty);
        expect(ExamController.instance.hasLinkedTasks(exam), isFalse);
        const engine = SmartRecommendationEngine();
        expect(
          engine.orderRecommendations().any((a) => a.taskId == task.id),
          isFalse,
        );
      },
    );
  });

  group('user isolation', () {
    test('logout clears derived and in-memory workspace state', () async {
      await SubjectController.instance.createSubject(name: 'Iso sub');
      await TaskController.instance.createTask(title: 'Iso task');
      await ExamController.instance.createExam(title: 'Iso exam');
      expect(DailyOsCoordinator.instance.snapshot, isNotNull);

      // Phase 1 isolation contract: controllers drop session state.
      SubjectController.instance.clearData();
      TaskController.instance.clearData();
      ExamController.instance.clearData();
      DailyOsCoordinator.instance.clearOnLogout();

      expect(SubjectController.instance.subjects, isEmpty);
      expect(TaskController.instance.tasks, isEmpty);
      expect(ExamController.instance.exams, isEmpty);
      expect(DailyOsCoordinator.instance.snapshot, isNull);

      DailyOsCoordinator.instance.init();
    });
  });

  group('legacy JSON compatibility', () {
    test('old task JSON without relationship fields loads safely', () {
      final task = StudentTask.fromJson({
        'id': 'legacy_1',
        'title': 'Legacy task',
        'createdAt': '2024-01-15T10:00:00.000',
        'sortOrder': 1,
      });
      expect(task.id, 'legacy_1');
      expect(task.subjectId, isNull);
      expect(task.examId, isNull);
      expect(task.reminderEnabled, isFalse);
    });

    test('old subject JSON without new fields loads safely', () {
      final subject = Subject.fromJson({
        'id': 'legacy_sub',
        'name': 'Legacy',
        'createdAt': '2024-01-15T10:00:00.000',
      });
      expect(subject.name, 'Legacy');
      expect(subject.archived, isFalse);
    });

    test('old exam JSON without syllabus loads safely', () {
      final exam = StudentExam.fromJson({
        'id': 'legacy_exam',
        'title': 'Legacy exam',
        'createdAt': '2024-01-15T10:00:00.000',
      });
      expect(exam.title, 'Legacy exam');
      expect(exam.subject, '');
      expect(exam.syllabusItems, isEmpty);
      expect(exam.isUpcoming, isTrue);
    });
  });
}

Future<void> _clean() async {
  for (final task in List.of(TaskController.instance.tasks)) {
    await TaskController.instance.deleteTask(task.id);
  }
  for (final exam in List.of(ExamController.instance.exams)) {
    await ExamController.instance.deleteExam(exam.id);
  }
  for (final subject in List.of(SubjectController.instance.subjects)) {
    await SubjectController.instance.deleteSubject(subject.id);
  }
  DailyOsCoordinator.instance.refresh();
}
